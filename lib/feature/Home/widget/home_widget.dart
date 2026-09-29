import 'package:dashboard_desginland/feature/Home/widget/quick_actions_grid.dart';
import 'package:dashboard_desginland/feature/Home/widget/store_health_card.dart';
import 'package:dashboard_desginland/feature/Home/widget/todays_schedule_card.dart';
import 'package:dashboard_desginland/feature/Home/widget/visitors_card.dart';
import 'package:dashboard_desginland/feature/Home/widget/welcome_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../controller/home_controller.dart';
import 'ModernFinancialCard.dart';
import 'ModernRecentOrdersCard.dart';
import 'ModernStatCard.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
    controller.initData(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121218) : const Color(0xFFF4F5F9);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final appBarBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple),
          ),
        );
      }

      final user = controller.currentUser.value;
      if (user == null) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple),
          ),
        );
      }

      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "System Overview".tr,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Real-time analytics and performance metrics".tr,
                style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12, left: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPurple, size: 18),
                onPressed: controller.refreshData,
                tooltip: "Refresh Data".tr,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              WelcomeBanner(role: user.role),
              const SizedBox(height: 16),

              Text(
                "Financials & Activity".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Primary Grid
              _buildPrimaryGrid(),
              const SizedBox(height: 16),

              // Quick Actions Grid
              Text(
                "Quick Actions & Shortcuts".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              QuickActionsGrid(
                isDark: isDark,
                cardBg: cardBg,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 16),

              // Responsive Two-Column Section for Health and Schedule
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TodaysScheduleCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: StoreHealthCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        TodaysScheduleCard(
                          isDark: isDark,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        StoreHealthCard(
                          isDark: isDark,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              Text(
                "Resource Management".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Secondary Grid
              _buildSecondaryGrid(),
              const SizedBox(height: 16),

              // Recent Active Orders Card
              ModernRecentOrdersCard(
                activeOrders: controller.activeOrders,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPrimaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 750 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 500 ? 2.2 : 1.9,
          ),
          children: [
            VisitorsCard(
              cardBg: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E2E)
                  : Colors.white,
              textPrimary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF111827),
              textSecondary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : const Color(0xFF6B7280),
              stats: controller.visitorStats.value,
            ),
            ModernFinancialCard(
              stats: controller.financialStats.value,
            ),
            ModernStatCard(
              title: "Total Customers".tr,
              stream: controller.clientsStream,
              icon: Icons.people_alt_rounded,
              gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 5
            : (constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 600 ? 3 : 2));

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth < 400 ? 1.8 : 2.0,
          ),
          children: [
            ModernStatCard(
              title: "Staff Members".tr,
              stream: controller.staffStream,
              icon: Icons.badge_outlined,
              gradientColors: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
            ),
            ModernStatCard(
              title: "Products".tr,
              stream: controller.productsStream,
              icon: Icons.grid_view_rounded,
              gradientColors: const [Color(0xFFA855F7), Color(0xFF7C3AED)],
            ),
            ModernStatCard(
              title: "Promo Codes".tr,
              stream: controller.promoStream,
              icon: Icons.confirmation_number_outlined,
              gradientColors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
            ),
            ModernStatCard(
              title: "Categories".tr,
              stream: controller.categoriesStream,
              icon: Icons.category_rounded,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            ModernStatCard(
              title: "Subcategories".tr,
              stream: controller.subcategoriesStream,
              icon: Icons.account_tree_rounded,
              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ],
        );
      },
    );
  }
}