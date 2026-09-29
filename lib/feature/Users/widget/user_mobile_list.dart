import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_actions_menu.dart';

class UserMobileList extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final Function(String id, Map<String, dynamic> data) onUserSelected;

  const UserMobileList({
    super.key,
    required this.docs,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E1E2E) : theme.cardColor;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF111827));
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final String name = data['name'] ?? 'N/A';
        final String email = data['email'] ?? 'N/A';
        final String imageUrl = data['image'] ?? data['profilePic'] ?? '';
        final bool isBlocked = data['isBlocked'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            onTap: () => onUserSelected(doc.id, data),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Blocked",
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Text(email, style: TextStyle(color: subtitleColor, fontSize: 12)),
            trailing: UserActionsMenu(
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