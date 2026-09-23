import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';

enum ReportType { combinedFinancial, orders, users }

class ReportWidget extends StatefulWidget {
  const ReportWidget({super.key});

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
  List<String> _permision = [];
  DateTimeRange? _selectedDateRange;
  String _searchQuery = "";
  ReportType _selectedReportType = ReportType.combinedFinancial;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  void _loadPermissions() async {
    _permision = await GetPermisionUser();
    setState(() {});
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd hh:mm a').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('yyyy-MM-dd hh:mm a').format(timestamp);
    }
    return "N/A";
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("reports")
        ? Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Comprehensive Financial Reports",
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Order Expenses, General Expenses & Revenue Logs",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterHeader(),
            const SizedBox(height: 24),
            _buildSelectedReportView(),
          ],
        ),
      ),
    )
        : AccessDefindView();
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ReportType>(
                value: _selectedReportType,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryPurple),
                onChanged: (ReportType? newValue) {
                  if (newValue != null) setState(() => _selectedReportType = newValue);
                },
                items: const [
                  DropdownMenuItem(
                    value: ReportType.combinedFinancial,
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text("Financial Ledger & Expenses", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ReportType.orders,
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Orders & Manual Orders", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ReportType.users,
                    child: Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 20, color: AppColors.primaryPurple),
                        SizedBox(width: 8),
                        Text("Users Report", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.date_range, color: AppColors.primaryPurple),
            label: Text(
              _selectedDateRange == null
                  ? "Filter by Date (All Time)"
                  : "${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}",
              style: const TextStyle(color: AppColors.textDark),
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null) setState(() => _selectedDateRange = picked);
            },
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => _selectedDateRange = null),
            ),
          SizedBox(
            width: 250,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedReportView() {
    switch (_selectedReportType) {
      case ReportType.combinedFinancial:
        return _buildCombinedFinancialSection();
      case ReportType.orders:
        return _buildOrdersReportSection();
      case ReportType.users:
        return _buildUsersReportSection();
    }
  }

  // ===========================================================================
  // 1. UNIFIED FINANCIAL LEDGER (المصروفات بأنواعها + المقبوضات)
  // ===========================================================================
  Widget _buildCombinedFinancialSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Combined Financial Ledger", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Shows Order Expenses, External Expenses & Payments", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text("Add General Expense", style: TextStyle(color: Colors.white)),
                    onPressed: () => _showAddExpenseDialog(),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(Icons.table_chart, color: Colors.white, size: 18),
                    label: const Text("Export Excel Sheet", style: TextStyle(color: Colors.white)),
                    onPressed: () => _exportFinancialExcel(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('payments').snapshots(),
            builder: (context, paymentsSnap) {
              final paymentDocs = paymentsSnap.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                builder: (context, expensesSnap) {
                  final expenseDocs = expensesSnap.data?.docs ?? [];

                  if (paymentsSnap.connectionState == ConnectionState.waiting || expensesSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> combinedList = [];

                  // 1. مدفوعات الأوردرات (Income)
                  for (var doc in paymentDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    combinedList.add({
                      'id': doc.id,
                      'category': 'Payment In',
                      'notes': data['notes'] ?? 'Order Payment',
                      'orderId': data['orderId'] ?? '',
                      'userId': data['userId'] ?? '',
                      'amount': (data['amount'] ?? 0).toDouble(),
                      'createdAt': data['createdAt'] ?? data['timestamp'] ?? data['date'],
                    });
                  }

                  // 2. المصروفات (Expenses - سواء مرتبط بأوردر أو خارجي)
                  for (var doc in expenseDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String orderId = data['orderId'] ?? '';
                    final bool isOrderExpense = orderId.isNotEmpty;

                    combinedList.add({
                      'id': doc.id,
                      'category': isOrderExpense ? 'Order Expense' : 'General Expense',
                      'notes': data['notes'] ?? data['title'] ?? 'Expense',
                      'orderId': orderId,
                      'userId': data['userId'] ?? '',
                      'amount': (data['amount'] ?? 0).toDouble(),
                      'createdAt': data['createdAt'] ?? data['date'],
                    });
                  }

                  // الترتيب حسب الوقت (الأحدث أولاً)
                  combinedList.sort((a, b) {
                    DateTime dtA = (a['createdAt'] is Timestamp) ? (a['createdAt'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                    DateTime dtB = (b['createdAt'] is Timestamp) ? (b['createdAt'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                    return dtB.compareTo(dtA);
                  });

                  if (combinedList.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No Records Found")));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Transaction ID")),
                        DataColumn(label: Text("Type")),
                        DataColumn(label: Text("Notes / Description")),
                        DataColumn(label: Text("Order ID")),
                        DataColumn(label: Text("User ID")),
                        DataColumn(label: Text("Amount")),
                        DataColumn(label: Text("Date & Time")),
                      ],
                      rows: combinedList.map((item) {
                        final String category = item['category'];
                        final bool isIncome = category == 'Payment In';
                        final bool isOrderExpense = category == 'Order Expense';

                        Color chipColor = Colors.green;
                        if (isOrderExpense) chipColor = Colors.orange;
                        if (category == 'General Expense') chipColor = Colors.red;

                        return DataRow(cells: [
                          DataCell(Text("#${item['id'].toString().substring(0, item['id'].toString().length > 8 ? 8 : item['id'].toString().length)}")),
                          DataCell(Chip(
                            label: Text(category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: chipColor,
                          )),
                          DataCell(Text(item['notes'])),
                          DataCell(Text(item['orderId'].isNotEmpty ? "#${item['orderId'].toString().substring(0, item['orderId'].toString().length > 8 ? 8 : item['orderId'].toString().length)}" : "-")),
                          DataCell(Text(item['userId'].isNotEmpty ? "#${item['userId'].toString().substring(0, item['userId'].toString().length > 8 ? 8 : item['userId'].toString().length)}" : "-")),
                          DataCell(Text(
                            "${isIncome ? '+' : '-'}${item['amount'].toStringAsFixed(2)} EGP",
                            style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                          )),
                          DataCell(Text(_formatDateTime(item['createdAt']))),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. ORDERS REPORT SECTION
  // ===========================================================================
  Widget _buildOrdersReportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Orders Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.table_chart, color: Colors.white, size: 18),
                label: const Text("Export Excel Sheet", style: TextStyle(color: Colors.white)),
                onPressed: () => _exportOrdersExcel(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('manual_orders').snapshots(),
            builder: (context, manualSnap) {
              final manualDocs = manualSnap.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, usersSnap) {
                  final userDocs = usersSnap.data?.docs ?? [];

                  return FutureBuilder<List<QuerySnapshot>>(
                    future: Future.wait(userDocs.map((u) => u.reference.collection('orders').get())),
                    builder: (context, ordersSnapshots) {
                      if (ordersSnapshots.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      List<Map<String, dynamic>> allOrders = [];

                      if (ordersSnapshots.hasData) {
                        for (int i = 0; i < ordersSnapshots.data!.length; i++) {
                          final userData = userDocs[i].data() as Map<String, dynamic>? ?? {};
                          for (var oDoc in ordersSnapshots.data![i].docs) {
                            final orderData = oDoc.data() as Map<String, dynamic>;
                            orderData['orderId'] = oDoc.id;
                            orderData['userName'] = userData['name'] ?? 'System User';
                            orderData['type'] = 'System';
                            allOrders.add(orderData);
                          }
                        }
                      }

                      for (var mDoc in manualDocs) {
                        final mData = mDoc.data() as Map<String, dynamic>;
                        mData['orderId'] = mDoc.id;
                        mData['userName'] = mData['customerName'] ?? 'Manual Customer';
                        mData['type'] = 'Manual';
                        allOrders.add(mData);
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Order ID")),
                            DataColumn(label: Text("Type")),
                            DataColumn(label: Text("Customer")),
                            DataColumn(label: Text("Total Price")),
                            DataColumn(label: Text("Date & Time")),
                            DataColumn(label: Text("Status")),
                          ],
                          rows: allOrders.map((order) {
                            return DataRow(cells: [
                              DataCell(Text("#${order['orderId'].toString().substring(0, 8)}")),
                              DataCell(Chip(
                                label: Text(order['type'], style: const TextStyle(color: Colors.white, fontSize: 10)),
                                backgroundColor: order['type'] == 'Manual' ? Colors.purple : Colors.blue,
                              )),
                              DataCell(Text(order['userName'])),
                              DataCell(Text("${(order['totalPrice'] ?? 0.0).toStringAsFixed(2)} EGP")),
                              DataCell(Text(_formatDateTime(order['createdAt'] ?? order['date']))),
                              DataCell(Text(order['status'] ?? 'Pending')),
                            ]);
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. USERS REPORT SECTION
  // ===========================================================================
  Widget _buildUsersReportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Users Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.table_chart, color: Colors.white, size: 18),
                label: const Text("Export Excel Sheet", style: TextStyle(color: Colors.white)),
                onPressed: () => _exportUsersExcel(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              return DataTable(
                columns: const [
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Email")),
                  DataColumn(label: Text("Phone")),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    DataCell(Text(data['name'] ?? 'N/A')),
                    DataCell(Text(data['email'] ?? 'N/A')),
                    DataCell(Text(data['phone'] ?? 'N/A')),
                  ]);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD EXTERNAL EXPENSE DIALOG (مطابق تماماً للهيكلة المتفق عليها)
  // ===========================================================================
  void _showAddExpenseDialog() {
    final notesController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add General Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: notesController, decoration: const InputDecoration(labelText: "Notes / Description (e.g. سيرفرات / شحن)")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (notesController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final amount = int.tryParse(amountController.text) ?? double.tryParse(amountController.text) ?? 0;

                await FirebaseFirestore.instance.collection('expenses').add({
                  'amount': amount,
                  'notes': notesController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'orderId': null, // مصروف عام غير مرتبط بأوردر
                  'userId': null,
                });

                Navigator.pop(ctx);
              }
            },
            child: const Text("Save Expense"),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EXCEL EXPORT ENGINE
  // ===========================================================================
  void _downloadExcelSheet(Excel excel, String fileName) {
    List<int>? fileBytes = excel.save();
    if (fileBytes != null && kIsWeb) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "$fileName.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportFinancialExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Financial_Ledger'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('Transaction ID'),
      TextCellValue('Category'),
      TextCellValue('Notes'),
      TextCellValue('Order ID'),
      TextCellValue('User ID'),
      TextCellValue('Amount'),
      TextCellValue('Date & Time'),
    ]);

    final paymentsSnap = await FirebaseFirestore.instance.collection('payments').get();
    for (var pDoc in paymentsSnap.docs) {
      final data = pDoc.data();
      sheetObject.appendRow([
        TextCellValue(pDoc.id),
        TextCellValue('Payment In'),
        TextCellValue(data['notes'] ?? 'Order Payment'),
        TextCellValue(data['orderId'] ?? ''),
        TextCellValue(data['userId'] ?? ''),
        DoubleCellValue((data['amount'] ?? 0.0).toDouble()),
        TextCellValue(_formatDateTime(data['createdAt'] ?? data['timestamp'] ?? data['date'])),
      ]);
    }

    final expensesSnap = await FirebaseFirestore.instance.collection('expenses').get();
    for (var eDoc in expensesSnap.docs) {
      final data = eDoc.data();
      final String orderId = data['orderId'] ?? '';
      sheetObject.appendRow([
        TextCellValue(eDoc.id),
        TextCellValue(orderId.isNotEmpty ? 'Order Expense' : 'General Expense'),
        TextCellValue(data['notes'] ?? data['title'] ?? 'Expense'),
        TextCellValue(orderId),
        TextCellValue(data['userId'] ?? ''),
        DoubleCellValue( (data['amount'] ?? 0.0).toDouble()*-1),
        TextCellValue(_formatDateTime(data['createdAt'] ?? data['date'])),
      ]);
    }

    _downloadExcelSheet(excel, 'Financial_Ledger_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}');
  }

  Future<void> _exportOrdersExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Orders_Report'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('Order ID'),
      TextCellValue('Type'),
      TextCellValue('Customer Name'),
      TextCellValue('Total Price'),
      TextCellValue('Date & Time'),
      TextCellValue('Status'),
    ]);

    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    for (var uDoc in usersSnap.docs) {
      final ordersSnap = await uDoc.reference.collection('orders').get();
      for (var oDoc in ordersSnap.docs) {
        final data = oDoc.data();
        sheetObject.appendRow([
          TextCellValue(oDoc.id),
          TextCellValue('System'),
          TextCellValue(uDoc.data()['name'] ?? 'N/A'),
          DoubleCellValue((data['totalPrice'] ?? 0.0).toDouble()),
          TextCellValue(_formatDateTime(data['createdAt'] ?? data['date'])),
          TextCellValue(data['status'] ?? 'Pending'),
        ]);
      }
    }

    final manualSnap = await FirebaseFirestore.instance.collection('manual_orders').get();
    for (var mDoc in manualSnap.docs) {
      final data = mDoc.data();
      sheetObject.appendRow([
        TextCellValue(mDoc.id),
        TextCellValue('Manual'),
        TextCellValue(data['customerName'] ?? 'Manual Customer'),
        DoubleCellValue((data['totalPrice'] ?? 0.0).toDouble()),
        TextCellValue(_formatDateTime(data['createdAt'] ?? data['date'])),
        TextCellValue(data['status'] ?? 'Completed'),
      ]);
    }

    _downloadExcelSheet(excel, 'Orders_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}');
  }

  Future<void> _exportUsersExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Users_Report'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('User ID'),
      TextCellValue('Name'),
      TextCellValue('Email'),
      TextCellValue('Phone'),
    ]);

    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    for (var doc in usersSnap.docs) {
      final data = doc.data();
      sheetObject.appendRow([
        TextCellValue(doc.id),
        TextCellValue(data['name'] ?? 'N/A'),
        TextCellValue(data['email'] ?? 'N/A'),
        TextCellValue(data['phone'] ?? 'N/A'),
      ]);
    }

    _downloadExcelSheet(excel, 'Users_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}');
  }
}