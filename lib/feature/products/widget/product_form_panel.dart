import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';
import '../../../model/dynamic_field_model.dart';

class ProductFormPanel extends StatefulWidget {
  final bool isDark;
  final CollectionReference productsRef;
  final CollectionReference categoriesRef;
  final CollectionReference subcategoriesRef;

  const ProductFormPanel({
    super.key,
    required this.isDark,
    required this.productsRef,
    required this.categoriesRef,
    required this.subcategoriesRef,
  });

  static Future<void> show(
      BuildContext context, {
        required bool isDark,
        required CollectionReference productsRef,
        required CollectionReference categoriesRef,
        required CollectionReference subcategoriesRef,
      }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProductForm',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => ProductFormPanel(
        isDark: isDark,
        productsRef: productsRef,
        categoriesRef: categoriesRef,
        subcategoriesRef: subcategoriesRef,
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

  @override
  State<ProductFormPanel> createState() => _ProductFormPanelState();
}

class _ProductFormPanelState extends State<ProductFormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPercController = TextEditingController();
  final _discountDaysController = TextEditingController();

  late final EditorState _editorState;
  late final EditorScrollController _editorScrollController;
  final FocusNode _editorFocusNode = FocusNode();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  bool _isActive = true;
  bool _isSaving = false;

  List<XFile> _pickedImages = [];
  List<Uint8List> _imagesBytes = [];
  final List<DynamicFieldModel> _customFields = [];

