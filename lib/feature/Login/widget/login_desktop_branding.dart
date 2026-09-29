import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Core/Utils/app.images.dart';

class LoginDesktopBranding extends StatelessWidget {
  final bool isDark;

  const LoginDesktopBranding({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF252538), const Color(0xFF1E1E2E)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // شعار دائر بالحواف المضاءة مطابق للـ Sidebar Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 46,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage(AppImages.appPLogo),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Welcome Back!".tr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "DesignLand Admin Dashboard\nManage orders, products & customized gifts".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}