import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _userNamesCache = {};

  /// جلب اسم العميل مع التخزين المؤقت لمنع الاستعلامات المتكررة
  Future<String> getCustomerName(String userId, Map<String, dynamic> orderData) async {
    if (userId.isEmpty) {
      return orderData['customerName'] ?? orderData['userEmail'] ?? 'Guest';
    }

    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('user').doc(userId).get();
      String userName = "Unknown User";

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData?['name'] != null && userData!['name'].toString().isNotEmpty) {
          userName = userData['name'];
        } else if (userData?['addresses'] is List && (userData!['addresses'] as List).isNotEmpty) {
          final firstAddr = (userData['addresses'] as List).first;
          if (firstAddr is Map) {
            userName = firstAddr['fullName'] ?? firstAddr['name'] ?? userName;
          }
        } else {
          userName = orderData['customerName'] ?? orderData['userEmail'] ?? userId;
        }
      } else {
        userName = orderData['customerName'] ?? orderData['userEmail'] ?? userId;
      }

      _userNamesCache[userId] = userName;
      return userName;
    } catch (_) {
      return orderData['customerName'] ?? orderData['userEmail'] ?? userId;
    }
  }

  String? getCachedName(String userId) => _userNamesCache[userId];
}