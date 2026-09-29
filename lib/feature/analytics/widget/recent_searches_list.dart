import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecentSearchesList extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final Color cardBgColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const RecentSearchesList({
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length > 5 ? 5 : docs.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: textSecondaryColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          bool isGuest = data['gust'] ?? data['isGuest'] ?? false;
          String query = data['query'] ?? 'Empty search'.tr;
          String userId = data['userID'] ?? data['userId'] ?? 'guest';

          Timestamp? createdAt = data['createdAt'] as Timestamp?;
          String timeStr = createdAt != null
              ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
              : 'undefined'.tr;

          if (isGuest || userId == 'guest') {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
              title: Text(
                '"$query"',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
              ),
              subtitle: Text('Source: Guest'.tr, style: TextStyle(color: textSecondaryColor)),
              trailing: Text(
                timeStr,
                style: TextStyle(color: textSecondaryColor, fontSize: 12),
              ),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('user').doc(userId).get(),
            builder: (context, userSnapshot) {
              String userName = '${"User (".tr}$userId)';
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  userName = userData['name'] ?? userData['username'] ?? userName;
                }
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  '"$query"',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
                ),
                subtitle: Text('${"user:".tr}$userName', style: TextStyle(color: textSecondaryColor)),
                trailing: Text(
                  timeStr,
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