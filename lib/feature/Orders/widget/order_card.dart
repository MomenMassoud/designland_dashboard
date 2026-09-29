import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/order_service.dart';
import '../../../Core/server/user_service.dart';
import 'order_details_widget.dart';

class OrderCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> orderDoc;
  final bool isDark;
  final OrderService orderService;
  final UserService userService;
  final List<String> statuses;

  const OrderCard({
    super.key,
    required this.orderDoc,
    required this.isDark,
    required this.orderService,
    required this.userService,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    final orderData = orderDoc.data();
    final String orderId = orderDoc.id;
    final String userId = orderData['userId'] ?? orderDoc.reference.parent.parent?.id ?? '';

    final String currentStatus = orderData['status'] ?? 'pending';
    final num totalPrice = orderData['totalPrice'] ?? 0;
    final List items = orderData['items'] as List? ?? [];
    final bool isManual = orderData['isManual'] ?? false;
    final int orderNumber = orderData['orderNumber'] ?? 0;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey[400] : AppColors.textMuted;

    String formattedDate = 'N/A';
    if (orderData['createdAt'] is Timestamp) {
      final dt = (orderData['createdAt'] as Timestamp).toDate();
      formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Card(
      elevation: 0,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isManual
              ? Colors.orange.shade400
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
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
                        "Order #${orderNumber != 0 ? orderNumber : orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                      ),
                      if (isManual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("Manual", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  _buildStatusDropdown(context, userId, orderId, currentStatus, totalPrice, orderDoc.reference, orderNumber, orderData),
                ],
              ),
              Divider(height: 20, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCustomerNameWidget(userId, orderData, textColor, mutedTextColor),
                      const SizedBox(height: 4),
                      Text("Date: $formattedDate", style: TextStyle(fontSize: 12, color: mutedTextColor)),
                      const SizedBox(height: 4),
                      Text("${items.length} Item(s)", style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text("$totalPrice EGP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerNameWidget(String userId, Map<String, dynamic> orderData, Color textColor, Color? mutedTextColor) {
    if (orderData['isManual'] == true && (orderData['customerName']?.toString().isNotEmpty ?? false)) {
      return Text(
        "Customer: ${orderData['customerName']}",
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
      );
    }

    final cachedName = userService.getCachedName(userId);
    if (cachedName != null) {
      return Text(
        "Customer: $cachedName",
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
      );
    }

    return FutureBuilder<String>(
      future: userService.getCustomerName(userId, orderData),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Loading...';
        return Text(
          "Customer: $name",
          style: TextStyle(
            fontSize: 13,
            color: snapshot.hasData ? textColor : mutedTextColor,
            fontWeight: snapshot.hasData ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      },
    );
  }

  Widget _buildStatusDropdown(BuildContext context, String userId, String orderId, String currentStatus, num total, DocumentReference orderRef, int orderNumber, Map<String, dynamic> orderData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: _getStatusBgColor(currentStatus, isDark), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          value: statuses.contains(currentStatus.toLowerCase()) ? currentStatus.toLowerCase() : 'pending',
          icon: Icon(Icons.arrow_drop_down, color: _getStatusColor(currentStatus, isDark)),
          style: TextStyle(color: _getStatusColor(currentStatus, isDark), fontWeight: FontWeight.bold, fontSize: 11),
          onChanged: (String? newStatus) async {
            if (newStatus != null) {
              await orderService.updateOrderStatus(
                context: context,
                orderRef: orderRef,
                newStatus: newStatus,
                currentStatus: currentStatus,
                userId: userId,
                orderId: orderId,
                total: total,
                orderNumber: orderNumber,
                orderData: orderData,
                onError: (err) {},
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
              }
            }
          },
          items: statuses.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase()))).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'completed': return isDark ? Colors.greenAccent : Colors.green;
      case 'cancelled': return isDark ? Colors.redAccent : Colors.red;
      case 'shipping': return isDark ? Colors.blueAccent : Colors.blue;
      default: return isDark ? Colors.orangeAccent : Colors.orange;
    }
  }

  Color _getStatusBgColor(String status, bool isDark) {
    if (isDark) {
      switch (status.toLowerCase()) {
        case 'completed': return Colors.green.withOpacity(0.2);
        case 'cancelled': return Colors.red.withOpacity(0.2);
        case 'shipping': return Colors.blue.withOpacity(0.2);
        default: return Colors.orange.withOpacity(0.2);
      }
    }
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade50;
      case 'cancelled': return Colors.red.shade50;
      case 'shipping': return Colors.blue.shade50;
      default: return Colors.orange.shade50;
    }
  }
}