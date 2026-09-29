import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductBarChart extends StatelessWidget {
  final Map<String, int> productViews;
  final bool isDark;
  final Color cardBgColor;
  final Color textSecondaryColor;

  const ProductBarChart({
    Key? key,
    required this.productViews,
    required this.isDark,
    required this.cardBgColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (productViews.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('There are no product views yet to generate a graph.'.tr,
              style: TextStyle(color: textSecondaryColor)),
        ),
      );
    }

    var sortedEntries = productViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topProducts = sortedEntries.take(5).toList();

    double maxY = topProducts.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY + 2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => isDark ? Colors.grey.shade800 : Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${topProducts[groupIndex].key}\n${rod.toY.toInt()}${"Views".tr}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < topProducts.length) {
                      String title = topProducts[index].key;
                      if (title.length > 8) {
                        title = '${title.substring(0, 7)}...';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          title,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: textSecondaryColor),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 == 0) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: textSecondaryColor),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: topProducts.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.value.toDouble(),
                    color: Colors.blueAccent,
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}