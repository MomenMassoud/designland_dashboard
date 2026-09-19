import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../Core/server/get_permision.dart';

class StaffWidget extends StatefulWidget {
  const StaffWidget({Key? key}) : super(key: key);

  @override
  State<StaffWidget> createState() => _StaffWidgetState();
}

class _StaffWidgetState extends State<StaffWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // شاشة الانتهاء أو نموذج الإضافة/التعديل
  bool _isFormOpen = false;

  @override
  void initState() {
    super.initState();
    Start();
  }

  List<String> _permision = [];

  void Start() async {
    _permision = await GetPermisionUser();
    setState(() {
      _permision;
    });
  }

  // بيانات النموذج الحالية
  String? _editingDocId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  List<String> _selectedPermissions = [];

  final List<String> _availablePermissions = [
    'categories',
    'orders',
    'reports',
    'products',
    'users',
    'about',
    'banner',
    'promo',
  ];

  void _openForm({
    String? docId,
    String? currentName,
    String? currentEmail,
    List<String>? currentPermissions,
  }) {
    setState(() {
      _editingDocId = docId;
      _nameController.text = currentName ?? '';
      _emailController.text = currentEmail ?? '';
      _passwordController.clear();
      _selectedPermissions = List.from(currentPermissions ?? []);
      _isFormOpen = true;
    });
  }

  void _closeForm() {
    setState(() {
      _isFormOpen = false;
      _editingDocId = null;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedPermissions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("staff")
        ? Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _isFormOpen
              ? (_editingDocId != null ? "Modifying an employee's powers" : 'Add a new employee')
              : 'Staff Management',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: _isFormOpen
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _closeForm,
        )
            : null,
      ),
      floatingActionButton: !_isFormOpen
          ? FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          'Add a new employee',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: _isFormOpen ? _buildStaffForm() : _buildStaffList(),
      ),
    )
        :  AccessDefindView();
  }

  // --- 1. قائمة الموظفين ---
  Widget _buildStaffList() {
    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('StaffList'),
      stream: _firestore
          .collection('user')
          .where('role', isEqualTo: 'staff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('An error occurred:${snapshot.error}'));
        }

        final staffDocs = snapshot.data?.docs ?? [];

        if (staffDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_outlined, size: 70, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  "There are currently no employees.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: staffDocs.length,
          itemBuilder: (context, index) {
            final doc = staffDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            final String name = data['name'] ?? 'Anonymous';
            final String email = data['email'] ?? '';
            final List<dynamic> permissions = data['permissions'] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: permissions.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            p.toString(),
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openForm(
                        docId: doc.id,
                        currentName: name,
                        currentEmail: email,
                        currentPermissions: List<String>.from(permissions),
                      );
                    } else if (value == 'delete') {
                      _deleteStaff(doc.id, name);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Modify permissions'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete employee'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. واجهة صفحة الإضافة والتعديل ---
  Widget _buildStaffForm() {
    final isEdit = _editingDocId != null;

    return SingleChildScrollView(
      key: const ValueKey('StaffForm'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Employee Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter the name.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    enabled: !isEdit,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'e-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your email address.' : null,
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isObscure = !_isObscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter the password.';
                        if (v.length < 6) return 'It must be at least 6 characters long.';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // قسم الصلاحيات
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Page access permissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availablePermissions.map((perm) {
                      final isSelected = _selectedPermissions.contains(perm);
                      return ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            perm,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPermissions.add(perm);
                            } else {
                              _selectedPermissions.remove(perm);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // أزرار الحفظ والإلغاء
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _saveStaffData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isEdit ? 'Updating Permissions' : 'Save and create account',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _saveStaffData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_editingDocId != null) {
        // تعديل بيانات وصلاحيات موظف حالي
        await _firestore.collection('user').doc(_editingDocId).update({
          'name': _nameController.text.trim(),
          'permissions': _selectedPermissions,
        });
      } else {
        // إنشاء موظف جديد عن طريق الـ Backend API
        final url = Uri.parse('https://designland-backend.vercel.app/api/create_staff');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'name': _nameController.text.trim(),
            'permissions': _selectedPermissions,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode != 200 || data['success'] != true) {
          throw Exception(data['error'] ?? 'Failed to create the employee account.');
        }
      }

      _closeForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingDocId != null ? 'The data has been successfully updated.' : 'The employee account has been successfully created.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred:$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --- 4. حذف الموظف عبر Backend API ---
  Future<void> _deleteStaff(String docId, String name) async {
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
                  Text('Confirm Deletion'),
                ],
              ),
              content: Text(
                'Are you sure you want to delete the employee?"$name" Permanently? It will be deleted from Firebase Auth و Firestore.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                    setDialogState(() => isDeleting = true);

                    try {
                      final url = Uri.parse('https://designland-backend.vercel.app/api/delete-account');

                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'uid': docId}),
                      );

                      final data = jsonDecode(response.body);

                      if (response.statusCode == 200 && data['success'] == true) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('The employee was successfully removed from the system and Auth was notified.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        throw Exception(data['error'] ?? 'Failed to delete the employee.');
                      }
                    } catch (e) {
                      setDialogState(() => isDeleting = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('An error occurred during deletion:$e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: isDeleting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Permanent deletion', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}