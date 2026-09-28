import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';

Map<String, dynamic>? _normalizeAppFlowyJson(
    dynamic value,
    ) {
  if (value is! Map) {
    return null;
  }

  dynamic current = value;

  int safetyCounter = 0;

  while (current is Map && safetyCounter < 20) {
    safetyCounter++;

    final map = Map<String, dynamic>.from(current);

    if (map['type'] == 'page') {
      return {
        'document': map,
      };
    }

    if (map.containsKey('document')) {
      final nested = map['document'];

      if (nested is Map) {
        current = nested;
        continue;
      }

      if (nested is String) {
        try {
          current = jsonDecode(nested);
          continue;
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  return null;
}

// نموذج يمثل الحقل المخصص للمنتج
class DynamicFieldModel {
  String name;
  String type; // 'text', 'number', 'drive_link', 'dropdown'
  bool isRequired;
  List<String> options; // الخيارات الخاصة بالقائمة المنسدلة

  DynamicFieldModel({
    required this.name,
    this.type = 'text',
    this.isRequired = true,
    List<String>? options,
  }) : options = options ?? [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isRequired': isRequired,
      'options': options,
    };
  }

  factory DynamicFieldModel.fromMap(Map<String, dynamic> map) {
    return DynamicFieldModel(
      name: map['name'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? true,
      options: map['options'] != null ? List<String>.from(map['options']) : [],
    );
  }
}

class ProductDetailsWidget extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsWidget({super.key, required this.product});

  @override
  State<ProductDetailsWidget> createState() => _ProductDetailsWidgetState();
}

class _ProductDetailsWidgetState extends State<ProductDetailsWidget> {
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');

  late ProductModel _currentProduct;
  final PageController _pageController = PageController();
  int _selectedImageIndex = 0;

  List<DynamicFieldModel> _productFields = [];
  bool _isLoadingFields = true;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _fetchProductFields();
  }

  Future<void> _fetchProductFields() async {
    try {
      final docSnap = await _productsRef.doc(_currentProduct.doc).get();
      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data['fields'] != null) {
          final fieldsData = data['fields'] as List<dynamic>;
          setState(() {
            _productFields = fieldsData
                .map((f) => DynamicFieldModel.fromMap(f as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching fields: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFields = false;
        });
      }
    }
  }

  // تغيير حالة المنتج (Active / Inactive) من واجهة التفاصيل
  Future<void> _toggleProductStatus(bool newStatus) async {
    setState(() => _isTogglingStatus = true);
    try {
      await _productsRef.doc(_currentProduct.doc).update({
        'isActive': newStatus,
      });

      if (!mounted) return;

      setState(() {
        _currentProduct = ProductModel(
          doc: _currentProduct.doc,
          title: _currentProduct.title,
          price: _currentProduct.price,
          avgRate: _currentProduct.avgRate,
          categoryDoc: _currentProduct.categoryDoc,
          description: _currentProduct.description,
          images: _currentProduct.images,
          SubCategoryDoc: _currentProduct.SubCategoryDoc,
          discountPercentage: _currentProduct.discountPercentage,
          discountUntil: _currentProduct.discountUntil,
          isActive: newStatus,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? "Product is now Active"
                : "Product is now Inactive",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: _currentProduct.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _removeDiscount() async {
    try {
      await _productsRef.doc(_currentProduct.doc).update({
        'discountPercentage': 0.0,
        'discountUntil': FieldValue.delete(),
      });

      if (!mounted) return;

      setState(() {
        _currentProduct = ProductModel(
          doc: _currentProduct.doc,
          title: _currentProduct.title,
          price: _currentProduct.price,
          avgRate: _currentProduct.avgRate,
          categoryDoc: _currentProduct.categoryDoc,
          description: _currentProduct.description,
          images: _currentProduct.images,
          SubCategoryDoc: _currentProduct.SubCategoryDoc,
          discountPercentage: 0,
          discountUntil: null,
          isActive: _currentProduct.isActive,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discount removed successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove discount: $e")),
      );
    }
  }

  void _showDiscountDialog(BuildContext parentContext) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final discountController = TextEditingController(
      text: _currentProduct.discountPercentage > 0
          ? _currentProduct.discountPercentage.toString()
          : '',
    );
    DateTime selectedDate = _currentProduct.discountUntil ??
        DateTime.now().add(const Duration(days: 7));
    bool isSaving = false;

    showDialog(
      context: parentContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(dialogContext).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.local_offer, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Text(
                    "Set Temporary Discount",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(dialogContext).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: TextStyle(
                        color: Theme.of(dialogContext).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: "Discount Percentage (%)",
                      hintText: "e.g. 15 for 15%",
                      prefixIcon: const Icon(Icons.percent,
                          color: AppColors.primaryPurple),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month,
                        color: AppColors.primaryPurple),
                    title: Text(
                      "Discount Valid Until:",
                      style: TextStyle(
                          color: Theme.of(dialogContext)
                              .textTheme
                              .bodyMedium
                              ?.color),
                    ),
                    subtitle: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} - ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          if (!dialogContext.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple),
                  onPressed: isSaving
                      ? null
                      : () async {
                    final percent =
                        int.tryParse(discountController.text.trim()) ?? 0;
                    if (percent <= 0 || percent > 100) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Please enter a valid percentage (1-100)")),
                      );
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    final discountData = {
                      'discountPercentage': percent,
                      'discountUntil': Timestamp.fromDate(selectedDate),
                    };

                    try {
                      await _productsRef
                          .doc(_currentProduct.doc)
                          .update(discountData);

                      if (!mounted) return;

                      setState(() {
                        _currentProduct = ProductModel(
                          doc: _currentProduct.doc,
                          title: _currentProduct.title,
                          price: _currentProduct.price,
                          avgRate: _currentProduct.avgRate,
                          categoryDoc: _currentProduct.categoryDoc,
                          description: _currentProduct.description,
                          images: _currentProduct.images,
                          SubCategoryDoc: _currentProduct.SubCategoryDoc,
                          discountPercentage: double.parse(percent.toString()),
                          discountUntil: selectedDate,
                          isActive: _currentProduct.isActive,
                        );
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                              content:
                              Text("Failed to apply discount: $e")),
                        );
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text("Apply Discount",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : AppColors.textDark);
    final textSecondary = isDark ? Colors.grey.shade400 : AppColors.textMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primaryPurple),
            onPressed: () => _showEditProductDialog(context),
            tooltip: "Edit Product",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
            tooltip: "Delete Product",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // معرض الصور
            Container(
              color: cardColor,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: _currentProduct.images.isNotEmpty
                        ? PageView.builder(
                      controller: _pageController,
                      itemCount: _currentProduct.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openFullScreenImage(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Image.network(
                                    _currentProduct.images[index],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                        Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentProduct.images.length > 1) ...[
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _currentProduct.images.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedImageIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryPurple
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _currentProduct.images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // تفاصيل المنتج والخصومات وحالة المنتج
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // شريط عرض وتعديل حالة المنتج (Active / Inactive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentProduct.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _currentProduct.isActive
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _currentProduct.isActive
                                        ? Icons.check_circle_outline
                                        : Icons.pause_circle_outline,
                                    color: _currentProduct.isActive
                                        ? Colors.green
                                        : Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Status: ${_currentProduct.isActive ? 'Active' : 'Inactive'}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _currentProduct.isActive
                                          ? Colors.green
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              _isTogglingStatus
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                                  : Switch(
                                value: _currentProduct.isActive,
                                activeColor: Colors.green,
                                onChanged: (val) =>
                                    _toggleProductStatus(val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _currentProduct.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (_currentProduct.hasActiveDiscount) ...[
                                  Text(
                                    "${_currentProduct.price.toStringAsFixed(2)} EGP",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  Text(
                                    "${_currentProduct.discountedPrice.toStringAsFixed(2)} EGP",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.greenAccent
                                          : Colors.green,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    "${_currentProduct.price} EGP",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.greenAccent
                                          : Colors.green,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_currentProduct.hasActiveDiscount) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.orange.withOpacity(0.15)
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.orange.withOpacity(0.4)
                                      : Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${_currentProduct.discountPercentage.toInt()}% OFF until ${_currentProduct.discountUntil!.day}/${_currentProduct.discountUntil!.month} ${_currentProduct.discountUntil!.hour}:${_currentProduct.discountUntil!.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _removeDiscount,
                                  child: const Icon(Icons.cancel,
                                      color: Colors.redAccent, size: 20),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primaryPurple),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showDiscountDialog(context),
                            icon: const Icon(Icons.local_offer_outlined,
                                color: AppColors.primaryPurple, size: 18),
                            label: Text(
                              _currentProduct.hasActiveDiscount
                                  ? "Edit Discount"
                                  : "Add Discount Offer",
                              style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentProduct.avgRate.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Product ID: ${_currentProduct.doc.length > 6 ? _currentProduct.doc.substring(0, 6) : _currentProduct.doc}...",
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // الوصف
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ProductDescriptionWidget(
                          description: _currentProduct.description,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // عرض الحقول المخصصة لطلب المنتج
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Required Order Fields",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingFields)
                          const Center(child: CircularProgressIndicator())
                        else if (_productFields.isEmpty)
                          Text(
                            "No custom fields required for ordering this product.",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _productFields.length,
                            separatorBuilder: (context, index) =>
                            const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final field = _productFields[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            field.type == 'drive_link'
                                                ? Icons.add_to_drive
                                                : field.type == 'number'
                                                ? Icons.pin
                                                : field.type == 'dropdown'
                                                ? Icons
                                                .arrow_drop_down_circle_outlined
                                                : Icons.short_text,
                                            size: 18,
                                            color: AppColors.primaryPurple,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            field.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: field.isRequired
                                              ? Colors.red.withOpacity(0.15)
                                              : (isDark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade100),
                                          borderRadius:
                                          BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          field.isRequired
                                              ? "Required"
                                              : "Optional",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: field.isRequired
                                                ? Colors.redAccent
                                                : textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (field.type == 'dropdown' &&
                                      field.options.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: field.options.map((opt) {
                                        return Chip(
                                          label: Text(opt,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.purple.shade200
                                                      : Colors
                                                      .purple.shade900)),
                                          backgroundColor: isDark
                                              ? Colors.purple.withOpacity(0.2)
                                              : Colors.purple.shade50,
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        );
                                      }).toList(),
                                    ),
                                  ]
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // تقييمات العملاء
                  Text(
                    "Customer Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: _productsRef
                        .doc(_currentProduct.doc)
                        .collection('reviews')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final reviews = snapshot.data?.docs ?? [];

                      if (reviews.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "No reviews for this product yet.",
                              style: TextStyle(color: textSecondary),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review =
                          reviews[index].data() as Map<String, dynamic>;
                          final userName = review['userName'] ?? 'Anonymous';
                          final comment = review['comment'] ?? '';
                          final rating = (review['rating'] ?? 0).toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryPurple
                                      .withOpacity(0.15),
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppColors.primaryPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            userName,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: textPrimary),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded,
                                                  color: Colors.amber,
                                                  size: 16),
                                              const SizedBox(width: 2),
                                              Text(
                                                "$rating",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: textPrimary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (comment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          comment,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Document createDocumentFromString(String text) {
    return Document(
      root: pageNode(
        children: [
          paragraphNode(text: text),
        ],
      ),
    );
  }

  Document _getAppFlowyDocument(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return createDocumentFromString('');
    }

    try {
      dynamic parsed = jsonDecode(trimmed);

      while (parsed is String) {
        final inner = parsed.trim();

        if (inner.isEmpty) {
          break;
        }

        parsed = jsonDecode(inner);
      }

      final normalized = _normalizeAppFlowyJson(parsed);

      if (normalized != null) {
        return Document.fromJson(normalized);
      }
    } catch (e, stackTrace) {
      debugPrint(
        "Error parsing AppFlowy document: $e",
      );

      debugPrint(
        stackTrace.toString(),
      );
    }

    return createDocumentFromString(text);
  }

  // ==================== نافذة تعديل المنتج بالكامل ====================
  void _showEditProductDialog(BuildContext parentContext) async {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: _currentProduct.title);
    final priceController =
    TextEditingController(text: _currentProduct.price.toString());

    bool isProductActive = _currentProduct.isActive;

    final editorState = EditorState(
      document: _getAppFlowyDocument(_currentProduct.description),
    );

    final EditorScrollController editorScrollController =
    EditorScrollController(editorState: editorState);
    final FocusNode editorFocusNode = FocusNode();

    String? selectedCategoryId = _currentProduct.categoryDoc;
    String? selectedSubcategoryId = _currentProduct.SubCategoryDoc;

    List<String> existingImages = List<String>.from(_currentProduct.images);
    List<XFile> newlyPickedImages = [];
    List<Uint8List> newImagesBytes = [];

    List<DynamicFieldModel> customFields = _productFields
        .map((f) => DynamicFieldModel(
      name: f.name,
      type: f.type,
      isRequired: f.isRequired,
      options: List<String>.from(f.options),
    ))
        .toList();

    bool isSaving = false;

    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cardBgColor = Theme.of(context).cardColor;
            final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
                (isDark ? Colors.white : AppColors.textDark);
            final borderColor =
            isDark ? Colors.grey.shade700 : Colors.grey.shade300;
            final inputFillColor =
            isDark ? const Color(0xFF2A2A2A) : Colors.white;

            return AlertDialog(
              backgroundColor: cardBgColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text("Edit Product Details",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor)),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // تعديل حالة النشاط داخل الحوار
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "Product Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            isProductActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color: isProductActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: isProductActive,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            setDialogState(() {
                              isProductActive = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // التصنيف الرئيسي
                        StreamBuilder<QuerySnapshot>(
                          stream: _categoriesRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return DropdownButtonFormField<String>(
                              dropdownColor: cardBgColor,
                              value: selectedCategoryId != null &&
                                  selectedCategoryId!.isNotEmpty
                                  ? selectedCategoryId
                                  : null,
                              decoration: const InputDecoration(
                                  labelText: "Select Category"),
                              items: snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                      "${data['nameEn']} (${data['nameAr']})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedCategoryId = val;
                                  selectedSubcategoryId = null;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // التصنيف الفرعي
                        if (selectedCategoryId != null)
                          StreamBuilder<QuerySnapshot>(
                            stream: _subcategoriesRef
                                .where('categoryId',
                                isEqualTo: selectedCategoryId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const LinearProgressIndicator();
                              }
                              return DropdownButtonFormField<String>(
                                dropdownColor: cardBgColor,
                                value: selectedSubcategoryId != null &&
                                    selectedSubcategoryId!.isNotEmpty
                                    ? selectedSubcategoryId
                                    : null,
                                decoration: const InputDecoration(
                                    labelText: "Select Subcategory"),
                                items: snapshot.data!.docs.map((doc) {
                                  final data =
                                  doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(
                                        "${data['nameEn']} (${data['nameAr']})"),
                                  );
                                }).toList(),
                                onChanged: (val) => setDialogState(
                                        () => selectedSubcategoryId = val),
                              );
                            },
                          ),
                        const SizedBox(height: 12),

                        // اسم المنتج
                        TextFormField(
                          controller: titleController,
                          decoration:
                          const InputDecoration(labelText: "Product Title"),
                          validator: (val) => val == null || val.isEmpty
                              ? "Required field"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // السعر
                        TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                          const InputDecoration(labelText: "Price (\$)"),
                          validator: (val) => double.tryParse(val ?? '') == null
                              ? "Enter valid price"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ==================== الوصف والتعديل الغني ====================
                        Text(
                          "Description",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 15,
                          ),
                        ),
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
                                    color: isDark
                                        ? const Color(0xFF252525)
                                        : Colors.grey.shade50,
                                    border: Border(
                                      bottom: BorderSide(color: borderColor),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Undo',
                                          icon: Icon(Icons.undo,
                                              color: textColor, size: 20),
                                          onPressed: () {
                                            editorState.undoManager.undo();
                                            editorFocusNode.requestFocus();
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Redo',
                                          icon: Icon(Icons.redo,
                                              color: textColor, size: 20),
                                          onPressed: () {
                                            editorState.undoManager.redo();
                                            editorFocusNode.requestFocus();
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                            width: 1,
                                            height: 24,
                                            color: borderColor),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Bold',
                                          icon: Icon(Icons.format_bold,
                                              color: textColor, size: 20),
                                          onPressed: () {
                                            editorState.toggleAttribute(
                                              AppFlowyRichTextKeys.bold,
                                            );
                                            editorFocusNode.requestFocus();
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Italic',
                                          icon: Icon(Icons.format_italic,
                                              color: textColor, size: 20),
                                          onPressed: () {
                                            editorState.toggleAttribute(
                                              AppFlowyRichTextKeys.italic,
                                            );
                                            editorFocusNode.requestFocus();
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Underline',
                                          icon: Icon(Icons.format_underline,
                                              color: textColor, size: 20),
                                          onPressed: () {
                                            editorState.toggleAttribute(
                                              AppFlowyRichTextKeys.underline,
                                            );
                                            editorFocusNode.requestFocus();
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Strikethrough',
                                          icon: Icon(Icons.strikethrough_s,
                                              color: textColor, size: 20),
                                          onPressed: () {
                                            editorState.toggleAttribute(
                                              AppFlowyRichTextKeys
                                                  .strikethrough,
                                            );
                                            editorFocusNode.requestFocus();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FloatingToolbar(
                                    editorState: editorState,
                                    editorScrollController:
                                    editorScrollController,
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
                                      editorState: editorState,
                                      editorScrollController:
                                      editorScrollController,
                                      focusNode: editorFocusNode,
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

                        // ==================== تعديل صور المنتج ====================
                        Text(
                          "Product Images",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor),
                        ),
                        const SizedBox(height: 8),

                        if (existingImages.isNotEmpty) ...[
                          Text("Current Images:",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: existingImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          right: 8, top: 4),
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              existingImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setDialogState(() {
                                            existingImages.removeAt(index);
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close,
                                              size: 12, color: Colors.white),
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
                              final List<XFile> images =
                              await picker.pickMultiImage(imageQuality: 85);
                              if (images.isNotEmpty) {
                                List<Uint8List> bytesList = [];
                                for (var img in images) {
                                  bytesList.add(await img.readAsBytes());
                                }
                                setDialogState(() {
                                  newlyPickedImages.addAll(images);
                                  newImagesBytes.addAll(bytesList);
                                });
                              }
                            } catch (e) {
                              debugPrint("Error picking images: $e");
                            }
                          },
                          icon: const Icon(Icons.add_a_photo_outlined,
                              size: 18),
                          label: Text(
                              "Add More Images (${newlyPickedImages.length} selected)"),
                        ),

                        if (newImagesBytes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: newImagesBytes.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          right: 8, top: 4),
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: MemoryImage(
                                              newImagesBytes[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setDialogState(() {
                                            newlyPickedImages.removeAt(index);
                                            newImagesBytes.removeAt(index);
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close,
                                              size: 12, color: Colors.white),
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

                        // ==================== تعديل الحقول المخصصة ====================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Required Order Fields",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textColor),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  customFields.add(DynamicFieldModel(name: ''));
                                });
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Field"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (customFields.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "No custom fields required.",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  fontSize: 12),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: customFields.length,
                            itemBuilder: (context, fIndex) {
                              final field = customFields[fIndex];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: field.name,
                                            decoration: const InputDecoration(
                                              labelText: "Field Name / Title",
                                              isDense: true,
                                            ),
                                            onChanged: (val) =>
                                            field.name = val.trim(),
                                            validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? "Enter field name"
                                                : null,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 20),
                                          onPressed: () {
                                            setDialogState(() {
                                              customFields.removeAt(fIndex);
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<
                                              String>(
                                            dropdownColor:
                                            Theme.of(context).cardColor,
                                            value: field.type,
                                            decoration: const InputDecoration(
                                              labelText: "Field Type",
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'text',
                                                child: Text("Text / كلام"),
                                              ),
                                              DropdownMenuItem(
                                                value: 'number',
                                                child: Text("Number / أرقام"),
                                              ),
                                              DropdownMenuItem(
                                                value: 'drive_link',
                                                child: Text(
                                                    "Google Drive Link / لينك درايف"),
                                              ),
                                              DropdownMenuItem(
                                                value: 'dropdown',
                                                child: Text(
                                                    "Dropdown Options / قائمة خيارات"),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setDialogState(() {
                                                  field.type = val;
                                                  if (val == 'dropdown' &&
                                                      field.options.isEmpty) {
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
                                              onChanged: (val) {
                                                setDialogState(() {
                                                  field.isRequired =
                                                      val ?? true;
                                                });
                                              },
                                            ),
                                            const Text("Required",
                                                style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (field.type == 'dropdown') ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Dropdown Options:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                        const NeverScrollableScrollPhysics(),
                                        itemCount: field.options.length,
                                        itemBuilder: (context, optIndex) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: field
                                                        .options[optIndex],
                                                    decoration: InputDecoration(
                                                      labelText:
                                                      "Option ${optIndex + 1}",
                                                      isDense: true,
                                                    ),
                                                    onChanged: (val) => field
                                                        .options[optIndex] =
                                                        val.trim(),
                                                    validator: (v) {
                                                      if (field.type ==
                                                          'dropdown' &&
                                                          (v == null ||
                                                              v
                                                                  .trim()
                                                                  .isEmpty)) {
                                                        return "Enter option name";
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      color: Colors.red,
                                                      size: 18),
                                                  onPressed: field
                                                      .options.length >
                                                      1
                                                      ? () {
                                                    setDialogState(() {
                                                      field.options
                                                          .removeAt(
                                                          optIndex);
                                                    });
                                                  }
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          setDialogState(() {
                                            field.options.add('');
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 16),
                                        label: const Text("Add Option",
                                            style: TextStyle(fontSize: 12)),
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
                  onPressed: () {
                    editorFocusNode.dispose();
                    Navigator.pop(ctx);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      if (existingImages.isEmpty &&
                          newlyPickedImages.isEmpty) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Product must have at least one image!")),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final String updatedDescJson = jsonEncode({
                          "document": editorState.document.toJson(),
                        });

                        List<String> uploadedUrls = [];
                        for (var img in newlyPickedImages) {
                          final url =
                          await CloudinaryService.uploadImage(img);
                          if (url != null) uploadedUrls.add(url);
                        }

                        final List<String> finalImages = [
                          ...existingImages,
                          ...uploadedUrls,
                        ];

                        List<Map<String, dynamic>> fieldsList =
                        customFields.map((f) => f.toMap()).toList();

                        final updatedData = {
                          'title': titleController.text.trim(),
                          'description': updatedDescJson,
                          'price':
                          double.parse(priceController.text.trim()),
                          'categoryId': selectedCategoryId,
                          'subcategoryId': selectedSubcategoryId,
                          'images': finalImages,
                          'fields': fieldsList,
                          'isActive': isProductActive,
                        };

                        await _productsRef
                            .doc(_currentProduct.doc)
                            .update(updatedData);

                        if (!mounted) return;

                        setState(() {
                          _currentProduct = ProductModel(
                            doc: _currentProduct.doc,
                            title: titleController.text.trim(),
                            price:
                            double.parse(priceController.text.trim()),
                            avgRate: _currentProduct.avgRate,
                            categoryDoc: selectedCategoryId ?? '',
                            description: updatedDescJson,
                            images: finalImages,
                            SubCategoryDoc: selectedSubcategoryId ?? '',
                            discountPercentage:
                            _currentProduct.discountPercentage,
                            discountUntil: _currentProduct.discountUntil,
                            isActive: isProductActive,
                          );
                          _productFields = customFields;
                        });

                        editorFocusNode.dispose();
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext)
                              .showSnackBar(
                            SnackBar(
                                content:
                                Text("Failed to update product: $e")),
                          );
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text("Delete Product",
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color)),
        content: Text(
            "Are you sure you want to delete '${_currentProduct.title}'?",
            style:
            TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                for (var imgUrl in _currentProduct.images) {
                  await CloudinaryService.deleteImage(imgUrl);
                }
                await _productsRef.doc(_currentProduct.doc).delete();

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) Navigator.pop(parentContext);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text("Failed to delete product: $e")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==================== Product Description Viewer ====================

class _ProductDescriptionWidget extends StatefulWidget {
  final String description;

  const _ProductDescriptionWidget({
    required this.description,
  });

  @override
  State<_ProductDescriptionWidget> createState() =>
      __ProductDescriptionWidgetState();
}

class __ProductDescriptionWidgetState
    extends State<_ProductDescriptionWidget> {
  EditorState? _editorState;
  EditorScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _parseDescription();
  }

  @override
  void didUpdateWidget(
      covariant _ProductDescriptionWidget oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.description != widget.description) {
      _disposeEditor();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _parseDescription();

        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _disposeEditor() {
    _scrollController?.dispose();
    _scrollController = null;
    _editorState = null;
  }

  void _parseDescription() {
    final text = widget.description.trim();

    if (text.isEmpty) {
      _editorState = null;
      _scrollController = null;
      return;
    }

    try {
      dynamic parsed = jsonDecode(text);

      while (parsed is String) {
        final inner = parsed.trim();
        if (inner.isEmpty) break;
        parsed = jsonDecode(inner);
      }

      final normalized = _normalizeAppFlowyJson(parsed);

      if (normalized != null) {
        final document = Document.fromJson(normalized);
        final editorState = EditorState(document: document);
        final scrollController =
        EditorScrollController(editorState: editorState);

        _editorState = editorState;
        _scrollController = scrollController;
        return;
      }
    } catch (e, stackTrace) {
      debugPrint("Error parsing product description JSON: $e");
      debugPrint(stackTrace.toString());
    }

    _editorState = null;
    _scrollController = null;
  }

  Map<String, dynamic>? _normalizeAppFlowyJson(dynamic value) {
    if (value is! Map) return null;

    dynamic current = value;
    int safetyCounter = 0;

    while (current is Map && safetyCounter < 20) {
      safetyCounter++;
      final map = Map<String, dynamic>.from(current);

      if (map['type'] == 'page') {
        return {'document': map};
      }

      if (map.containsKey('document')) {
        final nested = map['document'];

        if (nested is Map) {
          current = nested;
          continue;
        }

        if (nested is String) {
          try {
            current = jsonDecode(nested);
            continue;
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }
    return null;
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _scrollController = null;
    _editorState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.grey.shade300 : AppColors.textDark;

    final description = widget.description.trim();

    if (description.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Text(
          "No description available for this product.",
          style: TextStyle(
            color: isDark ? Colors.grey.shade500 : AppColors.textMuted,
            height: 1.5,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_editorState != null && _scrollController != null) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 60,
          maxHeight: 350,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: AppFlowyEditor(
          editorState: _editorState!,
          editorScrollController: _scrollController!,
          editable: false,
          autoFocus: false,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: SelectableText(
        widget.description,
        style: TextStyle(
          color: textSecondary,
          height: 1.6,
          fontSize: 14,
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1} / ${widget.images.length}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}