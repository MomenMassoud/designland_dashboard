import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreHealthCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final double healthPercentage;

  const StoreHealthCard({
    super.key,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    this.healthPercentage = 92.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Store Health".tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "View Details".tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: healthPercentage / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                    ),
                    Center(
                      child: Text(
                        "${healthPercentage.toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your store is in great shape!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "All systems operational",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          _buildHealthStatusRow("Performance", "Excellent", Colors.greenAccent),
          const SizedBox(height: 6),
          _buildHealthStatusRow("Security", "Secure", Colors.lightBlueAccent),
          const SizedBox(height: 6),
          _buildHealthStatusRow("SEO Score", "Good", Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _buildHealthStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label.tr,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
            ),
          ],
        ),
        Text(
          value.tr,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}