import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/analytics/widget/platform_pie_chart.dart';
import 'package:dashboard_desginland/feature/analytics/widget/product_bar_chart.dart';
import 'package:dashboard_desginland/feature/analytics/widget/recent_searches_list.dart';
import 'package:dashboard_desginland/feature/analytics/widget/recent_sessions_list.dart';
import 'package:dashboard_desginland/feature/analytics/widget/recommendations_section.dart';
import 'package:dashboard_desginland/feature/analytics/widget/time_filter_bar.dart';
import 'package:dashboard_desginland/feature/analytics/widget/top_searches_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/analytics_controller.dart';
import 'ai_analysis_card.dart';
import 'analytics_kpi_grid.dart';
import 'hourly_activity_chart.dart';
import 'live_products_grid.dart';

class AnalyticsWidget extends StatelessWidget {
  AnalyticsWidget({Key? key}) : super(key: key);

  final AnalyticsController controller = Get.put(AnalyticsController());

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;
    final Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textPrimaryColor = isDark ? Colors.white : Colors.black87;
    final Color textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Obx(() {
      if (controller.isLoadingRole.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.role.value != "admin") {
        return AccessDefindView();
      }

      if (controller.isLoadingData.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.hasError.value) {
        return Scaffold(
          body: Center(
            child: Text('${"An error occurred while loading the data:".tr}${controller.errorMessage.value}'),
          ),
        );
      }

      final data = controller.analyticsData.value;
      if (data == null) return const Scaffold(body: SizedBox());

      final recommendations = controller.generateRecommendations();

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
        appBar: AppBar(
          title: Text(
            'Analytics and Business Management Center'.tr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimaryColor,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: cardBgColor,
          foregroundColor: textPrimaryColor,
          actions: [
            ElevatedButton.icon(
              onPressed: controller.isAnalyzingAi.value ? null : () => controller.analyzeWithGemini(),
              icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              label: const Text(
                'Ask AI',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.table_chart_outlined, color: Colors.green),
              tooltip: 'Export to Excel'.tr,
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preparing and saving the Excel file...'.tr)),
                );
                await controller.exportToExcel();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimeFilterBar(
                selectedPeriod: controller.selectedPeriod.value,
                OnPeriodChanged: (p) => controller.changePeriod(p),
                isDark: isDark,
                cardBgColor: cardBgColor,
                textPrimaryColor: textPrimaryColor,
              ),
              const SizedBox(height: 16),

              AiAnalysisCard(
                isAnalyzing: controller.isAnalyzingAi.value,
                result: controller.aiAnalysisResult.value,
                isDark: isDark,
                OnClose: () => controller.aiAnalysisResult.value = null,
              ),

              if (recommendations.isNotEmpty) ...[
                _buildSectionHeader('Business Growth Recommendations and Analyses 🚀'.tr, textPrimaryColor),
                const SizedBox(height: 12),
                RecommendationsSection(recommendations: recommendations, isDark: isDark),
                const SizedBox(height: 24),
              ],

              _buildSectionHeader('Key Performance Indicators (KPIs)'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              AnalyticsKpiGrid(
                data: data,
                cardBgColor: cardBgColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Most searched terms and categories 🔍'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              TopSearchesCard(
                searchQueries: data.searchQueriesCount,
                isDark: isDark,
                cardBgColor: cardBgColor,
                textSecondaryColor: textSecondaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Recent visitor and user search log'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              RecentSearchesList(
                docs: data.rawSearchDocs,
                cardBgColor: cardBgColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Visitor activity by time of day (Peak Hours)'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              HourlyActivityChart(
                hourlyActivity: data.hourlyActivity,
                isDark: isDark,
                cardBgColor: cardBgColor,
                textSecondaryColor: textSecondaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Distribution of Platforms and Devices (Pie Chart)'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              PlatformPieChart(
                platforms: data.platformCount,
                total: data.totalSessions,
                cardBgColor: cardBgColor,
                textPrimaryColor: textPrimaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Bar chart of most-viewed products'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              ProductBarChart(
                productViews: data.productViewsCount,
                isDark: isDark,
                cardBgColor: cardBgColor,
                textSecondaryColor: textSecondaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Product performance using live data'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              LiveProductsGrid(
                productStatsList: data.productStatsMap.values.toList(),
                isDark: isDark,
                cardBgColor: cardBgColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Recent session log and details'.tr, textPrimaryColor),
              const SizedBox(height: 12),
              RecentSessionsList(
                docs: data.rawSessionDocs,
                cardBgColor: cardBgColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, Color textPrimaryColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
    );
  }
}