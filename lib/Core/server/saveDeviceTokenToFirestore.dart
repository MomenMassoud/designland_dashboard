import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

const String webVapidKey =
    'BKEi5yHMVzHRrfr0gqS4emFwSLU7aSorBBpdtdGqDPH841gSsd9GgJ2jTWnW9NawmB7y3R5guNyri0BA_9Yy2Fc';

Future<void> saveDeviceTokenToFirestore() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    print(webVapidKey);
    if (user == null) {
      debugPrint('FCM: No logged-in user.');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    // Request notification permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'FCM permission: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus !=
        AuthorizationStatus.authorized) {
      debugPrint('FCM: Notification permission not authorized.');
      return;
    }

    String? token;

    if (kIsWeb) {
      debugPrint('FCM: Getting Web token...');

      token = await messaging.getToken(
        vapidKey: webVapidKey,
      );
    } else {
      debugPrint('FCM: Getting Mobile token...');

      token = await messaging.getToken();
    }

    if (token == null || token.isEmpty) {
      debugPrint('FCM: Token is null/empty.');
      return;
    }

    debugPrint('FCM Token received.');

    await FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .set(
      {
        'devices': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );

    debugPrint('FCM: Device token saved successfully.');

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(
          (newToken) async {
        try {
          final currentUser =
              FirebaseAuth.instance.currentUser;

          if (currentUser == null) {
            debugPrint(
              'FCM refresh: No logged-in user.',
            );
            return;
          }

          await FirebaseFirestore.instance
              .collection('user')
              .doc(currentUser.uid)
              .set(
            {
              'devices': FieldValue.arrayUnion([newToken]),
            },
            SetOptions(merge: true),
          );

          debugPrint(
            'FCM: Refreshed token saved successfully.',
          );
        } catch (e, stackTrace) {
          debugPrint(
            'FCM refresh error: $e',
          );
          debugPrint(
            stackTrace.toString(),
          );
        }
      },
      onError: (error) {
        debugPrint(
          'FCM token refresh error: $error',
        );
      },
    );
  } catch (e, stackTrace) {
    debugPrint('FCM ERROR: $e');
    debugPrint(stackTrace.toString());
  }
}
