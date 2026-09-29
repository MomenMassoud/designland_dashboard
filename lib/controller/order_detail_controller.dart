import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:dashboard_desginland/Core/server/get_client_data.dart';
import 'package:dashboard_desginland/model/user_model.dart';

class OrderFinancialData {
  final num totalPaid;
  final num totalExpenses;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> payDocs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> expDocs;

  OrderFinancialData({
    required this.totalPaid,
    required this.totalExpenses,
    required this.payDocs,
    required this.expDocs,
  });
}

class OrderDetailController extends GetxController {
  final String orderId;
  final String userId;
  final Map<String, dynamic> orderData;

  OrderDetailController({
    required this.orderId,
    required this.userId,
    required this.orderData,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoadingUser = false.obs;

  Stream<OrderFinancialData>? financialStream;

  @override
  void onInit() {
    super.onInit();
    _initFinancialStream();
    _fetchUserData();
  }

  void _initFinancialStream() {
    final paymentsStream = _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .snapshots();

    final expensesStream = _firestore
        .collection('expenses')
        .where('orderId', isEqualTo: orderId)
        .snapshots();

    // دمج الـ Streams لتحديث الواجهة مرة واحدة فقط بدلاً من Nesting
    financialStream = rx.Rx.combineLatest2(
      paymentsStream,
      expensesStream,
          (QuerySnapshot<Map<String, dynamic>> paySnap, QuerySnapshot<Map<String, dynamic>> expSnap) {
        num totalPaid = 0;
        num totalExpenses = 0;

        for (var doc in paySnap.docs) {
          totalPaid += (doc.data()['amount'] ?? 0);
        }
        for (var doc in expSnap.docs) {
          totalExpenses += (doc.data()['amount'] ?? 0);
        }

        return OrderFinancialData(
          totalPaid: totalPaid,
          totalExpenses: totalExpenses,
          payDocs: paySnap.docs,
          expDocs: expSnap.docs,
        );
      },
    ).asBroadcastStream();
  }

  Future<void> _fetchUserData() async {
    if (orderData['isManual'] != null) return;

    try {
      isLoadingUser.value = true;
      if (Get.context != null) {
        userModel.value = await getClientData(Get.context!, userId);
      }
      final doc = await _firestore.collection('user').doc(userId).get();
      userData.value = doc.data();
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      isLoadingUser.value = false;
    }
  }

  Future<bool> addTransaction({
    required bool isExpense,
    required double amount,
    required String notes,
  }) async {
    try {
      final collectionName = isExpense ? 'expenses' : 'payments';
      await _firestore.collection(collectionName).add({
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'notes': notes.isEmpty ? (isExpense ? 'Expense' : 'Deposit') : notes,
        'createdAt': FieldValue.serverTimestamp(),
        'ordernumber': orderData['orderNumber'].toString(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}