import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String doc;
  final String title;
  final double price;
  final double avgRate;
  final String categoryDoc;
  final String SubCategoryDoc;
  final String description;
  final List<String> images;
  final double discountPercentage;
  final DateTime? discountUntil;
  final bool isActive; // <--- حقل الحالة الجديد

  ProductModel({
    required this.doc,
    required this.title,
    required this.price,
    required this.avgRate,
    required this.categoryDoc,
    required this.SubCategoryDoc,
    required this.description,
    required this.images,
    this.discountPercentage = 0,
    this.discountUntil,
    this.isActive = true, // القيمة الافتراضية
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      doc: docId,
      title: map['title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      avgRate: (map['avgRate'] ?? 0).toDouble(),
      categoryDoc: map['categoryId'] ?? '',
      SubCategoryDoc: map['subcategoryId'] ?? '',
      description: map['description'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
      discountUntil: map['discountUntil'] != null
          ? (map['discountUntil'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true, // قراءة حالة المنتجات
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'avgRate': avgRate,
      'categoryId': categoryDoc,
      'subcategoryId': SubCategoryDoc,
      'description': description,
      'images': images,
      'discountPercentage': discountPercentage,
      'discountUntil': discountUntil != null ? Timestamp.fromDate(discountUntil!) : null,
      'isActive': isActive,
    };
  }

  bool get hasActiveDiscount {
    if (discountPercentage <= 0 || discountUntil == null) return false;
    return DateTime.now().isBefore(discountUntil!);
  }

  double get discountedPrice {
    if (!hasActiveDiscount) return price;
    return price * (1 - (discountPercentage / 100));
  }
}