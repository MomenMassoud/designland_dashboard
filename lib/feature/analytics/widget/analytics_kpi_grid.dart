
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../model/analytics_data_model.dart';

class AnalyticsKpiGrid extends StatelessWidget {
  final AnalyticsDataModel data;
  final Color cardBgColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const AnalyticsKpiGrid({
    Key? key,
    required this.data,
    required this.cardBgColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard(
          title: 'Total sessions'.tr,
          value: '${data.totalSessions}',
          subtitle: '${"guests".tr}: ${data.guestSessions} | ${"Registered".tr}: ${data.userSessions}',
          icon: Icons.bar_chart_rounded,
          color: Colors.blue,
        ),
        _buildKpiCard(
          title: 'Total searches'.tr,
          value: '${data.totalSearches}',
          subtitle: '${"Guest Research:".tr}${data.guestSearches}',
          icon: Icons.search_rounded,
          color: Colors.orange,
        ),
        _buildKpiCard(
          title: 'Average dwell time'.tr,
          value: '${data.avgSessionDuration.toStringAsFixed(1)} ${"minute".tr}',
          subtitle: 'Reaction rate'.tr,
          icon: Icons.timer_outlined,
          color: Colors.purple,
        ),
        _buildKpiCard(
          title: 'Peak hour'.tr,
          value: '${data.peakHour}:00',
          subtitle: '${data.maxHourCount}${"Visitor at this time".tr}',
          icon: Icons.access_time_filled_sharp,
          color: Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: textSecondaryColor),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}