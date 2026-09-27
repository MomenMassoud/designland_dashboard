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
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final scaffoldBg = isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FA);
    final appBarBg = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'User Orders History',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: appBarBg,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textColor),
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
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No orders found for this user.",
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
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
                _buildOverviewCards(docs.length, totalSpent, isDarkMode, theme),
                const SizedBox(height: 24),

                Text(
                  "All Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
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
                    return _buildOrderCard(orderId, orderData, isDarkMode, theme);
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
  Widget _buildOverviewCards(int totalOrders, double totalSpent, bool isDarkMode, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Total Orders",
            value: totalOrders.toString(),
            icon: Icons.receipt_long_rounded,
            color: Colors.blue,
            isDarkMode: isDarkMode,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: "Total Spent",
            value: "${totalSpent.toStringAsFixed(0)} EGP",
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.green,
            isDarkMode: isDarkMode,
            theme: theme,
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
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
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
  Widget _buildOrderCard(String orderId, Map<String, dynamic> data, bool isDarkMode, ThemeData theme) {
    final int orderNumber = data['orderNumber'] ?? 0;
    final String status = (data['status'] ?? 'pending').toString().toLowerCase();
    final num totalPrice = data['totalPrice'] ?? 0;
    final num subtotal = data['subtotal'] ?? 0;
    final num discountAmount = data['discountAmount'] ?? 0;
    final List items = data['items'] as List? ?? [];
    final Map<String, dynamic> address = data['selectedAddress'] as Map<String, dynamic>? ?? {};

    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    // تنسيق وقت الإنشاء
    String dateStr = 'N/A';
    if (data['createdAt'] is Timestamp) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      dateStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: subtitleColor,
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: textColor),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          iconColor: textColor,
          collapsedIconColor: subtitleColor,
          title: Row(
            children: [
              Text(
                "Order #${orderNumber > 0 ? orderNumber : orderId.substring(0, 6)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusBadge(status, isDarkMode),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              "Date: $dateStr | Total: $totalPrice EGP",
              style: TextStyle(fontSize: 13, color: subtitleColor),
            ),
          ),
          children: [
            Divider(
              height: 1,
              color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قائمة المنتجات
                  Text(
                    "Order Items",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
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
                          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                          ),
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
                                errorBuilder: (_, __, ___) => _buildPlaceholderImage(isDarkMode),
                              )
                                  : _buildPlaceholderImage(isDarkMode),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Qty: $quantity x $price EGP",
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Notes: $notes",
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            Text(
                              "${price * quantity} EGP",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // تفاصيل العنوان المختار للشحن
                  if (address.isNotEmpty) ...[
                    Text(
                      "Shipping Address",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.shade900.withOpacity(0.3)
                            : Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${address['fullName'] ?? ''} (${address['phone'] ?? ''})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatAddressString(address),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                  ),
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
                      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow("Subtotal", "$subtotal EGP", isDarkMode: isDarkMode),
                        if (discountAmount > 0)
                          _buildPriceRow("Discount", "- $discountAmount EGP", isDiscount: true, isDarkMode: isDarkMode),
                        Divider(
                          height: 16,
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                        _buildPriceRow("Total Price", "$totalPrice EGP", isBold: true, isDarkMode: isDarkMode),
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
  Widget _buildStatusBadge(String status, bool isDarkMode) {
    Color bg;
    Color fg;

    switch (status) {
      case 'completed':
      case 'delivered':
        bg = isDarkMode ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50;
        fg = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
        break;
      case 'cancelled':
        bg = isDarkMode ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50;
        fg = isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
        break;
      case 'processing':
        bg = isDarkMode ? Colors.blue.shade900.withOpacity(0.4) : Colors.blue.shade50;
        fg = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
        break;
      default:
        bg = isDarkMode ? Colors.orange.shade900.withOpacity(0.4) : Colors.orange.shade50;
        fg = isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
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
  Widget _buildPlaceholderImage(bool isDarkMode) {
    return Container(
      width: 50,
      height: 50,
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Icon(
        Icons.image,
        color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
        size: 24,
      ),
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
  Widget _buildPriceRow(
      String label,
      String amount, {
        bool isDiscount = false,
        bool isBold = false,
        required bool isDarkMode,
      }) {
    final defaultLabelColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final defaultValueColor = isDarkMode ? Colors.white : Colors.black87;

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
              color: isDiscount ? (isDarkMode ? Colors.redAccent : Colors.red) : defaultLabelColor,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? (isDarkMode ? Colors.redAccent : Colors.red) : defaultValueColor,
            ),
          ),
        ],
      ),
    );
  }
}