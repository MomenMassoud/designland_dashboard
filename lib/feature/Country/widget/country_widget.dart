import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';
import '../../SubCountry/view/sub_country_view.dart';

class CountryWidget extends StatefulWidget {
  const CountryWidget({super.key});

  @override
  State<CountryWidget> createState() => _CountryWidgetState();
}

class _CountryWidgetState extends State<CountryWidget> {
  List<String> _permission = [];
  bool _isLoadingPermissions = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    try {
      final permissions = await GetPermisionUser();
      if (mounted) {
        setState(() {
          _permission = permissions ?? [];
          _isLoadingPermissions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permission = [];
          _isLoadingPermissions = false;
        });
      }
    }
  }

  // Add or Edit Country Dialog
  void _showAddEditCountryDialog({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    final Map<String, dynamic>? data =
    isEditing ? doc.data() as Map<String, dynamic>? : null;

    final nameEnController =
    TextEditingController(text: data?['nameEn'] ?? data?['name'] ?? '');
    final nameArController =
    TextEditingController(text: data?['nameAr'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            isEditing ? "Edit Country" : "Add New Country",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameEnController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: "Country Name (English - Default) *",
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      prefixIcon: const Icon(Icons.language_rounded,
                          color: AppColors.primaryPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "English name is required" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameArController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: "Country Name (Arabic)",
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      prefixIcon: const Icon(Icons.translate_rounded,
                          color: AppColors.primaryPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Arabic name is required" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final payload = {
                  'nameEn': nameEnController.text.trim(),
                  'nameAr': nameArController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (isEditing) {
                  await _firestore.collection('countries').doc(doc.id).update(payload);
                } else {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await _firestore.collection('countries').add(payload);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? "Country updated successfully"
                        : "Country added successfully"),
                    backgroundColor: AppColors.primaryPurple,
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

  // Delete Country Dialog
  void _deleteCountry(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Confirm Delete",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            "Are you sure you want to delete \"$name\"? This action cannot be undone.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await _firestore.collection('countries').doc(docId).delete();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Country deleted successfully")),
                );
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Navigate to SubCountries / Governorates page
  void _navigateToSubCountries(String countryId, String countryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubCountryView(
          CountryID: countryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingPermissions) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );
    }

    if (_permission.isEmpty || !_permission.contains("country")) {
      return AccessDefindView();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
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
                      "Countries Management",
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage your system countries and governorates.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 18,
                      vertical: isMobile ? 10 : 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddEditCountryDialog(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    "Add Country",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: "Search country by English or Arabic name...",
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primaryPurple),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Main Countries List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('countries').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryPurple),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nameEn =
                    (data['nameEn'] ?? data['name'] ?? '').toString().toLowerCase();
                    final nameAr = (data['nameAr'] ?? '').toString().toLowerCase();
                    final q = _searchQuery.toLowerCase();
                    return nameEn.contains(q) || nameAr.contains(q);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final nameEn = data['nameEn'] ?? data['name'] ?? 'Unnamed';
                      final nameAr = data['nameAr'] ?? 'N/A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryPurple.withOpacity(0.15),
                                child: Text(
                                  nameEn.isNotEmpty ? nameEn[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primaryPurple,
                                  ),
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
                                        fontSize: 14,
                                        color: isDark ? Colors.white : AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Arabic: $nameAr",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade400 : AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Actions Section
                              if (isMobile) ...[
                                IconButton(
                                  icon: const Icon(Icons.map_outlined,
                                      color: AppColors.primaryPurple, size: 20),
                                  onPressed: () => _navigateToSubCountries(doc.id, nameEn),
                                  tooltip: "Governorates",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent, size: 20),
                                  onPressed: () => _showAddEditCountryDialog(doc: doc),
                                  tooltip: "Edit",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteCountry(doc.id, nameEn),
                                  tooltip: "Delete",
                                ),
                              ] else ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.primaryPurple.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _navigateToSubCountries(doc.id, nameEn),
                                  icon: const Icon(Icons.map_outlined,
                                      size: 16, color: AppColors.primaryPurple),
                                  label: const Text(
                                    "Governorates",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent, size: 20),
                                  onPressed: () => _showAddEditCountryDialog(doc: doc),
                                  tooltip: "Edit",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteCountry(doc.id, nameEn),
                                  tooltip: "Delete",
                                ),
                              ],
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
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.public_off_rounded,
              size: 40,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "No countries found",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Click 'Add Country' above to create your first country.",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}