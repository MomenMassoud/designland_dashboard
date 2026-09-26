import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserOrdersDeatils extends StatefulWidget {
  final String _UserID;

  UserOrdersDeatils({required String UserID}) : _UserID = UserID;

  @override
  State<StatefulWidget> createState() {
    return _UserOrderDetails();
  }
}

class _UserOrderDetails extends State<UserOrdersDeatils> {
  // ألوان الـ Dashboard
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color bgColor = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'User Orders History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget._UserID)
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading orders: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "No orders found for this user.",
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // حساب الإحصائيات
          double totalSpent = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalSpent += (data['totalPrice'] ?? 0).toDouble();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. كروت الإحصائيات العلوية
                _buildOverviewCards(docs.length, totalSpent),
                const SizedBox(height: 24),

                const Text(
                  "All Orders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 2. قائمة الطلبات
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final orderData = docs[index].data() as Map<String, dynamic>;
                    final String orderId = docs[index].id;
                    return _buildOrderCard(orderId, orderData);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // كروت الإحصائيات العامة للمستخدم
  Widget _buildOverviewCards(int totalOrders, double totalSpent) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Total Orders",
            value: totalOrders.toString(),
            icon: Icons.receipt_long_rounded,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: "Total Spent",
            value: "${totalSpent.toStringAsFixed(0)} EGP",
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // كارت الطلب المفصل
  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final int orderNumber = data['orderNumber'] ?? 0;
    final String status = (data['status'] ?? 'pending').toString().toLowerCase();
    final num totalPrice = data['totalPrice'] ?? 0;
    final num subtotal = data['subtotal'] ?? 0;
    final num discountAmount = data['discountAmount'] ?? 0;
    final List items = data['items'] as List? ?? [];
    final Map<String, dynamic> address = data['selectedAddress'] as Map<String, dynamic>? ?? {};

    // تنسيق وقت الإنشاء
    String dateStr = 'N/A';
    if (data['createdAt'] is Timestamp) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      dateStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Text(
                "Order #${orderNumber > 0 ? orderNumber : orderId.substring(0, 6)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 10),
              _buildStatusBadge(status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              "Date: $dateStr | Total: $totalPrice EGP",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قائمة المنتجات
                  const Text(
                    "Order Items",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: items.map((item) {
                      final map = item as Map<String, dynamic>? ?? {};
                      final String title = map['title'] ?? 'Product';
                      final num price = map['price'] ?? 0;
                      final int quantity = map['quantity'] ?? 1;
                      final Map customData = map['customFieldsData'] as Map? ?? {};
                      final String imageUrl = customData['image'] ?? map['image'] ?? '';
                      final String notes = customData['notes'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                              )
                                  : _buildPlaceholderImage(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Qty: $quantity x $price EGP",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Notes: $notes",
                                      style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            Text(
                              "${price * quantity} EGP",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // تفاصيل العنوان المختار للشحن
                  if (address.isNotEmpty) ...[
                    const Text(
                      "Shipping Address",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${address['fullName'] ?? ''} (${address['phone'] ?? ''})",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatAddressString(address),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ملخص الحساب والتكلفة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow("Subtotal", "$subtotal EGP"),
                        if (discountAmount > 0)
                          _buildPriceRow("Discount", "- $discountAmount EGP", isDiscount: true),
                        const Divider(height: 16),
                        _buildPriceRow("Total Price", "$totalPrice EGP", isBold: true),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Badge حالة الطلب
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'completed':
      case 'delivered':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'processing':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // صورة بديلة عند عدم التمكن من تحميل صورة المنتج
  Widget _buildPlaceholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey, size: 24),
    );
  }

  // دالة لتجميع تفاصيل العنوان
  String _formatAddressString(Map<String, dynamic> addr) {
    List<String> parts = [];
    if ((addr['building'] ?? '').toString().isNotEmpty) parts.add("Building ${addr['building']}");
    if ((addr['street'] ?? '').toString().isNotEmpty) parts.add("Street ${addr['street']}");
    if ((addr['floor'] ?? '').toString().isNotEmpty) parts.add("Floor ${addr['floor']}");
    if ((addr['apartment'] ?? '').toString().isNotEmpty) parts.add("Apt ${addr['apartment']}");
    if ((addr['landmark'] ?? '').toString().isNotEmpty) parts.add("Near ${addr['landmark']}");
    if ((addr['city'] ?? '').toString().isNotEmpty) parts.add(addr['city']);
    if ((addr['governorate'] ?? '').toString().isNotEmpty) parts.add(addr['governorate']);

    return parts.join(', ');
  }

  // صف أرقام الأسعار
  Widget _buildPriceRow(String label, String amount, {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : Colors.grey.shade700,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}