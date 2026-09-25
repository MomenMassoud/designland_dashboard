import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> sendOrderReadyEmail({
  required String customerEmail,
  required String orderId,
  String? customerName,
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
        if (customerName != null) 'customerName': customerName,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('✨ Order confirmation email sent successfully!');
    } else {
      debugPrint('Failed to send email: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error sending order confirmation email: $e');
  }
}