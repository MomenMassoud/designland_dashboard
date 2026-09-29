import 'package:dashboard_desginland/feature/Banners/view/banners_view.dart';
import 'package:dashboard_desginland/feature/Reports/view/report_view.dart';
import 'package:dashboard_desginland/feature/products/view/products_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuickActionsGrid extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;

  const QuickActionsGrid({
    super.key,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        "title": "Add New Product",
        "subtitle": "Create & add item to store",
        "icon": Icons.add_box_rounded,
        "color": const Color(0xFF6366F1),
      },
      {
        "title": "Add New Banner",
        "subtitle": "Create & add banner",
        "icon": Icons.view_carousel_rounded,
        "color": const Color(0xFFEC4899),
      },
      {
        "title": "View Reports",
        "subtitle": "Check store performance",
        "icon": Icons.bar_chart_rounded,
        "color": const Color(0xFF10B981),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 500 ? 3 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 500 ? 2.8 : 2.2,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];
            final color = item["color"] as Color;
            return InkWell(
              onTap: () {
                if(item['title']=="Add New Product"){
                  Get.to(ProductsView());
                }
                else if(item['title']=="Add New Banner"){
                  Get.to(BannersView());
                }
                else{
                  Get.to(ReportView());
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item["icon"] as IconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (item["title"] as String).tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (item["subtitle"] as String).tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}