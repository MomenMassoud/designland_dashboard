import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../Core/server/get_permision.dart';
import '../../../model/product_model.dart';
import '../../Access Defind/view/access_defind_view.dart';
import '../../products/view/product_details_view.dart';
import 'product_card.dart';
import 'product_form_panel.dart';
import 'product_search_bar.dart';

class ProductsWidget extends StatefulWidget {
  const ProductsWidget({super.key});

  @override
  State<ProductsWidget> createState() => _ProductsWidgetState();
}

class _ProductsWidgetState extends State<ProductsWidget> {
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _permission = [];
  bool _isLoadingPermission = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final permissions = await GetPermisionUser();
    if (mounted) {
      setState(() {
        _permission = permissions;
        _isLoadingPermission = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteProduct(BuildContext context, ProductModel product, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Product",
          style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
        ),
        content: Text(
          "Are you sure you want to delete '${product.title}'?",
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              for (var imgUrl in product.images) {
                await CloudinaryService.deleteImage(imgUrl);
              }
              await _productsRef.doc(product.doc).delete();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsView(model: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermission) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
    }

    if (!_permission.contains("products")) {
      return  AccessDefindView();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : AppColors.bgLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isMobile, isDark),
                const SizedBox(height: 20),
                ProductSearchBar(
                  controller: _searchController,
                  isDark: isDark,
                  searchQuery: _searchQuery,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _productsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text("Error loading products!"));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryPurple),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        return title.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: isDark ? Colors.grey[600] : AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No products found matching your search.",
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : AppColors.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      int crossAxisCount = 4;
                      if (isMobile) {
                        crossAxisCount = 1;
                      } else if (isTablet) {
                        crossAxisCount = 2;
                      } else if (constraints.maxWidth < 1300) {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        itemCount: filteredDocs.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 2.3 : 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final priceVal = data['price'];
                          final double parsedPrice = (priceVal is num) ? priceVal.toDouble() : 0.0;

                          final discountVal = data['discountPercentage'];
                          final double parsedDiscount = discountVal is num
                              ? discountVal.toDouble()
                              : double.tryParse(discountVal?.toString() ?? '') ?? 0.0;

                          final avgRatingVal = data['avgRating'];
                          final double safeAvgRating = avgRatingVal is num
                              ? avgRatingVal.toDouble()
                              : double.tryParse(avgRatingVal?.toString() ?? '') ?? 0.0;

                          final rawImages = data['images'];
                          final List<String> safeImages = rawImages is List
                              ? rawImages.where((e) => e != null).map((e) => e.toString()).toList()
                              : <String>[];

                          final product = ProductModel(
                            doc: doc.id,
                            title: (data['title'] ?? '').toString(),
                            price: parsedPrice,
                            discountPercentage: parsedDiscount,
                            discountUntil: (data['discountUntil'] as Timestamp?)?.toDate(),
                            avgRate: safeAvgRating,
                            categoryDoc: (data['categoryId'] ?? '').toString(),
                            description: (data['description'] ?? '').toString(),
                            images: safeImages,
                            SubCategoryDoc: (data['subcategoryId'] ?? '').toString(),
                            isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
                          );

                          return ProductCard(
                            product: product,
                            isMobile: isMobile,
                            isDark: isDark,
                            onTap: () => _navigateToDetails(product),
                            onDelete: () => _confirmDeleteProduct(context, product, isDark),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;

    final openPanel = () => ProductFormPanel.show(
      context,
      isDark: isDark,
      productsRef: _productsRef,
      categoriesRef: _categoriesRef,
      subcategoriesRef: _subcategoriesRef,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Products Management",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage items, prices, and catalog",
            style: TextStyle(fontSize: 13, color: mutedTextColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openPanel,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add New Product",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Products Management",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage items, set prices, and view customer reviews",
              style: TextStyle(fontSize: 14, color: mutedTextColor),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: openPanel,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add New Product",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}