import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final int orderNumber;
  final String status;
  final double totalPrice;
  final String customerName;
  final String customerEmail;
  final bool isManual;
  final DateTime? createdAt;
  final List<dynamic> items;
  final Map<String, dynamic> selectedAddress;
  final DocumentReference reference;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.customerName,
    required this.customerEmail,
    required this.isManual,
    this.createdAt,
    required this.items,
    required this.selectedAddress,
    required this.reference,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // استخراج اسم العميل بمرونة عالية
    String name = data['customerName'] ?? '';
    if (name.isEmpty && data['selectedAddress'] is Map) {
      final addr = data['selectedAddress'] as Map;
      name = (addr['fullName'] ?? addr['name'] ?? '').toString();
    }

    DateTime? date;
    if (data['createdAt'] is Timestamp) {
      date = (data['createdAt'] as Timestamp).toDate();
    }

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? doc.reference.parent.parent?.id ?? '',
      orderNumber: (data['orderNumber'] as num?)?.toInt() ?? 0,
      status: (data['status'] ?? 'pending').toString().toLowerCase(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      customerName: name,
      customerEmail: (data['userEmail'] ?? '').toString(),
      isManual: data['isManual'] ?? false,
      createdAt: date,
      items: data['items'] as List? ?? [],
      selectedAddress: data['selectedAddress'] as Map<String, dynamic>? ?? {},
      reference: doc.reference,
    );
  }

  String get formattedDate {
    if (createdAt == null) return 'N/A';
    return "${createdAt!.day}/${createdAt!.month}/${createdAt!.year} - ${createdAt!.hour}:${createdAt!.minute.toString().padLeft(2, '0')}";
  }
}