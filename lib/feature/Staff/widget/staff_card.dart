import 'package:flutter/material.dart';

import '../../../model/staff_model.dart';

class StaffCard extends StatelessWidget {
  final StaffModel staff;
  final Function(StaffModel) onEdit;
  final Function(StaffModel) onDelete;

  const StaffCard({
    Key? key,
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final titleTextColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black38 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: theme.primaryColor.withOpacity(0.15),
          child: Text(
            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          staff.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleTextColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(staff.email, style: TextStyle(color: subtitleTextColor, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: staff.permissions.map((p) => _PermissionChip(label: p, isDarkMode: isDarkMode)).toList(),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: cardBg,
          onSelected: (val) {
            if (val == 'edit') onEdit(staff);
            if (val == 'delete') onDelete(staff);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Modify permissions', style: TextStyle(color: titleTextColor)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Delete employee', style: TextStyle(color: titleTextColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool isDarkMode;

  const _PermissionChip({required this.label, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.blue.shade700.withOpacity(0.5) : Colors.blue.shade100,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade800,
        ),
      ),
    );
  }
}