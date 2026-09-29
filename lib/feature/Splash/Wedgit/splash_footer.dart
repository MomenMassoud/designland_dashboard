import 'package:flutter/material.dart';

class SplashFooter extends StatelessWidget {
  const SplashFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          color: Color(0xFF111827),
          size: 16,
        ),
        SizedBox(width: 6),
        Text(
          "@Designland.eg",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}