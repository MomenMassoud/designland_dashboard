import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime eventTime;
  final String category; // e.g. "meeting", "shoot", "review"
  final bool isCompleted;

  CalendarEventModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.eventTime,
    required this.category,
    this.isCompleted = false,
  });

  factory CalendarEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CalendarEventModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      eventTime: (data['eventTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? 'general',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'eventTime': Timestamp.fromDate(eventTime),
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}