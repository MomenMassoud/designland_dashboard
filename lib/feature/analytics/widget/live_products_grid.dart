import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveProductsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> productStatsList;
  final bool isDark;
  final Color cardBgColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const LiveProductsGrid({
    Key? key,
    required this.productStatsList,
    required this.isDark,
    required this.cardBgColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (productStatsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No products have been viewed yet during this period.'.tr,
              style: TextStyle(color: textSecondaryColor)),
        ),
      );
    }

    var sortedList = List<Map<String, dynamic>>.from(productStatsList);
    sortedList.sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900
            ? 4
            : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final itemStat = sortedList[index];
        final rawItem = itemStat['rawItem'] as Map<String, dynamic>;
        final String docId = itemStat['id'];
        final int views = itemStat['views'] ?? 0;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('products').doc(docId).snapshots(),
          builder: (context, productSnap) {
            Map<String, dynamic> data = rawItem;

            if (productSnap.hasData && productSnap.data!.exists) {
              data = productSnap.data!.data() as Map<String, dynamic>;
            }

            final String title = data['title'] ?? 'Untitled Product'.tr;
            final num price = data['price'] ?? 0;
            final num avgRating = data['avgRating'] ?? 0;

            String imageUrl = '';
            if (data['images'] != null &&
                (data['images'] is List) &&
                (data['images'] as List).isNotEmpty) {
              imageUrl = data['images'][0].toString();
            } else if (data['image'] != null) {
              imageUrl = data['image'].toString();
            }

            return Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image_not_supported, color: textSecondaryColor),
                          )
                              : Icon(Icons.shopping_bag_outlined,
                              color: textSecondaryColor, size: 40),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price ${"EGP".tr}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(docId)
                                    .collection('reviews')
                                    .snapshots(),
                                builder: (context, reviewSnap) {
                                  int reviewsCount = reviewSnap.data?.docs.length ?? 0;

                                  return Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${avgRating.toStringAsFixed(1)} ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        '($reviewsCount)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined,
                                      size: 14, color: Colors.blue),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$views',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}