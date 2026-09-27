import 'package:flutter/material.dart';

Widget buildActionButton({
  required BuildContext context,
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  // في حالة الدارك مود يمكن استخدام درجة أغمق أو أهدأ قليلاً للون الخلفية
  final effectiveBackgroundColor = isDarkMode ? color.withOpacity(0.85) : color;

  return SizedBox(
    height: 45,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: Colors.white,
        elevation: isDarkMode ? 0 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: isDarkMode
              ? BorderSide(color: Colors.white.withOpacity(0.12), width: 1)
              : BorderSide.none,
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}