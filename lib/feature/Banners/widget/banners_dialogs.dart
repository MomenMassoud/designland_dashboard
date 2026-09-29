import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../model/banner_model.dart';

class BannerDialogs {
  static final ImagePicker _picker = ImagePicker();

  // قص وتعديل الصورة
  static Future<Uint8List?> cropImage({
    required BuildContext context,
    required XFile imageFile,
  }) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Banner'.tr,
            toolbarColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF6366F1),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF6366F1),
            backgroundColor: isDark ? const Color(0xFF121218) : Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Edit Banner'.tr),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page,
            size: const CropperSize(width: 700, height: 400),
            viewwMode: WebViewMode.mode_2,
            dragMode: WebDragMode.crop,
            movable: true,
            rotatable: true,
            scalable: true,
            zoomable: true,
          ),
        ],
      );

      if (croppedFile == null) return null;
      return await croppedFile.readAsBytes();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"Failed to edit image".tr}: $e")),
        );
      }
      return null;
    }
  }

  // تغيير أبعاد الصورة (تم تصحيح الخطأ هنا)
  static Future<Uint8List?> showResizeDialog(
      BuildContext context,
      Uint8List originalBytes,
      ) async {
    final img.Image? decoded = img.decodeImage(originalBytes);
    if (decoded == null) return null;

    final int originalWidth = decoded.width;
    final int originalHeight = decoded.height;
    final TextEditingController widthController = TextEditingController(text: originalWidth.toString());
    final TextEditingController heightController = TextEditingController(text: originalHeight.toString());
    bool keepRatio = true;
    final double ratio = originalWidth / originalHeight;

    return await showDialog<Uint8List?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.photo_size_select_large, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text("Resize Image".tr, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: widthController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Width".tr, suffixText: "px"),
                      onChanged: (val) {
                        if (!keepRatio) return;
                        final w = int.tryParse(val);
                        if (w != null && w > 0) {
                          heightController.text = (w / ratio).round().toString();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Keep aspect ratio".tr),
                        Switch(
                          value: keepRatio,
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (v) => setState(() => keepRatio = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Height".tr, suffixText: "px"),
                      onChanged: (val) {
                        if (!keepRatio) return;
                        final h = int.tryParse(val);
                        if (h != null && h > 0) {
                          widthController.text = (h * ratio).round().toString();
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text("Cancel".tr),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () {
                    final w = int.tryParse(widthController.text);
                    final h = int.tryParse(heightController.text);
                    if (w == null || h == null || w <= 0 || h <= 0) return;

                    final img.Image resized = img.copyResize(decoded, width: w, height: h);
                    final Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

                    // النقل الصحيح للقيمة بدلاً من return داخل onPressed
                    Navigator.pop(dialogContext, resizedBytes);
                  },
                  child: Text("Resize".tr, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // إضافة أو تعديل البانر
  static Future<void> showBannerDialog({
    required BuildContext context,
    required CollectionReference bannersRef,
    required CollectionReference categoriesRef,
    BannerModel? currentBanner,
  }) async {
    String? selectedCategoryId = currentBanner?.categoryId;
    bool isOnClick = currentBanner?.isOnClick ?? false;
    String currentImageUrl = currentBanner?.image ?? '';

    XFile? pickedImage;
    Uint8List? pickedImageBytes;
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final double screenWidth = MediaQuery.of(context).size.width;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                currentBanner == null ? "Adding a new Banar".tr : "Modify the banner".tr,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: screenWidth > 600 ? 500 : screenWidth * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: pickedImageBytes != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(pickedImageBytes!, fit: BoxFit.cover),
                        )
                            : currentImageUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(currentImageUrl, fit: BoxFit.cover),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF6366F1)),
                            const SizedBox(height: 8),
                            Text(
                              "Click to select a banner image".tr,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(pickedImageBytes == null ? "Select Image".tr : "Change Image".tr),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                final selected = await _picker.pickImage(source: ImageSource.gallery);
                                if (selected != null) {
                                  final cropped = await cropImage(context: context, imageFile: selected);
                                  if (cropped != null) {
                                    setDialogState(() {
                                      pickedImageBytes = cropped;
                                      pickedImage = XFile.fromData(cropped, name: 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (pickedImageBytes != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.crop_rotate),
                                label: Text("Edit / Crop".tr),
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                  if (pickedImage == null) return;
                                  final edited = await cropImage(context: context, imageFile: pickedImage!);
                                  if (edited != null) {
                                    setDialogState(() {
                                      pickedImageBytes = edited;
                                      pickedImage = XFile.fromData(edited, name: 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_size_select_large),
                                label: Text("Resize".tr),
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                  if (pickedImageBytes == null) return;
                                  final resized = await showResizeDialog(context, pickedImageBytes!);
                                  if (resized != null) {
                                    setDialogState(() {
                                      pickedImageBytes = resized;
                                      pickedImage = XFile.fromData(resized, name: 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("Clickable (OnClick)".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        value: isOnClick,
                        activeColor: const Color(0xFF6366F1),
                        onChanged: isLoading
                            ? null
                            : (val) {
                          setDialogState(() {
                            isOnClick = val;
                            if (!isOnClick) selectedCategoryId = null;
                          });
                        },
                      ),
                      if (isOnClick) ...[
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: categoriesRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const CircularProgressIndicator();
                            final docs = snapshot.data!.docs;
                            return DropdownButtonFormField<String>(
                              dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                              value: selectedCategoryId,
                              hint: Text("Select the relevant section.".tr),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(data['nameAr'] ?? data['nameEn'] ?? 'Uncategorized'.tr),
                                );
                              }).toList(),
                              onChanged: isLoading ? null : (val) => setDialogState(() => selectedCategoryId = val),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text("cancellation".tr),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (pickedImage == null && currentImageUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please choose an image first".tr)));
                      return;
                    }
                    if (isOnClick && (selectedCategoryId == null || selectedCategoryId!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a section when enabling click functionality.".tr)));
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    try {
                      String finalImageUrl = currentImageUrl;
                      if (pickedImage != null) {
                        final uploadedUrl = await CloudinaryService.uploadImage(pickedImage!);
                        if (uploadedUrl != null) {
                          if (currentImageUrl.isNotEmpty) {
                            await CloudinaryService.deleteImage(currentImageUrl);
                          }
                          finalImageUrl = uploadedUrl;
                        }
                      }

                      if (currentBanner == null) {
                        final countSnapshot = await bannersRef.get();
                        final newOrder = countSnapshot.docs.length;

                        final newBanner = BannerModel(
                          id: '',
                          image: finalImageUrl,
                          isOnClick: isOnClick,
                          categoryId: isOnClick ? selectedCategoryId ?? '' : '',
                          order: newOrder,
                        );
                        await bannersRef.add(newBanner.toMap());
                      } else {
                        final updatedBanner = BannerModel(
                          id: currentBanner.id,
                          image: finalImageUrl,
                          isOnClick: isOnClick,
                          categoryId: isOnClick ? selectedCategoryId ?? '' : '',
                          order: currentBanner.order,
                        );
                        await bannersRef.doc(currentBanner.id).update(updatedBanner.toMap());
                      }

                      if (context.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${"Something went wrong".tr}: $e")));
                      }
                    }
                  },
                  child: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(currentBanner == null ? "Add".tr : "Save changes".tr, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}