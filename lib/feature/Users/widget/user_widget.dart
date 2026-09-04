import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_details_widget.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';

class UserWidget extends StatefulWidget {
  const UserWidget({super.key});

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  // القراءة من كوليكشن 'user' بالسنجلر
  final CollectionReference _userRef =
  FirebaseFirestore.instance.collection('user');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _permision=[];
  void Start()async{
    _permision=await GetPermisionUser();
    setState(() {
      _permision;
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Start();
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
    return _permision.contains("users")? Scaffold(
      backgroundColor: AppColors.bgLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _userRef.where('role', isEqualTo: 'user').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text("Error fetching users!"));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryPurple),
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
                            children: const [
                              Icon(Icons.person_off_outlined, size: 64, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text("No users found.", style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return isMobile
                          ? _buildMobileUserList(filteredDocs)
                          : _buildDesktopUserTable(filteredDocs);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ):AccessDefindView();
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Users Management",
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Click on any user to view detailed address & session analytics",
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search users by name or email...",
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDesktopUserTable(List<QueryDocumentSnapshot> docs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columns: const [
              DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'N/A';
              final String email = data['email'] ?? 'N/A';
              final String imageUrl = data['image'] ?? data['profilePic'] ?? '';

              String createdAtStr = 'N/A';
              if (data['createdAt'] is Timestamp) {
                DateTime dt = (data['createdAt'] as Timestamp).toDate();
                createdAtStr = "${dt.day}/${dt.month}/${dt.year}";
              }

              return DataRow(
                onSelectChanged: (_) => _onUserSelected(doc.id, data),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl.isEmpty
                              ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  DataCell(Text(email)),
                  DataCell(Text(createdAtStr)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteUser(doc.id, name),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUserList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final String name = data['name'] ?? 'N/A';
        final String email = data['email'] ?? 'N/A';
        final String imageUrl = data['image'] ?? data['profilePic'] ?? '';

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            onTap: () => _onUserSelected(doc.id, data),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(email),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeleteUser(doc.id, name),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete User"),
        content: Text("Are you sure you want to delete user '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _userRef.doc(userId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}