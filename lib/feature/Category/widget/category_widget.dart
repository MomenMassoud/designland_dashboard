import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_permision.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/SubCategory/view/subcategory_view.dart';
import 'package:dashboard_desginland/model/category_model.dart';
import 'package:flutter/foundation.dart';
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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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

  List<String> _permision = [];
  void Start() async {
    _permision = await GetPermisionUser();
    setState(() {
      _permision;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("categories")
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
                    stream: _categoriesRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading categories!"),
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
                        final nameAr = (data['nameAr'] ?? '')
                            .toString()
                            .toLowerCase();
                        final nameEn = (data['nameEn'] ?? '')
                            .toString()
                            .toLowerCase();
                        return nameAr.contains(_searchQuery) ||
                            nameEn.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.category_outlined,
                                  size: 64, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                "No categories found matching your search.",
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
                          childAspectRatio: isMobile ? 2.5 : 1.3,
                        ),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;
                          final nameAr = data['nameAr'] ?? '';
                          final nameEn = data['nameEn'] ?? '';
                          final imageUrl = data['imageUrl'] ?? '';

                          CategoryModel cat = CategoryModel(
                            doc: docId,
                            ImageUrl: imageUrl,
                            NameAr: nameAr,
                            NameEn: nameEn,
                          );

                          return _buildCategoryCard(
                            context,
                            cat: cat,
                            docId: docId,
                            nameAr: nameAr,
                            nameEn: nameEn,
                            imageUrl: imageUrl,
                            isMobile: isMobile,
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
            "Categories Management",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Manage your store product categories",
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openCategoryFormPanel(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add New Category",
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
          ),
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
          onPressed: () => _openCategoryFormPanel(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add New Category",
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, {
        required CategoryModel cat,
        required String docId,
        required String nameAr,
        required String nameEn,
        required String imageUrl,
        required bool isMobile,
      }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoryView(categoryModel: cat),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isMobile
              ? Row(
            children: [
              _buildImageThumbnail(imageUrl, width: 60, height: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      nameEn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildCardActions(context, docId, nameAr, nameEn, imageUrl),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildImageThumbnail(imageUrl, width: 50, height: 50),
                  _buildCardActions(
                      context, docId, nameAr, nameEn, imageUrl),
                ],
              ),
              const Spacer(),
              Text(
                nameAr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                nameEn,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String imageUrl,
      {required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl.isNotEmpty
          ? Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      )
          : Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Icon(
          Icons.category_outlined,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCardActions(
      BuildContext context,
      String docId,
      String nameAr,
      String nameEn,
      String imageUrl,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          icon: const Icon(Icons.edit_outlined,
              size: 20, color: AppColors.primaryPurple),
          onPressed: () => _openCategoryFormPanel(
            context,
            docId: docId,
            currentNameAr: nameAr,
            currentNameEn: nameEn,
            currentImageUrl: imageUrl,
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          icon: const Icon(Icons.delete_outline,
              size: 20, color: Colors.redAccent),
          onPressed: () => _confirmDelete(context, docId, nameEn, imageUrl),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String docId, String nameEn, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '$nameEn'?"),
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
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openCategoryFormPanel(
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

    final ImagePicker picker = ImagePicker();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CategoryForm',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setPanelState) {
                final double panelWidth = MediaQuery.of(context).size.width > 600
                    ? 450
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
                              Text(
                                docId == null
                                    ? "Add New Category"
                                    : "Edit Category",
                                style: const TextStyle(
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
                                  const Text(
                                    "Category Image",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        final XFile? image = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 85,
                                        );
                                        if (image != null) {
                                          setPanelState(() {
                                            pickedImage = image;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint("Error picking image: $e");
                                      }
                                    },
                                    child: Container(
                                      height: 150,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: pickedImage != null
                                          ? FutureBuilder<Uint8List>(
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
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      )
                                          : (imageUrl != null &&
                                          imageUrl!.isNotEmpty)
                                          ? ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                          : Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 36,
                                            color: AppColors
                                                .primaryPurple,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Click to select Category Image",
                                            style: TextStyle(
                                              color:
                                              AppColors.textMuted,
                                              fontSize: 13,
                                            ),
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
                                    validator: (v) => v == null ||
                                        v.trim().isEmpty
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
                                    validator: (v) => v == null ||
                                        v.trim().isEmpty
                                        ? "Please enter English name"
                                        : null,
                                  ),
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
                                    if (formKey.currentState!.validate()) {
                                      setPanelState(() => isSaving = true);

                                      if (pickedImage != null) {
                                        final uploadedUrl =
                                        await CloudinaryService
                                            .uploadImage(pickedImage!);
                                        if (uploadedUrl != null) {
                                          if (currentImageUrl != null &&
                                              currentImageUrl.isNotEmpty) {
                                            await CloudinaryService
                                                .deleteImage(
                                                currentImageUrl);
                                          }
                                          imageUrl = uploadedUrl;
                                        }
                                      }

                                      final dataMap = {
                                        'nameAr':
                                        nameArController.text.trim(),
                                        'nameEn':
                                        nameEnController.text.trim(),
                                        'imageUrl': imageUrl ?? '',
                                        'updatedAt':
                                        FieldValue.serverTimestamp(),
                                      };

                                      if (docId == null) {
                                        dataMap['createdAt'] =
                                            FieldValue.serverTimestamp();
                                        await _categoriesRef.add(dataMap);
                                      } else {
                                        await _categoriesRef
                                            .doc(docId)
                                            .update(dataMap);
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
                                    style: const TextStyle(
                                        color: Colors.white),
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
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

}