import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../model/category_model.dart';

class SubcategoryWidget extends StatefulWidget {
  final CategoryModel categoryModel;

  const SubcategoryWidget({super.key, required this.categoryModel});

  @override
  State<SubcategoryWidget> createState() => _SubcategoryWidgetState();
}

class _SubcategoryWidgetState extends State<SubcategoryWidget> {
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');

  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      if (sourcePath.isEmpty) throw Exception("Image path is empty");

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Subcategory Image',
            toolbarColor: AppColors.primaryPurple,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primaryPurple,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Edit Subcategory Image',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to edit image: $e")),
        );
      }
      return null;
    }
  }

  // ============================================================
  // RESIZE IMAGE
  // ============================================================
  Future<Uint8List?> _resizeImage(
      Uint8List bytes, {
        required int width,
        required int height,
      }) async {
    try {
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception("Could not decode image");

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
        const SnackBar(content: Text("Could not read image dimensions")),
      );
      return null;
    }

    final int originalWidth = decoded.width;
    final int originalHeight = decoded.height;

    final TextEditingController widthController =
    TextEditingController(text: originalWidth.toString());
    final TextEditingController heightController =
    TextEditingController(text: originalHeight.toString());

    bool keepRatio = true;
    final double ratio = originalWidth / originalHeight;

    return await showDialog<Uint8List?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.photo_size_select_large,
                      color: AppColors.primaryPurple),
                  SizedBox(width: 10),
                  Text("Resize Image"),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primaryPurple, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Original size: $originalWidth × $originalHeight px",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widthController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Width",
                        suffixText: "px",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        if (!keepRatio) return;
                        final int? width = int.tryParse(value);
                        if (width == null || width <= 0) return;
                        heightController.text =
                            (width / ratio).round().toString();
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text("Keep aspect ratio",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: keepRatio,
                          activeColor: AppColors.primaryPurple,
                          onChanged: (val) => setState(() => keepRatio = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Height",
                        suffixText: "px",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        if (!keepRatio) return;
                        final int? height = int.tryParse(value);
                        if (height == null || height <= 0) return;
                        widthController.text =
                            (height * ratio).round().toString();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Resize"),
                  onPressed: () async {
                    final int? width = int.tryParse(widthController.text);
                    final int? height = int.tryParse(heightController.text);

                    if (width == null ||
                        height == null ||
                        width <= 0 ||
                        height <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please enter valid dimensions")),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    final resized = await _resizeImage(originalBytes,
                        width: width, height: height);

                    if (resized == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to resize image")),
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
  }

  // ============================================================
  // SELECT & EDIT IMAGE FLOW
  // ============================================================
  Future<void> _selectAndEditImage({
    required BuildContext context,
    required void Function(Uint8List bytes, XFile file) onSuccess,
  }) async {
    try {
      final XFile? selectedImage =
      await _picker.pickImage(source: ImageSource.gallery);
      if (selectedImage == null) return;

      final Uint8List originalBytes = await selectedImage.readAsBytes();
      if (originalBytes.isEmpty) throw Exception("Selected image is empty");

      final Uint8List? croppedBytes = await _cropImage(
        context: context,
        imageFile: selectedImage,
      );

      if (croppedBytes == null) return;

      final XFile editedFile = XFile.fromData(
        croppedBytes,
        name: 'subcategory_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );

      onSuccess(croppedBytes, editedFile);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to edit image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white,
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Subcategories: ${widget.categoryModel.NameEn}",
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 650;
          final bool isTablet =
              constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16.0 : 28.0,
              vertical: isMobile ? 16.0 : 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isMobile),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _subcategoriesRef
                        .where('categoryId',
                        isEqualTo: widget.categoryModel.doc)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading subcategories!"),
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
                        final nameAr =
                        (data['nameAr'] ?? '').toString().toLowerCase();
                        final nameEn =
                        (data['nameEn'] ?? '').toString().toLowerCase();
                        return nameAr.contains(_searchQuery) ||
                            nameEn.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                  AppColors.primaryPurple.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.category_outlined,
                                  size: 48,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No subcategories found matching your search.",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      int crossAxisCount = 4;
                      double childAspectRatio = 0.85;

                      if (isMobile) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.82;
                      } else if (isTablet) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.85;
                      } else if (constraints.maxWidth < 1400) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.88;
                      } else {
                        crossAxisCount = 5;
                        childAspectRatio = 0.90;
                      }

                      return GridView.builder(
                        itemCount: filteredDocs.length,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
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

                          return _buildSubcategoryCard(
                            context,
                            docId: docId,
                            nameAr: nameAr,
                            nameEn: nameEn,
                            imageUrl: imageUrl,
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
    );
  }

  // Header Section
  Widget _buildHeader(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Subcategories for '${widget.categoryModel.NameEn}'",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Add or update sub-items linked to this category",
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openSubcategoryFormPanel(context),
              icon:
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: const Text(
                "Add Subcategory",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                elevation: 0,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Subcategories for '${widget.categoryModel.NameEn}'",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Add or update sub-items linked to this category",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openSubcategoryFormPanel(context),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: const Text(
            "Add Subcategory",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Modern Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: "Search subcategories by Arabic or English name...",
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primaryPurple, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.cancel_rounded,
                color: Colors.grey, size: 20),
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

  // Modern Clean Subcategory Card
  Widget _buildSubcategoryCard(
      BuildContext context, {
        required String docId,
        required String nameAr,
        required String nameEn,
        required String imageUrl,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner Section
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                      color: Color(0xFFF1F5F9),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.grey, size: 32),
                        ),
                      )
                          : const Center(
                        child: Icon(Icons.category_outlined,
                            color: Colors.grey, size: 36),
                      ),
                    ),
                  ),

                  // Top Action Overlay Buttons
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _openSubcategoryFormPanel(
                              context,
                              docId: docId,
                              currentNameAr: nameAr,
                              currentNameEn: nameEn,
                              currentImageUrl: imageUrl,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.edit_outlined,
                                  size: 18, color: AppColors.primaryPurple),
                            ),
                          ),
                          const SizedBox(width: 2),
                          InkWell(
                            onTap: () => _confirmDelete(
                                context, docId, nameEn, imageUrl),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title and Meta Data Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
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
                    const SizedBox(height: 2),
                    Text(
                      nameEn,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubcategoryFormPanel(
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
    Uint8List? pickedImageBytes;
    String? imageUrl = currentImageUrl;
    bool isSaving = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SubcategoryForm',
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
                              Text(
                                docId == null
                                    ? "Add Subcategory"
                                    : "Edit Subcategory",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
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
                                    "Subcategory Image",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Preview Container
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: pickedImageBytes != null
                                        ? ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      child: Image.memory(
                                        pickedImageBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                        : (imageUrl != null &&
                                        imageUrl!.isNotEmpty)
                                        ? ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                        : const Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 38,
                                          color:
                                          AppColors.primaryPurple,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Click button below to select Subcategory Image",
                                          style: TextStyle(
                                            color:
                                            AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Control Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(
                                              Icons.photo_library_outlined,
                                              size: 18),
                                          label: Text(
                                            pickedImageBytes == null
                                                ? "Select Image"
                                                : "Change Image",
                                            style:
                                            const TextStyle(fontSize: 12),
                                          ),
                                          onPressed: isSaving
                                              ? null
                                              : () async {
                                            await _selectAndEditImage(
                                              context: context,
                                              onSuccess: (bytes, file) {
                                                setPanelState(() {
                                                  pickedImage = file;
                                                  pickedImageBytes =
                                                      bytes;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (pickedImageBytes != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.crop_rotate,
                                                size: 18),
                                            label: const Text("Crop / Edit",
                                                style: TextStyle(fontSize: 12)),
                                            onPressed: isSaving
                                                ? null
                                                : () async {
                                              if (pickedImage == null) {
                                                return;
                                              }
                                              final edited =
                                              await _cropImage(
                                                context: context,
                                                imageFile: pickedImage!,
                                              );
                                              if (edited != null) {
                                                setPanelState(() {
                                                  pickedImageBytes =
                                                      edited;
                                                  pickedImage =
                                                      XFile.fromData(
                                                        edited,
                                                        name:
                                                        'subcategory_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                                        mimeType:
                                                        'image/jpeg',
                                                      );
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                                Icons.photo_size_select_large,
                                                size: 18),
                                            label: const Text("Resize",
                                                style: TextStyle(fontSize: 12)),
                                            onPressed: isSaving
                                                ? null
                                                : () async {
                                              if (pickedImageBytes ==
                                                  null) return;
                                              final resized =
                                              await _showResizeDialog(
                                                  context,
                                                  pickedImageBytes!);
                                              if (resized != null) {
                                                setPanelState(() {
                                                  pickedImageBytes =
                                                      resized;
                                                  pickedImage =
                                                      XFile.fromData(
                                                        resized,
                                                        name:
                                                        'subcategory_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                                        mimeType:
                                                        'image/jpeg',
                                                      );
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: nameArController,
                                    decoration: InputDecoration(
                                      labelText: "الاسم بالعربي",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (v) =>
                                    v == null || v.trim().isEmpty
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
                                    validator: (v) =>
                                    v == null || v.trim().isEmpty
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
                                    elevation: 0,
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
                                      setPanelState(
                                              () => isSaving = true);

                                      try {
                                        if (pickedImage != null) {
                                          final uploadedUrl =
                                          await CloudinaryService
                                              .uploadImage(
                                              pickedImage!);
                                          if (uploadedUrl != null) {
                                            if (currentImageUrl != null &&
                                                currentImageUrl
                                                    .isNotEmpty) {
                                              await CloudinaryService
                                                  .deleteImage(
                                                  currentImageUrl);
                                            }
                                            imageUrl = uploadedUrl;
                                          }
                                        }

                                        final dataMap = {
                                          'categoryId':
                                          widget.categoryModel.doc,
                                          'nameAr': nameArController.text
                                              .trim(),
                                          'nameEn': nameEnController.text
                                              .trim(),
                                          'imageUrl': imageUrl ?? '',
                                          'updatedAt':
                                          FieldValue.serverTimestamp(),
                                        };

                                        if (docId == null) {
                                          dataMap['createdAt'] =
                                              FieldValue.serverTimestamp();
                                          await _subcategoriesRef
                                              .add(dataMap);
                                        } else {
                                          await _subcategoriesRef
                                              .doc(docId)
                                              .update(dataMap);
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                      } catch (e) {
                                        debugPrint(
                                            "Error saving subcategory: $e");
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
                                      : Text(
                                    docId == null ? "Save" : "Update",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
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

  void _confirmDelete(
      BuildContext context,
      String docId,
      String subcategoryName,
      String imageUrl,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Subcategory",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$subcategoryName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (imageUrl.isNotEmpty) {
                await CloudinaryService.deleteImage(imageUrl);
              }

              await _subcategoriesRef.doc(docId).delete();

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