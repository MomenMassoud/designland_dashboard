import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../Core/Utils/app.colors.dart';

// دالة normalizeAppFlowyJson لمعالجة وتحديد بناء مستند AppFlowy
Map<String, dynamic>? _normalizeAppFlowyJson(dynamic value) {
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

class UserProductDetailsWidget extends StatelessWidget {
  final String productId;

  const UserProductDetailsWidget({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanProductId = productId.trim();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final scaffoldBg = isDarkMode ? theme.scaffoldBackgroundColor : AppColors.bgLight;
    final appBarBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;
    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Product Details",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarBg,
        foregroundColor: textColor,
        elevation: 0.5,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(cleanProductId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(color: subtitleColor),
                ),
              ),
            );
          }

          final rawData = snapshot.data?.data();

          if (!snapshot.hasData || !snapshot.data!.exists || rawData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 64,
                      color: isDarkMode ? Colors.grey.shade600 : AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Product with ID '$cleanProductId' does not exist in Firestore.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final Map<String, dynamic> data = rawData;

          final String title = data['title'] ?? data['name'] ?? 'No Title';
          final String description = data['description'] ?? 'No description available.';
          final String price = (data['price'] ?? 0).toString();
          final String categoryId = data['categoryId'] ?? 'N/A';
          final String subcategoryId = data['subcategoryId'] ?? 'N/A';
          final String discount = (data['discountPercentage'] ?? 0).toString();

          final List dynamicImages = data['images'] as List? ?? [];
          final List<String> images = dynamicImages.map((e) => e.toString()).toList();
          final String mainImage = images.isNotEmpty ? images.first : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Main Image
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mainImage.isNotEmpty
                        ? Image.network(
                      mainImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: subtitleColor,
                      ),
                    )
                        : Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: subtitleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Details Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text("Discount: $discount%"),
                            backgroundColor: isDarkMode
                                ? Colors.deepOrange.withOpacity(0.2)
                                : Colors.orange.shade50,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "\$$price",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.greenAccent : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Divider(height: 24, color: borderColor),
                      Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ==================== الشفرة البرمجية الجديدة للوصف ====================
                      _ProductDescriptionWidget(
                        description: description,
                      ),
                      // ==========================================================

                      Divider(height: 24, color: borderColor),
                      _buildMetaRow("Product ID", cleanProductId, subtitleColor, textColor),
                      _buildMetaRow("Category ID", categoryId, subtitleColor, textColor),
                      _buildMetaRow("Subcategory ID", subcategoryId, subtitleColor, textColor),
                      _buildMetaRow("Average Rating", (data['avgRating'] ?? 0).toString(), subtitleColor, textColor),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor)),
        ],
      ),
    );
  }
}

// ==================== Product Description Viewer الجديد ====================

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