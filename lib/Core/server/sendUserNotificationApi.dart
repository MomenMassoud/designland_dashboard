import 'dart:convert';
import 'package:http/http.dart' as http;

Future<bool> sendUserNotificationApi({
  required String userId,
  required String title,
  required String body,
  Map<String, dynamic>? extraData,
}) async {
  // استبدل الـ URL برابط السيرفر بتاعك (مثلاً Localhost أو IP السيرفر)
  // لو شغال على Emulator استخدم 10.0.2.2 بدلاً من localhost
  final Uri url = Uri.parse('https://designland-backend.vercel.app/api/notify_client');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'body': body,
        'data': extraData ?? {},
      }),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      print("Notification Sent Successfully: ${resData['message']}");
      return true;
    } else {
      print("Failed to send notification: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error calling Notification API: $e");
    return false;
  }
}