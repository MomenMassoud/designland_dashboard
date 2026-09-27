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

class OrdersReportSection extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final Function(String) onShowMessage;

  const OrdersReportSection({
    super.key,
    required this.selectedDateRange,
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
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAllOrders(selectedDateRange),
        builder: (context, allOrdersSnap) {
          if (allOrdersSnap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final allOrders = allOrdersSnap.data ?? [];

          double total = 0;
          for (final order in allOrders) {
            total += toDouble(order['calculatedTotal']);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionHeader(
                context: context,
                title: "Orders Report",
                subtitle: "View both customer orders and manual entries.",
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.orange,
                actions: [
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
                      exportOrdersExcel(selectedDateRange);
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
              Divider(color: borderColor),
              const SizedBox(height: 16),
              if (allOrders.isEmpty)
                buildEmptyState(
                  context: context,
                  icon: Icons.shopping_bag_outlined,
                  title: "No Orders Found",
                  subtitle: "No orders match the current filters.",
                )
              else if (mobile)
                _buildOrdersMobileList(allOrders)
              else
                _buildOrdersDesktopTable(context, allOrders),
            ],
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
    final mobile = isMobile(context);

    final cards = [
      summaryCard(
        context: context,
        title: "Total Orders",
        value: count.toString(),
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue,
      ),
      summaryCard(
        context: context,
        title: "Orders Value",
        value: money(total),
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
      BuildContext context, List<Map<String, dynamic>> orders) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          columnSpacing: 32,
          columns: [
            DataColumn(label: Text("Order ID", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Type", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Customer", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Total Price", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Date", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Status", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
          ],
          rows: orders.map((order) {
            final type = order['type']?.toString() ?? "Customer";

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    order['orderId'].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                DataCell(_buildOrderTypeChip(context, type)),
                DataCell(
                  Text(
                    order['userName']?.toString() ?? "N/A",
                    style: TextStyle(color: textColor),
                  ),
                ),
                DataCell(
                  Text(
                    money(toDouble(order['calculatedTotal'])),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.greenAccent : Colors.green.shade800,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatDateTime(order['createdAtFormatted']),
                    style: TextStyle(color: textColor),
                  ),
                ),
                DataCell(
                  _buildStatusChip(
                    context,
                    order['status']?.toString() ?? "Pending",
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersMobileList(List<Map<String, dynamic>> orders) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], context);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    final type = order['type']?.toString() ?? "Customer";

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

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
              _buildOrderTypeChip(context, type),
              const Spacer(),
              _buildStatusChip(
                context,
                order['status']?.toString() ?? "Pending",
              ),
            ],
          ),
          const SizedBox(height: 12),
          mobileInfoRow(
            context,
            Icons.shopping_bag_outlined,
            "Order ID",
            order['orderId'].toString(),
          ),
          mobileInfoRow(
            context,
            Icons.person_outline_rounded,
            "Customer",
            order['userName']?.toString() ?? "N/A",
          ),
          mobileInfoRow(
            context,
            Icons.payments_outlined,
            "Total",
            money(toDouble(order['calculatedTotal'])),
          ),
          mobileInfoRow(
            context,
            Icons.access_time_rounded,
            "Date",
            formatDateTime(order['createdAtFormatted']),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeChip(BuildContext context, String type) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isManual = type == 'Manual';
    final color = isManual ? Colors.orange : Colors.blue;

    final effectiveColor = isDarkMode
        ? (isManual ? Colors.orangeAccent : Colors.lightBlueAccent)
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
        type,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color color = Colors.orange;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
      case 'delivered':
        color = isDarkMode ? Colors.greenAccent : Colors.green;
        break;

      case 'cancelled':
      case 'canceled':
      case 'rejected':
        color = isDarkMode ? Colors.redAccent : Colors.red;
        break;

      case 'processing':
      case 'pending':
        color = isDarkMode ? Colors.orangeAccent : Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.20 : 0.10),
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
}