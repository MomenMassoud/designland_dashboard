import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../function/report_function.dart';


Widget buildSectionHeader({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color iconColor,
  List<Widget> actions = const [],
}) {
  final mobile = isMobile(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: mobile ? 42 : 46,
            height: mobile ? 42 : 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: mobile ? 21 : 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: mobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: mobile ? 11 : 12,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 14),
        if (mobile)
          Column(
            children: actions
                .map(
                  (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: action,
                ),
              ),
            )
                .toList(),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
      ],
    ],
  );
}