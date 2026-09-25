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
      return;
    }

    String? token;

    if (kIsWeb) {


      token = await messaging.getToken(
        vapidKey: webVapidKey,
      );
    } else {


      token = await messaging.getToken();
    }

    if (token == null || token.isEmpty) {

      return;
    }


    await FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .set(
      {
        'devices': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );


    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(
          (newToken) async {
        try {
          final currentUser =
              FirebaseAuth.instance.currentUser;

          if (currentUser == null) {

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
