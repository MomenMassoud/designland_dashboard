import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../Core/server/get_permision.dart';

class BannersWidget extends StatefulWidget {
  const BannersWidget({super.key});

  @override
  State<BannersWidget> createState() => _BannersWidgetState();
}

class _BannersWidgetState extends State<BannersWidget> {
  final CollectionReference _bannersRef = FirebaseFirestore.instance.collection(
    'banners',
  );

  final CollectionReference _categoriesRef = FirebaseFirestore.instance
      .collection('categories');

  final ImagePicker _picker = ImagePicker();

  List<String> _permision = [];

  void Start() async {
    _permision = await GetPermisionUser();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    Start();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage({
    required void Function(Uint8List bytes, XFile file) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        onError("The selected image is empty".tr);
        return;
      }

      onSuccess(bytes, image);
    } catch (e) {
      onError("${"Failed to select image".tr}: $e");
    }
  }

  // ============================================================
  // CROP + ROTATE
  // ============================================================

  Future<Uint8List?> _cropImage({
    required BuildContext context,
    required XFile imageFile,
  }) async {
    try {
      final String sourcePath = imageFile.path;

      if (sourcePath.isEmpty) {
        throw Exception("Image path is empty");
      }

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Banner'.tr,
            toolbarColor: const Color(0xFF6C5CE7),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF6C5CE7),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),

          IOSUiSettings(
            title: 'Edit Banner'.tr,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),

          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page,

            // Cropper size
            size: const CropperSize(width: 700, height: 500),

            // Image behavior
            viewwMode: WebViewMode.mode_2,
            dragMode: WebDragMode.crop,

            // Enable editing
            movable: true,
            rotatable: true,
            scalable: true,
            zoomable: true,

            // Zoom with mouse wheel
            zoomOnWheel: true,
            zoomOnTouch: true,

            // Crop UI
            modal: true,
            guides: true,
            center: true,
            highlight: true,
            background: true,

