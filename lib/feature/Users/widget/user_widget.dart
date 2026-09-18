import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/email_notification_service.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';

class UserWidget extends StatefulWidget {
  const UserWidget({super.key});

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  final CollectionReference _userRef =
  FirebaseFirestore.instance.collection('user');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _permision = [];

  void Start() async {
    _permision = await GetPermisionUser();
    setState(() {
      _permision;
    });
  }

  @override
  void initState() {
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

  // ==================== 1. تبديل حالة الحظر ====================
  Future<void> _toggleBlockStatus(String userId, bool currentBlockState) async {
    try {
      await _userRef.doc(userId).update({
        'isBlocked': !currentBlockState,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentBlockState
                ? "User blocked successfully"
                : "User unblocked successfully",
          ),
          backgroundColor: !currentBlockState ? Colors.redAccent : Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, "Error", e.toString());
      }
    }
  }

  // ==================== 2. نافذة إرسال بريد إلكتروني مخصص ====================
  void _showSendEmailDialog(String customerEmail, String userName) {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Send Email to $userName",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          labelText: "Subject",
                          hintText: "Enter email subject...",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Please enter a subject"
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: bodyController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: "Message Body",
                          hintText: "Write your message here...",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Please enter message content"
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple),
                  onPressed: isSending
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSending = true);
                      try {
                        await EmailNotificationService().sendCustomEmail(
                          recipientEmail: customerEmail,
                          subject: subjectController.text.trim(),
                          messageBody: bodyController.text.trim(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Email sent successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSending = false);
                        if (mounted) {
                          showErrorDialog(context, "Failed to Send Email", e.toString());
                        }
                      }
                    }
                  },
                  icon: isSending
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.send, size: 18, color: Colors.white),
                  label: const Text("Send", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== 3. حذف الحساب نهائياً عبر الـ API الخاص بـ Backend ====================
  void _confirmDeleteUser(String userId, String name) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text("Delete Account"),
                ],
              ),
              content: Text(
                "Are you sure you want to permanently delete '$name'? This action will delete user from Firebase Auth and Firestore.",
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: isDeleting
                      ? null
                      : () async {
                    setDialogState(() => isDeleting = true);

                    try {
                      // ضعف هنا رابط الـ API المخصص للحذف
                      final url = Uri.parse('https://designland-backend.vercel.app/api/delete-account');

                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'uid': userId}),
                      );

                      final data = jsonDecode(response.body);

                      if (response.statusCode == 200 && data['success'] == true) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User deleted successfully from Auth and Firestore"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } else {
                        throw Exception(data['error'] ?? 'Failed to delete user');
                      }
                    } catch (e) {
                      setDialogState(() => isDeleting = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        showErrorDialog(context, "Error Deleting User", e.toString());
                      }
                    }
                  },
                  child: isDeleting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Delete Permanently", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== قائمة الخيارات المنسدلة للأدمن ====================
  Widget _buildUserActionsMenu({
    required String userId,
    required String userName,
    required String userEmail,
    required bool isBlocked,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'block_toggle') {
          _toggleBlockStatus(userId, isBlocked);
        } else if (value == 'send_email') {
          _showSendEmailDialog(userEmail, userName);
        } else if (value == 'delete_user') {
          _confirmDeleteUser(userId, userName);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'block_toggle',
          child: Row(
            children: [
              Icon(
                isBlocked ? Icons.lock_open : Icons.block,
                color: isBlocked ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                isBlocked ? 'Unblock User' : 'Block User',
                style: TextStyle(
                  color: isBlocked ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'send_email',
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: AppColors.primaryPurple, size: 20),
              SizedBox(width: 10),
              Text('Send Custom Email', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete_user',
          child: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Text('Delete Account',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("users")
        ? Scaffold(
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
                    stream: _userRef
                        .where('role', isEqualTo: 'user')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text("Error fetching users!"));
                      }
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryPurple),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                        (data['name'] ?? '').toString().toLowerCase();
                        final email =
                        (data['email'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) ||
                            email.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.person_off_outlined,
                                  size: 64, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text("No users found.",
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 16)),
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
    )
        :  AccessDefindView();
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
        onChanged: (val) =>
            setState(() => _searchQuery = val.trim().toLowerCase()),
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              DataColumn(
                  label: Text('User',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Email',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Joined Date',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'N/A';
              final String email = data['email'] ?? 'N/A';
              final String imageUrl = data['image'] ?? data['profilePic'] ?? '';
              final bool isBlocked = data['isBlocked'] ?? false;
              final String id = doc.id;

              String createdAtStr = 'N/A';
              if (data['createdAt'] is Timestamp) {
                DateTime dt = (data['createdAt'] as Timestamp).toDate();
                createdAtStr = "${dt.day}/${dt.month}/${dt.year}";
              }

              return DataRow(
                onSelectChanged: (_) => _onUserSelected(id, data),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                          AppColors.primaryPurple.withOpacity(0.1),
                          backgroundImage:
                          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
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
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  DataCell(Text(email)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isBlocked ? "Blocked" : "Active",
                        style: TextStyle(
                          color: isBlocked ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(createdAtStr)),
                  DataCell(
                    _buildUserActionsMenu(
                      userId: id,
                      userName: name,
                      userEmail: email,
                      isBlocked: isBlocked,
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
        final bool isBlocked = data['isBlocked'] ?? false;

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
              backgroundImage:
              imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
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
            title: Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (isBlocked)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("Blocked",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(email),
            trailing: _buildUserActionsMenu(
              userId: doc.id,
              userName: name,
              userEmail: email,
              isBlocked: isBlocked,
            ),
          ),
        );
      },
    );
  }
}