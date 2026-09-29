import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_actions_menu.dart';

class UserDesktopTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final Function(String id, Map<String, dynamic> data) onUserSelected;

  const UserDesktopTable({
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(
              isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFB),
            ),
            dataRowMaxHeight: 60,
            columns: [
              DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
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
                onSelectChanged: (_) => onUserSelected(id, data),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
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
                        const SizedBox(width: 12),
                        Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  DataCell(Text(email, style: TextStyle(color: subtitleColor, fontSize: 13))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? const Color(0xFFEF4444).withOpacity(0.15)
                            : const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isBlocked ? "Blocked" : "Active",
                        style: TextStyle(
                          color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(createdAtStr, style: TextStyle(color: subtitleColor, fontSize: 13))),
                  DataCell(
                    UserActionsMenu(
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
}