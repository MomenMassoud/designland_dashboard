import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../controller/home_controller.dart';
import '../../../model/CalendarEventModel.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final HomeController controller = Get.find<HomeController>();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121218) : const Color(0xFFF4F5F9);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final appBarBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final userId = controller.currentUser.value?.uid ?? '';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Calendar & Tasks".tr,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage your personal schedule and daily events".tr,
              style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, left: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primaryPurple, size: 20),
              onPressed: () => _showAddEventDialog(context, userId),
              tooltip: "Add Event".tr,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // horizontal Date Picker Card
            _buildDatePickerCard(isDark, cardBg, textPrimary, textSecondary),
            const SizedBox(height: 16),

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Events for ${DateFormat('EEEE, MMM d').format(_selectedDate)}".tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  DateFormat('yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dynamic Events List from Firestore
            _buildEventsListStream(userId, isDark, cardBg, textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  /// شريط أفقـي باختيار الأيام (Horizontal Date Selector)
  Widget _buildDatePickerCard(bool isDark, Color cardBg, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index - 3));
                final isSelected = DateUtils.isSameDay(date, _selectedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    width: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// StreamBuilder يجلب أحداث اليوم المحدد من `user/{userId}/calendar_events`
  Widget _buildEventsListStream(
      String userId, bool isDark, Color cardBg, Color textPrimary, Color textSecondary) {
    if (userId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('calendar_events')
          .where('eventTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('eventTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('eventTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded, size: 40, color: textSecondary.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text(
                  "No tasks or events for this day".tr,
                  style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data!.docs
            .map((doc) => CalendarEventModel.fromFirestore(doc))
            .toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final event = events[index];
            final formattedTime = DateFormat('hh:mm a').format(event.eventTime);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_note_rounded, color: AppColors.primaryPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (event.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            event.subtitle,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Checkbox(
                    value: event.isCompleted,
                    activeColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      controller.toggleTaskStatus(userId, event.id, val ?? false);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog لإضافة حدث للتقويم بنفس استايل الـ Inputs
  void _showAddEventDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add New Task".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task Title".tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration: InputDecoration(
                labelText: "Description".tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel".tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (titleController.text.isNotEmpty && userId.isNotEmpty) {
                final newEvent = CalendarEventModel(
                  id: '',
                  title: titleController.text,
                  subtitle: subtitleController.text,
                  eventTime: _selectedDate,
                  category: 'general',
                );
                controller.addNewEvent(userId, newEvent);
                Navigator.pop(ctx);
              }
            },
            child: Text("Save".tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}