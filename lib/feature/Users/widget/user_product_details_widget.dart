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

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Product Details"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
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
                child: Text("Error: ${snapshot.error}"),
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
                    const Icon(Icons.remove_shopping_cart_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      "Product with ID '$cleanProductId' does not exist in Firestore.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mainImage.isNotEmpty
                        ? Image.network(
                      mainImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                    )
                        : const Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),

                // Details Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text("Discount: $discount%"),
                            backgroundColor: Colors.orange.shade50,
                            labelStyle: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "\$$price",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const Divider(height: 24),
                      const Text(
                        "Description",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(color: AppColors.textMuted, height: 1.5),
                      ),
                      const Divider(height: 24),
                      _buildMetaRow("Product ID", cleanProductId),
                      _buildMetaRow("Category ID", categoryId),
                      _buildMetaRow("Subcategory ID", subcategoryId),
                      _buildMetaRow("Average Rating", (data['avgRating'] ?? 0).toString()),
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

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}