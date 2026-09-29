import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HourlyActivityChart extends StatelessWidget {
  final Map<int, int> hourlyActivity;
  final bool isDark;
  final Color cardBgColor;
  final Color textSecondaryColor;

  const HourlyActivityChart({
    Key? key,
    required this.hourlyActivity,
    required this.isDark,
    required this.cardBgColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visits are distributed throughout the 24-hour period.'.tr,
            style: TextStyle(fontSize: 13, color: textSecondaryColor),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (hourlyActivity.values.isEmpty
                    ? 5
                    : hourlyActivity.values.reduce((a, b) => a > b ? a : b) + 2)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        int hour = val.toInt();
                        if (hour % 4 == 0) {
                          return Text('$hour:00',
                              style: TextStyle(fontSize: 9, color: textSecondaryColor));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(24, (index) {
                  int count = hourlyActivity[index] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: count > 0
                            ? Colors.deepOrangeAccent
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}