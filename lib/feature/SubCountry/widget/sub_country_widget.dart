import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

class SubCountryWidget extends StatefulWidget {
  final String _countryID;
  final String? countryName;

  const SubCountryWidget({
    super.key,
    required String countryID,
    this.countryName,
  }) : _countryID = countryID;

  @override
  State<SubCountryWidget> createState() => _SubCountryWidgetState();
}

class _SubCountryWidgetState extends State<SubCountryWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Collection Reference for Sub-Countries (Governorates)
  CollectionReference get _subCountriesRef => _firestore
      .collection('countries')
      .doc(widget._countryID)
      .collection('sub_countries');

  // Add or Edit Governorate Dialog
  void _showAddEditSubCountryDialog({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    final Map<String, dynamic>? data =
    isEditing ? doc.data() as Map<String, dynamic>? : null;

    final nameEnController =
    TextEditingController(text: data?['nameEn'] ?? data?['name'] ?? '');
    final nameArController =
    TextEditingController(text: data?['nameAr'] ?? '');
    final shippingFeeController = TextEditingController(
      text: data?['shippingFee'] != null ? data!['shippingFee'].toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final labelStyle = TextStyle(color: isDarkMode ? Colors.grey.shade400 : null);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: cardBg,
          title: Text(
            isEditing ? "Edit Governorate" : "Add New Governorate",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameEnController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Governorate Name (English - Default) *",
                      labelStyle: labelStyle,
                      prefixIcon: const Icon(Icons.location_city_rounded,
                          color: AppColors.primaryPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "English name is required"
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameArController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Governorate Name (Arabic) *",
                      labelStyle: labelStyle,
                      prefixIcon: const Icon(Icons.translate_rounded,
                          color: AppColors.primaryPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Arabic name is required"
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: shippingFeeController,
                    style: TextStyle(color: textColor),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Shipping Fee *",
                      labelStyle: labelStyle,
                      prefixIcon: const Icon(Icons.local_shipping_outlined,
                          color: AppColors.primaryPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Shipping fee is required";
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return "Enter a valid number";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final payload = {
                  'nameEn': nameEnController.text.trim(),
                  'nameAr': nameArController.text.trim(),
                  'shippingFee':
                  double.parse(shippingFeeController.text.trim()),
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (isEditing) {
                  await _subCountriesRef.doc(doc.id).update(payload);
                } else {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await _subCountriesRef.add(payload);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? "Governorate updated successfully"
                        : "Governorate added successfully"),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
              },
              child: Text(isEditing ? "Save" : "Add",
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Delete Governorate Dialog
  void _deleteSubCountry(String docId, String name) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Confirm Delete",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        content: Text(
          "Are you sure you want to delete \"$name\"? This action cannot be undone.",
          style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              await _subCountriesRef.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Governorate deleted successfully")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final scaffoldBg = isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC);
    final appBarBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : AppColors.textMuted;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.countryName != null
              ? "${widget.countryName} - Governorates"
              : "Governorates Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Governorates & Shipping",
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage states/governorates and configure delivery rates.",
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 18,
                      vertical: isMobile ? 10 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddEditSubCountryDialog(),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  label: const Text(
                    "Add Governorate",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: "Search governorate by English or Arabic name...",
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey.shade400 : AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primaryPurple),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.cancel_rounded,
                        color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sub-Countries List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _subCountriesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nameEn = (data['nameEn'] ?? data['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final nameAr =
                    (data['nameAr'] ?? '').toString().toLowerCase();
                    final q = _searchQuery.toLowerCase();
                    return nameEn.contains(q) || nameAr.contains(q);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final nameEn =
                          data['nameEn'] ?? data['name'] ?? 'Unnamed';
                      final nameAr = data['nameAr'] ?? 'N/A';
                      final shippingFee = data['shippingFee'] ?? 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode ? theme.cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                AppColors.primaryPurple.withOpacity(0.12),
                                child: const Icon(
                                  Icons.location_city_rounded,
                                  size: 20,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nameEn,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Arabic: $nameAr",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtitleColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Shipping Fee Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_shipping_rounded,
                                        size: 14,
                                        color: isDarkMode
                                            ? Colors.greenAccent
                                            : Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$shippingFee EGP",
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.greenAccent
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Actions
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primaryPurple, size: 20),
                                onPressed: () =>
                                    _showAddEditSubCountryDialog(doc: doc),
                                tooltip: "Edit",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () =>
                                    _deleteSubCountry(doc.id, nameEn),
                                tooltip: "Delete",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 40,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No governorates found",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Click 'Add Governorate' above to add the first one.",
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}