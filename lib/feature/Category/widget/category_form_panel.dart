import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../controller/category_controller.dart';
import 'resize_image_dialog.dart';

class CategoryFormPanel extends StatefulWidget {
  final CategoryController controller;
  final String? docId;
  final String? currentNameAr;
  final String? currentNameEn;
  final String? currentImageUrl;

  const CategoryFormPanel({
    super.key,
    required this.controller,
    this.docId,
    this.currentNameAr,
    this.currentNameEn,
    this.currentImageUrl,
  });

  @override
  State<CategoryFormPanel> createState() => _CategoryFormPanelState();
}

class _CategoryFormPanelState extends State<CategoryFormPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameArController;
  late TextEditingController nameEnController;

  XFile? pickedImage;
  Uint8List? pickedImageBytes;

  @override
  void initState() {
    super.initState();
    nameArController = TextEditingController(text: widget.currentNameAr ?? '');
    nameEnController = TextEditingController(text: widget.currentNameEn ?? '');
  }

  @override
  void dispose() {
    nameArController.dispose();
    nameEnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double panelWidth = MediaQuery.of(context).size.width > 600
        ? 480
        : MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black12,
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.docId == null
                            ? "Add New Category".tr
                            : "Edit Category".tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  Divider(
                    height: 24,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Category Image".tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: pickedImageBytes != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                pickedImageBytes!,
                                fit: BoxFit.contain,
                              ),
                            )
                                : (widget.currentImageUrl != null &&
                                widget.currentImageUrl!.isNotEmpty)
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.currentImageUrl!,
                                fit: BoxFit.contain,
                              ),
                            )
                                : Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 38,
                                  color: AppColors.primaryPurple,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Click button below to select Category Image".tr,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                                  label: Text(
                                    pickedImageBytes == null ? "Select Image".tr : "Change Image".tr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    await widget.controller.selectAndEditImage(
                                      context: context,
                                      onSuccess: (bytes, file) {
                                        setState(() {
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.crop_rotate, size: 18),
                                    label: Text("Crop / Edit".tr, style: const TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      if (pickedImage == null) return;
                                      final edited = await widget.controller.cropImage(
                                        context: context,
                                        imageFile: pickedImage!,
                                      );
                                      if (edited != null) {
                                        final editedXFile = await widget.controller.bytesToXFile(
                                          edited,
                                          'category_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                        );

                                        setState(() {
                                          pickedImageBytes = edited;
                                          pickedImage = editedXFile;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.photo_size_select_large, size: 18),
                                    label: Text("Resize".tr, style: const TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      if (pickedImageBytes == null) return;
                                      final resized = await showDialog<Uint8List>(
                                        context: context,
                                        builder: (_) => ResizeImageDialog(originalBytes: pickedImageBytes!),
                                      );

                                      if (resized != null) {
                                        final resizedXFile = await widget.controller.bytesToXFile(
                                          resized,
                                          'category_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                        );

                                        setState(() {
                                          pickedImageBytes = resized;
                                          pickedImage = resizedXFile;
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
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: "الاسم بالعربي",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? "يرجى إدخال الاسم بالعربي"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: nameEnController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: "English Name",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? "Please enter English name"
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final bool isSaving = widget.controller.isSaving.value;
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            child: Text("Cancel".tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                            ),
                            onPressed: isSaving
                                ? null
                                : () {
                              if (_formKey.currentState!.validate()) {
                                widget.controller.saveOrUpdateCategory(
                                  docId: widget.docId,
                                  nameAr: nameArController.text,
                                  nameEn: nameEnController.text,
                                  pickedImage: pickedImage,
                                  currentImageUrl: widget.currentImageUrl,
                                  onSuccessCallback: () => Navigator.pop(context),
                                );
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
                              widget.docId == null ? "Save".tr : "Update".tr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}