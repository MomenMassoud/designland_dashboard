import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/order_detail_controller.dart';
import 'add_transaction_dialog.dart';

class OrderFinancialSummaryCard extends StatelessWidget {
  final OrderDetailController controller;
  final bool isDark;

  const OrderFinancialSummaryCard({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final order = controller.orderData;
    final num totalPrice = order['totalPrice'] ?? 0;
    final num discountAmount = order['discountAmount'] ?? 0;
    final String? promoCode = order['promoCode'];

    return StreamBuilder<OrderFinancialData>(
      stream: controller.financialStream,
      builder: (context, snapshot) {
        final financialData = snapshot.data;
        final totalPaid = financialData?.totalPaid ?? 0;
        final totalExpenses = financialData?.totalExpenses ?? 0;

        final num remaining = totalPrice - totalPaid;
        final num netProfit = totalPrice - totalExpenses;

        return Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Financial Summary".tr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                Divider(height: 20, color: dividerColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${"Total Price:".tr} $totalPrice EGP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                        if (promoCode != null)
                          Text("${"Promo Code:".tr} $promoCode (-$discountAmount) EGP",
                              style: TextStyle(
                                  color: isDark ? Colors.greenAccent : Colors.green, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: netProfit >= 0
                            ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                            : (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${"Net Profit:".tr} $netProfit EGP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: netProfit >= 0
                              ? (isDark ? Colors.greenAccent : Colors.green)
                              : (isDark ? Colors.redAccent : Colors.red),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBadge("Total Paid".tr, "$totalPaid EGP",
                        isDark ? Colors.greenAccent : Colors.green),
                    _buildBadge(
                        "Remaining".tr,
                        "$remaining EGP",
                        remaining > 0
                            ? (isDark ? Colors.redAccent : Colors.red)
                            : (isDark ? Colors.greenAccent : Colors.green)),
                    _buildBadge("Expenses".tr, "$totalExpenses EGP",
                        isDark ? Colors.orangeAccent : Colors.orange.shade800),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.green.shade700 : Colors.green),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: Text("Add Payment".tr, style: const TextStyle(color: Colors.white)),
                        onPressed: () => _showDialog(context, isExpense: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isDark ? Colors.orange.shade900 : Colors.orange.shade800),
                        icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.white),
                        label: Text("Add Expense".tr, style: const TextStyle(color: Colors.white)),
                        onPressed: () => _showDialog(context, isExpense: true),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDialog(BuildContext context, {required bool isExpense}) {
    showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(
        isExpense: isExpense,
        isDark: isDark,
        controller: controller,
      ),
    );
  }

  Widget _buildBadge(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }
}