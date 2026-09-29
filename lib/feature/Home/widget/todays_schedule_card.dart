import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controller/home_controller.dart';
import '../../../model/CalendarEventModel.dart';
import 'CalendarView.dart';



class TodaysScheduleCard extends GetView<HomeController> {
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;

  const TodaysScheduleCard({
    super.key,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final userId = controller.currentUser.value?.uid ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule".tr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.deepPurple),
                    tooltip: "Add Event".tr,
                    onPressed: () => _showAddEventDialog(context, userId),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.to(() => const CalendarView());
                    },
                    child: Text(
                      "View Calendar".tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.todaysEvents.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No events scheduled for today".tr,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.todaysEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = controller.todaysEvents[index];
                final formattedTime = DateFormat('hh:mm a').format(event.eventTime);

                return Row(
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: Colors.deepPurple, size: 18),
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
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(
                            event.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: event.isCompleted,
                      activeColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        if (userId.isNotEmpty) {
                          controller.toggleTaskStatus(userId, event.id, val ?? false);
                        }
                      },
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Event".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Title".tr),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subtitleController,
              decoration: InputDecoration(labelText: "Description".tr),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel".tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && userId.isNotEmpty) {
                final newEvent = CalendarEventModel(
                  id: '',
                  title: titleController.text,
                  subtitle: subtitleController.text,
                  eventTime: DateTime.now(),
                  category: 'general',
                );
                controller.addNewEvent(userId, newEvent);
                Navigator.pop(ctx);
              }
            },
            child: Text("Save".tr),
          ),
        ],
      ),
    );
  }
}