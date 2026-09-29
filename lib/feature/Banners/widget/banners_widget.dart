import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reorderables/reorderables.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../Core/server/get_permision.dart';
import '../../../model/banner_model.dart';
import '../../Access Defind/view/access_defind_view.dart';
import 'banners_dialogs.dart';

class BannersWidget extends StatefulWidget {
  const BannersWidget({super.key});

  @override
  State<BannersWidget> createState() => _BannersViewState();
}

class _BannersViewState extends State<BannersWidget> {
  final CollectionReference _bannersRef = FirebaseFirestore.instance.collection('banners');
  final CollectionReference _categoriesRef = FirebaseFirestore.instance.collection('categories');

  List<String> _permissions = [];
  final Map<String, String> _categoryNamesCache = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    _permissions = await GetPermisionUser();
    if (mounted) setState(() {});
  }

  // حل مشكلة BUG الحذف والتنسيق التلقائي للترتيب لعميل التطبيق
  Future<void> _deleteBanner(BannerModel banner) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        title: Text("Confirm Deletion".tr, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Text("Are you sure you want to permanently delete this banner?".tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("cancellation".tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("delete".tr, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (banner.image.isNotEmpty) {
          await CloudinaryService.deleteImage(banner.image);
        }

        // حذف البانر وتعديل ترتيب باقي البانرات بشكل تسلسلي متناسق
        final batch = FirebaseFirestore.instance.batch();
        batch.delete(_bannersRef.doc(banner.id));

        final snapshot = await _bannersRef.orderBy('order').get();
        final remainingBanners = snapshot.docs
            .where((doc) => doc.id != banner.id)
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList();

        for (int i = 0; i < remainingBanners.length; i++) {
          batch.update(_bannersRef.doc(remainingBanners[i].id), {'order': i});
        }

        await batch.commit();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${"Failed to delete banner".tr}: $e")));
        }
      }
    }
  }

  void _updateBannersOrder(List<BannerModel> banners, int oldIndex, int newIndex) {
    final item = banners.removeAt(oldIndex);
    banners.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < banners.length; i++) {
      batch.update(_bannersRef.doc(banners[i].id), {'order': i});
    }
    batch.commit();
  }

  Widget _buildCategoryName(String categoryId, bool isDark) {
    if (_categoryNamesCache.containsKey(categoryId)) {
      return Text(
        _categoryNamesCache[categoryId]!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2D3436)),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _categoriesRef.doc(categoryId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['nameAr'] ?? data['nameEn'] ?? 'Uncategorized'.tr;
          _categoryNamesCache[categoryId] = name;
          return Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2D3436)),
          );
        }
        return const Text("...", style: TextStyle(fontSize: 12));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.contains("banner")) return AccessDefindView();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 4,
        onPressed: () => BannerDialogs.showBannerDialog(
          context: context,
          bannersRef: _bannersRef,
          categoriesRef: _categoriesRef,
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text("Add Banner".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bannersRef.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "There are currently no banners.".tr,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 15),
              ),
            );
          }

          final banners = snapshot.data!.docs.map((doc) => BannerModel.fromFirestore(doc)).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.drag_indicator_rounded, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Text(
                      "Drag and drop banners to rearrange display order".tr,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ReorderableWrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  onReorder: (oldIndex, newIndex) => _updateBannersOrder(banners, oldIndex, newIndex),
                  children: banners.map((banner) {
                    return Container(
                      key: ValueKey(banner.id),
                      width: 320,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: AspectRatio(
                                  aspectRatio: 16 / 8,
                                  child: banner.image.isNotEmpty
                                      ? CachedNetworkImage(
                                    imageUrl: banner.image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: isDark ? Colors.white10 : Colors.black12),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                  )
                                      : Container(color: isDark ? Colors.white10 : Colors.black12, child: const Icon(Icons.image)),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: banner.isOnClick ? const Color(0xFF10B981) : Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(banner.isOnClick ? Icons.touch_app_rounded : Icons.visibility_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        banner.isOnClick ? "Interactive".tr : "Display only".tr,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: banner.isOnClick && banner.categoryId.isNotEmpty
                                      ? Row(
                                    children: [
                                      const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF6366F1)),
                                      const SizedBox(width: 6),
                                      Expanded(child: _buildCategoryName(banner.categoryId, isDark)),
                                    ],
                                  )
                                      : Row(
                                    children: [
                                      Icon(Icons.image_outlined, size: 16, color: isDark ? Colors.white38 : Colors.grey),
                                      const SizedBox(width: 6),
                                      Text("Static display image".tr, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 18),
                                  onPressed: () => BannerDialogs.showBannerDialog(
                                    context: context,
                                    bannersRef: _bannersRef,
                                    categoriesRef: _categoriesRef,
                                    currentBanner: banner,
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () => _deleteBanner(banner),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}