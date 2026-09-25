import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<void> sendOrderShippingEmail({
  required String customerEmail,
  required String orderId,
  String? customerName,
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
        if (customerName != null) 'customerName': customerName,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint('📦 Shipping notification email sent successfully!');
    } else {
      debugPrint('Failed to send shipping email: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error sending shipping email: $e');
  }
}