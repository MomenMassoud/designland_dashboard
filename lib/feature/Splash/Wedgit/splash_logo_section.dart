import 'package:flutter/material.dart';
import '../../../Core/Utils/app.images.dart';

class SplashLogoSection extends StatelessWidget {
  const SplashLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // إطار دائري للشعار
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 80,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage(AppImages.logo),
          ),
        ),
        const SizedBox(height: 24),
        // النص الرئيسي
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.0),
          child: Text(
            "A Happy Place for Customization\nPersonalized Gifts & More",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.1,
              color: Color(0xFF111827),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}