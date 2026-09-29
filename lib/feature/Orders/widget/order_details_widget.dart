import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../controller/order_detail_controller.dart';
import 'order_customer_info_card.dart';
import 'order_financial_summary_card.dart';
import 'order_items_list_card.dart';
import 'order_transactions_history_widget.dart';

class OrderDetailView extends StatelessWidget {
  final String orderId;
  final String userId;
  final Map<String, dynamic> orderData;

  const OrderDetailView({
    super.key,
    required this.orderId,
    required this.userId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    // تهيئة الـ Controller مع تمييزه بـ Tag أو استخدامه مباشرة
    final controller = Get.put(
      OrderDetailController(
        orderId: orderId,
        userId: userId,
        orderData: orderData,
      ),
      tag: orderId,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : AppColors.bgLight;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    final List items = orderData['items'] as List? ?? [];

    String formattedDate = 'N/A';
    if (orderData['createdAt'] is Timestamp) {
      final dt = (orderData['createdAt'] as Timestamp).toDate();
      formattedDate =
      "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "${"Order".tr} #${orderData['orderNumber']}",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ملخص المالية الذكي
            OrderFinancialSummaryCard(controller: controller, isDark: isDark),

            const SizedBox(height: 16),

            // 2. تفاصيل العميل والعنوان
            OrderCustomerInfoCard(
              controller: controller,
              isDark: isDark,
              formattedDate: formattedDate,
            ),

            const SizedBox(height: 16),

            // 3. عناصر الطلب والحقول الديناميكية
            OrderItemsListCard(items: items, isDark: isDark),

            const SizedBox(height: 16),

            // 4. سجل الدفعات والمصروفات بالتفصيل
            OrderTransactionsHistoryWidget(controller: controller, isDark: isDark),
          ],
        ),
      ),
    );
  }
}