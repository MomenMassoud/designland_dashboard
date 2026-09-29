import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../model/dashboard_stats_model.dart';

class FinancialOrdersCard extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final FinancialStats stats;

  const FinancialOrdersCard({
    super.key,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Financials & Orders Overview".tr,
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.green, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${stats.netMonthlyIncome.toStringAsFixed(2)} EGP",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: stats.netMonthlyIncome >= 0 ? Colors.green : Colors.red,
            ),
          ),
          Text(
            "Net Monthly Income".tr,
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge("Active", stats.activeOrders, Colors.orange),
              _buildBadge("Completed", stats.completedOrders, Colors.green),
              _buildBadge("Cancelled", stats.cancelledOrders, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label.tr,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}