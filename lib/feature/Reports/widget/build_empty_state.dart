import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';



Widget buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      vertical: 45,
      horizontal: 20,
    ),
    decoration: BoxDecoration(
      color: AppColors.bgLight,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Icon(icon, size: 46, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}