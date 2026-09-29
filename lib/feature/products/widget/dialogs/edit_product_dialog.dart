import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../../Core/Utils/appflowy_helper.dart';
import '../../../../Core/server/cloudinara_server.dart';
import '../../../../model/dynamic_field_model.dart';

class EditProductDialog extends StatefulWidget {
  final ProductModel product;
  final List<DynamicFieldModel> initialFields;
  final CollectionReference productsRef;
  final CollectionReference categoriesRef;
  final CollectionReference subcategoriesRef;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.initialFields,
    required this.productsRef,
    required this.categoriesRef,
    required this.subcategoriesRef,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;

  late bool _isProductActive;
  late EditorState _editorState;
  late EditorScrollController _editorScrollController;
  final FocusNode _editorFocusNode = FocusNode();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  late List<String> _existingImages;
  final List<XFile> _newlyPickedImages = [];
  final List<Uint8List> _newImagesBytes = [];

  late List<DynamicFieldModel> _customFields;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _isProductActive = widget.product.isActive;

    _editorState = EditorState(
      document: AppFlowyHelper.getAppFlowyDocument(widget.product.description),
    );
    _editorScrollController = EditorScrollController(editorState: _editorState);

    _selectedCategoryId = widget.product.categoryDoc;
    _selectedSubcategoryId = widget.product.SubCategoryDoc;

