import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/email_notification_service.dart';
import 'package:dashboard_desginland/feature/Top%20Fans/widget/top_fan_card.dart';
import 'package:dashboard_desginland/feature/Top%20Fans/widget/top_fans_filter_bar.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controller/top_fans_controller.dart';
import '../../../model/top_fan_model.dart';

class TopFansWidget extends StatefulWidget {
  const TopFansWidget({super.key});

  @override
  State<TopFansWidget> createState() => _TopFansWidgetState();
}

class _TopFansWidgetState extends State<TopFansWidget> {
  @override
  Widget build(BuildContext context) {
    final TopFansController controller = Get.put(TopFansController());
    final bool isDark = Get.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopFansFilterBar(controller: controller, isDark: isDark),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                );
              }
              if (controller.filteredTopFans.isEmpty) {
                return Center(
                  child: Text(
                    "No top fans found.".tr,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.filteredTopFans.length,
                itemBuilder: (context, index) {
                  final fan = controller.filteredTopFans[index];
                  return TopFanCard(
                    fan: fan,
                    rank: index + 1,
                    isDark: isDark,
                    onViewReport: () async {
                      try {
                        final docSnap = await FirebaseFirestore.instance
                            .collection('user')
                            .doc(fan.uid)
                            .get();
                        if (docSnap.exists && docSnap.data() != null) {
                          Get.to(() => UserDetailView(userId: fan.uid, userData: docSnap.data()!));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error loading user details: $e')),
                        );
                      }
                    },
                    onSendPromoCode: () {
                      _showCreatePromoDialog(fan);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniquePromoCode() async {
    while (true) {
      String code = _generateRandomCode();
      final doc = await FirebaseFirestore.instance.collection('promo_codes').doc(code).get();
      if (!doc.exists) {
        return code;
      }
    }
  }

  void _showCreatePromoDialog(TopFanModel fan) {
    final discountController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final theme = Theme.of(context);
            final titleTextColor = isDarkMode ? Colors.white : Colors.black87;
            final subtitleTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

            return AlertDialog(
              backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Create promo code for ${fan.name}',
                      style: TextStyle(color: titleTextColor, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: titleTextColor),
                    decoration: InputDecoration(
                      labelText: 'Discount rate (%)',
                      labelStyle: TextStyle(color: subtitleTextColor),
                      hintText: 'Example: 15',
                      hintStyle: TextStyle(color: subtitleTextColor),
                      prefixIcon: const Icon(Icons.percent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                    ),
                    leading: Icon(Icons.calendar_today, color: isDarkMode ? Colors.lightBlue : null),
                    title: Text(
                      selectedDate == null
                          ? 'Select the end date and time.'
                          : DateFormat('yyyy/MM/dd  hh:mm a').format(selectedDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate == null ? subtitleTextColor : titleTextColor,
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: isDarkMode
                                ? ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.blue,
                                onPrimary: Colors.white,
                                surface: theme.cardColor,
                                onSurface: Colors.white,
                              ),
                            )
                                : ThemeData.light(),
                            child: child!,
                          );
                        },
                      );

                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 23, minute: 59),
                          builder: (context, child) {
                            return Theme(
                              data: isDarkMode
                                  ? ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                  surface: theme.cardColor,
                                  onSurface: Colors.white,
                                ),
                              )
                                  : ThemeData.light(),
                              child: child!,
                            );
                          },
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
                  child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final discountStr = discountController.text.trim();
                    if (discountStr.isEmpty || selectedDate == null) {
                      Get.snackbar('Warning', 'Please specify the discount rate and the expiration date.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.shade800,
                          colorText: Colors.white);
                      return;
                    }

                    final double? discount = double.tryParse(discountStr);
                    if (discount == null || discount <= 0 || discount > 100) {
                      Get.snackbar('Warning', 'Please enter a valid discount percentage between 1 and 100.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.shade800,
                          colorText: Colors.white);
                      return;
                    }

                    if (fan.email.isEmpty) {
                      Get.snackbar('Error', 'This user does not have a valid email address.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white);
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      final firestore = FirebaseFirestore.instance;
                      String generatedCode = await _generateUniquePromoCode();
                      String formattedExpiry = DateFormat('MMMM dd, yyyy - hh:mm a').format(selectedDate!);

                      // 1. التخزين في Firestore
                      await firestore.collection('promo_codes').doc(generatedCode).set({
                        'code': generatedCode,
                        'discountPercentage': discount.toInt(),
                        'createdAt': FieldValue.serverTimestamp(),
                        'expiresAt': Timestamp.fromDate(selectedDate!),
                        'isActive': true,
                        'assignedToUser': fan.uid,
                      });

                      // 2. تجهيز الرسالة
                      String subject = "A Special Gift For You! 🎉 Exclusive Promo Code Inside";

                      String messageBody = """
Dear ${fan.name},

Thank you for being one of our most valued top customers! We deeply appreciate your trust and continuous support. 

To celebrate your loyalty and remarkable number of completed orders, we are excited to reward you with a special promo code as a token of our appreciation!

🎁 Your Exclusive Promo Code: $generatedCode
💥 Discount Rate: ${discount.toStringAsFixed(0)}% OFF
⏳ Valid Until: $formattedExpiry

Feel free to use this code on your next order, or share it with one of your friends as a gift!

Thank you for being an essential part of our community.

Best regards,
DesignLand Team
""";

                      // 3. إرسال الإيميل
                      await EmailNotificationService().sendCustomEmail(
                        recipientEmail: fan.email,
                        subject: subject,
                        messageBody: messageBody,
                      );

                      // التنبيه الآمن باستخدام GetX بدون الحاجة لـ Context
                      Get.snackbar(
                        'Success',
                        'Promo code generated & sent successfully to ${fan.email}!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'An error occurred: $e',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: const Text('Generate and Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}