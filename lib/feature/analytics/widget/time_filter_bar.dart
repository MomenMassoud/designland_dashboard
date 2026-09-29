import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TimeFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> OnPeriodChanged;
  final bool isDark;
  final Color cardBgColor;
  final Color textPrimaryColor;

  const TimeFilterBar({
    Key? key,
    required this.selectedPeriod,
    required this.OnPeriodChanged,
    required this.isDark,
    required this.cardBgColor,
    required this.textPrimaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Timeframe:'.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
          ),
          Row(
            children: [
              _buildFilterChip('today', 'today'),
              const SizedBox(width: 8),
              _buildFilterChip('7days', '7days'),
              const SizedBox(width: 8),
              _buildFilterChip('all', 'all'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue,
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) OnPeriodChanged(value);
      },
    );
  }
}