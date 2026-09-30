import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/top_fan_model.dart';

class TopFansController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var allTopFans = <TopFanModel>[].obs;
  var filteredTopFans = <TopFanModel>[].obs;

  // خيارات الفلترة لعدد المستخدمين المُراد عرضهم
  var selectedLimit = 5.obs;
  final List<int> limitOptions = [2, 3, 4, 5, 10, 20, 50];

  final TextEditingController searchController = TextEditingController();

  StreamSubscription<QuerySnapshot>? _usersSubscription;
  // قائمة للاحتفاظ بالـ Subscriptions الخاصة بأوردرات كل مستخدم لمنع التسريب
  final Map<String, StreamSubscription<QuerySnapshot>> _ordersSubscriptions = {};
  // خريطة لتخزين أحدث بيانات TopFanModel لكل مستخدم بشكل لحظي
  final Map<String, TopFanModel> _fansMap = {};

  @override
  void onInit() {
    super.onInit();
    listenToUsersAndTheirOrdersRealtime();
  }

  void listenToUsersAndTheirOrdersRealtime() {
    isLoading(true);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // 1. الاستماع لكوليكشن 'user' المفرد
    _usersSubscription = _firestore
        .collection('user')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .listen((userSnapshots) {
      if (userSnapshots.docs.isEmpty) {
        allTopFans.clear();
        filteredTopFans.clear();
        isLoading(false);
        return;
      }

      final currentUids = userSnapshots.docs.map((d) => d.id).toSet();

      // تنظيف الاشتراك للعملاء المقتطعين أو المحذوفين
      _ordersSubscriptions.removeWhere((uid, sub) {
        if (!currentUids.contains(uid)) {
          sub.cancel();
          _fansMap.remove(uid);
          return true;
        }
        return false;
      });

      for (var userDoc in userSnapshots.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();

        // 2. فتح Stream خاص ومستمر بأوردرات كل مستخدم بدلاً من .get()
        _ordersSubscriptions[userId] ??= _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .where('status', isEqualTo: 'completed')
            .snapshots()
            .listen((ordersSnap) {
          int completedCount = 0;
          double totalSpent = 0;
          String phoneFromOrder = '';

          for (var orderDoc in ordersSnap.docs) {
            final orderData = orderDoc.data();

            // الفلترة داخل الـ Memory لأوردرات الشهر الحالي
            if (orderData['createdAt'] != null && orderData['createdAt'] is Timestamp) {
              final DateTime orderDate = (orderData['createdAt'] as Timestamp).toDate();
              if (orderDate.isBefore(startOfMonth) || orderDate.isAfter(endOfMonth)) {
                continue;
              }
            }

            completedCount++;
            num price = orderData['totalPrice'] ?? 0;
            totalSpent += price.toDouble();

            if (phoneFromOrder.isEmpty && orderData['selectedAddress'] != null) {
              final address = orderData['selectedAddress'] as Map<String, dynamic>;
              if (address['phone'] != null) {
                phoneFromOrder = address['phone'].toString();
              }
            }
          }

          // إذا كان لدى المستخدم أوردرات مكتملة هذا الشهر يتم تحيينه في الخريطة
          if (completedCount > 0) {
            _fansMap[userId] = TopFanModel.fromFirestoreMap(
              userData,
              userId,
              completedCount,
              totalSpent,
              phoneFromOrder: phoneFromOrder,
            );
          } else {
            _fansMap.remove(userId);
          }

          _updateListAndSort();
        });
      }

      isLoading(false);
    }, onError: (error) {
      debugPrint("Error listening to users stream: $error");
      isLoading(false);
    });
  }

  void _updateListAndSort() {
    // تجميع كافة النتائج الحالية وفرزها تنازلياً فوراً
    List<TopFanModel> fans = _fansMap.values.toList();
    fans.sort((a, b) => b.completedOrdersCount.compareTo(a.completedOrdersCount));

    allTopFans.assignAll(fans);
    applyFilterAndSearch();
  }

  void applyFilterAndSearch() {
    String query = searchController.text.trim().toLowerCase();

    List<TopFanModel> temp = allTopFans.where((fan) {
      final matchesName = fan.name.toLowerCase().contains(query);
      final matchesEmail = fan.email.toLowerCase().contains(query);
      final matchesPhone = fan.phone.contains(query);
      return matchesName || matchesEmail || matchesPhone;
    }).toList();

    if (temp.length > selectedLimit.value) {
      filteredTopFans.assignAll(temp.sublist(0, selectedLimit.value));
    } else {
      filteredTopFans.assignAll(temp);
    }
  }

  void changeLimit(int limit) {
    selectedLimit.value = limit;
    applyFilterAndSearch();
  }

  @override
  void onClose() {
    _usersSubscription?.cancel();
    for (var sub in _ordersSubscriptions.values) {
      sub.cancel();
    }
    _ordersSubscriptions.clear();
    searchController.dispose();
    super.onClose();
  }
}