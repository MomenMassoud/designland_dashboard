import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../Core/server/get_permision.dart';

class BannersWidget extends StatefulWidget {
  const BannersWidget({super.key});

  @override
  State<BannersWidget> createState() => _BannersWidgetState();
}

class _BannersWidgetState extends State<BannersWidget> {
  final CollectionReference _bannersRef = FirebaseFirestore.instance.collection('banners');
  final CollectionReference _categoriesRef = FirebaseFirestore.instance.collection('categories');
  final ImagePicker _picker = ImagePicker();
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

  void _showBannerDialog({String? docId, Map<String, dynamic>? currentData}) {
    String? selectedCategoryId = currentData?['category'];
    bool isOnClick = currentData?['onclick'] ?? false;
    String? currentImageUrl = currentData?['image'];

    XFile? pickedImage;
    Uint8List? pickedImageBytes; // لحفظ بيانات الصورة للمعاينة والرفع على الويب والموبايل
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double screenWidth = MediaQuery.of(context).size.width;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(docId == null ? "Adding a new Banar".tr : "Modify the banner".tr),
              content: SizedBox(
                width: screenWidth > 600 ? 500 : screenWidth * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. معاينة واختيار الصورة (تعمل على الموبايل والويب)
                      GestureDetector(
                        onTap: () async {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setDialogState(() {
                              pickedImage = image;
                              pickedImageBytes = bytes;
                            });
                          }
                        },
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: pickedImageBytes != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(pickedImageBytes!, fit: BoxFit.cover),
                          )
                              : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(currentImageUrl, fit: BoxFit.cover),
                          )
                              :  Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF6C5CE7)),
                              SizedBox(height: 8),
                              Text("Click to select a banner image".tr, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. خيار التفاعل (onclick)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title:  Text("Clickable (OnClick)".tr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle:  Text("Upon activation, the user will be directed to the sections.".tr, style: TextStyle(fontSize: 11)),
                        value: isOnClick,
                        activeColor: const Color(0xFF6C5CE7),
                        onChanged: (val) {
                          setDialogState(() {
                            isOnClick = val;
                            if (!isOnClick) selectedCategoryId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      // 3. اختيار القسم المرتبط
                      if (isOnClick)
                        StreamBuilder<QuerySnapshot>(
                          stream: _categoriesRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final docs = snapshot.data!.docs;

                            return DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              hint:  Text("Select the relevant section.".tr),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(data['nameAr'] ?? data['nameEn'] ?? 'Uncategorized Section'.tr),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() => selectedCategoryId = val);
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child:  Text("cancellation".tr, style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (pickedImage == null && (currentImageUrl == null || currentImageUrl.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("Please choose an image first".tr)),
                      );
                      return;
                    }

                    if (isOnClick && (selectedCategoryId == null || selectedCategoryId!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("Please select a section when enabling click functionality.".tr)),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    String finalImageUrl = currentImageUrl ?? '';

                    if (pickedImage != null) {
                      final uploadedUrl = await CloudinaryService.uploadImage(pickedImage!);
                      if (uploadedUrl != null) {
                        if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
                          await CloudinaryService.deleteImage(currentImageUrl);
                        }
                        finalImageUrl = uploadedUrl;
                      } else {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text("Failed to upload the image to Cloudinary.".tr)),
                        );
                        return;
                      }
                    }

                    final dataToSave = {
                      'image': finalImageUrl,
                      'onclick': isOnClick,
                      'category': isOnClick ? selectedCategoryId : '',
                    };

                    if (docId == null) {
                      await _bannersRef.add(dataToSave);
                    } else {
                      await _bannersRef.doc(docId).update(dataToSave);
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  child: isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(docId == null ? "Add".tr : "Save changes".tr, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBanner(String docId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text("Confirm Deletion".tr),
        content:  Text("Are you sure you want to permanently delete this banner?".tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child:  Text("cancellation".tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text("delete".tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (imageUrl.isNotEmpty) {
        await CloudinaryService.deleteImage(imageUrl);
      }
      await _bannersRef.doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("banner")
        ? Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: () => _showBannerDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label:  Text("Add Banner".tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bannersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return  Center(
              child: Text("There are currently no banners.".tr,style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final docs = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisExtent: 260,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final String imageUrl = data['image'] ?? '';
                  final bool isOnClick = data['onclick'] ?? false;
                  final String categoryId = data['category'] ?? '';

                  return Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOnClick ? Icons.touch_app_rounded : Icons.visibility_rounded,
                                        size: 14,
                                        color: isOnClick ? Colors.greenAccent : Colors.orangeAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOnClick ? "Interactive".tr : "Display only".tr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOnClick ? Colors.greenAccent : Colors.orangeAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isOnClick) ...[
                                      Text(
                                        "${"Department:".tr}$categoryId",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)),
                                      ),
                                    ] else ...[
                                       Text(
                                        "Static display image".tr,
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF6C5CE7), size: 20),
                                    onPressed: () => _showBannerDialog(docId: doc.id, currentData: data),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteBanner(doc.id, imageUrl),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    )
        :  AccessDefindView();
  }
}