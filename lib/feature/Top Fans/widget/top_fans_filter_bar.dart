import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/top_fans_controller.dart';

class TopFansFilterBar extends StatelessWidget {
  final TopFansController controller;
  final bool isDark;

  const TopFansFilterBar({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          // شريط البحث
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: (_) => controller.applyFilterAndSearch(),
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search by name or phone...".tr,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // القائمة المنسدلة لاختيار عدد العرض
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: controller.selectedLimit.value,
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                items: controller.limitOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text("Display Top $value"),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) controller.changeLimit(val);
                },
              ),
            ),
          )),
        ],
      ),
    );
  }
}