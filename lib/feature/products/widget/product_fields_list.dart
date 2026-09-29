import 'package:flutter/material.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../model/dynamic_field_model.dart';

class ProductFieldsList extends StatelessWidget {
  final List<DynamicFieldModel> fields;
  final bool isLoading;

  const ProductFieldsList({
    super.key,
    required this.fields,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : AppColors.textDark);
    final textSecondary = isDark ? Colors.grey.shade400 : AppColors.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Required Order Fields",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (fields.isEmpty)
            Text(
              "No custom fields required for ordering this product.",
              style: TextStyle(color: textSecondary, fontSize: 14),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fields.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final field = fields[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              field.type == 'drive_link'
                                  ? Icons.add_to_drive
                                  : field.type == 'number'
                                  ? Icons.pin
                                  : field.type == 'dropdown'
                                  ? Icons.arrow_drop_down_circle_outlined
                                  : Icons.short_text,
                              size: 18,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              field.name,
                              style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: field.isRequired
                                ? Colors.red.withOpacity(0.15)
                                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            field.isRequired ? "Required" : "Optional",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: field.isRequired ? Colors.redAccent : textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (field.type == 'dropdown' && field.options.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: field.options.map((opt) {
                          return Chip(
                            label: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.purple.shade200 : Colors.purple.shade900,
                              ),
                            ),
                            backgroundColor: isDark ? Colors.purple.withOpacity(0.2) : Colors.purple.shade50,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ]
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}