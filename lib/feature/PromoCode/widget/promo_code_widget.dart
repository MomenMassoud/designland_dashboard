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
                  Text(
                    'Create a new promo code',
                    style: TextStyle(color: titleTextColor, fontSize: 18),
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
                  child: Text('cancel', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                    final discountStr = discountController.text.trim();
                    if (discountStr.isEmpty || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please specify the discount rate and the expiration date.')),
                      );
                      return;
                    }

                    final double? discount = double.tryParse(discountStr);
                    if (discount == null || discount <= 0 || discount > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid discount percentage between 1 and 100.')),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    Navigator.pop(ctx);

                    try {
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
                          content: Text('The promo code has been successfully created:$generatedCode'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('An error occurred during creation:$e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Generation and creation'),
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
      builder: (ctx) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? Theme.of(context).cardColor : Colors.white,
          title: Text(
            'Confirm Deletion',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Text(
            'Are you sure you want to delete this promo code?',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _db.collection('promo_codes').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The promo code has been successfully deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final backgroundColor = isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade100;
    final cardColor = isDarkMode ? theme.cardColor : Colors.white;
    final titleTextColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return _permision.contains("promo")
        ? Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Promo Code and Discount Management'),
        centerTitle: true,
        backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
        foregroundColor: titleTextColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePromoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Generate an automatic promo code'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('promo_codes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'An error occurred:${snapshot.error}',
                style: TextStyle(color: titleTextColor),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 70,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "There are currently no discount codes available.",
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                    ),
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    ),
                  ],
                  border: isDarkMode ? Border.all(color: Colors.grey.shade800, width: 1) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? (isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50)
                          : (isDarkMode ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      color: isExpired
                          ? (isDarkMode ? Colors.redAccent : Colors.red)
                          : (isDarkMode ? Colors.greenAccent : Colors.green),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.5,
                          color: titleTextColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? (isDarkMode ? Colors.red.shade900.withOpacity(0.5) : Colors.red.shade100)
                              : (isDarkMode ? Colors.green.shade900.withOpacity(0.5) : Colors.green.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired ? 'finished' : 'active',
                          style: TextStyle(
                            fontSize: 11,
                            color: isExpired
                                ? (isDarkMode ? Colors.red.shade200 : Colors.red.shade900)
                                : (isDarkMode ? Colors.green.shade200 : Colors.green.shade900),
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
                      Text(
                        'Discount rate: %$discount',
                        style: TextStyle(fontWeight: FontWeight.w600, color: titleTextColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expiresAt != null
                            ? 'Ends on:${DateFormat('yyyy/MM/dd  hh:mm a').format(expiresAt)}'
                            : 'No expiration date',
                        style: TextStyle(fontSize: 12, color: subtitleTextColor),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deletePromoCode(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    )
        : AccessDefindView();
  }
}