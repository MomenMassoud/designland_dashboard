import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../function/report_function.dart';


PreferredSizeWidget buildAppBar(BuildContext context) {
  final mobile = isMobile(context);

  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0.4,
    toolbarHeight: mobile ? 70 : 78,
    titleSpacing: mobile ? 16 : 24,
    title: Row(
      children: [
        Container(
          width: mobile ? 40 : 46,
          height: mobile ? 40 : 46,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(.10),
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
                  color: AppColors.textDark,
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
                  color: AppColors.textMuted,
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