import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String image;
  final bool isOnClick;
  final String categoryId;
  final int order;

  BannerModel({
    required this.id,
    required this.image,
    required this.isOnClick,
    required this.categoryId,
    required this.order,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BannerModel(
      id: doc.id,
      image: data['image'] ?? '',
      isOnClick: data['onclick'] ?? false,
      categoryId: data['category'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'onclick': isOnClick,
      'category': isOnClick ? categoryId : '',
      'order': order,
    };
  }
}