  @override
  void initState() {
    super.initState();
    _editorState = EditorState.blank(withInitialText: true);
    _editorScrollController = EditorScrollController(editorState: _editorState);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _discountPercController.dispose();
    _discountDaysController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, {String? hint}) {
    final mutedTextColor = widget.isDark ? Colors.grey[400] : AppColors.textMuted;
    final borderColor = widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final inputFillColor = widget.isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: mutedTextColor),
      hintStyle: TextStyle(color: widget.isDark ? Colors.grey[500] : Colors.grey[400]),
      filled: true,
      fillColor: inputFillColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image!")),
      );
      return;
    }

    for (final f in _customFields) {
      if (f.name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a name for all custom fields."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (f.type == 'dropdown' && f.options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please add at least one option for dropdown field '${f.name}'"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final List<String> uploadedUrls = [];
      for (final img in _pickedImages) {
        final url = await CloudinaryService.uploadImage(img);
        if (url != null && url.isNotEmpty) {
          uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isEmpty) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to upload images to Cloudinary!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final int discountVal = int.tryParse(_discountPercController.text.trim()) ?? 0;
      final int discountDays = int.tryParse(_discountDaysController.text.trim()) ?? 0;
      DateTime? discountUntilDate;

      if (discountVal > 0 && discountDays > 0) {
        discountUntilDate = DateTime.now().add(Duration(days: discountDays));
      }

      final String descriptionData = jsonEncode(_editorState.document.toJson());

      await widget.productsRef.add({
        'title': _titleController.text.trim(),
        'description': descriptionData,
        'price': double.parse(_priceController.text.trim()),
        'discountPercentage': discountVal.toDouble(),
        'discountUntil': discountUntilDate != null ? Timestamp.fromDate(discountUntilDate) : null,
        'categoryId': _selectedCategoryId,
        'subcategoryId': _selectedSubcategoryId,
        'images': uploadedUrls,
        'fields': _customFields.map((f) => f.toMap()).toList(),
        'avgRating': 0.0,
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving product: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = screenWidth > 900 ? 560.0 : (screenWidth > 600 ? 520.0 : screenWidth);

    final panelBgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = widget.isDark ? Colors.grey[400] : AppColors.textMuted;
    final borderColor = widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final cardBgColor = widget.isDark ? const Color(0xFF252525) : Colors.grey.shade50;
    final inputFillColor = widget.isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          height: screenHeight,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: panelBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.5 : 0.12),
                blurRadius: 20,
                spreadRadius: 5,
              ),
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
                        "Add New Product",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories Stream
                          StreamBuilder<QuerySnapshot>(
                            stream: widget.categoriesRef.snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const LinearProgressIndicator();
                              return DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                dropdownColor: panelBgColor,
                                style: TextStyle(color: textColor),
                                decoration: _buildInputDecoration("Select Category"),
                                items: snapshot.data!.docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text("${data['nameEn']} (${data['nameAr']})", style: TextStyle(color: textColor)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() {
                                  _selectedCategoryId = val;
                                  _selectedSubcategoryId = null;
                                }),
                                validator: (v) => v == null ? "Please select a category" : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Subcategories Stream
                          if (_selectedCategoryId != null)
                            StreamBuilder<QuerySnapshot>(
                              stream: widget.subcategoriesRef.where('categoryId', isEqualTo: _selectedCategoryId).snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const LinearProgressIndicator();
                                return DropdownButtonFormField<String>(
                                  value: _selectedSubcategoryId,
                                  dropdownColor: panelBgColor,
                                  style: TextStyle(color: textColor),
                                  decoration: _buildInputDecoration("Select Subcategory"),
                                  items: snapshot.data!.docs.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text("${data['nameEn']} (${data['nameAr']})", style: TextStyle(color: textColor)),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedSubcategoryId = val),
                                  validator: (v) => v == null ? "Please select a subcategory" : null,
                                );
                              },
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(color: textColor),
                            decoration: _buildInputDecoration("Product Title"),
                            validator: (v) => (v == null || v.trim().isEmpty) ? "Enter product title" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: textColor),
                            decoration: _buildInputDecoration("Price (\$)"),
                            validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? "Enter valid price" : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _discountPercController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textColor),
                                  decoration: _buildInputDecoration("Discount (%)", hint: "e.g. 10"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _discountDaysController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textColor),
                                  decoration: _buildInputDecoration("Duration (Days)", hint: "e.g. 7"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: SwitchListTile(
                              title: Text("Product Status", style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
                              subtitle: Text(
                                _isActive ? "Active (Visible to users)" : "Inactive (Hidden from users)",
                                style: TextStyle(color: _isActive ? Colors.green : Colors.red, fontSize: 12),
                              ),
                              value: _isActive,
                              activeColor: AppColors.primaryPurple,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text("Description", style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 16)),
                          const SizedBox(height: 8),
                          // Editor Widget Container
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              color: inputFillColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Column(
                                children: [
                                  Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: widget.isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                                      border: Border(bottom: BorderSide(color: borderColor)),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Undo',
                                            icon: Icon(Icons.undo, color: textColor),
                                            onPressed: () {
                                              _editorState.undoManager.undo();
                                              _editorFocusNode.requestFocus();
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Redo',
                                            icon: Icon(Icons.redo, color: textColor),
                                            onPressed: () {
                                              _editorState.undoManager.redo();
                                              _editorFocusNode.requestFocus();
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          Container(width: 1, height: 26, color: borderColor),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Bold',
                                            icon: Icon(Icons.format_bold, color: textColor),
                                            onPressed: () {
                                              _editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
                                              _editorFocusNode.requestFocus();
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Italic',
                                            icon: Icon(Icons.format_italic, color: textColor),
                                            onPressed: () {
                                              _editorState.toggleAttribute(AppFlowyRichTextKeys.italic);
                                              _editorFocusNode.requestFocus();
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Underline',
                                            icon: Icon(Icons.format_underline, color: textColor),
                                            onPressed: () {
                                              _editorState.toggleAttribute(AppFlowyRichTextKeys.underline);
                                              _editorFocusNode.requestFocus();
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Strikethrough',
                                            icon: Icon(Icons.strikethrough_s, color: textColor),
                                            onPressed: () {
                                              _editorState.toggleAttribute(AppFlowyRichTextKeys.strikethrough);
                                              _editorFocusNode.requestFocus();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: FloatingToolbar(
                                      editorState: _editorState,
                                      editorScrollController: _editorScrollController,
                                      textDirection: Directionality.of(context),
                                      items: [
                                        paragraphItem,
                                        ...headingItems,
                                        ...markdownFormatItems,
                                        quoteItem,
                                        bulletedListItem,
                                        numberedListItem,
                                        linkItem,
                                        buildTextColorItem(),
                                        buildHighlightColorItem(),
                                        ...alignmentItems,
                                        ...textDirectionItems,
                                      ],
                                      child: AppFlowyEditor(
                                        editorState: _editorState,
                                        editorScrollController: _editorScrollController,
                                        focusNode: _editorFocusNode,
                                        editable: true,
                                        autoFocus: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Custom Order Fields Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Required Order Fields", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                              TextButton.icon(
                                onPressed: () => setState(() => _customFields.add(DynamicFieldModel(name: ''))),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("Add Field"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_customFields.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "No custom fields added. Click 'Add Field' to define required inputs for this product.",
                                style: TextStyle(color: mutedTextColor, fontSize: 12),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _customFields.length,
                              itemBuilder: (context, fIndex) {
                                final field = _customFields[fIndex];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: field.name,
                                              style: TextStyle(color: textColor),
                                              decoration: InputDecoration(
                                                labelText: "Field Name / Title",
                                                hintText: "e.g. Select Size, Color, Drive Link",
                                                labelStyle: TextStyle(color: mutedTextColor),
                                                isDense: true,
                                              ),
                                              onChanged: (val) => field.name = val.trim(),
                                              validator: (v) => (v == null || v.trim().isEmpty) ? "Enter field name" : null,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () => setState(() => _customFields.removeAt(fIndex)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              value: field.type,
                                              dropdownColor: panelBgColor,
                                              style: TextStyle(color: textColor),
                                              decoration: InputDecoration(
                                                labelText: "Field Type",
                                                labelStyle: TextStyle(color: mutedTextColor),
                                                isDense: true,
                                              ),
                                              items: const [
                                                DropdownMenuItem(value: 'text', child: Text("Text / كلام")),
                                                DropdownMenuItem(value: 'number', child: Text("Number / أرقام")),
                                                DropdownMenuItem(value: 'drive_link', child: Text("Google Drive Link")),
                                                DropdownMenuItem(value: 'dropdown', child: Text("Dropdown")),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) setState(() => field.type = val);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: field.isRequired,
                                                activeColor: AppColors.primaryPurple,
                                                onChanged: (val) => setState(() => field.isRequired = val ?? true),
                                              ),
                                              Text("Required", style: TextStyle(fontSize: 12, color: textColor)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                          Text("Product Images", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              try {
                                final ImagePicker picker = ImagePicker();
                                final List<XFile> images = await picker.pickMultiImage(imageQuality: 85);
                                if (images.isNotEmpty) {
                                  final List<Uint8List> bytesList = [];
                                  for (final img in images) {
                                    bytesList.add(await img.readAsBytes());
                                  }
                                  setState(() {
                                    _pickedImages = images;
                                    _imagesBytes = bytesList;
                                  });
                                }
                              } catch (e) {
                                debugPrint("Error picking images: $e");
                              }
                            },
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text("Select Images (${_pickedImages.length} selected)", style: TextStyle(color: textColor)),
                          ),
                          if (_imagesBytes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _imagesBytes.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(image: MemoryImage(_imagesBytes[index]), fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Cancel", style: TextStyle(color: textColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSaving ? null : _handleSave,
                          child: _isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Text("Save Product", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}