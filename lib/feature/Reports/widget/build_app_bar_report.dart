import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../function/report_function.dart';

PreferredSizeWidget buildAppBar(BuildContext context) {
  final mobile = isMobile(context);
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final theme = Theme.of(context);

  // Dynamic colors based on active theme mode
  final appBarBgColor = isDarkMode ? theme.cardColor : Colors.white;
  final titleTextColor = isDarkMode ? Colors.white : AppColors.textDark;
  final subtitleTextColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;

  return AppBar(
    backgroundColor: appBarBgColor,
    elevation: isDarkMode ? 0 : 0.4,
    shadowColor: isDarkMode ? Colors.transparent : Colors.black12,
    toolbarHeight: mobile ? 70 : 78,
    titleSpacing: mobile ? 16 : 24,
    title: Row(
      children: [
        Container(
          width: mobile ? 40 : 46,
          height: mobile ? 40 : 46,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(isDarkMode ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.analytics_outlined,
            color: AppColors.primaryPurple,
            size: mobile ? 21 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Reports & Analytics",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: mobile ? 17 : 20,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Financial, orders and users reports",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleTextColor,
                  fontSize: mobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}