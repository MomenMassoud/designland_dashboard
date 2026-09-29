import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../controller/user_detail_controller.dart';
import 'user_product_details_widget.dart';

class UserSessionsSection extends StatelessWidget {
  final UserDetailController controller;

  const UserSessionsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final itemBg = isDark ? const Color(0xFF27273A) : const Color(0xFFF9FAFB);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Visit History (Analytics)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: controller.sessionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text("No activity sessions logged for this user.", style: TextStyle(color: textSecondary, fontSize: 12));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final session = docs[index].data() as Map<String, dynamic>;
                  final String sessionId = docs[index].id;
                  final String platform = session['platform'] ?? 'Web';
                  final List visitedTabs = session['visitedTabs'] as List? ?? [];
                  final List viewedProducts = session['viewedProducts'] as List? ?? [];

                  String startTimeStr = 'N/A';
                  if (session['startTime'] is Timestamp) {
                    DateTime dt = (session['startTime'] as Timestamp).toDate();
                    startTimeStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                  }

                  return Material(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showSessionDetailsDialog(context, sessionId, session),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                platform.toLowerCase() == 'web' ? Icons.language_rounded : Icons.phone_android_rounded,
                                color: const Color(0xFF6366F1),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Session: ${session['sessionId'] ?? sessionId}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Started: $startTimeStr | Platform: ${platform.toUpperCase()}",
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildBadge("${visitedTabs.length} Tabs Visited", const Color(0xFF3B82F6)),
                                      const SizedBox(width: 6),
                                      _buildBadge("${viewedProducts.length} Products Viewed", const Color(0xFFF59E0B)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showSessionDetailsDialog(BuildContext context, String docId, Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);

    final List visitedTabs = session['visitedTabs'] as List? ?? [];
    final List viewedProducts = session['viewedProducts'] as List? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Session Overview", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Visited Tabs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: visitedTabs.map((tab) => _buildBadge(tab.toString(), const Color(0xFF6366F1))).toList(),
                ),
                const SizedBox(height: 14),
                Text("Viewed Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 6),
                Column(
                  children: viewedProducts.map((pItem) {
                    final String productIdStr = pItem is Map ? (pItem['productId'] ?? '') : pItem.toString();
                    final String productTitle = pItem is Map ? (pItem['title'] ?? '') : '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(productTitle.isNotEmpty ? productTitle : "ID: $productIdStr", style: TextStyle(color: textPrimary, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UserProductDetailsWidget(productId: productIdStr)),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }
}