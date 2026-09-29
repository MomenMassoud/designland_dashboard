import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/products/widget/product_description_widget.dart';
import 'package:dashboard_desginland/feature/products/widget/product_fields_list.dart';
import 'package:dashboard_desginland/feature/products/widget/product_image_gallery.dart';
import 'package:dashboard_desginland/feature/products/widget/product_info_card.dart';
import 'package:dashboard_desginland/feature/products/widget/product_reviews_list.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../../Core/server/cloudinara_server.dart';
import '../../../model/dynamic_field_model.dart';
import 'dialogs/discount_dialog.dart';
import 'dialogs/edit_product_dialog.dart';
import 'full_screen_image_viewer.dart';

class ProductDetailsWidget extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsWidget({super.key, required this.product});

  @override
  State<ProductDetailsWidget> createState() => _ProductDetailsWidgetState();
}

class _ProductDetailsWidgetState extends State<ProductDetailsWidget> {
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef = FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef = FirebaseFirestore.instance.collection('subcategories');

  late ProductModel _currentProduct;
  List<DynamicFieldModel> _productFields = [];
  bool _isLoadingFields = true;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _fetchProductFields();
  }

  Future<void> _fetchProductFields() async {
    try {
      final docSnap = await _productsRef.doc(_currentProduct.doc).get();
      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data['fields'] != null) {
          final fieldsData = data['fields'] as List<dynamic>;
          setState(() {
            _productFields = fieldsData.map((f) => DynamicFieldModel.fromMap(f as Map<String, dynamic>)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching fields: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingFields = false);
      }
    }
  }

  Future<void> _toggleProductStatus(bool newStatus) async {
    setState(() => _isTogglingStatus = true);
    try {
      await _productsRef.doc(_currentProduct.doc).update({'isActive': newStatus});

      if (!mounted) return;

      setState(() {
        _currentProduct = ProductModel(
          doc: _currentProduct.doc,
          title: _currentProduct.title,
          price: _currentProduct.price,
          avgRate: _currentProduct.avgRate,
          categoryDoc: _currentProduct.categoryDoc,
          description: _currentProduct.description,
          images: _currentProduct.images,
          SubCategoryDoc: _currentProduct.SubCategoryDoc,
          discountPercentage: _currentProduct.discountPercentage,
          discountUntil: _currentProduct.discountUntil,
          isActive: newStatus,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus ? "Product is now Active" : "Product is now Inactive")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  Future<void> _removeDiscount() async {
    try {
      await _productsRef.doc(_currentProduct.doc).update({
        'discountPercentage': 0.0,
        'discountUntil': FieldValue.delete(),
      });

      if (!mounted) return;

      setState(() {
        _currentProduct = ProductModel(
          doc: _currentProduct.doc,
          title: _currentProduct.title,
          price: _currentProduct.price,
          avgRate: _currentProduct.avgRate,
          categoryDoc: _currentProduct.categoryDoc,
          description: _currentProduct.description,
          images: _currentProduct.images,
          SubCategoryDoc: _currentProduct.SubCategoryDoc,
          discountPercentage: 0,
          discountUntil: null,
          isActive: _currentProduct.isActive,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discount removed successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove discount: $e")),
      );
    }
  }

  void _openFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: _currentProduct.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showDiscountDialog() async {
    final updatedProduct = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => DiscountDialog(
        product: _currentProduct,
        productsRef: _productsRef,
      ),
    );

    if (updatedProduct != null && mounted) {
      setState(() => _currentProduct = updatedProduct);
    }
  }

  void _showEditProductDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditProductDialog(
        product: _currentProduct,
        initialFields: _productFields,
        productsRef: _productsRef,
        categoriesRef: _categoriesRef,
        subcategoriesRef: _subcategoriesRef,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentProduct = result['product'] as ProductModel;
        _productFields = result['fields'] as List<DynamicFieldModel>;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text("Delete Product", style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color)),
        content: Text("Are you sure you want to delete '${_currentProduct.title}'?",
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                for (var imgUrl in _currentProduct.images) {
                  await CloudinaryService.deleteImage(imgUrl);
                }
                await _productsRef.doc(_currentProduct.doc).delete();

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete product: $e")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : AppColors.textDark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryPurple),
            onPressed: _showEditProductDialog,
            tooltip: "Edit Product",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDelete,
            tooltip: "Delete Product",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProductImageGallery(
              images: _currentProduct.images,
              onImageTap: _openFullScreenImage,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductInfoCard(
                    product: _currentProduct,
                    isTogglingStatus: _isTogglingStatus,
                    onStatusToggle: _toggleProductStatus,
                    onRemoveDiscount: _removeDiscount,
                    onAddOrEditDiscount: _showDiscountDialog,
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                          "Description",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ProductDescriptionWidget(description: _currentProduct.description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductFieldsList(
                    fields: _productFields,
                    isLoading: _isLoadingFields,
                  ),
                  const SizedBox(height: 20),
                  ProductReviewsList(
                    productsRef: _productsRef,
                    productId: _currentProduct.doc,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}