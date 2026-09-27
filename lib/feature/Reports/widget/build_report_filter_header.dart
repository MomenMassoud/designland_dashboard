import 'package:dashboard_desginland/feature/Reports/widget/report_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' hide Border;
import 'package:intl/intl.dart';
import '../../../Core/Utils/app.colors.dart';
import '../function/report_function.dart';

class ReportFilterHeader extends StatelessWidget {
  final ReportType selectedReportType;
  final DateTimeRange? selectedDateRange;
  final ValueChanged<ReportType?> onReportTypeChanged;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearDate;
  final ValueChanged<String> onSearchChanged;

  const ReportFilterHeader({
    super.key,
    required this.selectedReportType,
    required this.selectedDateRange,
    required this.onReportTypeChanged,
    required this.onSelectDateRange,
    required this.onClearDate,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final cardBackgroundColor = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final titleTextColor = isDarkMode ? Colors.white : AppColors.textDark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 18),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: BoxBorder.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(.25)
                : Colors.black.withOpacity(.035),
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
                color: titleTextColor,
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
                if (selectedDateRange != null) ...[
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
            if (selectedDateRange != null) ...[
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final fieldBg = isDarkMode ? Colors.grey.shade900 : AppColors.bgLight;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(13),
        border: BoxBorder.all(
          color: borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportType>(
          value: selectedReportType,
          dropdownColor: isDarkMode ? theme.cardColor : Colors.white,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryPurple,
          ),
          onChanged: onReportTypeChanged,
          items: [
            DropdownMenuItem(
              value: ReportType.combinedFinancial,
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: isDarkMode ? Colors.greenAccent : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Financial Ledger & Expenses",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor),
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
                    color: isDarkMode ? Colors.orangeAccent : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Orders Report",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ReportType.users,
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 20,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Users Report",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor),
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
    final mobile = isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final buttonBg = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: buttonBg,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          side: BorderSide(
            color: borderColor,
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
            selectedDateRange == null
                ? "Filter by Date"
                : "${DateFormat('yyyy/MM/dd').format(selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(selectedDateRange!.end)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: mobile ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onPressed: onSelectDateRange,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final fieldBg = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500;

    return SizedBox(
      height: 52,
      child: TextField(
        onChanged: onSearchChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: "Search reports...",
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 21,
            color: hintColor,
          ),
          filled: true,
          fillColor: fieldBg,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: borderColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: borderColor,
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
      onPressed: onClearDate,
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
}