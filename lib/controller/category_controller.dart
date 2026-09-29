import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../../Core/server/cloudinara_server.dart';
import '../../../../Core/server/get_permision.dart';
import '../helper/image_processing_helper.dart';

class CategoryController extends GetxController {
  final CollectionReference categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final ImagePicker _picker = ImagePicker();

  final RxList<String> permissions = <String>[].obs;
  final RxString searchQuery = "".obs;
  final RxBool isLoadingPermissions = true.obs;
  final RxBool isSaving = false.obs;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    initPermissions();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  Future<void> initPermissions() async {
    isLoadingPermissions.value = true;
    final res = await GetPermisionUser();
    permissions.assignAll(res);
    isLoadingPermissions.value = false;
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = query.trim().toLowerCase();
    });
  }

  Future<XFile> bytesToXFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      return XFile.fromData(bytes, name: filename, mimeType: 'image/jpeg');
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);
      return XFile(file.path);
    }
  }

  Future<Uint8List?> cropImage({
    required BuildContext context,
    required XFile imageFile,
  }) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      if (imageFile.path.isEmpty) throw Exception("Image path is empty");

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Category Image'.tr,
            toolbarColor: isDark ? const Color(0xFF1E1E1E) : AppColors.primaryPurple,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primaryPurple,
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: false,
            showCropGrid: true,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Edit Category Image'.tr,
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
            size: const CropperSize(width: 600, height: 500),
            viewwMode: WebViewMode.mode_2,
            dragMode: WebDragMode.crop,
            movable: true,
            rotatable: true,
            scalable: true,
            zoomable: true,
            zoomOnWheel: true,
            zoomOnTouch: true,
            modal: true,
            guides: true,
            center: true,
            highlight: true,
            background: true,
            checkCrossOrigin: true,
            checkOrientation: true,
          ),
        ],
      );

      if (croppedFile == null) return null;
      final Uint8List bytes = await croppedFile.readAsBytes();
      if (bytes.isEmpty) throw Exception("Edited image is empty");
      return bytes;
    } catch (e) {
      if (context.mounted) {
        Get.snackbar("Error".tr, "${"Failed to edit image".tr}: $e");
      }
      return null;
    }
  }

  Future<void> selectAndEditImage({
    required BuildContext context,
    required void Function(Uint8List bytes, XFile file) onSuccess,
  }) async {
    try {
      final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (selectedImage == null) return;

      final Uint8List originalBytes = await selectedImage.readAsBytes();
      if (originalBytes.isEmpty) throw Exception("Selected image is empty");

      final Uint8List? croppedBytes = await cropImage(
        context: context,
        imageFile: selectedImage,
      );

      if (croppedBytes == null) return;

      final XFile editedFile = await bytesToXFile(
        croppedBytes,
        'category_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      onSuccess(croppedBytes, editedFile);
    } catch (e) {
      if (context.mounted) {
        Get.snackbar("Error".tr, "${"Failed to edit image".tr}: $e");
      }
    }
  }

  Future<void> saveOrUpdateCategory({
    required String? docId,
    required String nameAr,
    required String nameEn,
    required XFile? pickedImage,
    required String? currentImageUrl,
    required VoidCallback onSuccessCallback,
  }) async {
    try {
      isSaving.value = true;
      String? imageUrl = currentImageUrl;

      if (pickedImage != null) {
        final uploadedUrl = await CloudinaryService.uploadImage(pickedImage);
        if (uploadedUrl != null) {
          if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
            await CloudinaryService.deleteImage(currentImageUrl);
          }
          imageUrl = uploadedUrl;
        }
      }

      final dataMap = {
        'nameAr': nameAr.trim(),
        'nameEn': nameEn.trim(),
        'imageUrl': imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        dataMap['createdAt'] = FieldValue.serverTimestamp();
        await categoriesRef.add(dataMap);
      } else {
        await categoriesRef.doc(docId).update(dataMap);
      }

      onSuccessCallback();
    } catch (e) {
      Get.snackbar("Error".tr, "${"Something went wrong".tr}: $e");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCategory(String docId, String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      await CloudinaryService.deleteImage(imageUrl);
    }
    await categoriesRef.doc(docId).delete();
  }
}