import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../controller/category_controller.dart';

class CategorySearchBar extends StatefulWidget {
  final CategoryController controller;
  const CategorySearchBar({super.key, required this.controller});

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.controller.onSearchChanged,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: "Search categories by Arabic or English name...".tr,
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade500 : AppColors.textMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primaryPurple, size: 22),
          suffixIcon: Obx(() => widget.controller.searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.cancel_rounded,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                size: 20),
            onPressed: () {
              _searchController.clear();
              widget.controller.onSearchChanged('');
            },
          )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}