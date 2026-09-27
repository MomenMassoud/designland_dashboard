import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

Widget summaryCard({
  required BuildContext context,
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  final titleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
  final valueColor = isDarkMode ? Colors.white : AppColors.textDark;

  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color.withOpacity(isDarkMode ? 0.15 : 0.055),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: color.withOpacity(isDarkMode ? 0.30 : 0.10),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}