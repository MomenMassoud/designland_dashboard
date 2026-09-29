import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecentSessionsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final Color cardBgColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const RecentSessionsList({
    Key? key,
    required this.docs,
    required this.cardBgColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length > 5 ? 5 : docs.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: textSecondaryColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          bool isGuest = data['isGuest'] ?? true;
          String userId = data['userId'] ?? 'guest';
          String platform = data['platform'] ?? 'Web';
          List viewedProducts = data['viewedProducts'] ?? [];

          Timestamp? start = data['startTime'] as Timestamp?;
          String timeStr = start != null
              ? '${start.toDate().hour.toString().padLeft(2, '0')}:${start.toDate().minute.toString().padLeft(2, '0')}'
              : 'غير محدد';

          if (isGuest || userId == 'guest') {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
              title: Text(
                'Guest Visitor (Guest)'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
              ),
              subtitle: Text(
                  '${"Platform:".tr}$platform | ${"Views:".tr} ${viewedProducts.length}',
                  style: TextStyle(color: textSecondaryColor)),
              trailing: Text(
                '${"It began".tr}$timeStr',
                style: TextStyle(color: textSecondaryColor, fontSize: 12),
              ),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('user').doc(userId).get(),
            builder: (context, userSnapshot) {
              String displayName = '${"Registered user (".tr}$userId)';
              String userEmail = '';

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  displayName = userData['name'] ?? userData['username'] ?? displayName;
                  userEmail = userData['email'] ?? '';
                }
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.verified_user_outlined, color: Colors.white),
                ),
                title: Text(
                  displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
                ),
                subtitle: Text(
                  '${userEmail.isNotEmpty ? "$userEmail | " : ""}${"Platform:".tr} $platform | ${"Views".tr} ${viewedProducts.length}',
                  style: TextStyle(color: textSecondaryColor),
                ),
                trailing: Text(
                  '${"It began".tr} $timeStr',
                  style: TextStyle(color: textSecondaryColor, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}