    _existingImages = List<String>.from(widget.product.images);
    _customFields = widget.initialFields
        .map((f) => DynamicFieldModel(
      name: f.name,
      type: f.type,
      isRequired: f.isRequired,
      options: List<String>.from(f.options),
    ))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : AppColors.textDark);
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final inputFillColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return AlertDialog(
      backgroundColor: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Edit Product Details", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Product Status", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: Text(
                    _isProductActive ? "Active" : "Inactive",
                    style: TextStyle(color: _isProductActive ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                  ),
                  value: _isProductActive,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _isProductActive = val),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: widget.categoriesRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return DropdownButtonFormField<String>(
                      dropdownColor: cardBgColor,
                      value: _selectedCategoryId != null && _selectedCategoryId!.isNotEmpty ? _selectedCategoryId : null,
                      decoration: const InputDecoration(labelText: "Select Category"),
                      items: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text("${data['nameEn']} (${data['nameAr']})"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedSubcategoryId = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (_selectedCategoryId != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: widget.subcategoriesRef.where('categoryId', isEqualTo: _selectedCategoryId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        dropdownColor: cardBgColor,
                        value: _selectedSubcategoryId != null && _selectedSubcategoryId!.isNotEmpty
                            ? _selectedSubcategoryId
                            : null,
                        decoration: const InputDecoration(labelText: "Select Subcategory"),
                        items: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text("${data['nameEn']} (${data['nameAr']})"),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSubcategoryId = val),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Product Title"),
                  validator: (val) => val == null || val.isEmpty ? "Required field" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Price (\$)"),
                  validator: (val) => double.tryParse(val ?? '') == null ? "Enter valid price" : null,
                ),
                const SizedBox(height: 16),
                Text("Description", style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 280,
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
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Undo',
                                  icon: Icon(Icons.undo, color: textColor, size: 20),
                                  onPressed: () {
                                    _editorState.undoManager.undo();
                                    _editorFocusNode.requestFocus();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Redo',
                                  icon: Icon(Icons.redo, color: textColor, size: 20),
                                  onPressed: () {
                                    _editorState.undoManager.redo();
                                    _editorFocusNode.requestFocus();
                                  },
                                ),
                                const SizedBox(width: 4),
                                Container(width: 1, height: 24, color: borderColor),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Bold',
                                  icon: Icon(Icons.format_bold, color: textColor, size: 20),
                                  onPressed: () {
                                    _editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
                                    _editorFocusNode.requestFocus();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Italic',
                                  icon: Icon(Icons.format_italic, color: textColor, size: 20),
                                  onPressed: () {
                                    _editorState.toggleAttribute(AppFlowyRichTextKeys.italic);
                                    _editorFocusNode.requestFocus();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Underline',
                                  icon: Icon(Icons.format_underline, color: textColor, size: 20),
                                  onPressed: () {
                                    _editorState.toggleAttribute(AppFlowyRichTextKeys.underline);
                                    _editorFocusNode.requestFocus();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Strikethrough',
                                  icon: Icon(Icons.strikethrough_s, color: textColor, size: 20),
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
                Text("Product Images", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                const SizedBox(height: 8),
                if (_existingImages.isNotEmpty) ...[
                  Text("Current Images:", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8, top: 4),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_existingImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _existingImages.removeAt(index)),
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final List<XFile> images = await picker.pickMultiImage(imageQuality: 85);
                      if (images.isNotEmpty) {
                        List<Uint8List> bytesList = [];
                        for (var img in images) {
                          bytesList.add(await img.readAsBytes());
                        }
                        setState(() {
                          _newlyPickedImages.addAll(images);
                          _newImagesBytes.addAll(bytesList);
                        });
                      }
                    } catch (e) {
                      debugPrint("Error picking images: $e");
                    }
                  },
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text("Add More Images (${_newlyPickedImages.length} selected)"),
                ),
                if (_newImagesBytes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newImagesBytes.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8, top: 4),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: MemoryImage(_newImagesBytes[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _newlyPickedImages.removeAt(index);
                                    _newImagesBytes.removeAt(index);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Required Order Fields", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _customFields.add(DynamicFieldModel(name: ''));
                        });
                      },
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
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "No custom fields required.",
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
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
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: field.name,
                                    decoration: const InputDecoration(labelText: "Field Name / Title", isDense: true),
                                    onChanged: (val) => field.name = val.trim(),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? "Enter field name" : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => setState(() => _customFields.removeAt(fIndex)),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: Theme.of(context).cardColor,
                                    value: field.type,
                                    decoration: const InputDecoration(labelText: "Field Type", isDense: true),
                                    items: const [
                                      DropdownMenuItem(value: 'text', child: Text("Text / كلام")),
                                      DropdownMenuItem(value: 'number', child: Text("Number / أرقام")),
                                      DropdownMenuItem(value: 'drive_link', child: Text("Google Drive Link / لينك درايف")),
                                      DropdownMenuItem(value: 'dropdown', child: Text("Dropdown Options / قائمة خيارات")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          field.type = val;
                                          if (val == 'dropdown' && field.options.isEmpty) {
                                            field.options = [''];
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: field.isRequired,
                                      onChanged: (val) => setState(() => field.isRequired = val ?? true),
                                    ),
                                    const Text("Required", style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            if (field.type == 'dropdown') ...[
                              const SizedBox(height: 12),
                              const Text("Dropdown Options:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: field.options.length,
                                itemBuilder: (context, optIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: field.options[optIndex],
                                            decoration: InputDecoration(
                                              labelText: "Option ${optIndex + 1}",
                                              isDense: true,
                                            ),
                                            onChanged: (val) => field.options[optIndex] = val.trim(),
                                            validator: (v) {
                                              if (field.type == 'dropdown' && (v == null || v.trim().isEmpty)) {
                                                return "Enter option name";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                          onPressed: field.options.length > 1
                                              ? () => setState(() => field.options.removeAt(optIndex))
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => field.options.add('')),
                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                label: const Text("Add Option", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
          onPressed: _isSaving
              ? null
              : () async {
            if (_formKey.currentState!.validate()) {
              if (_existingImages.isEmpty && _newlyPickedImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product must have at least one image!")),
                );
                return;
              }

              setState(() => _isSaving = true);

              try {
                final String updatedDescJson = jsonEncode({
                  "document": _editorState.document.toJson(),
                });

                List<String> uploadedUrls = [];
                for (var img in _newlyPickedImages) {
                  final url = await CloudinaryService.uploadImage(img);
                  if (url != null) uploadedUrls.add(url);
                }

                final List<String> finalImages = [..._existingImages, ...uploadedUrls];
                List<Map<String, dynamic>> fieldsList = _customFields.map((f) => f.toMap()).toList();

                final updatedData = {
                  'title': _titleController.text.trim(),
                  'description': updatedDescJson,
                  'price': double.parse(_priceController.text.trim()),
                  'categoryId': _selectedCategoryId,
                  'subcategoryId': _selectedSubcategoryId,
                  'images': finalImages,
                  'fields': fieldsList,
                  'isActive': _isProductActive,
                };

                await widget.productsRef.doc(widget.product.doc).update(updatedData);

                if (!mounted) return;

                final updatedProduct = ProductModel(
                  doc: widget.product.doc,
                  title: _titleController.text.trim(),
                  price: double.parse(_priceController.text.trim()),
                  avgRate: widget.product.avgRate,
                  categoryDoc: _selectedCategoryId ?? '',
                  description: updatedDescJson,
                  images: finalImages,
                  SubCategoryDoc: _selectedSubcategoryId ?? '',
                  discountPercentage: widget.product.discountPercentage,
                  discountUntil: widget.product.discountUntil,
                  isActive: _isProductActive,
                );

                Navigator.pop(context, {
                  'product': updatedProduct,
                  'fields': _customFields,
                });
              } catch (e) {
                setState(() => _isSaving = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update product: $e")),
                  );
                }
              }
            }
          },
          child: _isSaving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Text("Save Changes", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}