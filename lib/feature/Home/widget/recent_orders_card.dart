import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../model/dashboard_stats_model.dart';

class RecentOrdersCard extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final List<ActiveOrderModel> activeOrders;

  const RecentOrdersCard({
    super.key,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.activeOrders,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Text(
                  "Active Orders In Progress".tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.pending_actions_outlined,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No active orders currently in progress.".tr,
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeOrders.length,
              separatorBuilder: (context, index) => Divider(
                height: 16,
                color: textSecondary.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                final statusColor = _getStatusColor(order.status);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.15),
                    child: Icon(Icons.shopping_bag, color: statusColor, size: 18),
                  ),
                  title: Text(
                    "${"Order".tr} #${order.orderNumber}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    "${"Status:".tr} ${order.status}",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    "${order.totalPrice.toStringAsFixed(2)} EGP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}