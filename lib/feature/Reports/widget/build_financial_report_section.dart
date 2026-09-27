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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final cardBackgroundColor = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 22),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: BoxBorder.all(
          color: borderColor,
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

                          final Map<String, String> usersMap = {};
                          for (var doc in userDocs) {
                            final uData = doc.data() as Map<String, dynamic>;
                            final name = (uData['name'] ?? uData['customerName'] ?? uData['fullName'] ?? '').toString();
                            usersMap[doc.id] = name;
                            if (uData['uid'] != null) {
                              usersMap[uData['uid'].toString()] = name;
                            }
                          }

                          final Map<String, Map<String, dynamic>> ordersInfoMap = {};
                          for (var doc in orderDocs) {
                            final oData = doc.data() as Map<String, dynamic>;
                            final orderNo = oData['orderNumber'] != null ? "#${oData['orderNumber']}" : '';

                            String userId = (oData['userId'] ?? '').toString();
                            if (userId.isEmpty) {
                              final pathSegments = doc.reference.path.split('/');
                              if (pathSegments.length >= 4 && pathSegments[0] == 'users' && pathSegments[2] == 'orders') {
                                userId = pathSegments[1];
                              }
                            }

                            String customerName = '';

                            if (oData['customerName'] != null && oData['customerName'].toString().isNotEmpty) {
                              customerName = oData['customerName'].toString();
                            } else if (oData['selectedAddress'] != null && oData['selectedAddress'] is Map) {
                              final addr = oData['selectedAddress'] as Map<String, dynamic>;
                              customerName = (addr['fullName'] ?? addr['name'] ?? '').toString();
                            }

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
                                    context: context,
                                    label: "Add Income",
                                    icon: Icons.add_card_rounded,
                                    color: Colors.teal,
                                    onPressed: () => _showAddIncomeDialog(context),
                                  ),
                                  buildActionButton(
                                    context: context,
                                    label: "Add Expense",
                                    icon: Icons.add_rounded,
                                    color: AppColors.primaryPurple,
                                    onPressed: () => _showAddExpenseDialog(context),
                                  ),
                                  buildActionButton(
                                    context: context,
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
                              Divider(color: borderColor),
                              const SizedBox(height: 16),
                              if (combinedList.isEmpty)
                                buildEmptyState(
                                  context: context,
                                  icon: Icons.receipt_long_outlined,
                                  title: "No Financial Records",
                                  subtitle: "No records match the current filters.",
                                )
                              else if (mobile)
                                _buildFinancialMobileList(context, combinedList)
                              else
                                _buildFinancialDesktopTable(context, combinedList),
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
        context: context,
        title: "Total Income",
        value: money(income),
        icon: Icons.trending_up_rounded,
        color: Colors.green,
      ),
      summaryCard(
        context: context,
        title: "Total Expenses",
        value: money(expense),
        icon: Icons.trending_down_rounded,
        color: Colors.red,
      ),
      summaryCard(
        context: context,
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

  Widget _buildFinancialDesktopTable(
      BuildContext context, List<Map<String, dynamic>> list) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final tableHeaderBg = isDarkMode ? Colors.grey.shade900 : AppColors.bgLight;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: BoxBorder.all(
          color: borderColor,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(tableHeaderBg),
          columnSpacing: 28,
          columns: [
            DataColumn(label: Text("Transaction ID", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Type", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Description", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Order Number", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Customer Name", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Amount", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Date", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
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
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
                DataCell(_buildCategoryChip(context, category)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      item['notes'].toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    item['orderId'].toString().isEmpty
                        ? "-"
                        : item['orderId'].toString(),
                    style: TextStyle(color: textColor),
                  ),
                ),
                DataCell(
                  Text(
                    item['userName'].toString(),
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
                DataCell(
                  Text(
                    "${isIncome ? '+' : '-'}${money(toDouble(item['amount']))}",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isIncome
                          ? (isDarkMode ? Colors.greenAccent : Colors.green)
                          : (isDarkMode ? Colors.redAccent : Colors.red),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatDateTime(item['createdAt']),
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialMobileList(
      BuildContext context, List<Map<String, dynamic>> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildFinancialCard(context, list[index]);
      },
    );
  }

  Widget _buildFinancialCard(BuildContext context, Map<String, dynamic> item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final category = item['category'].toString();
    final isIncome = category == 'Payment In' || category == 'General Income';
    final amount = toDouble(item['amount']);

    final cardBg = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: BoxBorder.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCategoryChip(context, category),
              const Spacer(),
              Text(
                "${isIncome ? '+' : '-'}${money(amount)}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isIncome
                      ? (isDarkMode ? Colors.greenAccent : Colors.green)
                      : (isDarkMode ? Colors.redAccent : Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          mobileInfoRow(
            context,
            Icons.description_outlined,
            "Description",
            item['notes'].toString(),
          ),
          mobileInfoRow(
            context,
            Icons.shopping_bag_outlined,
            "Order Number",
            item['orderId'].toString().isEmpty
                ? "-"
                : item['orderId'].toString(),
          ),
          mobileInfoRow(
            context,
            Icons.person_outline_rounded,
            "Customer Name",
            item['userName'].toString(),
          ),
          mobileInfoRow(
            context,
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
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color color = Colors.green;

    if (category == 'General Income') {
      color = Colors.teal;
    } else if (category == 'Order Expense') {
      color = Colors.orange;
    } else if (category == 'General Expense') {
      color = Colors.red;
    }

    final effectiveColor = isDarkMode
        ? (color == Colors.green
        ? Colors.greenAccent
        : color == Colors.red
        ? Colors.redAccent
        : color)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(isDarkMode ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final notesController = TextEditingController();
    final amountController = TextEditingController();

    final List<String> categories = [
      'Products & Raw Materials',
      'Packaging',
      'Production',
      'Delivery & Logistics',
      'Marketing & Advertising',
      'Website & Technology',
      'Salaries & Freelancers',
      'Administrative Expenses',
      'Refunds & Replacements',
      'Equipment & Maintenance',
      'Bank & Payment Fees',
      'Other Expenses',
    ];

    String selectedCategory = categories.first;

    showDialog(
      context: context,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final theme = Theme.of(context);

        final dialogBg = isDarkMode ? theme.cardColor : Colors.white;
        final titleTextColor = isDarkMode ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              insetPadding: EdgeInsets.symmetric(
                horizontal: width < 500 ? 14 : 40,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Add General Expense",
                      style: TextStyle(color: titleTextColor),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: width < 600 ? width - 50 : 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: dialogBg,
                      style: TextStyle(color: titleTextColor),
                      decoration: InputDecoration(
                        labelText: "Category",
                        labelStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400),
                        ),
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                                fontSize: 14, color: titleTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      style: TextStyle(color: titleTextColor),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: "Amount",
                        labelStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                        suffixText: "EGP",
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400),
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
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : null),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (amountController.text.trim().isEmpty) {
                      return;
                    }

                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;
                    final formattedNotes = "$selectedCategory";

                    await FirebaseFirestore.instance.collection('expenses').add({
                      'amount': amount,
                      'notes': formattedNotes,
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
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final theme = Theme.of(context);

        final dialogBg = isDarkMode ? theme.cardColor : Colors.white;
        final titleTextColor = isDarkMode ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: dialogBg,
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 500 ? 14 : 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Add General Income",
                  style: TextStyle(color: titleTextColor),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: width < 600 ? width - 50 : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  style: TextStyle(color: titleTextColor),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount",
                    labelStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700),
                    suffixText: "EGP",
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade400),
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
              child: Text(
                "Cancel",
                style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : null),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (amountController.text.trim().isEmpty) {
                  return;
                }

                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;

                await FirebaseFirestore.instance.collection('incomes').add({
                  'amount': amount,
                  'notes': "order",
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