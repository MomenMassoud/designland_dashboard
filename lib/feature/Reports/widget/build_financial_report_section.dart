import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Reports/widget/summry_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Border;
import '../../../Core/Utils/app.colors.dart';
import '../function/report_function.dart';
import 'build_action_button.dart';
import 'build_empty_state.dart';
import 'build_mobile_info_row.dart';
import 'build_section_header.dart';

class FinancialReportSection extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final String searchQuery;
  final Function(String) onShowMessage;

  const FinancialReportSection({
    super.key,
    required this.selectedDateRange,
    required this.searchQuery,
    required this.onShowMessage,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: BoxBorder.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('payments').snapshots(),
        builder: (context, paymentsSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
            builder: (context, expensesSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('incomes').snapshots(),
                builder: (context, incomesSnap) {
                  // جلب كافة المجموعات المسماة orders سواء المباشرة أو الفرعية users/{userId}/orders
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
                    builder: (context, ordersSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, usersSnap) {
                          if (paymentsSnap.connectionState == ConnectionState.waiting ||
                              expensesSnap.connectionState == ConnectionState.waiting ||
                              incomesSnap.connectionState == ConnectionState.waiting ||
                              ordersSnap.connectionState == ConnectionState.waiting ||
                              usersSnap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(50),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final paymentDocs = paymentsSnap.data?.docs ?? [];
                          final expenseDocs = expensesSnap.data?.docs ?? [];
                          final incomeDocs = incomesSnap.data?.docs ?? [];
                          final orderDocs = ordersSnap.data?.docs ?? [];
                          final userDocs = usersSnap.data?.docs ?? [];

                          // 1. خريطة للمستخدمين من كوليكشن users
                          final Map<String, String> usersMap = {};
                          for (var doc in userDocs) {
                            final uData = doc.data() as Map<String, dynamic>;
                            final name = (uData['name'] ?? uData['customerName'] ?? uData['fullName'] ?? '').toString();
                            usersMap[doc.id] = name;
                            if (uData['uid'] != null) {
                              usersMap[uData['uid'].toString()] = name;
                            }
                          }

                          // 2. خريطة الأوردرات استناداً إلى CollectionGroup
                          final Map<String, Map<String, dynamic>> ordersInfoMap = {};
                          for (var doc in orderDocs) {
                            final oData = doc.data() as Map<String, dynamic>;
                            final orderNo = oData['orderNumber'] != null ? "#${oData['orderNumber']}" : '';

                            // استخراج userId بأمان لتجنب استدعاء .parent في Flutter Web
                            String userId = (oData['userId'] ?? '').toString();
                            if (userId.isEmpty) {
                              final pathSegments = doc.reference.path.split('/');
                              // المسار: users / {userId} / orders / {orderId}
                              if (pathSegments.length >= 4 && pathSegments[0] == 'users' && pathSegments[2] == 'orders') {
                                userId = pathSegments[1];
                              }
                            }

                            // تحديد اسم العميل
                            String customerName = '';

                            // أ) إذا كان الأوردر مانوال أو يحتوي على customerName صريح
                            if (oData['customerName'] != null && oData['customerName'].toString().isNotEmpty) {
                              customerName = oData['customerName'].toString();
                            }
                            // ب) أو البحث داخل selectedAddress
                            else if (oData['selectedAddress'] != null && oData['selectedAddress'] is Map) {
                              final addr = oData['selectedAddress'] as Map<String, dynamic>;
                              customerName = (addr['fullName'] ?? addr['name'] ?? '').toString();
                            }

                            // جـ) إذا لم يجد اسماً في الأوردر، يبحث في خريطة usersMap بواسطة userId
                            if (customerName.isEmpty && userId.isNotEmpty) {
                              customerName = usersMap[userId] ?? '';
                            }

                            ordersInfoMap[doc.id] = {
                              'orderNumber': orderNo,
                              'customerName': customerName,
                              'userId': userId,
                            };
                          }

                          final combinedList = _buildFinancialList(
                            paymentDocs,
                            expenseDocs,
                            incomeDocs,
                            ordersInfoMap,
                            usersMap,
                          );

                          double totalIncome = 0;
                          double totalExpense = 0;

                          for (final item in combinedList) {
                            final amount = toDouble(item['amount']);
                            final category = item['category'];

                            if (category == 'Payment In' || category == 'General Income') {
                              totalIncome += amount;
                            } else {
                              totalExpense += amount;
                            }
                          }

                          final net = totalIncome - totalExpense;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildSectionHeader(
                                context: context,
                                title: "Financial Ledger",
                                subtitle:
                                "Track payments, general income, and expenses accurately.",
                                icon: Icons.account_balance_wallet_outlined,
                                iconColor: Colors.green,
                                actions: [
                                  buildActionButton(
                                    label: "Add Income",
                                    icon: Icons.add_card_rounded,
                                    color: Colors.teal,
                                    onPressed: () => _showAddIncomeDialog(context),
                                  ),
                                  buildActionButton(
                                    label: "Add Expense",
                                    icon: Icons.add_rounded,
                                    color: AppColors.primaryPurple,
                                    onPressed: () => _showAddExpenseDialog(context),
                                  ),
                                  buildActionButton(
                                    label: "Export Excel",
                                    icon: Icons.table_chart_rounded,
                                    color: Colors.green,
                                    onPressed: () {
                                      if (!kIsWeb) {
                                        onShowMessage("Excel export is available on Web.");
                                        return;
                                      }
                                      exportFinancialExcel();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildFinancialSummary(
                                context,
                                totalIncome,
                                totalExpense,
                                net,
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.shade200),
                              const SizedBox(height: 16),
                              if (combinedList.isEmpty)
                                buildEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: "No Financial Records",
                                  subtitle: "No records match the current filters.",
                                )
                              else if (mobile)
                                _buildFinancialMobileList(combinedList)
                              else
                                _buildFinancialDesktopTable(combinedList),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _buildFinancialList(
      List<QueryDocumentSnapshot> paymentDocs,
      List<QueryDocumentSnapshot> expenseDocs,
      List<QueryDocumentSnapshot> incomeDocs,
      Map<String, Map<String, dynamic>> ordersInfoMap,
      Map<String, String> usersMap,
      ) {
    final list = <Map<String, dynamic>>[];

    Map<String, String> resolveOrderAndUser(String rawOrderId, String rawUserId) {
      String displayOrderNo = '';
      String customerName = '';

      if (rawOrderId.isNotEmpty && ordersInfoMap.containsKey(rawOrderId)) {
        final orderInfo = ordersInfoMap[rawOrderId]!;
        displayOrderNo = orderInfo['orderNumber'].toString();
        customerName = orderInfo['customerName'].toString();
        if (rawUserId.isEmpty) {
          rawUserId = orderInfo['userId'].toString();
        }
      }

      if (customerName.isEmpty && rawUserId.isNotEmpty) {
        customerName = usersMap[rawUserId] ?? '';
      }

      if (customerName.isEmpty) {
        customerName = rawUserId.isNotEmpty ? shortId(rawUserId) : '-';
      }

      if (displayOrderNo.isEmpty && rawOrderId.isNotEmpty) {
        displayOrderNo = shortId(rawOrderId);
      }

      return {
        'orderNo': displayOrderNo,
        'customerName': customerName,
        'userId': rawUserId,
      };
    }

    for (final doc in paymentDocs) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      final createdAt = data['createdAt'] ?? data['timestamp'] ?? data['date'];

      if (!matchesDateFilter(createdAt, selectedDateRange)) continue;

      final notes = data['notes'] ?? 'Order Payment';
      final rawOrderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
      final rawUserId = (data['userId'] ?? '').toString();

      final resolved = resolveOrderAndUser(rawOrderId, rawUserId);

      if (!matchesSearch([
        doc.id,
        "Payment In",
        notes.toString(),
        rawOrderId,
        resolved['orderNo']!,
        resolved['userId']!,
        resolved['customerName']!,
      ], searchQuery)) {
        continue;
      }

      list.add({
        'id': doc.id,
        'category': 'Payment In',
        'notes': notes,
        'orderId': resolved['orderNo'],
        'userId': resolved['userId'],
        'userName': resolved['customerName'],
        'amount': toDouble(data['amount']),
        'createdAt': createdAt,
      });
    }

    for (final doc in incomeDocs) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      final createdAt = data['createdAt'] ?? data['date'];

      if (!matchesDateFilter(createdAt, selectedDateRange)) continue;

      final notes = data['notes'] ?? data['title'] ?? 'Income';
      final rawOrderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
      final rawUserId = (data['userId'] ?? '').toString();

      final resolved = resolveOrderAndUser(rawOrderId, rawUserId);

      if (!matchesSearch([
        doc.id,
        "General Income",
        notes.toString(),
        rawOrderId,
        resolved['orderNo']!,
        resolved['userId']!,
        resolved['customerName']!,
      ], searchQuery)) {
        continue;
      }

      list.add({
        'id': doc.id,
        'category': 'General Income',
        'notes': notes,
        'orderId': resolved['orderNo'],
        'userId': resolved['userId'],
        'userName': resolved['customerName'],
        'amount': toDouble(data['amount']),
        'createdAt': createdAt,
      });
    }

    for (final doc in expenseDocs) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      final createdAt = data['createdAt'] ?? data['date'];
      final rawOrderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
      final rawUserId = (data['userId'] ?? '').toString();
      final category = rawOrderId.isNotEmpty ? 'Order Expense' : 'General Expense';

      if (!matchesDateFilter(createdAt, selectedDateRange)) continue;

      final notes = data['notes'] ?? data['title'] ?? 'Expense';
      final resolved = resolveOrderAndUser(rawOrderId, rawUserId);

      if (!matchesSearch([
        doc.id,
        category,
        notes.toString(),
        rawOrderId,
        resolved['orderNo']!,
        resolved['userId']!,
        resolved['customerName']!,
      ], searchQuery)) {
        continue;
      }

      list.add({
        'id': doc.id,
        'category': category,
        'notes': notes,
        'orderId': resolved['orderNo'],
        'userId': resolved['userId'],
        'userName': resolved['customerName'],
        'amount': toDouble(data['amount']),
        'createdAt': createdAt,
      });
    }

    list.sort((a, b) {
      final dateA = parseDate(a['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = parseDate(b['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return list;
  }

  Widget _buildFinancialSummary(
      BuildContext context,
      double income,
      double expense,
      double net,
      ) {
    final mobile = isMobile(context);

    final cards = [
      summaryCard(
        title: "Total Income",
        value: money(income),
        icon: Icons.trending_up_rounded,
        color: Colors.green,
      ),
      summaryCard(
        title: "Total Expenses",
        value: money(expense),
        icon: Icons.trending_down_rounded,
        color: Colors.red,
      ),
      summaryCard(
        title: "Net Balance",
        value: money(net),
        icon: Icons.account_balance_rounded,
        color: net >= 0 ? Colors.blue : Colors.orange,
      ),
    ];

    if (mobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: SizedBox(
              width: double.infinity,
              child: card,
            ),
          ),
        )
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildFinancialDesktopTable(List<Map<String, dynamic>> list) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: BoxBorder.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.bgLight),
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text("Transaction ID")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Description")),
            DataColumn(label: Text("Order Number")),
            DataColumn(label: Text("Customer Name")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Date")),
          ],
          rows: list.map((item) {
            final category = item['category'].toString();
            final isIncome =
                category == 'Payment In' || category == 'General Income';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    shortId(item['id']),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(_buildCategoryChip(category)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      item['notes'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(item['orderId'].toString().isEmpty
                      ? "-"
                      : item['orderId'].toString()),
                ),
                DataCell(
                  Text(
                    item['userName'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(
                  Text(
                    "${isIncome ? '+' : '-'}${money(toDouble(item['amount']))}",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                DataCell(
                  Text(formatDateTime(item['createdAt'])),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialMobileList(List<Map<String, dynamic>> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildFinancialCard(list[index]);
      },
    );
  }

  Widget _buildFinancialCard(Map<String, dynamic> item) {
    final category = item['category'].toString();
    final isIncome = category == 'Payment In' || category == 'General Income';
    final amount = toDouble(item['amount']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: BoxBorder.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCategoryChip(category),
              const Spacer(),
              Text(
                "${isIncome ? '+' : '-'}${money(amount)}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          mobileInfoRow(
            Icons.description_outlined,
            "Description",
            item['notes'].toString(),
          ),
          mobileInfoRow(
            Icons.shopping_bag_outlined,
            "Order Number",
            item['orderId'].toString().isEmpty
                ? "-"
                : item['orderId'].toString(),
          ),
          mobileInfoRow(
            Icons.person_outline_rounded,
            "Customer Name",
            item['userName'].toString(),
          ),
          mobileInfoRow(
            Icons.access_time_rounded,
            "Date",
            formatDateTime(item['createdAt']),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "ID: ${shortId(item['id'])}",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color = Colors.green;

    if (category == 'General Income') {
      color = Colors.teal;
    } else if (category == 'Order Expense') {
      color = Colors.orange;
    } else if (category == 'General Expense') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final notesController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 500 ? 14 : 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.primaryPurple,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text("Add General Expense"),
              ),
            ],
          ),
          content: SizedBox(
            width: width < 600 ? width - 50 : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Notes / Description",
                    hintText: "e.g. Servers / Shipping",
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount",
                    suffixText: "EGP",
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (notesController.text.trim().isEmpty ||
                    amountController.text.trim().isEmpty) {
                  return;
                }

                final amount = double.tryParse(amountController.text.trim()) ?? 0;

                await FirebaseFirestore.instance.collection('expenses').add({
                  'amount': amount,
                  'notes': notesController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'orderId': null,
                  'userId': null,
                });

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Save Expense"),
            ),
          ],
        );
      },
    );
  }

  void _showAddIncomeDialog(BuildContext context) {
    final notesController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 500 ? 14 : 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.teal,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text("Add General Income"),
              ),
            ],
          ),
          content: SizedBox(
            width: width < 600 ? width - 50 : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Notes / Description",
                    hintText: "e.g. Investment / Additional Capital",
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount",
                    suffixText: "EGP",
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (notesController.text.trim().isEmpty ||
                    amountController.text.trim().isEmpty) {
                  return;
                }

                final amount = double.tryParse(amountController.text.trim()) ?? 0;

                await FirebaseFirestore.instance.collection('incomes').add({
                  'amount': amount,
                  'notes': notesController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'orderId': null,
                  'userId': null,
                });

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Save Income"),
            ),
          ],
        );
      },
    );
  }
}