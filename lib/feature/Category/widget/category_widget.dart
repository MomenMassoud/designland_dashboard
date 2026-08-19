import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/SubCategory/view/subcategory_view.dart';
import 'package:dashboard_desginland/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');

  // Controller وكلام البحث
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Categories Management",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Manage your store product categories",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCategoryDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add New Category",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(height: 20),

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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search categories by Arabic or English name...",
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Real-time Stream Table
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _categoriesRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error loading categories!"),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // فلترة القائمة حسب نص البحث (عربي أو إنجليزي)
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nameAr = (data['nameAr'] ?? '').toString().toLowerCase();
                      final nameEn = (data['nameEn'] ?? '').toString().toLowerCase();
                      return nameAr.contains(_searchQuery) ||
                          nameEn.contains(_searchQuery);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No categories found matching your search.",
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 80,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.primaryPurple.withOpacity(0.05),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Image",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Arabic Name",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "English Name",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Actions",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: filteredDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final nameAr = data['nameAr'] ?? '';
                              final nameEn = data['nameEn'] ?? '';
                              final imageUrl = data['imageUrl'] ?? '';
                              CategoryModel cat=CategoryModel(doc: docId,
                                  ImageUrl: imageUrl, NameAr: nameAr, NameEn: nameEn);
                              return DataRow(
                                cells: [
                                  DataCell(
                                    onTap:(){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) =>  SubcategoryView(categoryModel: cat)),
                                      );
                                    },
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        )
                                            : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.category_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(nameAr)),
                                  DataCell(Text(nameEn)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: AppColors.primaryPurple),
                                          onPressed: () => _showCategoryDialog(
                                            context,
                                            docId: docId,
                                            currentNameAr: nameAr,
                                            currentNameEn: nameEn,
                                            currentImageUrl: imageUrl,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _confirmDelete(
                                            context,
                                            docId,
                                            nameEn,
                                            imageUrl,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog للإضافة والتعديل
  void _showCategoryDialog(
      BuildContext context, {
        String? docId,
        String? currentNameAr,
        String? currentNameEn,
        String? currentImageUrl,
      }) {
    final formKey = GlobalKey<FormState>();
    final nameArController = TextEditingController(text: currentNameAr ?? '');
    final nameEnController = TextEditingController(text: currentNameEn ?? '');
    XFile? pickedImage;
    String? imageUrl = currentImageUrl;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                docId == null ? "Add New Category" : "Edit Category",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              setDialogState(() {
                                pickedImage = image;
                              });
                            }
                          },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: pickedImage != null
                                ? FutureBuilder(
                              future: pickedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            )
                                : (imageUrl != null && imageUrl!.isNotEmpty)
                                ? ClipRRect(
                              borderRadius:
                              BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                                : const Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: AppColors.primaryPurple,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Click to select Category Image",
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: nameArController,
                          decoration: InputDecoration(
                            labelText: "الاسم بالعربي",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? "يرجى إدخال الاسم بالعربي"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: nameEnController,
                          decoration: InputDecoration(
                            labelText: "English Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? "Please enter English name"
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);

                      if (pickedImage != null) {
                        final uploadedUrl =
                        await CloudinaryService.uploadImage(
                            pickedImage!);
                        if (uploadedUrl != null) {
                          if (currentImageUrl != null &&
                              currentImageUrl.isNotEmpty) {
                            await CloudinaryService.deleteImage(
                                currentImageUrl);
                          }
                          imageUrl = uploadedUrl;
                        }
                      }

                      final dataMap = {
                        'nameAr': nameArController.text.trim(),
                        'nameEn': nameEnController.text.trim(),
                        'imageUrl': imageUrl ?? '',
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (docId == null) {
                        dataMap['createdAt'] =
                            FieldValue.serverTimestamp();
                        await _categoriesRef.add(dataMap);
                      } else {
                        await _categoriesRef.doc(docId).update(dataMap);
                      }

                      if (context.mounted) {
                        Navigator.pop(ctx);
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
                      : Text(
                    docId == null ? "Save" : "Update",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context,
      String docId,
      String categoryName,
      String imageUrl,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '$categoryName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (imageUrl.isNotEmpty) {
                await CloudinaryService.deleteImage(imageUrl);
              }

              await _categoriesRef.doc(docId).delete();

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
}