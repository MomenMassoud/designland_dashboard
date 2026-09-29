import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../model/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isMobile;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.isMobile,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isMobile
              ? _buildMobileLayout(textColor, mutedTextColor, hasImage)
              : _buildDesktopLayout(textColor, hasImage),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Color textColor, Color? mutedTextColor, bool hasImage) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: hasImage
              ? CachedNetworkImage(
           imageUrl:  product.images.first,
            width: 80,
            fit: BoxFit.cover,
            height: 80,
          )
              : _buildPlaceholder(80),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!product.isActive) ...[
                    const SizedBox(width: 6),
                    _buildInactiveBadge(),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              _PriceWidget(product: product, isDark: isDark),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.avgRate.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12, color: mutedTextColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Color textColor, bool hasImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? CachedNetworkImage(
                    imageUrl:
                    product.images.first,
                    fit: BoxFit.cover,
                  )
                      : _buildPlaceholder(double.infinity),
                ),
              ),
              if (!product.isActive)
                Positioned(top: 8, left: 8, child: _buildInactiveBadge()),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: isDark
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.9),
                  radius: 16,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: onDelete,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _PriceWidget(product: product, isDark: isDark)),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  product.avgRate.toStringAsFixed(1),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInactiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        "Inactive",
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPlaceholder(double dimension) {
    return Container(
      width: dimension,
      height: dimension,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported,
        color: isDark ? Colors.grey[600] : Colors.grey,
      ),
    );
  }
}

class _PriceWidget extends StatelessWidget {
  final ProductModel product;
  final bool isDark;

  const _PriceWidget({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final greenColor = isDark ? Colors.greenAccent : Colors.green;

    if (product.hasActiveDiscount) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            "\$${product.discountedPrice.toStringAsFixed(2)}",
            style: TextStyle(color: greenColor, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            "\$${product.price.toStringAsFixed(2)}",
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "-${product.discountPercentage}%",
              style: TextStyle(
                color: isDark ? Colors.red.shade300 : Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      "${product.price.toStringAsFixed(2)} EGP",
      style: TextStyle(color: greenColor, fontWeight: FontWeight.bold, fontSize: 15),
    );
  }
}