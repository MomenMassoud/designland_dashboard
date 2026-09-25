import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
Future<void> sendInvoiceEmail({
  required String customerEmail,
  required String customerName,
  required int orderNumber,
  required String orderId,
  required double total,
  required List<Map<String, dynamic>> items,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://designland-backend.vercel.app/api/send-email'), // استبدل بالرابط الخاص بك
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerEmail': customerEmail,
        'customerName': customerName,
        'orderNumber': orderNumber,
        'orderId': orderId,
        'total': total,
        'items': items,
      }),
    );
  } catch (e) {
    print("Error sending email: $e");
  }
}