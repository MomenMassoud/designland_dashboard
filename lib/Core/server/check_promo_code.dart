import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";


Future<List<Map<String, dynamic>>> cleanAndFetchValidPromoCodes() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DateTime now = DateTime.now();

  try {
    // 1. جلب كافة أوراق البرومو كود
    final QuerySnapshot snapshot = await db.collection('promo_codes').get();
    List<Map<String, dynamic>> validPromoCodes = [];

    // 2. استخدام WriteBatch لحذف الأكواد المنتهية في طلب واحد لتوفير الأداء
    WriteBatch batch = db.batch();
    bool hasExpiredCodes = false;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? expireTimestamp = data['expiresAt'];

      if (expireTimestamp != null) {
        final DateTime expiresAt = expireTimestamp.toDate();

        // التأكد مما إذا كان الكود منتهي الصلاحية
        if (now.isAfter(expiresAt)) {
          batch.delete(doc.reference);
          hasExpiredCodes = true;
        } else {
          validPromoCodes.add(data);
        }
      } else {
        // في حال كان البرومو كود بدون تاريخ انتهاء، يعتبر صالحاً
        validPromoCodes.add(data);
      }
    }

    // 3. تنفيذ عمليات الحذف دفعة واحدة إذا تم العثور على أكواد منتهية
    if (hasExpiredCodes) {
      await batch.commit();
      print('تم حذف جميع البرومو كود المنتهية بنجاح.');
    }

    return validPromoCodes;
  } catch (e) {
    print('حدث خطأ أثناء تنظيف وجلب البرومو كود: $e');
    return [];
  }
}