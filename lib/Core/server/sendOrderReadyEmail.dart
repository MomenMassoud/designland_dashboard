import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> sendOrderReadyEmail({
  required String customerEmail,
  required String orderId,
  required double total,
  String? deliveryNotes,
}) async {
  const String apiUrl = 'https://designland-backend.vercel.app/api/order-ready';

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
        if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('🎉 تم إرسال إيميل أن الطلب في الطريق بنجاح!');
    } else {
      debugPrint('فشل الإرسال: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}