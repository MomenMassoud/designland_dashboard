import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlatformPieChart extends StatelessWidget {
  final Map<String, int> platforms;
  final int total;
  final Color cardBgColor;
  final Color textPrimaryColor;

  const PlatformPieChart({
    Key? key,
    required this.platforms,
    required this.total,
    required this.cardBgColor,
    required this.textPrimaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (platforms.isEmpty || total == 0) {
      return const SizedBox();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red
    ];
    int colorIndex = 0;

    List<PieChartSectionData> sections = platforms.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final currentColor = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: currentColor,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 35,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: platforms.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[platforms.keys.toList().indexOf(e.key) % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.key}: ${e.value}${"session".tr}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: textPrimaryColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}