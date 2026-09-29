import 'package:flutter/material.dart';

class UserSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const UserSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E1E2E) : theme.cardColor;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF111827));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textPrimary, fontSize: 13.5),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Search users by name or email...",
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white54 : Colors.grey),
            onPressed: onClear,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}