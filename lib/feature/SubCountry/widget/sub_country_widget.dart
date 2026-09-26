import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  String _searchQuery = '';

  // Collection Reference for Sub-Countries (Governorates)
  CollectionReference get _subCountriesRef => _firestore
      .collection('countries')
      .doc(widget._countryID)
      .collection('sub_countries');

  // Add or Edit Governorate Dialog
  void _showAddEditSubCountryDialog({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    final Map<String, dynamic>? data = isEditing ? doc.data() as Map<String, dynamic>? : null;

    final nameEnController = TextEditingController(text: data?['nameEn'] ?? data?['name'] ?? '');
    final nameArController = TextEditingController(text: data?['nameAr'] ?? '');
    final shippingFeeController = TextEditingController(
      text: data?['shippingFee'] != null ? data!['shippingFee'].toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            isEditing ? "Edit Governorate" : "Add New Governorate",
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameEnController,
                    decoration: const InputDecoration(
                      labelText: "Governorate Name (English - Default) *",
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "English name is required" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameArController,
                    decoration: const InputDecoration(
                      labelText: "Governorate Name (Arabic)",
                      prefixIcon: Icon(Icons.translate_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Arabic name is required" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: shippingFeeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Shipping Fee *",
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Shipping fee is required";
                      if (double.tryParse(v.trim()) == null) return "Enter a valid number";
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
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final payload = {
                  'nameEn': nameEnController.text.trim(),
                  'nameAr': nameArController.text.trim(),
                  'shippingFee': double.parse(shippingFeeController.text.trim()),
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
                    content: Text(isEditing ? "Governorate updated successfully" : "Governorate added successfully"),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
              },
              child: Text(isEditing ? "Save" : "Add", style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Delete Governorate Dialog
  void _deleteSubCountry(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Delete", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete \"$name\"? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _subCountriesRef.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Governorate deleted successfully")),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.countryName != null ? "${widget.countryName} - Governorates" : "Governorates Management",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage states/governorates and configure delivery rates.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 18,
                      vertical: isMobile ? 10 : 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddEditSubCountryDialog(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    "Add Governorate",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search governorate by English or Arabic name...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Sub-Countries List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _subCountriesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nameEn = (data['nameEn'] ?? data['name'] ?? '').toString().toLowerCase();
                    final nameAr = (data['nameAr'] ?? '').toString().toLowerCase();
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
                      final nameEn = data['nameEn'] ?? data['name'] ?? 'Unnamed';
                      final nameAr = data['nameAr'] ?? 'N/A';
                      final shippingFee = data['shippingFee'] ?? 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                child: Icon(
                                  Icons.location_city_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nameEn,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Arabic: $nameAr",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Shipping Fee Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_shipping_rounded, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$shippingFee EGP",
                                      style: const TextStyle(
                                        color: Colors.green,
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
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                onPressed: () => _showAddEditSubCountryDialog(doc: doc),
                                tooltip: "Edit",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteSubCountry(doc.id, nameEn),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No governorates found",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Click 'Add Governorate' above to add the first one.",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
