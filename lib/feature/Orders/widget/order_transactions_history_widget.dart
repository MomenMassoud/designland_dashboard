import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/order_detail_controller.dart';

class OrderTransactionsHistoryWidget extends StatelessWidget {
  final OrderDetailController controller;
  final bool isDark;

  const OrderTransactionsHistoryWidget({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final mutedTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return StreamBuilder<OrderFinancialData>(
      stream: controller.financialStream,
      builder: (context, snapshot) {
        final payDocs = snapshot.data?.payDocs ?? [];
        final expDocs = snapshot.data?.expDocs ?? [];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payments
            Expanded(
              child: Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Payments History".tr,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.greenAccent : Colors.green)),
                      Divider(color: dividerColor),
                      if (payDocs.isEmpty)
                        Text("No payments yet.".tr,
                            style: TextStyle(color: mutedTextColor, fontSize: 12))
                      else
                        Column(
                          children: payDocs.map((d) {
                            final data = d.data();
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text("${data['amount']} EGP",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.greenAccent : Colors.green)),
                              subtitle: Text(data['notes'] ?? '',
                                  style: TextStyle(color: mutedTextColor)),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Expenses
            Expanded(
              child: Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Expenses History".tr,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.orangeAccent : Colors.orange.shade800)),
                      Divider(color: dividerColor),
                      if (expDocs.isEmpty)
                        Text("No expenses yet.".tr,
                            style: TextStyle(color: mutedTextColor, fontSize: 12))
                      else
                        Column(
                          children: expDocs.map((d) {
                            final data = d.data();
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text("${data['amount']} EGP",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                      isDark ? Colors.orangeAccent : Colors.orange.shade800)),
                              subtitle: Text(data['notes'] ?? '',
                                  style: TextStyle(color: mutedTextColor)),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}