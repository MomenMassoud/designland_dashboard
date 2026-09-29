import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../model/staff_model.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl = 'https://designland-backend.vercel.app/api';

  Stream<List<StaffModel>> getStaffStream() {
    return _firestore
        .collection('user')
        .where('role', isEqualTo: 'staff')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => StaffModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<void> updatePermissions({
    required String docId,
    required String name,
    required List<String> permissions,
  }) async {
    await _firestore.collection('user').doc(docId).update({
      'name': name,
      'permissions': permissions,
    });
  }

  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required List<String> permissions,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/create_staff'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'permissions': permissions,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create employee');
    }
  }

  Future<void> deleteStaff(String docId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/delete-account'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': docId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to delete employee');
    }
  }
}