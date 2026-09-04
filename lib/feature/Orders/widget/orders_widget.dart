import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  // الحالات المتاحة للطلب
  final List<String> _statuses = ['pending', 'shipping', 'completed', 'cancelled'];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Start();
  }
  List<String> _permision=[];
  void Start()async{
    _permision=await GetPermisionUser();
    setState(() {
      _permision;
    });
  }
  @override
  Widget build(BuildContext context) {
    return _permision.contains("orders")? Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Orders & Financial Management"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }

          if (usersSnapshot.hasError) {
            return Center(child: Text("Error: ${usersSnapshot.error}"));
          }

          final userDocs = usersSnapshot.data?.docs ?? [];

          if (userDocs.isEmpty) {
            return const Center(
              child: Text("No users found.", style: TextStyle(color: AppColors.textMuted)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userDoc = userDocs[index];
              final userData = userDoc.data();
              final String userId = userDoc.id;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, ordersSnapshot) {
                  if (!ordersSnapshot.hasData || ordersSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final orderDocs = ordersSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: orderDocs.map((orderDoc) {
                      final orderData = orderDoc.data();
                      final String orderId = orderDoc.id;

                      final String currentStatus = orderData['status'] ?? 'pending';
                      final num totalPrice = orderData['totalPrice'] ?? 0;
                      final List items = orderData['items'] as List? ?? [];

                      String formattedDate = 'N/A';
                      if (orderData['createdAt'] is Timestamp) {
                        final dt = (orderData['createdAt'] as Timestamp).toDate();
                        formattedDate =
                        "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                      }

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showOrderDetailsDialog(
                            context,
                            orderId,
                            userId,
                            userData,
                            orderData,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}...",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    // القائمة المنسدلة لتغيير الحالة فوراً
                                    _buildStatusDropdown(userId, orderId, currentStatus),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Customer: ${userData['name'] ?? userData['email'] ?? userId}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Date: $formattedDate",
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${items.length} Item(s)",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "\$$totalPrice",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    ):AccessDefindView();
  }

  // Dropdown لتعديل الحالة المباشرة
  Widget _buildStatusDropdown(String userId, String orderId, String currentStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: _getStatusBgColor(currentStatus),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statuses.contains(currentStatus.toLowerCase())
              ? currentStatus.toLowerCase()
              : 'pending',
          icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(currentStatus)),
          style: TextStyle(
            color: _getStatusColor(currentStatus),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          onChanged: (String? newStatus) async {
            if (newStatus != null && newStatus != currentStatus) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': newStatus});

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Order status updated to $newStatus")),
                );
              }
            }
          },
          items: _statuses.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase()),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipping':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      case 'shipping':
        return Colors.blue.shade50;
      default:
        return Colors.orange.shade50;
    }
  }

  // تفاصيل الطلب مع إدارة المقبوضات المالية (Deposits)
  void _showOrderDetailsDialog(
      BuildContext context,
      String orderId,
      String userId,
      Map<String, dynamic> userData,
      Map<String, dynamic> orderData,
      ) {
    final List items = orderData['items'] as List? ?? [];
    final num totalPrice = orderData['totalPrice'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.receipt_long, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Text("Order & Payment Details"),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText("Order ID: $orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                SelectableText("User: ${userData['name'] ?? 'N/A'} ($userId)",
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const Divider(height: 24),

                // --- قسم المدفوعات والمقبوضات (Payments & Deposit Section) ---
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('payments')
                      .where('orderId', isEqualTo: orderId)
                      .snapshots(),
                  builder: (context, paymentsSnapshot) {
                    num totalPaid = 0;
                    final paymentDocs = paymentsSnapshot.data?.docs ?? [];

                    for (var doc in paymentDocs) {
                      totalPaid += (doc.data()['amount'] ?? 0);
                    }

                    num remainingAmount = totalPrice - totalPaid;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add Deposit"),
                                onPressed: () {
                                  _showAddDepositDialog(context, orderId, userId);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text("Total: \$$totalPrice", style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text("Paid: \$$totalPaid", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                              Text("Remaining: \$$remainingAmount", style: TextStyle(fontWeight: FontWeight.w600, color: remainingAmount > 0 ? Colors.red : Colors.green)),
                            ],
                          ),
                          if (paymentDocs.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text("Payment History:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Column(
                              children: paymentDocs.map((p) {
                                final pData = p.data();
                                final pDate = pData['paymentDate'] is Timestamp
                                    ? (pData['paymentDate'] as Timestamp).toDate().toString().split('.')[0]
                                    : 'N/A';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("• \$ ${pData['amount']} (${pData['notes'] ?? 'Deposit'})", style: const TextStyle(fontSize: 12)),
                                      Text(pDate, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                const Text("Items in Order:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),

                if (items.isEmpty)
                  const Text("No items found in this order.", style: TextStyle(color: AppColors.textMuted))
                else
                  Column(
                    children: items.map((item) {
                      final map = item is Map<String, dynamic> ? item : {};
                      final String title = map['title'] ?? 'Product';
                      final String image = map['image'] ?? '';
                      final num price = map['price'] ?? 0;
                      final int quantity = map['quantity'] ?? 1;
                      final String note = map['note'] ?? '';
                      final String driveUrl = map['driveUrl'] ?? '';
                      final String selectedAddress = map['selectedAddress'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: image.isNotEmpty
                                      ? Image.network(
                                    image,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image_not_supported, size: 20),
                                    ),
                                  )
                                      : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.shopping_bag, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Qty: $quantity  |  Price: \$$price",
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("Note: $note", style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                              ),
                            ],
                            if (selectedAddress.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text("Address: $selectedAddress", style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                                  ),
                                ],
                              ),
                            ],
                            if (driveUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final Uri url = Uri.parse(driveUrl.startsWith('http') ? driveUrl : 'https://$driveUrl');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.link, size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Drive Link: $driveUrl",
                                        style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // نافذة تسجيل الدفعة المادية (Deposit Dialog)
  void _showAddDepositDialog(BuildContext context, String orderId, String userId) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Record Deposit / Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount Paid (\$) *",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Notes (e.g. Vodafone Cash, Bank Transfer)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            onPressed: () async {
              final double? amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                // حفظ الدفعة في كوليكشن المبالغ المستقل (payments)
                await FirebaseFirestore.instance.collection('payments').add({
                  'orderId': orderId,
                  'userId': userId,
                  'amount': amount,
                  'notes': notesController.text.isEmpty ? 'Deposit' : notesController.text,
                  'paymentDate': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deposit recorded successfully!")),
                  );
                }
              }
            },
            child: const Text("Save Payment", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}