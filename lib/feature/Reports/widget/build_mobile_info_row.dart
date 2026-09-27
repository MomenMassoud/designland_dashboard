import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

Widget mobileInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  // Dynamic colors based on active theme mode
  final iconAndLabelColor = isDarkMode
      ? Colors.grey.shade400
      : Colors.grey.shade500;
  final valueTextColor = isDarkMode
      ? Colors.white
      : AppColors.textDark;

  return Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: iconAndLabelColor),
        const SizedBox(width: 9),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: iconAndLabelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}