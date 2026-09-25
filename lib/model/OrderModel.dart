import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final bool isManual;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.isManual = false,
  });

  factory OrderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: doc.id,
      // البحث عن رقم الأوردر في أكثر من مسمى متوقع، واستخدام جزء من id كخيار أخير
      orderNumber: data['orderNumber']?.toString() ??
          data['orderNo']?.toString() ??
          data['order_id']?.toString() ??
          (doc.id.length > 8 ? doc.id.substring(0, 8) : doc.id),
      totalAmount: (data['totalAmount'] ?? data['total'] ?? data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? data['payment_type'] ?? 'نقداً',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isManual: doc.reference.parent.id == 'orders',
    );
  }
}