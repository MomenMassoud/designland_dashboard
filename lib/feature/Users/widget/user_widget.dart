import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../Core/server/get_permision.dart';
import '../../Access%20Defind/view/access_defind_view.dart';
import '../widget/user_details_widget.dart';
import '../widget/user_desktop_table.dart';
import '../widget/user_mobile_list.dart';
import 'dailogs/user_search_bar.dart';

class UserWidget extends StatefulWidget {
  const UserWidget({super.key});

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  final CollectionReference _userRef = FirebaseFirestore.instance.collection('user');
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  List<String> _permission = [];
  bool _isLoadingPermission = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final perms = await GetPermisionUser();
    if (mounted) {
      setState(() {
        _permission = perms;
        _isLoadingPermission = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onUserSelected(String userId, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailView(
          userId: userId,
          userData: userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermission) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (!_permission.contains("users")) {
      return AccessDefindView();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 700;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile, theme, isDark),
                const SizedBox(height: 18),
                UserSearchBar(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _userRef.where('role', isEqualTo: 'user').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error fetching users!",
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) || email.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_rounded,
                                size: 56,
                                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No users found.",
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return isMobile
                          ? UserMobileList(
                        docs: filteredDocs,
                        onUserSelected: _onUserSelected,
                      )
                          : UserDesktopTable(
                        docs: filteredDocs,
                        onUserSelected: _onUserSelected,
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

  Widget _buildHeader(bool isMobile, ThemeData theme, bool isDark) {
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF111827));
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Users Management",
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Click on any user to view detailed address & session analytics",
          style: TextStyle(fontSize: 13.5, color: subtitleColor),
        ),
      ],
    );
  }
}