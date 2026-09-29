import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../Core/widgets/error_dailog_custom.dart';
import 'dailogs/delete_user_dialog.dart';
import 'dailogs/send_email_dialog.dart';

class UserActionsMenu extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final bool isBlocked;

  const UserActionsMenu({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.isBlocked,
  });

  Future<void> _toggleBlockStatus(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'isBlocked': !isBlocked,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!isBlocked ? "User blocked successfully" : "User unblocked successfully"),
          backgroundColor: !isBlocked ? const Color(0xFFEF4444) : Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) showErrorDialog(context, "Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF111827));

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
      color: isDark ? const Color(0xFF1E1E2E) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
      ),
      onSelected: (value) {
        if (value == 'block_toggle') {
          _toggleBlockStatus(context);
        } else if (value == 'send_email') {
          showDialog(
            context: context,
            builder: (_) => SendEmailDialog(customerEmail: userEmail, userName: userName),
          );
        } else if (value == 'delete_user') {
          showDialog(
            context: context,
            builder: (_) => DeleteUserDialog(userId: userId, userName: userName),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'block_toggle',
          child: Row(
            children: [
              Icon(
                isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                color: isBlocked ? Colors.green : Colors.amber.shade700,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                isBlocked ? 'Unblock User' : 'Block User',
                style: TextStyle(
                  color: isBlocked ? Colors.green : Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'send_email',
          child: Row(
            children: [
              const Icon(Icons.email_outlined, color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 10),
              Text('Send Custom Email', style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuDivider(color: isDark ? Colors.white12 : Colors.black12),
        const PopupMenuItem<String>(
          value: 'delete_user',
          child: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 10),
              Text('Delete Account', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}