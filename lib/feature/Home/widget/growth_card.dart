import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../model/dashboard_stats_model.dart';

class GrowthCard extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final GrowthStats stats;

  const GrowthCard({
    super.key,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = stats.monthlyGrowthPercent >= 0;

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
                "Business Growth".tr,
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${isPositive ? '+' : ''}${stats.monthlyGrowthPercent.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          Text(
            "Monthly Growth Rate".tr,
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${"Avg Order:".tr} ${stats.avgOrderValue.toStringAsFixed(0)} EGP",
                style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.bold),
              ),
              Text(
                "${"Conv. Rate:".tr} ${stats.conversionRate.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}