import 'package:flutter/material.dart';

import '../../../model/staff_model.dart';
import 'staff_card.dart';

class StaffList extends StatelessWidget {
  final Stream<List<StaffModel>> staffStream;
  final Function(StaffModel) onEdit;
  final Function(StaffModel) onDelete;

  const StaffList({
    Key? key,
    required this.staffStream,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffModel>>(
      key: const ValueKey('StaffList'),
      stream: staffStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }

        final staffDocs = snapshot.data ?? const [];

        if (staffDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_outlined, size: 70, color: Colors.grey.shade500),
                const SizedBox(height: 12),
                Text("There are currently no employees.", style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: staffDocs.length,
          itemBuilder: (context, index) {
            return StaffCard(
              staff: staffDocs[index],
              onEdit: onEdit,
              onDelete: onDelete,
            );
          },
        );
      },
    );
  }
}