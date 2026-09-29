import 'package:dashboard_desginland/feature/Users/widget/user_actions_card.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_addresses_section.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_basic_info_card.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_sessions_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/user_detail_controller.dart';

class UserDetailView extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailView({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserDetailController(userId), tag: userId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF121218) : const Color(0xFFF4F5F9);
    final appBarBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData['name'] ?? 'User Details',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Account overview and activity log",
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. البيانات الأساسية
            UserBasicInfoCard(userData: userData),
            const SizedBox(height: 16),

            // 2. كروت المفضلة والطلبات
            UserActionsCard(userId: userId),
            const SizedBox(height: 16),

            // 3. العناوين ورقم الهاتف
            UserAddressesSection(controller: controller),
            const SizedBox(height: 16),

            // 4. سجل الجلسات والزيارات
            UserSessionsSection(controller: controller),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}