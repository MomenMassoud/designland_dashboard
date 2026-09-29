import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dashboard_desginland/Core/server/get_current_user.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import '../model/dashboard_stats_model.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = true.obs;

  final Rx<VisitorStats> visitorStats = const VisitorStats().obs;
  final Rx<FinancialStats> financialStats = const FinancialStats().obs;
  final Rx<GrowthStats> growthStats = const GrowthStats().obs;
  final RxList<ActiveOrderModel> activeOrders = <ActiveOrderModel>[].obs;

  // Streams لجميع الـ Collections المطلوب مراقبتها
  Stream<QuerySnapshot> get clientsStream =>
      _firestore.collection('user').where('role', isEqualTo: 'user').snapshots();

  Stream<QuerySnapshot> get staffStream =>
      _firestore.collection('user').where('role', isEqualTo: 'staff').snapshots();

  Stream<QuerySnapshot> get productsStream =>
      _firestore.collection('products').snapshots();

  Stream<QuerySnapshot> get promoStream =>
      _firestore.collection('promo_codes').snapshots();

  Stream<QuerySnapshot> get categoriesStream =>
      _firestore.collection('categories').snapshots();

  Stream<QuerySnapshot> get subcategoriesStream =>
      _firestore.collection('subcategories').snapshots();

  StreamSubscription? _visitorsSub;
  StreamSubscription? _financialsSub;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData({BuildContext? context}) async {
    isLoading.value = true;
    try {
      if (context != null) {
        currentUser.value = await GetCurrentUserData(context);
      }
      _listenToVisitors();
      _listenToFinancialsAndOrders();
    } catch (e) {
      debugPrint("Error initializing HomeController: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void refreshData() {
    initData();
  }

  void _listenToVisitors() {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    final DateTime startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final DateTime startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    _visitorsSub?.cancel();
    _visitorsSub = _firestore
        .collection('analytics_sessions')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday))
        .where('startTime', isLessThan: Timestamp.fromDate(startOfTomorrow))
        .snapshots()
        .listen((snapshot) {
      int todayVisitors = 0, yesterdayVisitors = 0, todayGuests = 0, todayRegistered = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['startTime'] is! Timestamp) continue;

        final DateTime startTime = (data['startTime'] as Timestamp).toDate();
        final bool isToday = !startTime.isBefore(startOfToday) && startTime.isBefore(startOfTomorrow);
        final bool isYesterday = !startTime.isBefore(startOfYesterday) && startTime.isBefore(startOfToday);
        final bool isGuest = data['isGuest'] == true;

        if (isToday) {
          todayVisitors++;
          if (isGuest) {
            todayGuests++;
          } else {
            todayRegistered++;
          }
        } else if (isYesterday) {
          yesterdayVisitors++;
        }
      }

      visitorStats.value = VisitorStats(
        todayVisitors: todayVisitors,
        yesterdayVisitors: yesterdayVisitors,
        todayGuests: todayGuests,
        todayRegistered: todayRegistered,
      );
    });
  }

  void _listenToFinancialsAndOrders() {
    _financialsSub?.cancel();

    // نستخدم Collection Group لاستجابة أسرع وأداء عالٍ
    _financialsSub = _firestore.collectionGroup('orders').snapshots().listen((ordersSnap) async {
      int active = 0, completed = 0, cancelled = 0;
      List<ActiveOrderModel> activeList = [];
      double totalOrdersAmount = 0.0;
      int totalOrdersCount = ordersSnap.docs.length;

      for (var doc in ordersSnap.docs) {
        final order = ActiveOrderModel.fromFirestore(doc);
        final status = order.status.toLowerCase();

        totalOrdersAmount += order.totalPrice;

        if (status == 'completed' || status == 'delivered') {
          completed++;
        } else if (status == 'cancelled') {
          cancelled++;
        } else {
          active++;
          activeList.add(order);
        }
      }

      activeList.sort((a, b) => (b.createdAt ?? Timestamp.now()).compareTo(a.createdAt ?? Timestamp.now()));
      activeOrders.value = activeList.take(4).toList();

      await _calculateFinancialsAndGrowth(active, completed, cancelled, totalOrdersAmount, totalOrdersCount);
    });
  }

  Future<void> _calculateFinancialsAndGrowth(
      int active,
      int completed,
      int cancelled,
      double totalOrdersAmount,
      int totalOrdersCount,
      ) async {
    final DateTime now = DateTime.now();

    final paymentsSnap = await _firestore.collection('payments').get();
    final incomesSnap = await _firestore.collection('incomes').get();
    final expensesSnap = await _firestore.collection('expenses').get();
    final sessionsSnap = await _firestore.collection('analytics_sessions').get();

    double totalCollectedCurrentMonth = 0.0;
    double totalCollectedPrevMonth = 0.0;
    double totalGeneralIncome = 0.0;
    double totalSpent = 0.0;

    final DateTime firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final DateTime firstDayPrevMonth = DateTime(now.year, now.month - 1, 1);

    for (var doc in paymentsSnap.docs) {
      final data = doc.data();
      final num amount = data['amount'] ?? data['price'] ?? data['total'] ?? 0;
      dynamic dateVal = data['paymentDate'] ?? data['createdAt'] ?? data['timestamp'] ?? data['date'];

      if (dateVal is Timestamp) {
        DateTime d = dateVal.toDate();
        if (d.isAfter(firstDayCurrentMonth)) {
          totalCollectedCurrentMonth += amount;
        } else if (d.isAfter(firstDayPrevMonth) && d.isBefore(firstDayCurrentMonth)) {
          totalCollectedPrevMonth += amount;
        }
      }
    }

    for (var doc in incomesSnap.docs) {
      final data = doc.data();
      final num amount = data['amount'] ?? 0;
      dynamic dateVal = data['createdAt'] ?? data['timestamp'] ?? data['date'];

      if (dateVal is Timestamp && dateVal.toDate().isAfter(firstDayCurrentMonth)) {
        totalGeneralIncome += amount;
      }
    }

    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      final num amount = data['amount'] ?? data['price'] ?? data['cost'] ?? 0;
      dynamic dateVal = data['date'] ?? data['createdAt'] ?? data['timestamp'] ?? data['expenseDate'];

      if (dateVal is Timestamp && dateVal.toDate().isAfter(firstDayCurrentMonth)) {
        totalSpent += amount;
      }
    }

    final double totalIncome = totalCollectedCurrentMonth + totalGeneralIncome;
    final double netMonthlyIncome = totalIncome - totalSpent;

    financialStats.value = FinancialStats(
      netMonthlyIncome: netMonthlyIncome,
      totalIncome: totalIncome,
      totalSpent: totalSpent,
      activeOrders: active,
      completedOrders: completed,
      cancelledOrders: cancelled,
    );

    // حساب النمو
    double growthPercent = 0.0;
    if (totalCollectedPrevMonth > 0) {
      growthPercent = ((totalCollectedCurrentMonth - totalCollectedPrevMonth) / totalCollectedPrevMonth) * 100;
    } else if (totalCollectedCurrentMonth > 0) {
      growthPercent = 100.0;
    }

    final int totalSessions = sessionsSnap.docs.length;
    final double avgOrder = totalOrdersCount > 0 ? totalOrdersAmount / totalOrdersCount : 0.0;
    final double conversion = totalSessions > 0 ? (totalOrdersCount / totalSessions) * 100 : 0.0;

    growthStats.value = GrowthStats(
      monthlyGrowthPercent: growthPercent,
      avgOrderValue: avgOrder,
      conversionRate: conversion,
      totalOrdersCount: totalOrdersCount,
      totalSessionsCount: totalSessions,
    );
  }

  @override
  void onClose() {
    _visitorsSub?.cancel();
    _financialsSub?.cancel();
    super.onClose();
  }
}