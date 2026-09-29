import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TopSearchesCard extends StatelessWidget {
  final Map<String, int> searchQueries;
  final bool isDark;
  final Color cardBgColor;
  final Color textSecondaryColor;

  const TopSearchesCard({
    Key? key,
    required this.searchQueries,
    required this.isDark,
    required this.cardBgColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (searchQueries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('There are no recorded searches for this period.'.tr,
              style: TextStyle(color: textSecondaryColor)),
        ),
      );
    }

    var sortedSearches = searchQueries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topList = sortedSearches.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topList.map((e) {
          return Chip(
            avatar: const CircleAvatar(
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.search, size: 12, color: Colors.white),
            ),
            label: Text(
              '${e.key} (${e.value})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.orange.shade100 : Colors.orange.shade900,
              ),
            ),
            backgroundColor: isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50,
            side: BorderSide(color: isDark ? Colors.orange.shade700 : Colors.orange.shade200),
          );
        }).toList(),
      ),
    );
  }
}