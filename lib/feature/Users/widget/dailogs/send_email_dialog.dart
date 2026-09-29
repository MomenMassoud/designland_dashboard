import 'package:flutter/material.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../../Core/server/email_notification_service.dart';
import '../../../../Core/widgets/error_dailog_custom.dart';

class SendEmailDialog extends StatefulWidget {
  final String customerEmail;
  final String userName;

  const SendEmailDialog({
    super.key,
    required this.customerEmail,
    required this.userName,
  });

  @override
  State<SendEmailDialog> createState() => _SendEmailDialogState();
}

class _SendEmailDialogState extends State<SendEmailDialog> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.email_outlined, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Send Email to ${widget.userName}",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                style: TextStyle(color: textColor, fontSize: 13.5),
                decoration: _inputDecoration("Subject", "Enter email subject...", isDarkMode),
                validator: (val) => val == null || val.trim().isEmpty ? "Please enter a subject" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                style: TextStyle(color: textColor, fontSize: 13.5),
                decoration: _inputDecoration("Message Body", "Write your message here...", isDarkMode),
                validator: (val) => val == null || val.trim().isEmpty ? "Please enter message content" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _isSending ? null : _sendEmail,
          icon: _isSending
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
          label: const Text("Send", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280), fontSize: 13),
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
    );
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await EmailNotificationService().sendCustomEmail(
        recipientEmail: widget.customerEmail,
        subject: _subjectController.text.trim(),
        messageBody: _bodyController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email sent successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) showErrorDialog(context, "Failed to Send Email", e.toString());
    }
  }
}