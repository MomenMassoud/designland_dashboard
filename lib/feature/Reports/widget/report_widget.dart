import 'package:flutter/material.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/server/get_permision.dart';
import '../function/report_function.dart';
import 'build_app_bar_report.dart';
import 'build_financial_report_section.dart';
import 'build_orders_report_section.dart';
import 'build_report_filter_header.dart';
import 'build_user_report.dart';

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

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 12;
    if (width < 1100) return 20;

    return 28;
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
      return AccessDefindView();
    }

    final mobile = isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding(context),
            vertical: mobile ? 12 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportFilterHeader(
                selectedReportType: _selectedReportType,
                selectedDateRange: _selectedDateRange,
                onReportTypeChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedReportType = value;
                  });
                },
                onSelectDateRange: () async {
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
                onClearDate: () {
                  setState(() {
                    _selectedDateRange = null;
                  });
                },
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
              SizedBox(height: mobile ? 14 : 24),
              _buildSelectedReportView(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedReportView(BuildContext context) {
    switch (_selectedReportType) {
      case ReportType.combinedFinancial:
        return FinancialReportSection(
          selectedDateRange: _selectedDateRange,
          searchQuery: _searchQuery,
          onShowMessage: _showMessage,
        );

      case ReportType.orders:
        return OrdersReportSection(
          selectedDateRange: _selectedDateRange,
          onShowMessage: _showMessage,
        );

      case ReportType.users:
        return buildUsersReportSection(context, _searchQuery);
    }
  }
}