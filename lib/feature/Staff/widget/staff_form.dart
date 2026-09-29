import 'package:flutter/material.dart';

class StaffForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isEdit;
  final bool isObscure;
  final bool isLoading;
  final List<String> availablePermissions;
  final List<String> selectedPermissions;
  final VoidCallback onToggleObscure;
  final Function(String, bool) onPermissionChanged;
  final VoidCallback onSubmit;

  const StaffForm({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isEdit,
    required this.isObscure,
    required this.isLoading,
    required this.availablePermissions,
    required this.selectedPermissions,
    required this.onToggleObscure,
    required this.onPermissionChanged,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final titleTextColor = isDarkMode ? Colors.white : Colors.black87;
    final inputBorderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400;

    return SingleChildScrollView(
      key: const ValueKey('StaffForm'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Basic Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleTextColor)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: titleTextColor),
                    decoration: _inputDecoration('Employee Name', Icons.person_outline, isDarkMode, inputBorderColor),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter the name.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    enabled: !isEdit,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: titleTextColor),
                    decoration: _inputDecoration('e-mail', Icons.email_outlined, isDarkMode, inputBorderColor),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your email address.' : null,
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: isObscure,
                      style: TextStyle(color: titleTextColor),
                      decoration: _inputDecoration('password', Icons.lock_outline, isDarkMode, inputBorderColor).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: onToggleObscure,
                        ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Page access permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleTextColor)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availablePermissions.map((perm) {
                      final isSelected = selectedPermissions.contains(perm);
                      return ChoiceChip(
                        label: Text(perm, style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.grey.shade300 : Colors.black87))),
                        selected: isSelected,
                        selectedColor: theme.primaryColor,
                        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        onSelected: (val) => onPermissionChanged(perm, val),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'Updating Permissions' : 'Save and create account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDarkMode, Color border) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
    );
  }
}