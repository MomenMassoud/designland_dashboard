import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

class UserProductDetailsWidget extends StatelessWidget {
  final String productId;

  const UserProductDetailsWidget({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanProductId = productId.trim();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final scaffoldBg = isDarkMode ? theme.scaffoldBackgroundColor : AppColors.bgLight;
    final appBarBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Product Details",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        elevation: 0.5,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(cleanProductId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(color: subtitleColor),
                ),
              ),
            );
          }

          // فحص آمن لمنع الـ TypeError
          final rawData = snapshot.data?.data();

          if (!snapshot.hasData || !snapshot.data!.exists || rawData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 64,
                      color: isDarkMode ? Colors.grey.shade600 : AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Product with ID '$cleanProductId' does not exist in Firestore.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final Map<String, dynamic> data = rawData;

          final String title = data['title'] ?? data['name'] ?? 'No Title';
          final String description = data['description'] ?? 'No description available.';
          final String price = (data['price'] ?? 0).toString();
          final String categoryId = data['categoryId'] ?? 'N/A';
          final String subcategoryId = data['subcategoryId'] ?? 'N/A';
          final String discount = (data['discountPercentage'] ?? 0).toString();

          final List dynamicImages = data['images'] as List? ?? [];
          final List<String> images = dynamicImages.map((e) => e.toString()).toList();
          final String mainImage = images.isNotEmpty ? images.first : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Main Image
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mainImage.isNotEmpty
                        ? Image.network(
                      mainImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: subtitleColor,
                      ),
                    )
                        : Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: subtitleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Details Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text("Discount: $discount%"),
                            backgroundColor: isDarkMode
                                ? Colors.deepOrange.withOpacity(0.2)
                                : Colors.orange.shade50,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "\$$price",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.greenAccent : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Divider(height: 24, color: borderColor),
                      Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(color: subtitleColor, height: 1.5),
                      ),
                      Divider(height: 24, color: borderColor),
                      _buildMetaRow("Product ID", cleanProductId, subtitleColor, textColor),
                      _buildMetaRow("Category ID", categoryId, subtitleColor, textColor),
                      _buildMetaRow("Subcategory ID", subcategoryId, subtitleColor, textColor),
                      _buildMetaRow("Average Rating", (data['avgRating'] ?? 0).toString(), subtitleColor, textColor),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor)),
        ],
      ),
    );
  }
}