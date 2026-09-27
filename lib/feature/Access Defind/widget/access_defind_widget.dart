import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccessDefindWidget extends StatefulWidget {
  const AccessDefindWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AccessDefindWidget();
  }
}

class _AccessDefindWidget extends State<AccessDefindWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey.shade100,
      body: Center(
        child: Text(
          "Access Defined !".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}