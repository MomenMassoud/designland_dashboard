import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';
import 'package:dashboard_desginland/feature/products/view/product_details_view.dart';
import 'package:dashboard_desginland/model/product_model.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showProductDialog(context),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Add New Product",
                            style: TextStyle(color: Colors.white),
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
                      onPressed: () => _showProductDialog(context),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Add New Product",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
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
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.primaryPurple),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Responsive Data List/Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("Error loading products!"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryPurple),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title =
                    (data['title'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text("No products found.",
                          style: TextStyle(color: AppColors.textMuted)),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // طريقة العرض للموبايل (Cards View)
                      if (constraints.maxWidth < 700) {
                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final product = ProductModel(
                              doc: doc.id,
                              title: data['title'] ?? '',
                              price: (data['price'] ?? 0.0).toDouble(),
                              avgRate: (data['avgRating'] ?? 0.0).toDouble(),
                              categoryDoc: data['categoryId'] ?? '',
                              description: data['description'] ?? '',
                              images: List<String>.from(data['images'] ?? []),
                              SubCategoryDoc: data['subcategoryId'] ?? '',
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () => _navigateToDetails(product),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product.images.isNotEmpty
                                      ? Image.network(product.images.first,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover)
                                      : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                        Icons.image_not_supported),
                                  ),
                                ),
                                title: Text(product.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text("\$${product.price}",
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16),
                              ),
                            );
                          },
                        );
                      }

                      // طريقة العرض للشاشات الكبيرة (DataTable View)
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("Image")),
                                  DataColumn(label: Text("Title")),
                                  DataColumn(label: Text("Price")),
                                  DataColumn(label: Text("Rating")),
                                  DataColumn(label: Text("Details")),
                                ],
                                rows: filteredDocs.map((doc) {
                                  final data =
                                  doc.data() as Map<String, dynamic>;
                                  final product = ProductModel(
                                    doc: doc.id,
                                    title: data['title'] ?? '',
                                    price: (data['price'] ?? 0.0).toDouble(),
                                    avgRate:
                                    (data['avgRating'] ?? 0.0).toDouble(),
                                    categoryDoc: data['categoryId'] ?? '',
                                    description: data['description'] ?? '',
                                    images: List<String>.from(
                                        data['images'] ?? []),
                                    SubCategoryDoc:
                                    data['subcategoryId'] ?? '',
                                  );

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: product.images.isNotEmpty
                                              ? Image.network(
                                              product.images.first,
                                              width: 45,
                                              height: 45,
                                              fit: BoxFit.cover)
                                              : Container(
                                            width: 45,
                                            height: 45,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.image_not_supported),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(product.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600))),
                                      DataCell(Text("\$${product.price}",
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 18),
                                            const SizedBox(width: 4),
                                            Text(product.avgRate
                                                .toStringAsFixed(1)),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            AppColors.primaryPurple,
                                          ),
                                          icon: const Icon(Icons.visibility,
                                              size: 16, color: Colors.white),
                                          label: const Text("View",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          onPressed: () =>
                                              _navigateToDetails(product),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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

  // ==================== ADD DIALOG ====================
  void _showProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    String? selectedCategoryId;
    String? selectedSubcategoryId;

    List<XFile> pickedImages = [];
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Add New Product",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: _categoriesRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              decoration: const InputDecoration(
                                  labelText: "Select Category"),
                              items: snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                      "${data['nameEn']} (${data['nameAr']})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
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
                        const SizedBox(height: 12),
                        if (selectedCategoryId != null)
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
                                decoration: const InputDecoration(
                                    labelText: "Select Subcategory"),
                                items: snapshot.data!.docs.map((doc) {
                                  final data =
                                  doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(
                                        "${data['nameEn']} (${data['nameAr']})"),
                                  );
                                }).toList(),
                                onChanged: (val) => setDialogState(
                                        () => selectedSubcategoryId = val),
                                validator: (v) => v == null
                                    ? "Please select a subcategory"
                                    : null,
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleController,
                          decoration:
                          const InputDecoration(labelText: "Product Title"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Enter product title"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration:
                          const InputDecoration(labelText: "Price (\$)"),
                          validator: (v) =>
                          v == null || double.tryParse(v) == null
                              ? "Enter valid price"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          decoration:
                          const InputDecoration(labelText: "Description"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Enter description"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // زر اختيار الصور المتوافق 100% مع الويب والهوستنج
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: true,
                                withData: true, // ضروري للويب لقراءة الملفات مباشرة
                              );

                              if (result != null && result.files.isNotEmpty) {
                                List<XFile> tempImages = [];
                                for (var file in result.files) {
                                  if (file.bytes != null) {
                                    tempImages.add(
                                      XFile.fromData(
                                        file.bytes!,
                                        name: file.name,
                                      ),
                                    );
                                  }
                                }
                                setDialogState(() {
                                  pickedImages = tempImages;
                                });
                              }
                            } catch (e) {
                              debugPrint("Error picking files on Web: $e");
                            }
                          },
                          icon: const Icon(Icons.add_a_photo),
                          label: Text("Select Images (${pickedImages.length})"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      if (pickedImages.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Please select at least one image!")),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      List<String> uploadedUrls = [];
                      for (var img in pickedImages) {
                        final url =
                        await CloudinaryService.uploadImage(img);
                        if (url != null) uploadedUrls.add(url);
                      }

                      if (uploadedUrls.isEmpty) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Failed to upload images to Cloudinary!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      await _productsRef.add({
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'price':
                        double.parse(priceController.text.trim()),
                        'categoryId': selectedCategoryId,
                        'subcategoryId': selectedSubcategoryId,
                        'images': uploadedUrls,
                        'avgRating': 0.0,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Save Product"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}