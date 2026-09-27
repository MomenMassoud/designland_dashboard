import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

Widget buildEmptyState({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final theme = Theme.of(context);

  // Dynamic colors based on active theme mode
  final backgroundColor = isDarkMode
      ? theme.cardColor
      : AppColors.bgLight;
  final titleColor = isDarkMode
      ? Colors.white
      : AppColors.textDark; // أو أي لون نصوص رئيسي محدد في التصميم
  final subtitleColor = isDarkMode
      ? Colors.grey.shade400
      : Colors.grey.shade500;
  final iconColor = isDarkMode
      ? Colors.grey.shade500
      : Colors.grey.shade400;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      vertical: 45,
      horizontal: 20,
    ),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(15),
      border: isDarkMode
          ? Border.all(color: Colors.grey.shade800, width: 1)
          : null,
    ),
    child: Column(
      children: [
        Icon(icon, size: 46, color: iconColor),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}