import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_client_data.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/feature/Users/widget/user_details_widget.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Core/Utils/app.colors.dart';

class OrderDetailView extends StatefulWidget {
  final String orderId;
  final String userId;
  final Map<String, dynamic> orderData;

  const OrderDetailView({
    super.key,
    required this.orderId,
    required this.userId,
    required this.orderData,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel _userModel=UserModel(uid: "", email: "", Name: "", role: "");
  Map<String, dynamic> ?data;
  @override
  void initState() {
    super.initState();
    _Start();
  }

  void _Start()async{
    try{
      if(widget.orderData['isManual']==null){
        _userModel=await getClientData(context, widget.userId);
        await _firestore.collection('user').doc(widget.userId).get().then((value){
          data = value.data() as Map<String, dynamic>;
        });
        setState(() {
          _userModel;
        });
      }
    }
    catch(e){
      showErrorDialog(context, "Error", e.toString());
    }
  }
  void _showAddTransactionDialog(BuildContext context, {required bool isExpense}) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isExpense ? "Record New Expense".tr : "Record New Payment Deposit".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isExpense ? "Expense Amount (\$) *" : "Amount Paid (\$) *".tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: isExpense
                    ? "Notes (e.g. Shipping, Printing, Packaging)".tr
                    : "Notes (e.g. Bank Transfer, Instapay, Cash)".tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child:  Text("Cancel".tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isExpense ? Colors.orange.shade800 : AppColors.primaryPurple,
            ),
            onPressed: () async {
              final double? amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final collectionName = isExpense ? 'expenses' : 'payments';
                await _firestore.collection(collectionName).add({
                  'orderId': widget.orderId,
                  'userId': widget.userId,
                  'amount': amount,
                  'notes': notesController.text.isEmpty
                      ? (isExpense ? 'Expense' : 'Deposit')
                      : notesController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${isExpense ? 'Expense'.tr : 'Payment'.tr} ${"recorded successfully!".tr}",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child:  Text("Save Transaction".tr, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderData;
    final List items = order['items'] as List? ?? [];
    final num totalPrice = order['totalPrice'] ?? 0;
    final num discountAmount = order['discountAmount'] ?? 0;
    final String? promoCode = order['promoCode'];

    String formattedDate = 'N/A';
    if (order['createdAt'] is Timestamp) {
      final dt = (order['createdAt'] as Timestamp).toDate();
      formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text("${"Order".tr} #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId}"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ملخص المالية الذكي
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('payments').where('orderId', isEqualTo: widget.orderId).snapshots(),
              builder: (context, paySnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore.collection('expenses').where('orderId', isEqualTo: widget.orderId).snapshots(),
                  builder: (context, expSnap) {
                    final payDocs = paySnap.data?.docs ?? [];
                    final expDocs = expSnap.data?.docs ?? [];

                    num totalPaid = 0;
                    num totalExpenses = 0;

                    for (var doc in payDocs) {
                      totalPaid += (doc.data()['amount'] ?? 0);
                    }
                    for (var doc in expDocs) {
                      totalExpenses += (doc.data()['amount'] ?? 0);
                    }

                    num remaining = totalPrice - totalPaid;
                    num netProfit = totalPrice - totalExpenses;

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text("Financial Summary".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${"Total Price:".tr} $totalPrice EGP", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (promoCode != null)
                                      Text("${"Promo Code:".tr} $promoCode (-$discountAmount) EGP", style: const TextStyle(color: Colors.green, fontSize: 12)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: netProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${"Net Profit:".tr} $netProfit EGP",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: netProfit >= 0 ? Colors.green : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryBadge("Total Paid".tr, "$totalPaid EGP", Colors.green),
                                _buildSummaryBadge("Remaining".tr, "$remaining EGP", remaining > 0 ? Colors.red : Colors.green),
                                _buildSummaryBadge("Expenses".tr, "$totalExpenses EGP", Colors.orange.shade800),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                    label:  Text("Add Payment".tr, style: TextStyle(color: Colors.white)),
                                    onPressed: () => _showAddTransactionDialog(context, isExpense: false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.white),
                                    label:  Text("Add Expense".tr, style: TextStyle(color: Colors.white)),
                                    onPressed: () => _showAddTransactionDialog(context, isExpense: true),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. تفاصيل العميل
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("Customer Info".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    ListTile(
                      title: Text("${"Customer Name:".tr}"
                          " ${order['customerName'] ?? order['userEmail'] ?? _userModel.Name}"),
                      leading: Icon(Icons.person),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: (){
                        Get.to(UserDetailView(userId: widget.userId, userData: data!));
                      },
                    ),

                    const SizedBox(height: 4),
                      ListTile(
                        title:  SelectableText("${"Order Date:".tr} $formattedDate", style: const TextStyle(color: AppColors.textMuted)),
                      ),
                      if (order['selectedAddress'] != null) ...[
                      const SizedBox(height: 8),
                      Text("${"Address:".tr} ${order['selectedAddress']['title'] ?? ''} - ${order['selectedAddress']['details'] ?? ''}",
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. عناصر الطلب والحقول الديناميكية
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("Order Items & Details".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    ...items.map((item) {
                      final map = item is Map<String, dynamic> ? item : {};
                      final customFields = map['customFieldsData'] as Map<String, dynamic>? ?? {};
                      final String notes = map['notes'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${map['title']} (x${map['quantity'] ?? 1})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("${map['price'] ?? 0} EGP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text("${"Notes:".tr} $notes", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                            if (customFields.isNotEmpty) ...[
                              const SizedBox(height: 8),
                               Text("Admin Dynamic Specifications:".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryPurple)),
                              const SizedBox(height: 4),
                              ...customFields.entries.map((entry) {
                                final isLink = entry.value.toString().startsWith('http');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: isLink
                                      ? InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse(entry.value.toString());
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Text("${entry.key}: ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        const Icon(Icons.link, size: 14, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            entry.value.toString(),
                                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : SelectableText("${entry.key}: ${entry.value}", style: const TextStyle(fontSize: 13)),
                                );
                              }),
                            ]
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. سجل الدفعات والمصروفات بالتفصيل
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("Payments History".tr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          const Divider(),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestore.collection('payments').where('orderId', isEqualTo: widget.orderId).snapshots(),
                            builder: (context, snap) {
                              final docs = snap.data?.docs ?? [];
                              if (docs.isEmpty) return  Text("No payments yet.".tr, style: TextStyle(color: Colors.grey, fontSize: 12));

                              return Column(
                                children: docs.map((d) {
                                  final data = d.data();
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text("${data['amount']} EGP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    subtitle: Text(data['notes'] ?? ''),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Expenses History".tr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                          const Divider(),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestore.collection('expenses').where('orderId', isEqualTo: widget.orderId).snapshots(),
                            builder: (context, snap) {
                              final docs = snap.data?.docs ?? [];
                              if (docs.isEmpty) return  Text("No expenses yet.".tr, style: TextStyle(color: Colors.grey, fontSize: 12));

                              return Column(
                                children: docs.map((d) {
                                  final data = d.data();
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text("${data['amount']} EGP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                                    subtitle: Text(data['notes'] ?? ''),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }
}