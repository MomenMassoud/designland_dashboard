import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorStats {
  final int todayVisitors;
  final int yesterdayVisitors;
  final int todayGuests;
  final int todayRegistered;

  const VisitorStats({
    this.todayVisitors = 0,
    this.yesterdayVisitors = 0,
    this.todayGuests = 0,
    this.todayRegistered = 0,
  });
}

class FinancialStats {
  final double netMonthlyIncome;
  final double totalIncome;
  final double totalSpent;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;

  const FinancialStats({
    this.netMonthlyIncome = 0.0,
    this.totalIncome = 0.0,
    this.totalSpent = 0.0,
    this.activeOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
  });
}

class GrowthStats {
  final double monthlyGrowthPercent;
  final double avgOrderValue;
  final double conversionRate;
  final int totalOrdersCount;
  final int totalSessionsCount;

  const GrowthStats({
    this.monthlyGrowthPercent = 0.0,
    this.avgOrderValue = 0.0,
    this.conversionRate = 0.0,
    this.totalOrdersCount = 0,
    this.totalSessionsCount = 0,
  });
}

class ActiveOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final double totalPrice;
  final Timestamp? createdAt;

  ActiveOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    this.createdAt,
  });

  factory ActiveOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    double price = (data['totalPrice'] ?? 0.0).toDouble();

    if (price == 0.0 && data['items'] is List) {
      for (var item in (data['items'] as List)) {
        final itemPrice = (item['price'] ?? 0).toDouble();
        final itemQty = (item['quantity'] ?? 1).toDouble();
        price += itemPrice * itemQty;
      }
    }

    return ActiveOrderModel(
      id: doc.id,
      orderNumber: data['orderNumber']?.toString() ?? '',
      status: data['status'] ?? 'In Progress',
      totalPrice: price,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}