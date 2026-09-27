import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';
import 'package:dashboard_desginland/feature/products/view/product_details_view.dart';
import 'package:dashboard_desginland/model/product_model.dart';

import '../../../Core/server/get_permision.dart';

// نموذج يمثل الحقل المخصص للمنتج
class DynamicFieldModel {
  String name;
  String type; // 'text', 'number', 'drive_link', 'dropdown'
  bool isRequired;
  List<String> options; // قائمة الخيارات في حال كان النوع dropdown

  DynamicFieldModel({
    required this.name,
    this.type = 'text',
    this.isRequired = true,
    List<String>? options,
  }) : options = options ?? [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isRequired': isRequired,
      'options': options,
    };
  }
}

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
  List<String> _permision = [];

  void Start() async {
    _permision = await GetPermisionUser();
    setState(() {
      _permision;
    });
  }

  @override
  void initState() {
    super.initState();
    Start();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : AppColors.bgLight;

    return _permision.contains("products")
        ? Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isMobile, isDark),
                const SizedBox(height: 20),
                _buildSearchBar(isDark),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _productsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading products!"),
                        );
                      }
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPurple,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '')
                            .toString()
                            .toLowerCase();
                        return title.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64,
                                  color: isDark ? Colors.grey[600] : AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                "No products found matching your search.",
                                style: TextStyle(
                                    color: isDark ? Colors.grey[400] : AppColors.textMuted,
                                    fontSize: 16),
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
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 2.3 : 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final discountUntilTimestamp =
                          data['discountUntil'] as Timestamp?;

                          return StreamBuilder<QuerySnapshot>(
                            stream: _productsRef
                                .doc(doc.id)
                                .collection('reviews')
                                .snapshots(),
                            builder: (context, reviewSnapshot) {
                              double calculatedAvg = 0.0;

                              if (reviewSnapshot.hasData &&
                                  reviewSnapshot.data!.docs.isNotEmpty) {
                                final reviews = reviewSnapshot.data!.docs;
                                final totalRating = reviews.fold<double>(
                                  0.0,
                                      (sum, rDoc) {
                                    final rData = rDoc.data()
                                    as Map<String, dynamic>;
                                    final ratingVal = rData['rating'];
                                    final num ratingNum =
                                    (ratingVal is num)
                                        ? ratingVal
                                        : 0;
                                    return sum + ratingNum.toDouble();
                                  },
                                );
                                calculatedAvg =
                                    totalRating / reviews.length;
                              } else {
                                final avgVal = data['avgRating'];
                                calculatedAvg = (avgVal is num)
                                    ? avgVal.toDouble()
                                    : 0.0;
                              }

                              final priceVal = data['price'];
                              final double parsedPrice = (priceVal is num)
                                  ? priceVal.toDouble()
                                  : 0.0;

                              final product = ProductModel(
                                doc: doc.id,
                                title: data['title'] ?? '',
                                price: parsedPrice,
                                discountPercentage:
                                data['discountPercentage'] ?? 0,
                                discountUntil:
                                discountUntilTimestamp?.toDate(),
                                avgRate: calculatedAvg,
                                categoryDoc: data['categoryId'] ?? '',
                                description: data['description'] ?? '',
                                images: List<String>.from(
                                    data['images'] ?? []),
                                SubCategoryDoc:
                                data['subcategoryId'] ?? '',
                              );

                              return _buildProductCard(
                                context,
                                product: product,
                                isMobile: isMobile,
                                isDark: isDark,
                              );
                            },
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
    )
        : AccessDefindView();
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Products Management",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
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
              onPressed: () => _openProductFormPanel(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add New Product",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )
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
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage items, set prices, and view customer reviews",
              style: TextStyle(
                fontSize: 14,
                color: mutedTextColor,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openProductFormPanel(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add New Product",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Search products by title...",
          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = "";
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPriceWidget(ProductModel product, bool isDark) {
    final greenColor = isDark ? Colors.greenAccent : Colors.green;

    if (product.hasActiveDiscount) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            "\$${product.discountedPrice.toStringAsFixed(2)}",
            style: TextStyle(
              color: greenColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
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
      style: TextStyle(
        color: greenColor,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, {
        required ProductModel product,
        required bool isMobile,
        required bool isDark,
      }) {
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
        onTap: () => _navigateToDetails(product),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isMobile
              ? Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasImage
                    ? Image.network(
                  product.images.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholder(80, isDark),
                )
                    : _buildPlaceholder(80, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildPriceWidget(product, isDark),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          product.avgRate.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDeleteProduct(context, product, isDark),
              ),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasImage
                            ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(double.infinity, isDark),
                        )
                            : _buildPlaceholder(double.infinity, isDark),
                      ),
                    ),
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
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                          onPressed: () =>
                              _confirmDeleteProduct(context, product, isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildPriceWidget(product, isDark)),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product.avgRate.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
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
    );
  }

  Widget _buildPlaceholder(double dimension, bool isDark) {
    return Container(
      width: dimension,
      height: dimension,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      child: Icon(Icons.image_not_supported, color: isDark ? Colors.grey[600] : Colors.grey),
    );
  }

  void _openProductFormPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final discountPercController = TextEditingController();
    final discountDaysController = TextEditingController();

    String? selectedCategoryId;
    String? selectedSubcategoryId;

    List<XFile> pickedImages = [];
    List<Uint8List> imagesBytes = [];
    bool isSaving = false;

    // قائمة الحقول المخصصة
    List<DynamicFieldModel> customFields = [];

    // الألوان للوضع الداكن داخل اللوحة
    final panelBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;
    final cardBgColor = isDark ? const Color(0xFF252525) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final inputFillColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProductForm',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setPanelState) {
                final double panelWidth =
                MediaQuery.of(context).size.width > 600
                    ? 540
                    : MediaQuery.of(context).size.width;

                InputDecoration buildInputDecoration(String label, {String? hint}) {
                  return InputDecoration(
                    labelText: label,
                    hintText: hint,
                    labelStyle: TextStyle(color: mutedTextColor),
                    hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                    filled: true,
                    fillColor: inputFillColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                    ),
                  );
                }

                return Container(
                  width: panelWidth,
                  height: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: panelBgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Add New Product",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: textColor),
                                onPressed: () => Navigator.pop(ctx),
                              )
                            ],
                          ),
                          Divider(height: 24, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _categoriesRef.snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const LinearProgressIndicator();
                                      }
                                      return DropdownButtonFormField<String>(
                                        value: selectedCategoryId,
                                        dropdownColor: panelBgColor,
                                        style: TextStyle(color: textColor),
                                        decoration: buildInputDecoration("Select Category"),
                                        items: snapshot.data!.docs.map((doc) {
                                          final data = doc.data()
                                          as Map<String, dynamic>;
                                          return DropdownMenuItem<String>(
                                            value: doc.id,
                                            child: Text(
                                              "${data['nameEn']} (${data['nameAr']})",
                                              style: TextStyle(color: textColor),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setPanelState(() {
                                            selectedCategoryId = val;
                                            selectedSubcategoryId = null;
                                          });
                                        },
                                        validator: (v) => v == null
                                            ? "Please select a category"
                                            : null,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (selectedCategoryId != null) ...[
                                    StreamBuilder<QuerySnapshot>(
                                      stream: _subcategoriesRef
                                          .where('categoryId',
                                          isEqualTo: selectedCategoryId)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const LinearProgressIndicator();
                                        }
                                        return DropdownButtonFormField<String>(
                                          value: selectedSubcategoryId,
                                          dropdownColor: panelBgColor,
                                          style: TextStyle(color: textColor),
                                          decoration: buildInputDecoration("Select Subcategory"),
                                          items: snapshot.data!.docs.map((doc) {
                                            final data = doc.data()
                                            as Map<String, dynamic>;
                                            return DropdownMenuItem<String>(
                                              value: doc.id,
                                              child: Text(
                                                "${data['nameEn']} (${data['nameAr']})",
                                                style: TextStyle(color: textColor),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setPanelState(
                                                  () => selectedSubcategoryId = val),
                                          validator: (v) => v == null
                                              ? "Please select a subcategory"
                                              : null,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextFormField(
                                    controller: titleController,
                                    style: TextStyle(color: textColor),
                                    decoration: buildInputDecoration("Product Title"),
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Enter product title"
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: priceController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: textColor),
                                    decoration: buildInputDecoration("Price (\$)"),
                                    validator: (v) =>
                                    v == null || double.tryParse(v) == null
                                        ? "Enter valid price"
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: discountPercController,
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: textColor),
                                          decoration: buildInputDecoration("Discount (%)", hint: "e.g. 10"),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: discountDaysController,
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: textColor),
                                          decoration: buildInputDecoration("Duration (Days)", hint: "e.g. 7"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: descController,
                                    maxLines: 3,
                                    style: TextStyle(color: textColor),
                                    decoration: buildInputDecoration("Description"),
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Enter description"
                                        : null,
                                  ),
                                  const SizedBox(height: 20),

                                  // ==================== قسم الحقول المخصصة ====================
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Required Order Fields",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          setPanelState(() {
                                            customFields.add(
                                                DynamicFieldModel(name: ''));
                                          });
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text("Add Field"),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (customFields.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cardBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "No custom fields added. Click 'Add Field' to define required inputs for this product.",
                                        style: TextStyle(
                                            color: mutedTextColor,
                                            fontSize: 12),
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                      const NeverScrollableScrollPhysics(),
                                      itemCount: customFields.length,
                                      itemBuilder: (context, fIndex) {
                                        final field = customFields[fIndex];
                                        final optionController =
                                        TextEditingController();

                                        return Container(
                                          margin:
                                          const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cardBgColor,
                                            borderRadius:
                                            BorderRadius.circular(10),
                                            border: Border.all(
                                                color: borderColor),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: field.name,
                                                      style: TextStyle(color: textColor),
                                                      decoration: InputDecoration(
                                                        labelText: "Field Name / Title",
                                                        hintText: "e.g. Select Size, Color, Drive Link",
                                                        labelStyle: TextStyle(color: mutedTextColor),
                                                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                                        isDense: true,
                                                      ),
                                                      onChanged: (val) =>
                                                      field.name =
                                                          val.trim(),
                                                      validator: (v) => (v ==
                                                          null ||
                                                          v.trim().isEmpty)
                                                          ? "Enter field name"
                                                          : null,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.redAccent,
                                                        size: 20),
                                                    onPressed: () {
                                                      setPanelState(() {
                                                        customFields
                                                            .removeAt(fIndex);
                                                      });
                                                    },
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: DropdownButtonFormField<String>(
                                                      value: field.type,
                                                      dropdownColor: panelBgColor,
                                                      style: TextStyle(color: textColor),
                                                      decoration: InputDecoration(
                                                        labelText: "Field Type",
                                                        labelStyle: TextStyle(color: mutedTextColor),
                                                        isDense: true,
                                                      ),
                                                      items: [
                                                        DropdownMenuItem(
                                                          value: 'text',
                                                          child: Text("Text / كلام", style: TextStyle(color: textColor)),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'number',
                                                          child: Text("Number / أرقام", style: TextStyle(color: textColor)),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'drive_link',
                                                          child: Text("Google Drive Link / لينك درايف", style: TextStyle(color: textColor)),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'dropdown',
                                                          child: Text("Dropdown / قائمة اختيارات", style: TextStyle(color: textColor)),
                                                        ),
                                                      ],
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          setPanelState(() {
                                                            field.type = val;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Row(
                                                    children: [
                                                      Checkbox(
                                                        value: field.isRequired,
                                                        activeColor: AppColors.primaryPurple,
                                                        onChanged: (val) {
                                                          setPanelState(() {
                                                            field.isRequired =
                                                                val ?? true;
                                                          });
                                                        },
                                                      ),
                                                      Text("Required",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: textColor)),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              // ==================== خيارات Dropdown ====================
                                              if (field.type == 'dropdown') ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  "Dropdown Options:",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller: optionController,
                                                        style: TextStyle(color: textColor),
                                                        decoration: InputDecoration(
                                                          hintText: "Add option (e.g. Red, XL)",
                                                          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 8),
                                                          border: OutlineInputBorder(
                                                            borderSide: BorderSide(color: borderColor),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.primaryPurple,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      ),
                                                      onPressed: () {
                                                        final text = optionController.text.trim();
                                                        if (text.isNotEmpty) {
                                                          setPanelState(() {
                                                            field.options.add(text);
                                                            optionController.clear();
                                                          });
                                                        }
                                                      },
                                                      child: const Text("Add", style: TextStyle(color: Colors.white)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                if (field.options.isEmpty)
                                                  const Text(
                                                    "Please add at least one option for this dropdown.",
                                                    style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontSize: 11),
                                                  )
                                                else
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: field.options
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      final optIndex = entry.key;
                                                      final optValue = entry.value;
                                                      return Chip(
                                                        label: Text(optValue,
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: isDark ? Colors.white : AppColors.primaryPurple)),
                                                        deleteIcon: Icon(
                                                            Icons.close,
                                                            size: 14,
                                                            color: isDark ? Colors.white70 : Colors.black),
                                                        onDeleted: () {
                                                          setPanelState(() {
                                                            field.options.removeAt(optIndex);
                                                          });
                                                        },
                                                        backgroundColor: AppColors.primaryPurple.withOpacity(isDark ? 0.3 : 0.1),
                                                      );
                                                    }).toList(),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 20),

                                  // ==================== صور المنتج ====================
                                  Text(
                                    "Product Images",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: BorderSide(color: borderColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final ImagePicker picker = ImagePicker();
                                        final List<XFile> images = await picker.pickMultiImage(
                                          imageQuality: 85,
                                        );

                                        if (images.isNotEmpty) {
                                          List<Uint8List> bytesList = [];
                                          for (var img in images) {
                                            bytesList.add(await img.readAsBytes());
                                          }
                                          setPanelState(() {
                                            pickedImages = images;
                                            imagesBytes = bytesList;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint("Error picking images: $e");
                                      }
                                    },
                                    icon: const Icon(Icons.add_a_photo_outlined),
                                    label: Text(
                                      "Select Images (${pickedImages.length} selected)",
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                  if (imagesBytes.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 80,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: imagesBytes.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: MemoryImage(imagesBytes[index]),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text("Cancel", style: TextStyle(color: textColor)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryPurple,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                    if (formKey.currentState!.validate()) {
                                      if (pickedImages.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Please select at least one image!"),
                                          ),
                                        );
                                        return;
                                      }

                                      for (var f in customFields) {
                                        if (f.type == 'dropdown' && f.options.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Please add at least one option for dropdown field '${f.name}'"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                      }

                                      setPanelState(() => isSaving = true);

                                      try {
                                        List<String> uploadedUrls = [];
                                        for (var img in pickedImages) {
                                          final url = await CloudinaryService.uploadImage(img);
                                          if (url != null) {
                                            uploadedUrls.add(url);
                                          }
                                        }

                                        if (uploadedUrls.isEmpty) {
                                          setPanelState(() => isSaving = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Failed to upload images to Cloudinary!"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final int discountVal = int.tryParse(discountPercController.text.trim()) ?? 0;
                                        final int discountDays = int.tryParse(discountDaysController.text.trim()) ?? 0;

                                        DateTime? discountUntilDate;
                                        if (discountVal > 0 && discountDays > 0) {
                                          discountUntilDate = DateTime.now().add(Duration(days: discountDays));
                                        }

                                        List<Map<String, dynamic>> fieldsList = customFields.map((f) => f.toMap()).toList();

                                        await _productsRef.add({
                                          'title': titleController.text.trim(),
                                          'description': descController.text.trim(),
                                          'price': double.parse(priceController.text.trim()),
                                          'discountPercentage': discountVal,
                                          'discountUntil': discountUntilDate != null ? Timestamp.fromDate(discountUntilDate) : null,
                                          'categoryId': selectedCategoryId,
                                          'subcategoryId': selectedSubcategoryId,
                                          'images': uploadedUrls,
                                          'fields': fieldsList,
                                          'avgRating': 0.0,
                                          'createdAt': FieldValue.serverTimestamp(),
                                        });

                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                      } catch (e) {
                                        debugPrint("Error saving product: $e");
                                        setPanelState(() => isSaving = false);
                                      }
                                    }
                                  },
                                  child: isSaving
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
                                    "Save Product",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
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

              if (context.mounted) {
                Navigator.pop(ctx);
              }
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
}