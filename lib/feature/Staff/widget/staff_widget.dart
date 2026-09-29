import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/feature/Staff/widget/staff_form.dart';
import 'package:dashboard_desginland/feature/Staff/widget/staff_list.dart';
import 'package:flutter/material.dart';
import '../../../Core/server/get_permision.dart';
import '../../../Core/server/staff_service.dart';
import '../../../model/staff_model.dart';

class StaffWidget extends StatefulWidget {
  const StaffWidget({Key? key}) : super(key: key);

  @override
  State<StaffWidget> createState() => _StaffWidgetState();
}

class _StaffWidgetState extends State<StaffWidget> {
  final StaffService _staffService = StaffService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<String> _permissions = const [];
  List<String> _selectedPermissions = [];
  String? _editingDocId;
  bool _isFormOpen = false;
  bool _isObscure = true;
  bool _isLoading = false;

  final List<String> _availablePermissions = const [
    'categories', 'orders', 'reports', 'products', 'users', 'about', 'banner', 'promo', 'country'
  ];

  @override
  void initState() {
    super.initState();
    _checkUserPermissions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkUserPermissions() async {
    final perms = await GetPermisionUser();
    if (mounted) {
      setState(() => _permissions = perms);
    }
  }

  void _openForm([StaffModel? staff]) {
    setState(() {
      _editingDocId = staff?.id;
      _nameController.text = staff?.name ?? '';
      _emailController.text = staff?.email ?? '';
      _passwordController.clear();
      _selectedPermissions = List.from(staff?.permissions ?? const []);
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

  Future<void> _saveStaffData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_editingDocId != null) {
        await _staffService.updatePermissions(
          docId: _editingDocId!,
          name: _nameController.text.trim(),
          permissions: _selectedPermissions,
        );
      } else {
        await _staffService.createStaff(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          permissions: _selectedPermissions,
        );
      }

      _closeForm();
      if (mounted) {
        _showSnackBar(_editingDocId != null ? 'Data updated.' : 'Employee created.', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Delete "${staff.name}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _staffService.deleteStaff(staff.id);
        if (mounted) _showSnackBar('Employee deleted.', Colors.green);
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
      }
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.contains("staff")) return AccessDefindView();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_isFormOpen ? (_editingDocId != null ? "Modifying permissions" : 'Add employee') : 'Staff Management'),
        centerTitle: true,
        leading: _isFormOpen ? IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: _closeForm) : null,
      ),
      floatingActionButton: !_isFormOpen
          ? FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Add employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isFormOpen
            ? StaffForm(
          formKey: _formKey,
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          isEdit: _editingDocId != null,
          isObscure: _isObscure,
          isLoading: _isLoading,
          availablePermissions: _availablePermissions,
          selectedPermissions: _selectedPermissions,
          onToggleObscure: () => setState(() => _isObscure = !_isObscure),
          onPermissionChanged: (perm, selected) {
            setState(() {
              selected ? _selectedPermissions.add(perm) : _selectedPermissions.remove(perm);
            });
          },
          onSubmit: _saveStaffData,
        )
            : StaffList(
          staffStream: _staffService.getStaffStream(),
          onEdit: _openForm,
          onDelete: _deleteStaff,
        ),
      ),
    );
  }
}