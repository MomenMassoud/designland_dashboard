import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../Core/widgets/error_dailog_custom.dart';

class DeleteUserDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const DeleteUserDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Text("Delete Account", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Text(
        "Are you sure you want to permanently delete '${widget.userName}'? This action will remove the user from Auth and Firestore.",
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13.5),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isDeleting ? null : _deleteUser,
          child: _isDeleting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Text("Delete Permanently", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _deleteUser() async {
    setState(() => _isDeleting = true);
    try {
      final url = Uri.parse('https://designland-backend.vercel.app/api/delete-account');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': widget.userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User deleted successfully from Auth and Firestore"),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      } else {
        throw Exception(data['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        Navigator.pop(context);
        showErrorDialog(context, "Error Deleting User", e.toString());
      }
    }
  }
}