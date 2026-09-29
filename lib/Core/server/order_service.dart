import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_desginland/Core/server/get_client_data.dart';
import 'package:dashboard_desginland/Core/server/sendCancelInvoiceEmail.dart';
import 'package:dashboard_desginland/Core/server/sendOrderConfirmationEmail.dart';
import 'package:dashboard_desginland/Core/server/sendOrderReadyEmail.dart';
import 'package:dashboard_desginland/Core/server/sendUserNotificationApi.dart';
import 'package:dashboard_desginland/Core/server/send_pending_email.dart';
import 'package:dashboard_desginland/model/user_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرسال إشعار للعميل والحفظ في Firestore
  Future<void> saveNotification({
    required String userID,
    required String title,
    required String body,
    required Function(String error) onError,
  }) async {
    try {
      await _firestore.collection('user').doc(userID).collection('notifications').add({
        'isRead': false,
        'body': body,
        "title": title,
        "targetUser": userID,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      onError(e.toString());
    }
  }

  /// تحديث حالة الطلب وإرسال الإيميلات والإشعارات المترتبة عليها
  Future<void> updateOrderStatus({
    required BuildContext context,
    required DocumentReference orderRef,
    required String newStatus,
    required String currentStatus,
    required String userId,
    required String orderId,
    required num total,
    required int orderNumber,
    required Map<String, dynamic> orderData,
    required Function(String error) onError,
  }) async {
    if (newStatus == currentStatus) return;

    await orderRef.update({'status': newStatus});

    final selectedAddress = orderData['selectedAddress'] ?? {};
    final customerName = selectedAddress['fullName'] ?? orderData['customerName'];

    if (userId.isNotEmpty) {
      try {
        UserModel user = await getClientData(context, userId);

        if (newStatus == "pending") {
          sendInvoiceEmail(
            customerEmail: user.email,
            orderId: orderId,
            total: total.toDouble(),
            orderNumber: orderNumber,
            items: orderData['items'],
            customerName: customerName,
          );
        } else if (newStatus == "shipping") {
          sendOrderShippingEmail(
            customerEmail: user.email,
            orderId: orderNumber.toString(),
            customerName: customerName,
          );
          sendUserNotificationApi(
            userId: userId,
            title: "Order Confirmed!",
            body: "We’re now preparing your order with care.",
          );
          await saveNotification(
            userID: userId,
            title: "Order Confirmed!",
            body: "We’re now preparing your order with care.",
            onError: onError,
          );
        } else if (newStatus == "completed") {
          sendOrderReadyEmail(
            customerEmail: user.email,
            orderId: orderNumber.toString(),
            customerName: customerName,
          );
          sendUserNotificationApi(
            userId: userId,
            title: "Order Shipped!",
            body: "Please expect a call from our courier.",
          );
          await saveNotification(
            userID: userId,
            title: "Order Shipped!",
            body: "Please expect a call from our courier.",
            onError: onError,
          );
        } else {
          sendCancelInvoiceEmail(
            customerEmail: user.email,
            orderId: orderId,
            total: total.toDouble(),
            items: orderData['items'],
            customerName: customerName,
            orderNumber: orderNumber,
          );
          sendUserNotificationApi(
            userId: userId,
            title: "Your Order Updated Status",
            body: "Your Order Status $newStatus!",
          );
          await saveNotification(
            userID: userId,
            title: "Your Order Updated Status",
            body: "Your Order Status $newStatus!",
            onError: onError,
          );
        }
      } catch (e) {
        onError("Failed to send notification/email: $e");
      }
    }
  }

  /// حساب رقم الطلب الجديد للطلب اليدوي
  Future<int> getNextOrderNumber() async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('orders')
          .orderBy('orderNumber', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final maxNumber = querySnapshot.docs.first.data()['orderNumber'];
        if (maxNumber is int) {
          return maxNumber + 1;
        }
      }
    } catch (_) {
      final querySnapshot = await _firestore.collectionGroup('orders').get();
      if (querySnapshot.docs.isNotEmpty) {
        int maxNum = 1000;
        for (var doc in querySnapshot.docs) {
          final numVal = doc.data()['orderNumber'];
          if (numVal is int && numVal > maxNum) {
            maxNum = numVal;
          }
        }
        return maxNum + 1;
      }
    }
    return 1000;
  }
}