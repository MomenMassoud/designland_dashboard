import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Core/Utils/app.colors.dart';

class OrderItemsListCard extends StatelessWidget {
  final List items;
  final bool isDark;

  const OrderItemsListCard({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Items & Details".tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            Divider(height: 20, color: dividerColor),
            ...items.map((item) {
              final map = item is Map<String, dynamic> ? item : {};
              final customFields = map['customFieldsData'] as Map<String, dynamic>? ?? {};
              final String notes = map['notes'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${map['title']} (x${map['quantity'] ?? 1})",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        Text("${map['price'] ?? 0} EGP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.greenAccent : Colors.green)),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text("${"Notes:".tr} $notes",
                          style: TextStyle(color: mutedTextColor, fontSize: 13)),
                    ],
                    if (customFields.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text("Admin Dynamic Specifications:".tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primaryPurple)),
                      const SizedBox(height: 4),
                      ...customFields.entries.map((entry) {
                        final isLink = entry.value.toString().startsWith('http');
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: isLink
                              ? InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(entry.value.toString());
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              children: [
                                Text("${entry.key}: ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: textColor)),
                                Icon(Icons.link,
                                    size: 14,
                                    color: isDark ? Colors.lightBlueAccent : Colors.blue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.lightBlueAccent
                                            : Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : SelectableText("${entry.key}: ${entry.value}",
                              style: TextStyle(fontSize: 13, color: textColor)),
                        );
                      }),
                    ]
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}