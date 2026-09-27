import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

class UserFavouriteProduct extends StatefulWidget {
  final String UserId;
  const UserFavouriteProduct({Key? key, required this.UserId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _UserFavouriteProduct();
  }
}

class _UserFavouriteProduct extends State<UserFavouriteProduct> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب كافة بيانات المنتجات المفضلة بناءً على الـ Sub-collection "fav"
  Future<List<Map<String, dynamic>>> _getFavouriteProducts() async {
    // 1. قراءة كل الـ Documents داخل fav
    final favSnapshot = await _firestore
        .collection('user')
        .doc(widget.UserId)
        .collection('fav')
        .get();

    if (favSnapshot.docs.isEmpty) {
      return [];
    }

    // 2. استخراج الـ Product IDs
    List<String> productIds = favSnapshot.docs
        .map((doc) => doc.data()['product'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    if (productIds.isEmpty) return [];

    // 3. جلب بيانات كل منتج من كوليكشن products بالتوازي
    List<Future<DocumentSnapshot>> productFutures = productIds
        .map((productId) => _firestore.collection('products').doc(productId).get())
        .toList();

    List<DocumentSnapshot> productDocs = await Future.wait(productFutures);

    // 4. تجميع البيانات المرجعة للمنتجات الموجودة فقط
    List<Map<String, dynamic>> products = [];
    for (var doc in productDocs) {
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        products.add(data);
      }
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final scaffoldBg = isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC);
    final appBarBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Favorite Products',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        elevation: 0.5,
        backgroundColor: appBarBg,
        foregroundColor: textColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFavouriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'An error occurred while loading favorites: ${snapshot.error}',
                style: TextStyle(color: subtitleColor),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 70,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'There are no favorite products for this customer.',
                    style: TextStyle(fontSize: 16, color: subtitleColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              final String title = product['title'] ?? 'بدون عنوان';
              final String description = product['description'] ?? '';
              final double price = (product['price'] ?? 0).toDouble();
              final int discount = (product['discountPercentage'] ?? 0).toInt();
              final List<dynamic> images = product['images'] ?? [];
              final String imageUrl = images.isNotEmpty ? images[0] : '';

              // حساب السعر بعد الخصم إن وجد
              final double finalPrice = discount > 0
                  ? price - (price * (discount / 100))
                  : price;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // صورة المنتج
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 85,
                                height: 85,
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: subtitleColor,
                                ),
                              ),
                        )
                            : Container(
                          width: 85,
                          height: 85,
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.image,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // تفاصيل المنتج
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // عرض الأسعار والخصم
                            Row(
                              children: [
                                Text(
                                  '${finalPrice.toStringAsFixed(0)} EGP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.lightBlue
                                        : Colors.blue,
                                    fontSize: 15,
                                  ),
                                ),
                                if (discount > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${price.toStringAsFixed(0)} EGP',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: isDarkMode
                                          ? Colors.grey.shade500
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '%$discount-',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.redAccent
                                            : Colors.red.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // زر إزالة المنتج من المفضلة
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {},
                        tooltip: 'Remove from favorites',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}