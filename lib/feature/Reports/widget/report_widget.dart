import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';

enum ReportType { users, orders, payments, products }

class ReportWidget extends StatefulWidget {
  const ReportWidget({super.key});

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
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
  DateTimeRange? _selectedDateRange;
  String _searchQuery = "";
  ReportType _selectedReportType = ReportType.users;
  String _selectedOrderStatusFilter = "ALL";

  @override
  Widget build(BuildContext context) {
    return _permision.contains("reports")? Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Comprehensive System Reports",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Detailed analytical reports with PDF export",
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
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
    ):AccessDefindView();
  }

  // ===========================================================================
  // 1. FILTER HEADER BAR
  // ===========================================================================
  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ReportType>(
                value: _selectedReportType,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryPurple),
                onChanged: (ReportType? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedReportType = newValue);
                  }
                },
                items: const [
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
                  DropdownMenuItem(
                    value: ReportType.orders,
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text("Orders Report", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ReportType.payments,
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text("Payments Report", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ReportType.products,
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Products Report (Coming Soon)", style: TextStyle(color: Colors.grey)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
              }
            },
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => _selectedDateRange = null),
              tooltip: "Clear Date Filter",
            ),
          SizedBox(
            width: 250,
            child: TextField(
              decoration: InputDecoration(
                hintText: _selectedReportType == ReportType.payments
                    ? "Search Order ID, Notes..."
                    : _selectedReportType == ReportType.orders
                    ? "Search Order ID, Title..."
                    : "Search user, email, phone...",
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
      case ReportType.users:
        return _buildUsersReportSection();
      case ReportType.orders:
        return _buildOrdersReportSection();
      case ReportType.payments:
        return _buildPaymentsReportSection();
      case ReportType.products:
        return const Center(child: Text("Products Report Under Development"));
    }
  }

  // ===========================================================================
  // 2. USERS REPORT SECTION
  // ===========================================================================
  Widget _buildUsersReportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detailed Customers Report",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Showing accounts with role 'user' & their complete activity",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: const Text("Export PDF", style: TextStyle(color: Colors.white)),
                onPressed: () => _generateUsersPdfReport(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .where('role', isEqualTo: 'user')
                .snapshots(),
            builder: (context, userAuthSnap) {
              if (userAuthSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final authDocs = userAuthSnap.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, usersDetailsSnap) {
                  if (usersDetailsSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final detailsDocs = usersDetailsSnap.data?.docs ?? [];
                  List<Map<String, dynamic>> combinedUsers = [];

                  for (var authDoc in authDocs) {
                    final authData = authDoc.data() as Map<String, dynamic>;
                    final uid = authDoc.id;

                    final matchingDetailDoc = detailsDocs
                        .cast<QueryDocumentSnapshot?>()
                        .firstWhere(
                          (d) => d?.id == uid,
                      orElse: () => null,
                    );

                    final detailsData = matchingDetailDoc != null
                        ? (matchingDetailDoc.data() as Map<String, dynamic>? ?? {})
                        : <String, dynamic>{};

                    combinedUsers.add({
                      'uid': uid,
                      'name': authData['name'] ?? detailsData['name'] ?? 'N/A',
                      'email': authData['email'] ?? 'N/A',
                      'role': authData['role'] ?? 'user',
                      'isBlocked': authData['isBlocked'] ?? false,
                      'phone': detailsData['phone'] ?? 'N/A',
                      'addresses': detailsData['addresses'] ?? [],
                    });
                  }

                  if (_searchQuery.isNotEmpty) {
                    combinedUsers = combinedUsers.where((u) {
                      final name = u['name'].toString().toLowerCase();
                      final email = u['email'].toString().toLowerCase();
                      final phone = u['phone'].toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }).toList();
                  }

                  return FutureBuilder<List<QuerySnapshot>>(
                    future: Future.wait(
                      combinedUsers.map((u) => FirebaseFirestore.instance
                          .collection('users')
                          .doc(u['uid'])
                          .collection('orders')
                          .get()),
                    ),
                    builder: (context, ordersSnapshots) {
                      if (ordersSnapshots.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      for (int i = 0; i < combinedUsers.length; i++) {
                        int totalOrders = 0;
                        double totalSpent = 0.0;

                        if (ordersSnapshots.hasData && i < ordersSnapshots.data!.length) {
                          for (var orderDoc in ordersSnapshots.data![i].docs) {
                            final oData = orderDoc.data() as Map<String, dynamic>;
                            Timestamp? createdAt = oData['createdAt'] as Timestamp?;

                            if (_selectedDateRange != null && createdAt != null) {
                              DateTime oDate = createdAt.toDate();
                              if (oDate.isBefore(_selectedDateRange!.start) ||
                                  oDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
                                continue;
                              }
                            }

                            totalOrders++;
                            totalSpent += (oData['totalPrice'] ?? 0.0).toDouble();
                          }
                        }

                        combinedUsers[i]['totalOrders'] = totalOrders;
                        combinedUsers[i]['totalSpent'] = totalSpent;
                      }

                      if (combinedUsers.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: Text("No users found matching current filters.")),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text("User Name", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Email / Role", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Addresses", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Orders Count", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Total Spent", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: combinedUsers.map((user) {
                            final List addresses = user['addresses'] as List;
                            final addressText = addresses
                                .map((a) => "${a['title'] ?? ''}: ${a['details'] ?? ''}")
                                .join(" | ");

                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        "UID: ${user['uid'].toString().substring(0, user['uid'].toString().length > 6 ? 6 : user['uid'].toString().length)}...",
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user['email']),
                                      Text("Role: ${user['role']}",
                                          style: const TextStyle(fontSize: 11, color: Colors.purple)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(user['phone'])),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      addressText.isEmpty ? "No address registered" : addressText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                                DataCell(Center(child: Text("${user['totalOrders']}"))),
                                DataCell(Text("\$${user['totalSpent'].toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: user['isBlocked'] ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user['isBlocked'] ? "Blocked" : "Active",
                                      style: TextStyle(
                                        color: user['isBlocked'] ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. ORDERS REPORT SECTION
  // ===========================================================================
  Widget _buildOrdersReportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Comprehensive Orders Report",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Track active, pending, completed and cancelled orders",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: const Text("Export PDF", style: TextStyle(color: Colors.white)),
                onPressed: () => _generateOrdersPdfReport(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip("ALL", "All Orders", Colors.grey),
              _buildStatusChip("PENDING", "Pending", Colors.orange),
              _buildStatusChip("IN_PROGRESS", "In Progress / Active", Colors.blue),
              _buildStatusChip("COMPLETED", "Completed", Colors.green),
              _buildStatusChip("CANCELLED", "Cancelled", Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnap) {
              if (usersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userDocs = usersSnap.data?.docs ?? [];

              return FutureBuilder<List<QuerySnapshot>>(
                future: Future.wait(
                  userDocs.map((u) => u.reference.collection('orders').get()),
                ),
                builder: (context, ordersSnapshots) {
                  if (ordersSnapshots.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> allOrders = [];

                  if (ordersSnapshots.hasData) {
                    for (int i = 0; i < ordersSnapshots.data!.length; i++) {
                      final uDoc = userDocs[i];
                      final userData = uDoc.data() as Map<String, dynamic>? ?? {};
                      final userName = userData['name'] ?? 'Unknown User';
                      final userPhone = userData['phone'] ?? 'N/A';

                      for (var oDoc in ordersSnapshots.data![i].docs) {
                        final orderData = oDoc.data() as Map<String, dynamic>;
                        orderData['orderId'] = oDoc.id;
                        orderData['userName'] = userName;
                        orderData['userPhone'] = userPhone;
                        orderData['userId'] = uDoc.id;
                        allOrders.add(orderData);
                      }
                    }
                  }

                  if (_selectedDateRange != null) {
                    allOrders = allOrders.where((order) {
                      Timestamp? createdAt = order['createdAt'] as Timestamp?;
                      if (createdAt == null) return false;
                      DateTime oDate = createdAt.toDate();
                      return !oDate.isBefore(_selectedDateRange!.start) &&
                          !oDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }).toList();
                  }

                  if (_selectedOrderStatusFilter != "ALL") {
                    allOrders = allOrders.where((order) {
                      final st = (order['status'] ?? '').toString().toUpperCase();
                      if (_selectedOrderStatusFilter == "PENDING") {
                        return st == 'PENDING';
                      } else if (_selectedOrderStatusFilter == "IN_PROGRESS") {
                        return st != 'CANCELLED' && st != 'COMPLETED' && st != 'DELIVERED' && st != 'PENDING';
                      } else if (_selectedOrderStatusFilter == "COMPLETED") {
                        return st == 'COMPLETED' || st == 'DELIVERED';
                      } else if (_selectedOrderStatusFilter == "CANCELLED") {
                        return st == 'CANCELLED';
                      }
                      return true;
                    }).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    allOrders = allOrders.where((o) {
                      final orderId = o['orderId'].toString().toLowerCase();
                      final userName = o['userName'].toString().toLowerCase();
                      final userPhone = o['userPhone'].toString().toLowerCase();
                      return orderId.contains(_searchQuery) ||
                          userName.contains(_searchQuery) ||
                          userPhone.contains(_searchQuery);
                    }).toList();
                  }

                  allOrders.sort((a, b) {
                    Timestamp? tA = a['createdAt'] as Timestamp?;
                    Timestamp? tB = b['createdAt'] as Timestamp?;
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tB.compareTo(tA);
                  });

                  if (allOrders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("No orders found matching current status/filters.")),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text("Order ID", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Items", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Total Price", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: allOrders.map((order) {
                        final orderId = order['orderId'] ?? '';
                        final userName = order['userName'] ?? 'N/A';
                        final userPhone = order['userPhone'] ?? 'N/A';
                        final status = (order['status'] ?? 'Pending').toString();
                        final totalPrice = (order['totalPrice'] ?? 0.0).toDouble();
                        final List items = order['items'] is List ? (order['items'] as List) : [];

                        Timestamp? createdAt = order['createdAt'] as Timestamp?;
                        final dateStr = createdAt != null
                            ? DateFormat('yyyy/MM/dd hh:mm a').format(createdAt.toDate())
                            : 'N/A';

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                "#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(userPhone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Text("${items.length} item(s)", style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            DataCell(
                              Text(
                                "\$${totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getOrderStatusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getOrderStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PAYMENTS REPORT SECTION (الكولكشن الجديد)
  // ===========================================================================
  Widget _buildPaymentsReportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Transactions & Payments Report",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Real-time financial transactions log from 'payment' collection",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: const Text("Export PDF", style: TextStyle(color: Colors.white)),
                onPressed: () => _generatePaymentsPdfReport(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('payments').snapshots(),
            builder: (context, paymentSnap) {
              if (paymentSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final paymentDocs = paymentSnap.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, usersSnap) {
                  if (usersSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userDocs = usersSnap.data?.docs ?? [];

                  List<Map<String, dynamic>> paymentsList = [];
                  double totalCollectedAmount = 0.0;

                  for (var pDoc in paymentDocs) {
                    final data = pDoc.data() as Map<String, dynamic>;
                    final userId = data['userId'] ?? '';

                    final userMatch = userDocs.cast<QueryDocumentSnapshot?>().firstWhere(
                          (u) => u?.id == userId,
                      orElse: () => null,
                    );

                    final userData = userMatch != null
                        ? (userMatch.data() as Map<String, dynamic>? ?? {})
                        : <String, dynamic>{};

                    paymentsList.add({
                      'paymentId': pDoc.id,
                      'amount': (data['amount'] ?? 0).toDouble(),
                      'notes': data['notes'] ?? 'N/A',
                      'orderId': data['orderId'] ?? 'N/A',
                      'paymentDate': data['paymentDate'] as Timestamp?,
                      'userId': userId,
                      'userName': userData['name'] ?? 'Unknown User',
                      'userPhone': userData['phone'] ?? 'N/A',
                    });
                  }

                  // 1. الفلترة بالتاريخ
                  if (_selectedDateRange != null) {
                    paymentsList = paymentsList.where((p) {
                      Timestamp? pDate = p['paymentDate'];
                      if (pDate == null) return false;
                      DateTime date = pDate.toDate();
                      return !date.isBefore(_selectedDateRange!.start) &&
                          !date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }).toList();
                  }

                  // 2. الفلترة بالبحث
                  if (_searchQuery.isNotEmpty) {
                    paymentsList = paymentsList.where((p) {
                      final orderId = p['orderId'].toString().toLowerCase();
                      final notes = p['notes'].toString().toLowerCase();
                      final userName = p['userName'].toString().toLowerCase();
                      final userPhone = p['userPhone'].toString().toLowerCase();
                      return orderId.contains(_searchQuery) ||
                          notes.contains(_searchQuery) ||
                          userName.contains(_searchQuery) ||
                          userPhone.contains(_searchQuery);
                    }).toList();
                  }

                  // ترتيب التواريخ من الأحدث للأقدم
                  paymentsList.sort((a, b) {
                    Timestamp? tA = a['paymentDate'];
                    Timestamp? tB = b['paymentDate'];
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tB.compareTo(tA);
                  });

                  for (var item in paymentsList) {
                    totalCollectedAmount += item['amount'];
                  }

                  if (paymentsList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("No payments found matching current filters.")),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Revenue Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              "Total Processed Revenue: \$${totalCollectedAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text("Payment ID", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Order ID", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Method / Notes", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Payment Date", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: paymentsList.map((p) {
                            final paymentId = p['paymentId'];
                            final orderId = p['orderId'];
                            final Timestamp? date = p['paymentDate'];
                            final dateStr = date != null
                                ? DateFormat('yyyy/MM/dd hh:mm a').format(date.toDate())
                                : 'N/A';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    "#${paymentId.length > 8 ? paymentId.substring(0, 8) : paymentId}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}",
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(p['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(p['userPhone'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "\$${p['amount'].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p['notes'],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String key, String label, Color color) {
    final bool isSelected = _selectedOrderStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedOrderStatusFilter = key);
        }
      },
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return Colors.red;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // ===========================================================================
  // 5. PDF EXPORT FUNCTIONS
  // ===========================================================================

  Future<void> _generatePaymentsPdfReport() async {
    final pdf = pw.Document();
    final paymentSnap = await FirebaseFirestore.instance.collection('payment').get();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> exportData = [];
    double totalSum = 0.0;

    for (var pDoc in paymentSnap.docs) {
      final data = pDoc.data();
      final userId = data['userId'] ?? '';
      Timestamp? date = data['paymentDate'] as Timestamp?;

      if (_selectedDateRange != null && date != null) {
        DateTime pDate = date.toDate();
        if (pDate.isBefore(_selectedDateRange!.start) ||
            pDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          continue;
        }
      }

      final userMatch = usersSnap.docs.cast<QueryDocumentSnapshot?>().firstWhere(
            (u) => u?.id == userId,
        orElse: () => null,
      );

      final userData = userMatch != null
          ? (userMatch.data() as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};

      final amount = (data['amount'] ?? 0).toDouble();
      totalSum += amount;

      exportData.add({
        'id': pDoc.id.substring(0, pDoc.id.length > 8 ? 8 : pDoc.id.length),
        'orderId': (data['orderId'] ?? 'N/A').toString(),
        'customer': userData['name'] ?? 'Unknown User',
        'amount': amount,
        'notes': data['notes'] ?? 'N/A',
        'date': date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date.toDate()) : 'N/A',
      });
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Payments & Revenue Financial Report",
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Total Revenue: \$${totalSum.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Payment ID', 'Order ID', 'Customer', 'Amount', 'Method/Notes', 'Date'],
                data: exportData
                    .map((p) => [
                  p['id'],
                  p['orderId'].length > 8 ? p['orderId'].substring(0, 8) : p['orderId'],
                  p['customer'],
                  '\$${p['amount'].toStringAsFixed(2)}',
                  p['notes'],
                  p['date'],
                ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Payments_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Payments_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    }
  }

  Future<void> _generateOrdersPdfReport() async {
    final pdf = pw.Document();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> exportOrders = [];

    for (var uDoc in usersSnap.docs) {
      final userData = uDoc.data();
      final userName = userData['name'] ?? 'Unknown';

      final ordersSnap = await uDoc.reference.collection('orders').get();

      for (var oDoc in ordersSnap.docs) {
        final data = oDoc.data();
        final status = (data['status'] ?? 'Pending').toString();
        Timestamp? createdAt = data['createdAt'] as Timestamp?;

        if (_selectedDateRange != null && createdAt != null) {
          DateTime oDate = createdAt.toDate();
          if (oDate.isBefore(_selectedDateRange!.start) ||
              oDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
            continue;
          }
        }

        final stUpper = status.toUpperCase();
        if (_selectedOrderStatusFilter == "PENDING" && stUpper != 'PENDING') continue;
        if (_selectedOrderStatusFilter == "IN_PROGRESS" &&
            (stUpper == 'CANCELLED' || stUpper == 'COMPLETED' || stUpper == 'DELIVERED' || stUpper == 'PENDING')) continue;
        if (_selectedOrderStatusFilter == "COMPLETED" && (stUpper != 'COMPLETED' && stUpper != 'DELIVERED')) continue;
        if (_selectedOrderStatusFilter == "CANCELLED" && stUpper != 'CANCELLED') continue;

        exportOrders.add({
          'id': oDoc.id.substring(0, oDoc.id.length > 8 ? 8 : oDoc.id.length),
          'customer': userName,
          'date': createdAt != null ? DateFormat('yyyy-MM-dd').format(createdAt.toDate()) : 'N/A',
          'itemsCount': data['items'] is List ? (data['items'] as List).length : 0,
          'price': (data['totalPrice'] ?? 0.0).toDouble(),
          'status': status,
        });
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Orders Detailed Report ($_selectedOrderStatusFilter)",
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Order ID', 'Customer', 'Date', 'Items', 'Total Price', 'Status'],
                data: exportOrders
                    .map((o) => [
                  o['id'],
                  o['customer'],
                  o['date'],
                  '${o['itemsCount']}',
                  '\$${o['price'].toStringAsFixed(2)}',
                  o['status'],
                ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Orders_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Orders_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    }
  }

  Future<void> _generateUsersPdfReport() async {
    final pdf = pw.Document();

    final userAuthSnap = await FirebaseFirestore.instance
        .collection('user')
        .where('role', isEqualTo: 'user')
        .get();

    final usersDetailsSnap = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> exportData = [];

    for (var authDoc in userAuthSnap.docs) {
      final authData = authDoc.data();
      final uid = authDoc.id;

      final detailMatch = usersDetailsSnap.docs.cast<QueryDocumentSnapshot?>().firstWhere(
            (d) => d?.id == uid,
        orElse: () => null,
      );

      final detailsData = detailMatch != null
          ? (detailMatch.data() as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};

      final ordersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .get();

      int totalOrders = 0;
      double totalSpent = 0.0;

      for (var oDoc in ordersSnap.docs) {
        final oData = oDoc.data();
        Timestamp? createdAt = oData['createdAt'] as Timestamp?;

        if (_selectedDateRange != null && createdAt != null) {
          DateTime oDate = createdAt.toDate();
          if (oDate.isBefore(_selectedDateRange!.start) ||
              oDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
            continue;
          }
        }

        totalOrders++;
        totalSpent += (oData['totalPrice'] ?? 0.0).toDouble();
      }

      exportData.add({
        'name': authData['name'] ?? detailsData['name'] ?? 'N/A',
        'email': authData['email'] ?? 'N/A',
        'phone': detailsData['phone'] ?? 'N/A',
        'orders': totalOrders,
        'spent': totalSpent,
        'status': authData['isBlocked'] == true ? "Blocked" : "Active",
      });
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Customers System Report (Role: User)",
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Name', 'Email', 'Phone', 'Orders', 'Total Spent', 'Status'],
                data: exportData
                    .map((u) => [
                  u['name'],
                  u['email'],
                  u['phone'],
                  '${u['orders']}',
                  '\$${u['spent'].toStringAsFixed(2)}',
                  u['status'],
                ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Users_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Users_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    }
  }
}