import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Reports/widget/summry_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../Core/Utils/app.colors.dart';
import '../function/report_function.dart';
import 'build_action_button.dart';
import 'build_empty_state.dart';
import 'build_mobile_info_row.dart';
import 'build_section_header.dart';



Widget buildUsersReportSection(BuildContext context,_searchQuery) {
  final mobile = isMobile(context);

  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(mobile ? 14 : 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: BoxBorder.all(
        color: Colors.grey.shade200,
      ),
    ),
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(50),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final users = <Map<String, dynamic>>[];

        for (final doc in docs) {
          final data = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );

          final name = data['name'] ?? 'N/A';
          final email = data['email'] ?? 'N/A';
          final phone = data['phone'] ?? 'N/A';

          if (!matchesSearch([
            doc.id,
            name.toString(),
            email.toString(),
            phone.toString(),
          ],_searchQuery)) {
            continue;
          }

          users.add({
            'id': doc.id,
            'name': name,
            'email': email,
            'phone': phone,
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(
              context: context,
              title: "Users Report",
              subtitle:
              "View registered users and their contact information.",
              icon: Icons.people_alt_outlined,
              iconColor: AppColors.primaryPurple,
              actions: [
                buildActionButton(
                  label: "Export Excel",
                  icon: Icons.table_chart_rounded,
                  color: Colors.green,
                  onPressed: () {
                    if (!kIsWeb) {
                      return;
                    }
                    exportUsersExcel();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            summaryCard(
              title: "Registered Users",
              value: users.length.toString(),
              icon: Icons.people_outline_rounded,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            if (users.isEmpty)
              buildEmptyState(
                icon: Icons.people_outline_rounded,
                title: "No Users Found",
                subtitle: "No users match the current search.",
              )
            else if (mobile)
              _buildUsersMobileList(users)
            else
              _buildUsersDesktopTable(users),
          ],
        );
      },
    ),
  );
}

Widget _buildUsersDesktopTable(List<Map<String, dynamic>> users) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: BoxBorder.all(
        color: Colors.grey.shade200,
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.bgLight),
        columnSpacing: 45,
        columns: const [
          DataColumn(label: Text("Name")),
          DataColumn(label: Text("Email")),
          DataColumn(label: Text("Phone")),
        ],
        rows: users.map((user) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  user['name'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DataCell(Text(user['email'].toString())),
              DataCell(Text(user['phone'].toString())),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

Widget _buildUsersMobileList(List<Map<String, dynamic>> users) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: users.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final user = users[index];

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: BoxBorder.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    user['name'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            mobileInfoRow(
              Icons.email_outlined,
              "Email",
              user['email'].toString(),
            ),
            mobileInfoRow(
              Icons.phone_outlined,
              "Phone",
              user['phone'].toString(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ID: ${shortId(user['id'])}",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

