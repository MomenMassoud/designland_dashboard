import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_client_data.dart';
import 'package:dashboard_desginland/Core/server/sendCancelInvoiceEmail.dart';
import 'package:dashboard_desginland/Core/server/sendOrderConfirmationEmail.dart';
import 'package:dashboard_desginland/Core/server/sendOrderReadyEmail.dart';
import 'package:dashboard_desginland/Core/server/sendUserNotificationApi.dart';
import 'package:dashboard_desginland/Core/server/send_pending_email.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';
import 'order_details_widget.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> with SingleTickerProviderStateMixin {
  final List<String> _statuses = ['pending', 'shipping', 'completed', 'cancelled'];
  final List<String> _tabs = ['All', 'Pending', 'Shipping', 'Completed', 'Cancelled'];

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _permision = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _start();
  }

  void _start() async {
    _permision = await GetPermisionUser();
    if (mounted) setState(() {});
  }

  void _saveNotification(String userID, String status, String orderID) async {
    try {
      await _firestore.collection('user').doc(userID).collection('notifications').add({
        'isRead': false,
        'body': "Your Order Is $status",
        "title": "Order $orderID is $status",
        "targetUser": userID,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      showErrorDialog(context, "Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permision.contains("orders")) return AccessDefindView();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Orders & Financial Management"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text("Manual Order"),
              onPressed: () => _showAddManualOrderDialog(context),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryPurple,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tabFilter) => _buildOrdersList(tabFilter)).toList(),
      ),
    );
  }

  Widget _buildOrdersList(String filterStatus) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var docs = snapshot.data?.docs ?? [];

        if (filterStatus != 'All') {
          docs = docs.where((doc) {
            final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
            return status == filterStatus.toLowerCase();
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(child: Text("No $filterStatus orders found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final orderDoc = docs[index];
            final orderData = orderDoc.data();
            final String orderId = orderDoc.id;
            final String userId = orderData['userId'] ?? orderDoc.reference.parent.parent?.id ?? '';

            final String currentStatus = orderData['status'] ?? 'pending';
            final num totalPrice = orderData['totalPrice'] ?? 0;
            final List items = orderData['items'] as List? ?? [];
            final bool isManual = orderData['isManual'] ?? false;
            String formattedDate = 'N/A';
            if (orderData['createdAt'] is Timestamp) {
              final dt = (orderData['createdAt'] as Timestamp).toDate();
              formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
            }

            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isManual ? Colors.orange.shade300 : Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailView(
                        orderId: orderId,
                        userId: userId,
                        orderData: orderData,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}...",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (isManual) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("Manual", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          _buildStatusDropdown(userId, orderId, currentStatus, totalPrice, orderDoc.reference),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // إذا كان الطلب يدوياً ولديه customerName قم بعرضه فوراً، وإلا جلب الاسم من Firestore
                              if (isManual && (orderData['customerName']?.toString().isNotEmpty ?? false)) ...[
                                Text(
                                  "Customer: ${orderData['customerName']}",
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                ),
                              ] else if (userId.isNotEmpty) ...[
                                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                  future: _firestore.collection('user').doc(userId).get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Text(
                                        "Customer: Loading...",
                                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                      );
                                    }

                                    String userName = "Unknown User";
                                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                      final userData = userSnapshot.data!.data();
                                      userName = userData?['name'] ?? orderData['customerName'] ?? orderData['userEmail'] ?? userId;
                                    } else {
                                      userName = orderData['customerName'] ?? orderData['userEmail'] ?? userId;
                                    }

                                    return Text(
                                      "Customer: $userName",
                                      style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ] else ...[
                                Text(
                                  "Customer: ${orderData['customerName'] ?? orderData['userEmail'] ?? 'Guest'}",
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text("Date: $formattedDate", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text("${items.length} Item(s)", style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text("$totalPrice EGP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusDropdown(String userId, String orderId, String currentStatus, num total, DocumentReference orderRef) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(color: _getStatusBgColor(currentStatus), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statuses.contains(currentStatus.toLowerCase()) ? currentStatus.toLowerCase() : 'pending',
          icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(currentStatus)),
          style: TextStyle(color: _getStatusColor(currentStatus), fontWeight: FontWeight.bold, fontSize: 11),
          onChanged: (String? newStatus) async {
            if (newStatus != null && newStatus != currentStatus) {
              await orderRef.update({'status': newStatus});

              if (userId.isNotEmpty) {
                UserModel user = await getClientData(context, userId);
                _saveNotification(userId, newStatus, orderId);

                if (newStatus == "pending"){
                  sendInvoiceEmail(customerEmail: user.email, orderId: orderId, total: total.toDouble());
                }
                else if (newStatus == "shipping") sendOrderConfirmationEmail(customerEmail: user.email, orderId: orderId, total: total.toDouble());
                else if (newStatus == "completed") sendOrderReadyEmail(customerEmail: user.email, orderId: orderId, total: total.toDouble());
                else sendCancelInvoiceEmail(customerEmail: user.email, orderId: orderId, total: total.toDouble());
                sendUserNotificationApi(
                    userId: userId,
                    title: "Your Order Updated Status", body: "Your Order Status ${newStatus}!");
              }

              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
            }
          },
          items: _statuses.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase()))).toList(),
        ),
      ),
    );
  }

  void _showAddManualOrderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final itemTitleController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Add Manual Order"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Customer Name *", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Customer Phone", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: itemTitleController, decoration: const InputDecoration(labelText: "Product/Service Description *", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Price (\$) *", border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            onPressed: () async {
              final double? price = double.tryParse(priceController.text);
              if (nameController.text.isNotEmpty && price != null) {
                await _firestore.collection('orders').add({
                  'customerName': nameController.text,
                  'customerPhone': phoneController.text,
                  'totalPrice': price,
                  'status': 'pending',
                  'isManual': true,
                  'userId': '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'items': [
                    {'title': itemTitleController.text, 'price': price, 'quantity': 1}
                  ]
                });

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manual Order Added Successfully!")));
                }
              }
            },
            child: const Text("Create Order", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'shipping': return Colors.blue;
      default: return Colors.orange;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade50;
      case 'cancelled': return Colors.red.shade50;
      case 'shipping': return Colors.blue.shade50;
      default: return Colors.orange.shade50;
    }
  }
}