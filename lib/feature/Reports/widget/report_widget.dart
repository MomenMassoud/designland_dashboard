import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';

enum ReportType {
  combinedFinancial,
  orders,
  users,
}

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

  bool _permissionsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final permissions = await GetPermisionUser();

    if (!mounted) return;

    setState(() {
      _permision = permissions;
      _permissionsLoading = false;
    });
  }

  // ===========================================================================
  // RESPONSIVE HELPERS
  // ===========================================================================

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 700 && width < 1100;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1100;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 12;
    if (width < 1100) return 20;

    return 28;
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return "N/A";

    DateTime? date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    }

    if (date == null) return "N/A";

    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  DateTime? _parseDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    return null;
  }

  bool _matchesDateFilter(dynamic timestamp) {
    if (_selectedDateRange == null) return true;

    final date = _parseDate(timestamp);

    if (date == null) return false;

    final start = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );

    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
      999,
    );

    return !date.isBefore(start) && !date.isAfter(end);
  }

  bool _matchesSearch(List<String> values) {
    if (_searchQuery.trim().isEmpty) return true;

    final query = _searchQuery.toLowerCase().trim();

    return values.any(
          (value) => value.toLowerCase().contains(query),
    );
  }

  String _shortId(dynamic value) {
    final id = value?.toString() ?? "";

    if (id.isEmpty) return "-";

    if (id.length <= 8) return "#$id";

    return "#${id.substring(0, 8)}";
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(double value) {
    return "${value.toStringAsFixed(2)} EGP";
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_permissionsLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_permision.contains("reports")) {
      return  AccessDefindView();
    }

    final mobile = _isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding(context),
            vertical: mobile ? 12 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterHeader(context),
              SizedBox(height: mobile ? 14 : 24),
              _buildSelectedReportView(context),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final mobile = _isMobile(context);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.4,
      toolbarHeight: mobile ? 70 : 78,
      titleSpacing: mobile ? 16 : 24,
      title: Row(
        children: [
          Container(
            width: mobile ? 40 : 46,
            height: mobile ? 40 : 46,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: AppColors.primaryPurple,
              size: mobile ? 21 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Reports & Analytics",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: mobile ? 17 : 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Financial, orders and users reports",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: mobile ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILTER HEADER
  // ===========================================================================

  Widget _buildFilterHeader(BuildContext context) {
    final mobile = _isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: BoxBorder.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            Text(
              "Report Filters",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (mobile)
            _buildReportDropdown(context)
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildReportDropdown(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildDateFilterButton(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildSearchField(context),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(width: 8),
                  _buildClearDateButton(),
                ],
              ],
            ),
          if (mobile) ...[
            const SizedBox(height: 10),
            _buildDateFilterButton(context),
            const SizedBox(height: 10),
            _buildSearchField(context),
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _buildClearDateButton(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildReportDropdown(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(13),
        border: BoxBorder.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportType>(
          value: _selectedReportType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryPurple,
          ),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedReportType = value;
            });
          },
          items: const [
            DropdownMenuItem(
              value: ReportType.combinedFinancial,
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Financial Ledger & Expenses",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ReportType.orders,
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Orders & Manual Orders",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ReportType.users,
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 20,
                    color: AppColors.primaryPurple,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Users Report",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(BuildContext context) {
    final mobile = _isMobile(context);

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(
          Icons.date_range_rounded,
          color: AppColors.primaryPurple,
          size: 20,
        ),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _selectedDateRange == null
                ? "Filter by Date"
                : "${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: mobile ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: _selectedDateRange,
          );

          if (picked != null && mounted) {
            setState(() {
              _selectedDateRange = picked;
            });
          }
        },
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Search reports...",
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 21,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearDateButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _selectedDateRange = null;
        });
      },
      icon: const Icon(
        Icons.close_rounded,
        color: Colors.red,
        size: 18,
      ),
      label: const Text(
        "Clear Date",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }

  // ===========================================================================
  // REPORT SWITCHER
  // ===========================================================================

  Widget _buildSelectedReportView(BuildContext context) {
    switch (_selectedReportType) {
      case ReportType.combinedFinancial:
        return _buildCombinedFinancialSection(context);

      case ReportType.orders:
        return _buildOrdersReportSection(context);

      case ReportType.users:
        return _buildUsersReportSection(context);
    }
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    List<Widget> actions = const [],
  }) {
    final mobile = _isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: mobile ? 42 : 46,
              height: mobile ? 42 : 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: mobile ? 21 : 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: mobile ? 17 : 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: mobile ? 11 : 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          if (mobile)
            Column(
              children: actions
                  .map(
                    (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: action,
                  ),
                ),
              )
                  .toList(),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SUMMARY CARD
  // ===========================================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(15),
        border: BoxBorder.all(
          color: color.withOpacity(.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FINANCIAL REPORT
  // ===========================================================================

  Widget _buildCombinedFinancialSection(BuildContext context) {
    final mobile = _isMobile(context);

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
        stream: FirebaseFirestore.instance
            .collection('payments')
            .snapshots(),
        builder: (context, paymentsSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expenses')
                .snapshots(),
            builder: (context, expensesSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('incomes')
                    .snapshots(),
                builder: (context, incomesSnap) {
                  if (paymentsSnap.connectionState ==
                      ConnectionState.waiting ||
                      expensesSnap.connectionState ==
                          ConnectionState.waiting ||
                      incomesSnap.connectionState ==
                          ConnectionState.waiting) {
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

                  final combinedList =
                  _buildFinancialList(
                    paymentDocs,
                    expenseDocs,
                    incomeDocs,
                  );

                  double totalIncome = 0;
                  double totalExpense = 0;

                  for (final item in combinedList) {
                    final amount = _toDouble(item['amount']);

                    final category = item['category'];

                    if (category == 'Payment In' ||
                        category == 'General Income') {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;
                    }
                  }

                  final net = totalIncome - totalExpense;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context: context,
                        title: "Financial Ledger",
                        subtitle:
                        "Track payments, income and expenses in one place.",
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.green,
                        actions: [
                          _buildActionButton(
                            label: "Add Income",
                            icon: Icons.add_card_rounded,
                            color: Colors.teal,
                            onPressed: _showAddIncomeDialog,
                          ),
                          _buildActionButton(
                            label: "Add Expense",
                            icon: Icons.add_rounded,
                            color: AppColors.primaryPurple,
                            onPressed: _showAddExpenseDialog,
                          ),
                          _buildActionButton(
                            label: "Export Excel",
                            icon: Icons.table_chart_rounded,
                            color: Colors.green,
                            onPressed: () {
                              if (!kIsWeb) {
                                _showMessage(
                                  "Excel export is available on Web.",
                                );
                                return;
                              }

                              _exportFinancialExcel();
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
                      Divider(
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 16),
                      if (combinedList.isEmpty)
                        _buildEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: "No Financial Records",
                          subtitle:
                          "No records match the current filters.",
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
      ),
    );
  }

  List<Map<String, dynamic>> _buildFinancialList(
      List<QueryDocumentSnapshot> paymentDocs,
      List<QueryDocumentSnapshot> expenseDocs,
      List<QueryDocumentSnapshot> incomeDocs,
      ) {
    final list = <Map<String, dynamic>>[];

    for (final doc in paymentDocs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );

      final createdAt =
          data['createdAt'] ?? data['timestamp'] ?? data['date'];

      if (!_matchesDateFilter(createdAt)) continue;

      final notes = data['notes'] ?? 'Order Payment';
      final orderId = data['orderId'] ?? '';
      final userId = data['userId'] ?? '';

      if (!_matchesSearch([
        doc.id,
        "Payment In",
        notes.toString(),
        orderId.toString(),
        userId.toString(),
      ])) {
        continue;
      }

      list.add({
        'id': doc.id,
        'category': 'Payment In',
        'notes': notes,
        'orderId': orderId,
        'userId': userId,
        'amount': _toDouble(data['amount']),
        'createdAt': createdAt,
      });
    }

    for (final doc in incomeDocs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );

      final createdAt = data['createdAt'] ?? data['date'];

      if (!_matchesDateFilter(createdAt)) continue;

      final notes = data['notes'] ?? data['title'] ?? 'Income';
      final orderId = data['orderId'] ?? '';
      final userId = data['userId'] ?? '';

      if (!_matchesSearch([
        doc.id,
        "General Income",
        notes.toString(),
        orderId.toString(),
        userId.toString(),
      ])) {
        continue;
      }

      list.add({
        'id': doc.id,
        'category': 'General Income',
        'notes': notes,
        'orderId': orderId,
        'userId': userId,
        'amount': _toDouble(data['amount']),
        'createdAt': createdAt,
      });
    }

    for (final doc in expenseDocs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );

      final createdAt = data['createdAt'] ?? data['date'];
      final orderId = data['orderId'] ?? '';
      final category =
      orderId.toString().isNotEmpty
          ? 'Order Expense'
          : 'General Expense';

      if (!_matchesDateFilter(createdAt)) continue;

      final notes = data['notes'] ?? data['title'] ?? 'Expense';
      final userId = data['userId'] ?? '';

      if (!_matchesSearch([
        doc.id,
        category,
        notes.toString(),
        orderId.toString(),
        userId.toString(),
      ])) {
        continue;
      }

      list.add({
        'id': doc.id,
        'category': category,
        'notes': notes,
        'orderId': orderId,
        'userId': userId,
        'amount': _toDouble(data['amount']),
        'createdAt': createdAt,
      });
    }

    list.sort((a, b) {
      final dateA = _parseDate(a['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final dateB = _parseDate(b['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

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
    final mobile = _isMobile(context);

    final cards = [
      _summaryCard(
        title: "Total Income",
        value: _money(income),
        icon: Icons.trending_up_rounded,
        color: Colors.green,
      ),
      _summaryCard(
        title: "Total Expenses",
        value: _money(expense),
        icon: Icons.trending_down_rounded,
        color: Colors.red,
      ),
      _summaryCard(
        title: "Net Balance",
        value: _money(net),
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
          if (i != cards.length - 1)
            const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildFinancialDesktopTable(
      List<Map<String, dynamic>> list,
      ) {
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
          headingRowColor: MaterialStateProperty.all(
            AppColors.bgLight,
          ),
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text("Transaction ID")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Description")),
            DataColumn(label: Text("Order ID")),
            DataColumn(label: Text("User ID")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Date")),
          ],
          rows: list.map((item) {
            final category = item['category'].toString();

            final isIncome =
                category == 'Payment In' ||
                    category == 'General Income';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    _shortId(item['id']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  _buildCategoryChip(category),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 260,
                    ),
                    child: Text(
                      item['notes'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _shortId(item['orderId']),
                  ),
                ),
                DataCell(
                  Text(
                    _shortId(item['userId']),
                  ),
                ),
                DataCell(
                  Text(
                    "${isIncome ? '+' : '-'}${_money(_toDouble(item['amount']))}",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isIncome
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDateTime(item['createdAt']),
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
      List<Map<String, dynamic>> list,
      ) {
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

  Widget _buildFinancialCard(
      Map<String, dynamic> item,
      ) {
    final category = item['category'].toString();

    final isIncome =
        category == 'Payment In' ||
            category == 'General Income';

    final amount = _toDouble(item['amount']);

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
                "${isIncome ? '+' : '-'}${_money(amount)}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isIncome
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileInfoRow(
            Icons.description_outlined,
            "Description",
            item['notes'].toString(),
          ),
          _mobileInfoRow(
            Icons.shopping_bag_outlined,
            "Order",
            _shortId(item['orderId']),
          ),
          _mobileInfoRow(
            Icons.person_outline_rounded,
            "User",
            _shortId(item['userId']),
          ),
          _mobileInfoRow(
            Icons.access_time_rounded,
            "Date",
            _formatDateTime(item['createdAt']),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "ID: ${_shortId(item['id'])}",
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

  // ===========================================================================
  // ORDERS REPORT
  // ===========================================================================

  Widget _buildOrdersReportSection(BuildContext context) {
    final mobile = _isMobile(context);

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
        stream: FirebaseFirestore.instance
            .collection('manual_orders')
            .snapshots(),
        builder: (context, manualSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, usersSnap) {
              if (manualSnap.connectionState ==
                  ConnectionState.waiting ||
                  usersSnap.connectionState ==
                      ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final manualDocs = manualSnap.data?.docs ?? [];
              final userDocs = usersSnap.data?.docs ?? [];

              return FutureBuilder<List<QuerySnapshot>>(
                future: Future.wait(
                  userDocs.map(
                        (user) => user.reference
                        .collection('orders')
                        .get(),
                  ),
                ),
                builder: (context, ordersSnapshots) {
                  if (ordersSnapshots.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final allOrders = <Map<String, dynamic>>[];

                  if (ordersSnapshots.hasData) {
                    for (int i = 0;
                    i < ordersSnapshots.data!.length;
                    i++) {
                      final userData =
                          userDocs[i].data()
                          as Map<String, dynamic>? ??
                              {};

                      for (final orderDoc
                      in ordersSnapshots.data![i].docs) {
                        final orderData =
                        Map<String, dynamic>.from(
                          orderDoc.data()
                          as Map<String, dynamic>,
                        );

                        final createdAt =
                            orderData['createdAt'] ??
                                orderData['date'];

                        if (!_matchesDateFilter(createdAt)) {
                          continue;
                        }

                        final userName =
                            userData['name'] ??
                                'System User';

                        final orderId = orderDoc.id;

                        if (!_matchesSearch([
                          orderId,
                          userName.toString(),
                          "System",
                          orderData['status']?.toString() ??
                              "Pending",
                        ])) {
                          continue;
                        }

                        orderData['orderId'] = orderId;
                        orderData['userName'] = userName;
                        orderData['type'] = 'System';

                        allOrders.add(orderData);
                      }
                    }
                  }

                  for (final manualDoc in manualDocs) {
                    final data =
                    Map<String, dynamic>.from(
                      manualDoc.data()
                      as Map<String, dynamic>,
                    );

                    final createdAt =
                        data['createdAt'] ?? data['date'];

                    if (!_matchesDateFilter(createdAt)) {
                      continue;
                    }

                    final customerName =
                        data['customerName'] ??
                            'Manual Customer';

                    if (!_matchesSearch([
                      manualDoc.id,
                      customerName.toString(),
                      "Manual",
                      data['status']?.toString() ??
                          "Completed",
                    ])) {
                      continue;
                    }

                    data['orderId'] = manualDoc.id;
                    data['userName'] = customerName;
                    data['type'] = 'Manual';

                    allOrders.add(data);
                  }

                  allOrders.sort((a, b) {
                    final dateA =
                        _parseDate(a['createdAt']) ??
                            _parseDate(a['date']) ??
                            DateTime.fromMillisecondsSinceEpoch(
                              0,
                            );

                    final dateB =
                        _parseDate(b['createdAt']) ??
                            _parseDate(b['date']) ??
                            DateTime.fromMillisecondsSinceEpoch(
                              0,
                            );

                    return dateB.compareTo(dateA);
                  });

                  double total = 0;

                  for (final order in allOrders) {
                    total += _toDouble(
                      order['totalPrice'],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context: context,
                        title: "Orders Report",
                        subtitle:
                        "System orders and manually created orders.",
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Colors.orange,
                        actions: [
                          _buildActionButton(
                            label: "Export Excel",
                            icon: Icons.table_chart_rounded,
                            color: Colors.green,
                            onPressed: () {
                              if (!kIsWeb) {
                                _showMessage(
                                  "Excel export is available on Web.",
                                );
                                return;
                              }

                              _exportOrdersExcel();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildOrdersSummary(
                        context,
                        allOrders.length,
                        total,
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 16),
                      if (allOrders.isEmpty)
                        _buildEmptyState(
                          icon: Icons.shopping_bag_outlined,
                          title: "No Orders Found",
                          subtitle:
                          "No orders match the current filters.",
                        )
                      else if (mobile)
                        _buildOrdersMobileList(allOrders)
                      else
                        _buildOrdersDesktopTable(allOrders),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrdersSummary(
      BuildContext context,
      int count,
      double total,
      ) {
    final mobile = _isMobile(context);

    final cards = [
      _summaryCard(
        title: "Total Orders",
        value: count.toString(),
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue,
      ),
      _summaryCard(
        title: "Orders Value",
        value: _money(total),
        icon: Icons.payments_outlined,
        color: Colors.green,
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: SizedBox(
                width: double.infinity,
                child: card,
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _buildOrdersDesktopTable(
      List<Map<String, dynamic>> orders,
      ) {
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
          headingRowColor: MaterialStateProperty.all(
            AppColors.bgLight,
          ),
          columnSpacing: 32,
          columns: const [
            DataColumn(label: Text("Order ID")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Customer")),
            DataColumn(label: Text("Total Price")),
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Status")),
          ],
          rows: orders.map((order) {
            final type = order['type']?.toString() ?? "System";

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    _shortId(order['orderId']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  _buildOrderTypeChip(type),
                ),
                DataCell(
                  Text(
                    order['userName']?.toString() ??
                        "N/A",
                  ),
                ),
                DataCell(
                  Text(
                    _money(
                      _toDouble(
                        order['totalPrice'],
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDateTime(
                      order['createdAt'] ??
                          order['date'],
                    ),
                  ),
                ),
                DataCell(
                  _buildStatusChip(
                    order['status']?.toString() ??
                        "Pending",
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersMobileList(
      List<Map<String, dynamic>> orders,
      ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(
      Map<String, dynamic> order,
      ) {
    final type = order['type']?.toString() ?? "System";

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
              _buildOrderTypeChip(type),
              const Spacer(),
              _buildStatusChip(
                order['status']?.toString() ??
                    "Pending",
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileInfoRow(
            Icons.shopping_bag_outlined,
            "Order ID",
            _shortId(order['orderId']),
          ),
          _mobileInfoRow(
            Icons.person_outline_rounded,
            "Customer",
            order['userName']?.toString() ?? "N/A",
          ),
          _mobileInfoRow(
            Icons.payments_outlined,
            "Total",
            _money(
              _toDouble(order['totalPrice']),
            ),
          ),
          _mobileInfoRow(
            Icons.access_time_rounded,
            "Date",
            _formatDateTime(
              order['createdAt'] ??
                  order['date'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeChip(String type) {
    final isManual = type == 'Manual';

    final color = isManual
        ? Colors.purple
        : Colors.blue;

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
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
      case 'delivered':
        color = Colors.green;
        break;

      case 'cancelled':
      case 'canceled':
      case 'rejected':
        color = Colors.red;
        break;

      case 'processing':
      case 'pending':
        color = Colors.orange;
        break;
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
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ===========================================================================
  // USERS REPORT
  // ===========================================================================

  Widget _buildUsersReportSection(BuildContext context) {
    final mobile = _isMobile(context);

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
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final users = <Map<String, dynamic>>[];

          for (final doc in docs) {
            final data =
            Map<String, dynamic>.from(
              doc.data() as Map<String, dynamic>,
            );

            final name = data['name'] ?? 'N/A';
            final email = data['email'] ?? 'N/A';
            final phone = data['phone'] ?? 'N/A';

            if (!_matchesSearch([
              doc.id,
              name.toString(),
              email.toString(),
              phone.toString(),
            ])) {
              continue;
            }

            users.add({
              'id': doc.id,
              'name': name,
              'email': email,
              'phone': phone,
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context: context,
                title: "Users Report",
                subtitle:
                "View registered users and their contact information.",
                icon: Icons.people_alt_outlined,
                iconColor: AppColors.primaryPurple,
                actions: [
                  _buildActionButton(
                    label: "Export Excel",
                    icon: Icons.table_chart_rounded,
                    color: Colors.green,
                    onPressed: () {
                      if (!kIsWeb) {
                        _showMessage(
                          "Excel export is available on Web.",
                        );
                        return;
                      }

                      _exportUsersExcel();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _summaryCard(
                title: "Registered Users",
                value: users.length.toString(),
                icon: Icons.people_outline_rounded,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(height: 20),
              Divider(
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 16),
              if (users.isEmpty)
                _buildEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: "No Users Found",
                  subtitle:
                  "No users match the current search.",
                )
              else if (mobile)
                _buildUsersMobileList(users)
              else
                _buildUsersDesktopTable(users),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersDesktopTable(
      List<Map<String, dynamic>> users,
      ) {
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
          headingRowColor: MaterialStateProperty.all(
            AppColors.bgLight,
          ),
          columnSpacing: 45,
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Email")),
            DataColumn(label: Text("Phone")),
          ],
          rows: users.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    user['name'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user['email'].toString(),
                  ),
                ),
                DataCell(
                  Text(
                    user['phone'].toString(),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUsersMobileList(
      List<Map<String, dynamic>> users,
      ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = users[index];

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
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple
                          .withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      user['name'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              _mobileInfoRow(
                Icons.email_outlined,
                "Email",
                user['email'].toString(),
              ),
              _mobileInfoRow(
                Icons.phone_outlined,
                "Phone",
                user['phone'].toString(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ID: ${_shortId(user['id'])}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // GENERIC UI HELPERS
  // ===========================================================================

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _mobileInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD EXPENSE
  // ===========================================================================

  void _showAddExpenseDialog() {
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
                child: Text(
                  "Add General Expense",
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
                  controller: notesController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Notes / Description",
                    hintText: "e.g. Servers / Shipping",
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Amount",
                    suffixText: "EGP",
                    prefixIcon: const Icon(
                      Icons.payments_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (notesController.text
                    .trim()
                    .isEmpty ||
                    amountController.text
                        .trim()
                        .isEmpty) {
                  return;
                }

                final amount =
                    double.tryParse(
                      amountController.text.trim(),
                    ) ??
                        0;

                await FirebaseFirestore.instance
                    .collection('expenses')
                    .add({
                  'amount': amount,
                  'notes': notesController.text.trim(),
                  'createdAt':
                  FieldValue.serverTimestamp(),
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

  // ===========================================================================
  // ADD INCOME
  // ===========================================================================

  void _showAddIncomeDialog() {
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
                child: Text(
                  "Add General Income",
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
                  controller: notesController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Notes / Description",
                    hintText:
                    "e.g. Investment / Additional Capital",
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Amount",
                    suffixText: "EGP",
                    prefixIcon: const Icon(
                      Icons.payments_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16,
          ),
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
                if (notesController.text
                    .trim()
                    .isEmpty ||
                    amountController.text
                        .trim()
                        .isEmpty) {
                  return;
                }

                final amount =
                    double.tryParse(
                      amountController.text.trim(),
                    ) ??
                        0;

                await FirebaseFirestore.instance
                    .collection('incomes')
                    .add({
                  'amount': amount,
                  'notes': notesController.text.trim(),
                  'createdAt':
                  FieldValue.serverTimestamp(),
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

  // ===========================================================================
  // EXCEL DOWNLOAD
  // ===========================================================================

  void _downloadExcelSheet(
      Excel excel,
      String fileName,
      ) {
    final fileBytes = excel.save();

    if (fileBytes != null && kIsWeb) {
      final blob = html.Blob(
        [
          fileBytes,
        ],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      final url =
      html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(
        href: url,
      )
        ..setAttribute(
          "download",
          "$fileName.xlsx",
        )
        ..click();

      html.Url.revokeObjectUrl(url);
    }
  }

  // ===========================================================================
  // FINANCIAL EXCEL
  // ===========================================================================

  Future<void> _exportFinancialExcel() async {
    var excel = Excel.createExcel();

    final sheetObject =
    excel['Financial_Ledger'];

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

    final paymentsSnap =
    await FirebaseFirestore.instance
        .collection('payments')
        .get();

    for (final doc in paymentsSnap.docs) {
      final data = doc.data();

      sheetObject.appendRow([
        TextCellValue(doc.id),
        TextCellValue('Payment In'),
        TextCellValue(
          data['notes'] ??
              'Order Payment',
        ),
        TextCellValue(
          data['orderId'] ?? '',
        ),
        TextCellValue(
          data['userId'] ?? '',
        ),
        DoubleCellValue(
          _toDouble(data['amount']),
        ),
        TextCellValue(
          _formatDateTime(
            data['createdAt'] ??
                data['timestamp'] ??
                data['date'],
          ),
        ),
      ]);
    }

    final incomesSnap =
    await FirebaseFirestore.instance
        .collection('incomes')
        .get();

    for (final doc in incomesSnap.docs) {
      final data = doc.data();

      sheetObject.appendRow([
        TextCellValue(doc.id),
        TextCellValue('General Income'),
        TextCellValue(
          data['notes'] ??
              data['title'] ??
              'Income',
        ),
        TextCellValue(
          data['orderId'] ?? '',
        ),
        TextCellValue(
          data['userId'] ?? '',
        ),
        DoubleCellValue(
          _toDouble(data['amount']),
        ),
        TextCellValue(
          _formatDateTime(
            data['createdAt'] ??
                data['date'],
          ),
        ),
      ]);
    }

    final expensesSnap =
    await FirebaseFirestore.instance
        .collection('expenses')
        .get();

    for (final doc in expensesSnap.docs) {
      final data = doc.data();

      final orderId =
          data['orderId'] ?? '';

      sheetObject.appendRow([
        TextCellValue(doc.id),
        TextCellValue(
          orderId.toString().isNotEmpty
              ? 'Order Expense'
              : 'General Expense',
        ),
        TextCellValue(
          data['notes'] ??
              data['title'] ??
              'Expense',
        ),
        TextCellValue(
          orderId.toString(),
        ),
        TextCellValue(
          data['userId'] ?? '',
        ),
        DoubleCellValue(
          _toDouble(data['amount']) * -1,
        ),
        TextCellValue(
          _formatDateTime(
            data['createdAt'] ??
                data['date'],
          ),
        ),
      ]);
    }

    _downloadExcelSheet(
      excel,
      'Financial_Ledger_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
    );
  }

  // ===========================================================================
  // ORDERS EXCEL
  // ===========================================================================

  Future<void> _exportOrdersExcel() async {
    var excel = Excel.createExcel();

    final sheetObject =
    excel['Orders_Report'];

    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('Order ID'),
      TextCellValue('Type'),
      TextCellValue('Customer Name'),
      TextCellValue('Total Price'),
      TextCellValue('Date & Time'),
      TextCellValue('Status'),
    ]);

    final usersSnap =
    await FirebaseFirestore.instance
        .collection('users')
        .get();

    for (final userDoc in usersSnap.docs) {
      final ordersSnap =
      await userDoc.reference
          .collection('orders')
          .get();

      for (final orderDoc in ordersSnap.docs) {
        final data = orderDoc.data();

        sheetObject.appendRow([
          TextCellValue(orderDoc.id),
          TextCellValue('System'),
          TextCellValue(
            userDoc.data()['name'] ??
                'N/A',
          ),
          DoubleCellValue(
            _toDouble(
              data['totalPrice'],
            ),
          ),
          TextCellValue(
            _formatDateTime(
              data['createdAt'] ??
                  data['date'],
            ),
          ),
          TextCellValue(
            data['status'] ??
                'Pending',
          ),
        ]);
      }
    }

    final manualSnap =
    await FirebaseFirestore.instance
        .collection('manual_orders')
        .get();

    for (final doc in manualSnap.docs) {
      final data = doc.data();

      sheetObject.appendRow([
        TextCellValue(doc.id),
        TextCellValue('Manual'),
        TextCellValue(
          data['customerName'] ??
              'Manual Customer',
        ),
        DoubleCellValue(
          _toDouble(
            data['totalPrice'],
          ),
        ),
        TextCellValue(
          _formatDateTime(
            data['createdAt'] ??
                data['date'],
          ),
        ),
        TextCellValue(
          data['status'] ??
              'Completed',
        ),
      ]);
    }

    _downloadExcelSheet(
      excel,
      'Orders_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
    );
  }

  // ===========================================================================
  // USERS EXCEL
  // ===========================================================================

  Future<void> _exportUsersExcel() async {
    var excel = Excel.createExcel();

    final sheetObject =
    excel['Users_Report'];

    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('User ID'),
      TextCellValue('Name'),
      TextCellValue('Email'),
      TextCellValue('Phone'),
    ]);

    final usersSnap =
    await FirebaseFirestore.instance
        .collection('users')
        .get();

    for (final doc in usersSnap.docs) {
      final data = doc.data();

      sheetObject.appendRow([
        TextCellValue(doc.id),
        TextCellValue(
          data['name'] ?? 'N/A',
        ),
        TextCellValue(
          data['email'] ?? 'N/A',
        ),
        TextCellValue(
          data['phone'] ?? 'N/A',
        ),
      ]);
    }

    _downloadExcelSheet(
      excel,
      'Users_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
    );
  }
}