            // Orientation
            checkCrossOrigin: true,
            checkOrientation: true,
          ),
        ],
      );

      if (croppedFile == null) {
        return null;
      }

      final Uint8List bytes = await croppedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception("Edited image is empty");
      }

      return bytes;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"Failed to edit image".tr}: $e")),
        );
      }

      return null;
    }
  }

  // ============================================================
  // RESIZE
  // ============================================================

  Future<Uint8List?> _resizeImage(
    Uint8List bytes, {
    required int width,
    required int height,
  }) async {
    try {
      final img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception("Could not decode image");
      }

      final img.Image resized = img.copyResize(
        decoded,
        width: width,
        height: height,
        interpolation: img.Interpolation.average,
      );

      final List<int> jpgBytes = img.encodeJpg(resized, quality: 90);

      return Uint8List.fromList(jpgBytes);
    } catch (e) {
      debugPrint("Resize error: $e");
      return null;
    }
  }

  // ============================================================
  // RESIZE DIALOG
  // ============================================================

  Future<Uint8List?> _showResizeDialog(
    BuildContext context,
    Uint8List originalBytes,
  ) async {
    final img.Image? decoded = img.decodeImage(originalBytes);

    if (decoded == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not read image dimensions".tr)),
      );

      return null;
    }

    final int originalWidth = decoded.width;
    final int originalHeight = decoded.height;

    final TextEditingController widthController = TextEditingController(
      text: originalWidth.toString(),
    );

    final TextEditingController heightController = TextEditingController(
      text: originalHeight.toString(),
    );

    bool keepRatio = true;

    final double ratio = originalWidth / originalHeight;

    final result = await showDialog<Uint8List?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.photo_size_select_large,
                    color: Color(0xFF6C5CE7),
                  ),
                  const SizedBox(width: 10),
                  Text("Resize Image".tr),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF6C5CE7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "${"Original size".tr}: "
                              "$originalWidth × $originalHeight px",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: widthController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Width".tr,
                        suffixText: "px",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        if (!keepRatio) return;

                        final int? width = int.tryParse(value);

                        if (width == null || width <= 0) return;

                        final int newHeight = (width / ratio).round();

                        heightController.text = newHeight.toString();
                      },
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Keep aspect ratio".tr,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: keepRatio,
                          activeColor: const Color(0xFF6C5CE7),
                          onChanged: (value) {
                            setState(() {
                              keepRatio = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Height".tr,
                        suffixText: "px",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        if (!keepRatio) return;

                        final int? height = int.tryParse(value);

                        if (height == null || height <= 0) return;

                        final int newWidth = (height * ratio).round();

                        widthController.text = newWidth.toString();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text("Cancel".tr),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: Text("Resize".tr),
                  onPressed: () async {
                    final int? width = int.tryParse(widthController.text);

                    final int? height = int.tryParse(heightController.text);

                    if (width == null ||
                        height == null ||
                        width <= 0 ||
                        height <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please enter valid dimensions".tr),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final resized = await _resizeImage(
                      originalBytes,
                      width: width,
                      height: height,
                    );

                    if (resized == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to resize image".tr)),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  // ============================================================
  // EDIT IMAGE FLOW
  // ============================================================

  Future<void> _selectAndEditImage({
    required BuildContext context,
    required void Function(Uint8List bytes, XFile file) onSuccess,
  }) async {
    try {
      final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (selectedImage == null) {
        return;
      }

      final Uint8List originalBytes = await selectedImage.readAsBytes();

      if (originalBytes.isEmpty) {
        throw Exception("Selected image is empty");
      }

      // Open cropper
      final Uint8List? croppedBytes = await _cropImage(
        context: context,
        imageFile: selectedImage,
      );

      if (croppedBytes == null) {
        return;
      }

      // Create a new XFile from edited bytes
      final XFile editedFile = XFile.fromData(
        croppedBytes,
        name: 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );

      onSuccess(croppedBytes, editedFile);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"Failed to edit image".tr}: $e")),
        );
      }
    }
  }

  // ============================================================
  // BANNER DIALOG
  // ============================================================

  void _showBannerDialog({String? docId, Map<String, dynamic>? currentData}) {
    String? selectedCategoryId = currentData?['category'];

    bool isOnClick = currentData?['onclick'] ?? false;

    String? currentImageUrl = currentData?['image'];

    XFile? pickedImage;

    Uint8List? pickedImageBytes;

    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double screenWidth = MediaQuery.of(context).size.width;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                docId == null
                    ? "Adding a new Banar".tr
                    : "Modify the banner".tr,
              ),
              content: SizedBox(
                width: screenWidth > 600 ? 560 : screenWidth * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // IMAGE PREVIEW
                      // ==================================================
                      Container(
                        height: 230,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: pickedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  pickedImageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : (currentImageUrl != null &&
                                  currentImageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  currentImageUrl!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 45,
                                    color: Color(0xFF6C5CE7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Click to select a banner image".tr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // IMAGE BUTTONS
                      // ==================================================
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(
                                pickedImageBytes == null
                                    ? "Select Image".tr
                                    : "Change Image".tr,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      await _selectAndEditImage(
                                        context: context,
                                        onSuccess: (bytes, file) {
                                          setDialogState(() {
                                            pickedImage = file;

                                            pickedImageBytes = bytes;
                                          });
                                        },
                                      );
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
                                        if (pickedImage == null) {
                                          return;
                                        }

                                        final edited = await _cropImage(
                                          context: context,
                                          imageFile: pickedImage!,
                                        );

                                        if (edited != null) {
                                          setDialogState(() {
                                            pickedImageBytes = edited;

                                            pickedImage = XFile.fromData(
                                              edited,
                                              name:
                                                  'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                              mimeType: 'image/jpeg',
                                            );
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
                                        if (pickedImageBytes == null) {
                                          return;
                                        }

                                        final resized = await _showResizeDialog(
                                          context,
                                          pickedImageBytes!,
                                        );

                                        if (resized != null) {
                                          setDialogState(() {
                                            pickedImageBytes = resized;

                                            pickedImage = XFile.fromData(
                                              resized,
                                              name:
                                                  'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                              mimeType: 'image/jpeg',
                                            );
                                          });
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ==================================================
                      // CLICKABLE
                      // ==================================================
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Clickable (OnClick)".tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Upon activation, the user will be directed to the sections."
                              .tr,
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: isOnClick,
                        activeColor: const Color(0xFF6C5CE7),
                        onChanged: isLoading
                            ? null
                            : (val) {
                                setDialogState(() {
                                  isOnClick = val;

                                  if (!isOnClick) {
                                    selectedCategoryId = null;
                                  }
                                });
                              },
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // CATEGORY
                      // ==================================================
                      if (isOnClick)
                        StreamBuilder<QuerySnapshot>(
                          stream: _categoriesRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            return DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              hint: Text("Select the relevant section.".tr),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    data['nameAr'] ??
                                        data['nameEn'] ??
                                        'Uncategorized Section'.tr,
                                  ),
                                );
                              }).toList(),
                              onChanged: isLoading
                                  ? null
                                  : (val) {
                                      setDialogState(() {
                                        selectedCategoryId = val;
                                      });
                                    },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // ACTIONS
              // ============================================================
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "cancellation".tr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          // -----------------------------
                          // Validate image
                          // -----------------------------

                          if (pickedImage == null &&
                              (currentImageUrl == null ||
                                  currentImageUrl!.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Please choose an image first".tr,
                                ),
                              ),
                            );

                            return;
                          }

                          // -----------------------------
                          // Validate category
                          // -----------------------------

                          if (isOnClick &&
                              (selectedCategoryId == null ||
                                  selectedCategoryId!.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Please select a section when enabling click functionality."
                                      .tr,
                                ),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            String finalImageUrl = currentImageUrl ?? '';

                            // -----------------------------
                            // Upload new image
                            // -----------------------------

                            if (pickedImage != null) {
                              final uploadedUrl =
                                  await CloudinaryService.uploadImage(
                                    pickedImage!,
                                  );

                              if (uploadedUrl != null) {
                                // Delete old image
                                if (currentImageUrl != null &&
                                    currentImageUrl!.isNotEmpty) {
                                  await CloudinaryService.deleteImage(
                                    currentImageUrl!,
                                  );
                                }

                                finalImageUrl = uploadedUrl;
                              } else {
                                throw Exception(
                                  "Failed to upload the image to Cloudinary.",
                                );
                              }
                            }

                            // -----------------------------
                            // Firestore data
                            // -----------------------------

                            final Map<String, dynamic> dataToSave = {
                              'image': finalImageUrl,
                              'onclick': isOnClick,
                              'category': isOnClick ? selectedCategoryId : '',
                            };

                            if (docId == null) {
                              dataToSave['order'] =
                                  DateTime.now().millisecondsSinceEpoch;

                              await _bannersRef.add(dataToSave);
                            } else {
                              await _bannersRef.doc(docId).update(dataToSave);
                            }

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${"Something went wrong".tr}: $e",
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          docId == null ? "Add".tr : "Save changes".tr,
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

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteBanner(String docId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirm Deletion".tr),
        content: Text(
          "Are you sure you want to permanently delete this banner?".tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("cancellation".tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("delete".tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (imageUrl.isNotEmpty) {
          await CloudinaryService.deleteImage(imageUrl);
        }

        await _bannersRef.doc(docId).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${"Failed to delete banner".tr}: $e")),
          );
        }
      }
    }
  }

  // ============================================================
  // REORDER
  // ============================================================

  void _updateBannersOrder(
    List<QueryDocumentSnapshot> docs,
    int oldIndex,
    int newIndex,
  ) {
    final item = docs.removeAt(oldIndex);

    docs.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < docs.length; i++) {
      batch.update(docs[i].reference, {'order': i});
    }

    batch.commit();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return _permision.contains("banner")
        ? Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),

            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C5CE7),
              onPressed: () => _showBannerDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                "Add Banner".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            body: StreamBuilder<QuerySnapshot>(
              stream: _bannersRef.snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "There are currently no banners.".tr,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final docs = List<QueryDocumentSnapshot>.from(
                  snapshot.data!.docs,
                );

                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;

                  final dataB = b.data() as Map<String, dynamic>;

                  final int orderA = dataA['order'] ?? 999999;

                  final int orderB = dataB['order'] ?? 999999;

                  return orderA.compareTo(orderB);
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.drag_indicator,
                            color: Color(0xFF6C5CE7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Drag and drop banners to rearrange display order"
                                .tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ReorderableWrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        onReorder: (oldIndex, newIndex) =>
                            _updateBannersOrder(docs, oldIndex, newIndex),
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          final String imageUrl = data['image'] ?? '';

                          final bool isOnClick = data['onclick'] ?? false;

                          final String categoryId = data['category'] ?? '';

                          return Container(
                            key: ValueKey(doc.id),
                            width: 360,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
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
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 8,
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey.shade100,
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                    ),

                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOnClick
                                              ? const Color(0xFF10B981)
                                              : Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isOnClick
                                                  ? Icons.touch_app
                                                  : Icons.visibility,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOnClick
                                                  ? "Interactive".tr
                                                  : "Display only".tr,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
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
                                        child:
                                            isOnClick && categoryId.isNotEmpty
                                            ? FutureBuilder<DocumentSnapshot>(
                                                future: _categoriesRef
                                                    .doc(categoryId)
                                                    .get(),
                                                builder: (context, catSnapshot) {
                                                  String categoryName = "...";

                                                  if (catSnapshot.hasData &&
                                                      catSnapshot
                                                          .data!
                                                          .exists) {
                                                    final catData =
                                                        catSnapshot.data!.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;

                                                    categoryName =
                                                        catData['nameAr'] ??
                                                        catData['nameEn'] ??
                                                        'Uncategorized Section'
                                                            .tr;
                                                  }

                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.grid_view_rounded,
                                                        size: 16,
                                                        color: Color(
                                                          0xFF6C5CE7,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          categoryName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF2D3436,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              )
                                            : Row(
                                                children: [
                                                  Icon(
                                                    Icons.image_outlined,
                                                    size: 16,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Static display image".tr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),

                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFF6C5CE7),
                                          size: 18,
                                        ),
                                        onPressed: () => _showBannerDialog(
                                          docId: doc.id,
                                          currentData: data,
                                        ),
                                      ),

                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _deleteBanner(doc.id, imageUrl),
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
          )
        : AccessDefindView();
  }
}
