import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/cloudinara_server.dart';

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.local_offer, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Text("Set Temporary Discount",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                    title: const Text("Discount Valid Until:"),
                    subtitle: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} - ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
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
                        int.tryParse(discountController.text.trim()) ??
                            0;
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
                          discountPercentage: percent,
                          discountUntil: selectedDate,
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Product Details",
          style: TextStyle(
            color: AppColors.textDark,
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
              color: Colors.white,
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
                                  color: Colors.black.withOpacity(0.05),
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
                        color: Colors.grey.shade100,
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

            // تفاصيل المنتج والخصومات
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _currentProduct.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
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
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    "${_currentProduct.price} EGP",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
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
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentProduct.description.isNotEmpty
                              ? _currentProduct.description
                              : "No description available for this product.",
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            height: 1.5,
                            fontSize: 14,
                          ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Required Order Fields",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingFields)
                          const Center(child: CircularProgressIndicator())
                        else if (_productFields.isEmpty)
                          const Text(
                            "No custom fields required for ordering this product.",
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _productFields.length,
                            separatorBuilder: (context, index) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final field = _productFields[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            field.type == 'drive_link'
                                                ? Icons.add_to_drive
                                                : field.type == 'number'
                                                ? Icons.pin
                                                : field.type == 'dropdown'
                                                ? Icons.arrow_drop_down_circle_outlined
                                                : Icons.short_text,
                                            size: 18,
                                            color: AppColors.primaryPurple,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            field.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: field.isRequired
                                              ? Colors.red.shade50
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          field.isRequired ? "Required" : "Optional",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: field.isRequired
                                                ? Colors.red.shade700
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (field.type == 'dropdown' && field.options.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: field.options.map((opt) {
                                        return Chip(
                                          label: Text(opt, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.purple.shade50,
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
                  const Text(
                    "Customer Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
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
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final reviews = snapshot.data?.docs ?? [];

                      if (reviews.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "No reviews for this product yet.",
                              style: TextStyle(color: AppColors.textMuted),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                                      .withOpacity(0.1),
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
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded,
                                                  color: Colors.amber,
                                                  size: 16),
                                              const SizedBox(width: 2),
                                              Text(
                                                "$rating",
                                                style: const TextStyle(
                                                    fontWeight:
                                                    FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (comment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          comment,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
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

  // ==================== نافذة تعديل المنتج بالكامل ====================
  void _showEditProductDialog(BuildContext parentContext) async {
    final formKey = GlobalKey<FormState>();
    final titleController =
    TextEditingController(text: _currentProduct.title);
    final descController =
    TextEditingController(text: _currentProduct.description);
    final priceController =
    TextEditingController(text: _currentProduct.price.toString());

    String? selectedCategoryId = _currentProduct.categoryDoc;
    String? selectedSubcategoryId = _currentProduct.SubCategoryDoc;

    List<String> existingImages = List<String>.from(_currentProduct.images);
    List<XFile> newlyPickedImages = [];
    List<Uint8List> newImagesBytes = [];

    // إعداد نسخة عميقة لـ customFields لمنع اختلال البيانات أثناء التعديل
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
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Product Details",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // التصنيف الرئيسي
                        StreamBuilder<QuerySnapshot>(
                          stream: _categoriesRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return DropdownButtonFormField<String>(
                              value: selectedCategoryId != null &&
                                  selectedCategoryId!.isNotEmpty
                                  ? selectedCategoryId
                                  : null,
                              decoration: const InputDecoration(
                                  labelText: "Select Category"),
                              items: snapshot.data!.docs.map((doc) {
                                final data =
                                doc.data() as Map<String, dynamic>;
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
                          validator: (val) =>
                          double.tryParse(val ?? '') == null
                              ? "Enter valid price"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // الوصف
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          decoration:
                          const InputDecoration(labelText: "Description"),
                        ),
                        const SizedBox(height: 20),

                        // ==================== تعديل صور المنتج ====================
                        const Text(
                          "Product Images",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),

                        // الصور الحالية المرفوعة
                        if (existingImages.isNotEmpty) ...[
                          const Text("Current Images:",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
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
                                        borderRadius:
                                        BorderRadius.circular(8),
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

                        // زر إضافة صور جديدة
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
                          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: Text("Add More Images (${newlyPickedImages.length} selected)"),
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
                                        borderRadius:
                                        BorderRadius.circular(8),
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
                            const Text(
                              "Required Order Fields",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  customFields
                                      .add(DynamicFieldModel(name: ''));
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
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "No custom fields required.",
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
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
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                  Border.all(color: Colors.grey.shade300),
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
                                          icon: const Icon(
                                              Icons.delete_outline,
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
                                                child: Text("Google Drive Link / لينك درايف"),
                                              ),
                                              DropdownMenuItem(
                                                value: 'dropdown',
                                                child: Text("Dropdown Options / قائمة خيارات"),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setDialogState(() {
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
                                              onChanged: (val) {
                                                setDialogState(() {
                                                  field.isRequired =
                                                      val ?? true;
                                                });
                                              },
                                            ),
                                            const Text("Required",
                                                style: TextStyle(
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // إعدادات الخيارات الخاصة بالـ Dropdown
                                    if (field.type == 'dropdown') ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Dropdown Options:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
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
                                                      ? () {
                                                    setDialogState(() {
                                                      field.options.removeAt(optIndex);
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
                  onPressed: () => Navigator.pop(ctx),
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
                        // رفع الصور الجديدة إلى Cloudinary
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

                        // تجهيز قائمة الحقول
                        List<Map<String, dynamic>> fieldsList =
                        customFields
                            .map((f) => f.toMap())
                            .toList();

                        final updatedData = {
                          'title': titleController.text.trim(),
                          'description': descController.text.trim(),
                          'price': double.parse(
                              priceController.text.trim()),
                          'categoryId': selectedCategoryId,
                          'subcategoryId': selectedSubcategoryId,
                          'images': finalImages,
                          'fields': fieldsList,
                        };

                        await _productsRef
                            .doc(_currentProduct.doc)
                            .update(updatedData);

                        if (!mounted) return;

                        // تحديث بيانات المنتج والحقول المخصصة فوراً في الـ UI
                        setState(() {
                          _currentProduct = ProductModel(
                            doc: _currentProduct.doc,
                            title: titleController.text.trim(),
                            price: double.parse(
                                priceController.text.trim()),
                            avgRate: _currentProduct.avgRate,
                            categoryDoc: selectedCategoryId ?? '',
                            description: descController.text.trim(),
                            images: finalImages,
                            SubCategoryDoc: selectedSubcategoryId ?? '',
                            discountPercentage:
                            _currentProduct.discountPercentage,
                            discountUntil: _currentProduct.discountUntil,
                          );
                          _productFields = customFields;
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext)
                              .showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Failed to update product: $e")),
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
        title: const Text("Delete Product"),
        content: Text(
            "Are you sure you want to delete '${_currentProduct.title}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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