import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widget/user_favourite_product.dart';
import '../widget/user_orders_deatils.dart';

class UserActionsCard extends StatelessWidget {
  final String userId;

  const UserActionsCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            isDark: isDark,
            title: "Favourite Products",
            subtitle: "View list",
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEF4444),
            onTap: () => Get.to(() => UserFavouriteProduct(UserId: userId)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            isDark: isDark,
            title: "User Orders",
            subtitle: "View history",
            icon: Icons.shopping_bag_rounded,
            iconColor: const Color(0xFF6366F1),
            onTap: () => Get.to(() => UserOrdersDeatils(UserID: userId)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}