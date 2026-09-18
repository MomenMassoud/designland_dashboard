import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Core/server/get_permision.dart';

class PromoCodeWidget extends StatefulWidget {
  const PromoCodeWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PromoCodeWidgetState();
  }
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<String> _permision = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Start();
  }

  void Start() async {
    _permision = await GetPermisionUser();
    setState(() {
      _permision;
    });
  }

  // توليد كود عشوائي مكون من 6 أرقام وحروف
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // التأكد من أن الكود العشوائي غير مكرر في Firestore
  Future<String> _generateUniquePromoCode() async {
    while (true) {
      String code = _generateRandomCode();
      final doc = await _db.collection('promo_codes').doc(code).get();
      if (!doc.exists) {
        return code;
      }
    }
  }

  // نافذة إنشاء برومو كود جديد
  void _showCreatePromoDialog() {
    final discountController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.local_offer_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('إنشاء برومو كود جديد'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'نسبة الخصم (%)',
                      hintText: 'مثال: 15',
                      prefixIcon: const Icon(Icons.percent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDate == null
                          ? 'اختر تاريخ وقت الانتهاء'
                          : DateFormat('yyyy/MM/dd  hh:mm a').format(selectedDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate == null ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );

                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 23, minute: 59),
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                    final discountStr = discountController.text.trim();
                    if (discountStr.isEmpty || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى تحديد نسبة الخصم وتاريخ الانتهاء')),
                      );
                      return;
                    }

                    final double? discount = double.tryParse(discountStr);
                    if (discount == null || discount <= 0 || discount > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('برجاء إدخال نسبة خصم صحيحة بين 1 و 100')),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    Navigator.pop(ctx);

                    try {
                      // إنشاء كود مميز عشوائي
                      String generatedCode = await _generateUniquePromoCode();

                      await _db.collection('promo_codes').doc(generatedCode).set({
                        'code': generatedCode,
                        'discountPercentage': discount,
                        'expiresAt': Timestamp.fromDate(selectedDate!),
                        'createdAt': FieldValue.serverTimestamp(),
                        'isActive': true,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إنشاء البرومو كود بنجاح: $generatedCode'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء الإنشاء: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('توليد وإنشاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // حذف برومو كود
  Future<void> _deletePromoCode(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متاكد من حذف هذا البرومو كود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('promo_codes').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف البرومو كود بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("promo")
        ? Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('إدارة البرومو كود والخصومات'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePromoDialog,
        icon: const Icon(Icons.add),
        label: const Text('إنشاء برومو كود تلقائي'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('promo_codes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد أكواد خصم متاحة حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String code = data['code'] ?? doc.id;
              final double discount = (data['discountPercentage'] ?? 0).toDouble();
              final Timestamp? expireTimestamp = data['expiresAt'];
              final DateTime? expiresAt = expireTimestamp?.toDate();

              final bool isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      color: isExpired ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired ? 'منتهي' : 'نشط',
                          style: TextStyle(
                            fontSize: 11,
                            color: isExpired ? Colors.red.shade900 : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('نسبة الخصم: %$discount', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        expiresAt != null
                            ? 'ينتهي في: ${DateFormat('yyyy/MM/dd  hh:mm a').format(expiresAt)}'
                            : 'بدون تاريخ انتهاء',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deletePromoCode(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    )
        :  AccessDefindView();
  }
}