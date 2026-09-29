import 'package:flutter/material.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import '../../../../Core/Utils/app.colors.dart';

class ProductInfoCard extends StatelessWidget {
  final ProductModel product;
  final bool isTogglingStatus;
  final ValueChanged<bool> onStatusToggle;
  final VoidCallback onRemoveDiscount;
  final VoidCallback onAddOrEditDiscount;

  const ProductInfoCard({
    super.key,
    required this.product,
    required this.isTogglingStatus,
    required this.onStatusToggle,
    required this.onRemoveDiscount,
    required this.onAddOrEditDiscount,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: product.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: product.isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      product.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                      color: product.isActive ? Colors.green : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Status: ${product.isActive ? 'Active' : 'Inactive'}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: product.isActive ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                isTogglingStatus
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Switch(
                  value: product.isActive,
                  activeColor: Colors.green,
                  onChanged: onStatusToggle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (product.hasActiveDiscount) ...[
                    Text(
                      "${product.price.toStringAsFixed(2)} EGP",
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.redAccent,
                      ),
                    ),
                    Text(
                      "${product.discountedPrice.toStringAsFixed(2)} EGP",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.greenAccent : Colors.green,
                      ),
                    ),
                  ] else ...[
                    Text(
                      "${product.price} EGP",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.greenAccent : Colors.green,
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (product.hasActiveDiscount) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.orange.withOpacity(0.4) : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${product.discountPercentage.toInt()}% OFF until ${product.discountUntil!.day}/${product.discountUntil!.month} ${product.discountUntil!.hour}:${product.discountUntil!.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onRemoveDiscount,
                    child: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryPurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onAddOrEditDiscount,
              icon: const Icon(Icons.local_offer_outlined, color: AppColors.primaryPurple, size: 18),
              label: Text(
                product.hasActiveDiscount ? "Edit Discount" : "Add Discount Offer",
                style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      product.avgRate.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Product ID: ${product.doc.length > 6 ? product.doc.substring(0, 6) : product.doc}...",
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}