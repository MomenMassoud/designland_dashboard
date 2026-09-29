import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../../model/category_model.dart';
import '../../../controller/category_controller.dart';
import '../../Access Defind/view/access_defind_view.dart';
import 'category_card.dart';
import 'category_form_panel.dart';
import 'category_search_bar.dart';


class CategoryWidget extends StatelessWidget {
  const CategoryWidget({super.key});

  void _openCategoryFormPanel(BuildContext context, CategoryController controller,
      {String? docId, String? currentNameAr, String? currentNameEn, String? currentImageUrl}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CategoryForm',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => CategoryFormPanel(
        controller: controller,
        docId: docId,
        currentNameAr: currentNameAr,
        currentNameEn: currentNameEn,
        currentImageUrl: currentImageUrl,
      ),
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

  void _confirmDelete(BuildContext context, CategoryController controller, String docId, String nameEn, String imageUrl) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Category".tr, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        content: Text("${"Are you sure you want to delete".tr} '$nameEn'?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel".tr, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            onPressed: () async {
              await controller.deleteCategory(docId, imageUrl);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text("Delete".tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CategoryController controller = Get.put(CategoryController());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoadingPermissions.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
        );
      }

      if (!controller.permissions.contains("categories")) {
        return  AccessDefindView();
      }

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 650;
            final bool isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 28.0,
                vertical: isMobile ? 16.0 : 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, controller, isMobile, isDark),
                  const SizedBox(height: 20),
                  CategorySearchBar(controller: controller),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: controller.categoriesRef.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error loading categories!".tr,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                        }

                        final docs = snapshot.data?.docs ?? [];

                        return Obx(() {
                          final query = controller.searchQuery.value;
                          final filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nameAr = (data['nameAr'] ?? '').toString().toLowerCase();
                            final nameEn = (data['nameEn'] ?? '').toString().toLowerCase();
                            return nameAr.contains(query) || nameEn.contains(query);
                          }).toList();

                          if (filteredDocs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPurple.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.category_outlined, size: 48, color: AppColors.primaryPurple),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No categories found matching your search.".tr,
                                    style: TextStyle(color: isDark ? Colors.grey.shade400 : AppColors.textMuted, fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          }

                          int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : (constraints.maxWidth < 1400 ? 4 : 5));
                          double childAspectRatio = isMobile ? 0.82 : 0.85;

                          return GridView.builder(
                            itemCount: filteredDocs.length,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: isMobile ? 12 : 20,
                              mainAxisSpacing: isMobile ? 12 : 20,
                              childAspectRatio: childAspectRatio,
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

                              return CategoryCard(
                                cat: cat,
                                docId: docId,
                                nameAr: nameAr,
                                nameEn: nameEn,
                                imageUrl: imageUrl,
                                onEdit: () => _openCategoryFormPanel(
                                  context,
                                  controller,
                                  docId: docId,
                                  currentNameAr: nameAr,
                                  currentNameEn: nameEn,
                                  currentImageUrl: imageUrl,
                                ),
                                onDelete: () => _confirmDelete(context, controller, docId, nameEn, imageUrl),
                              );
                            },
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CategoryController controller, bool isMobile, bool isDark) {
    final title = Text("Categories Management".tr, style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark));
    final subTitle = Text("Manage your store product categories".tr, style: TextStyle(fontSize: isMobile ? 12 : 14, color: isDark ? Colors.grey.shade400 : AppColors.textMuted));
    final button = ElevatedButton.icon(
      onPressed: () => _openCategoryFormPanel(context, controller),
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      label: Text("Add New Category".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          subTitle,
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, subTitle]),
        button,
      ],
    );
  }
}