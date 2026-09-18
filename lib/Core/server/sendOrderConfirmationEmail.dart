import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> sendOrderConfirmationEmail({
  required String customerEmail,
  required String orderId,
  required double total,
  String? estimatedTime,
}) async {
  const String apiUrl = 'https://designland-backend.vercel.app/api/confirm-order';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'customerEmail': customerEmail,
        'orderId': orderId,
        'total': total,
        if (estimatedTime != null) 'estimatedTime': estimatedTime,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('🎉 تم إرسال إيميل تأكيد الطلب وبدء العمل بنجاح!');
    } else {
      debugPrint('فشل الإرسال: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}