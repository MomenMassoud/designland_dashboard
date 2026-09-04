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
    return _permision.contains("products")
        ? Scaffold(
      backgroundColor: AppColors.bgLight,
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
                _buildHeader(context, isMobile),
                const SizedBox(height: 20),
                _buildSearchBar(),
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
                            children: const [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                "No products found matching your search.",
                                style: TextStyle(
                                    color: AppColors.textMuted,
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
                                    (ratingVal is num) ? ratingVal : 0;
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

                              final discountVal =
                              data['discountPercentage'];
                              final int parsedDiscount =
                              (discountVal is num)
                                  ? discountVal.toInt()
                                  : 0;

                              final product = ProductModel(
                                doc: doc.id,
                                title: data['title'] ?? '',
                                price: parsedPrice,
                                discountPercentage: data['discountPercentage']??0,
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Products Management",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Manage items, prices, and catalog",
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Products Management",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage items, set prices, and view customer reviews",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Search products by title...",
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
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

  Widget _buildPriceWidget(ProductModel product) {
    if (product.hasActiveDiscount) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            "\$${product.discountedPrice.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            "\$${product.price.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "-${product.discountPercentage}%",
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      "\$${product.price.toStringAsFixed(2)}",
      style: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, {
        required ProductModel product,
        required bool isMobile,
      }) {
    final hasImage = product.images.isNotEmpty;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
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
                      _buildPlaceholder(80),
                )
                    : _buildPlaceholder(80),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildPriceWidget(product),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          product.avgRate.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
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
                onPressed: () => _confirmDeleteProduct(context, product),
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
                              _buildPlaceholder(double.infinity),
                        )
                            : _buildPlaceholder(double.infinity),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        radius: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                          onPressed: () =>
                              _confirmDeleteProduct(context, product),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildPriceWidget(product)),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product.avgRate.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
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

  Widget _buildPlaceholder(double dimension) {
    return Container(
      width: dimension,
      height: dimension,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  void _openProductFormPanel(BuildContext context) {
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
                    ? 480
                    : MediaQuery.of(context).size.width;

                return Container(
                  width: panelWidth,
                  height: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
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
                              const Text(
                                "Add New Product",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              )
                            ],
                          ),
                          const Divider(height: 24),
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
                                        decoration: InputDecoration(
                                          labelText: "Select Category",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(10),
                                          ),
                                        ),
                                        items: snapshot.data!.docs.map((doc) {
                                          final data = doc.data()
                                          as Map<String, dynamic>;
                                          return DropdownMenuItem<String>(
                                            value: doc.id,
                                            child: Text(
                                                "${data['nameEn']} (${data['nameAr']})"),
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
                                          decoration: InputDecoration(
                                            labelText: "Select Subcategory",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                          ),
                                          items: snapshot.data!.docs.map((doc) {
                                            final data = doc.data()
                                            as Map<String, dynamic>;
                                            return DropdownMenuItem<String>(
                                              value: doc.id,
                                              child: Text(
                                                  "${data['nameEn']} (${data['nameAr']})"),
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
                                    decoration: InputDecoration(
                                      labelText: "Product Title",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Enter product title"
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: priceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "Price (\$)",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
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
                                          decoration: InputDecoration(
                                            labelText: "Discount (%)",
                                            hintText: "e.g. 10",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: discountDaysController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: "Duration (Days)",
                                            hintText: "e.g. 7",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: descController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: "Description",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Enter description"
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Product Images",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final ImagePicker picker = ImagePicker();
                                        final List<XFile> images =
                                        await picker.pickMultiImage(
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
                                            margin:
                                            const EdgeInsets.only(right: 8),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: MemoryImage(
                                                  imagesBytes[index],
                                                ),
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
                                  onPressed: isSaving
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryPurple,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                    if (formKey.currentState!
                                        .validate()) {
                                      if (pickedImages.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please select at least one image!",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setPanelState(
                                              () => isSaving = true);

                                      try {
                                        List<String> uploadedUrls = [];
                                        for (var img in pickedImages) {
                                          final url =
                                          await CloudinaryService
                                              .uploadImage(img);
                                          if (url != null) {
                                            uploadedUrls.add(url);
                                          }
                                        }

                                        if (uploadedUrls.isEmpty) {
                                          setPanelState(
                                                  () => isSaving = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Failed to upload images to Cloudinary!",
                                                ),
                                                backgroundColor:
                                                Colors.red,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final int discountVal =
                                            int.tryParse(
                                                discountPercController
                                                    .text
                                                    .trim()) ??
                                                0;
                                        final int discountDays =
                                            int.tryParse(
                                                discountDaysController
                                                    .text
                                                    .trim()) ??
                                                0;

                                        DateTime? discountUntilDate;
                                        if (discountVal > 0 &&
                                            discountDays > 0) {
                                          discountUntilDate = DateTime.now()
                                              .add(Duration(
                                              days: discountDays));
                                        }

                                        await _productsRef.add({
                                          'title':
                                          titleController.text.trim(),
                                          'description':
                                          descController.text.trim(),
                                          'price': double.parse(
                                              priceController.text.trim()),
                                          'discountPercentage':
                                          discountVal,
                                          'discountUntil':
                                          discountUntilDate != null
                                              ? Timestamp.fromDate(
                                              discountUntilDate)
                                              : null,
                                          'categoryId': selectedCategoryId,
                                          'subcategoryId':
                                          selectedSubcategoryId,
                                          'images': uploadedUrls,
                                          'avgRating': 0.0,
                                          'createdAt':
                                          FieldValue.serverTimestamp(),
                                        });

                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                      } catch (e) {
                                        debugPrint(
                                            "Error saving product: $e");
                                        setPanelState(
                                                () => isSaving = false);
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
          ).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete '${product.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
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