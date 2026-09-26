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
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 16),
              if (allOrders.isEmpty)
                buildEmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: "No Orders Found",
                  subtitle: "No orders match the current filters.",
                )
              else if (mobile)
                _buildOrdersMobileList(allOrders)
              else
                _buildOrdersDesktopTable(allOrders),
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
        title: "Total Orders",
        value: count.toString(),
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue,
      ),
      summaryCard(
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

  Widget _buildOrdersDesktopTable(List<Map<String, dynamic>> orders) {
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
            final type = order['type']?.toString() ?? "Customer";

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    order['orderId'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(_buildOrderTypeChip(type)),
                DataCell(
                  Text(order['userName']?.toString() ?? "N/A"),
                ),
                DataCell(
                  Text(
                    money(toDouble(order['calculatedTotal'])),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatDateTime(order['createdAtFormatted']),
                  ),
                ),
                DataCell(
                  _buildStatusChip(
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
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final type = order['type']?.toString() ?? "Customer";

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
                order['status']?.toString() ?? "Pending",
              ),
            ],
          ),
          const SizedBox(height: 12),
          mobileInfoRow(
            Icons.shopping_bag_outlined,
            "Order ID",
            order['orderId'].toString(),
          ),
          mobileInfoRow(
            Icons.person_outline_rounded,
            "Customer",
            order['userName']?.toString() ?? "N/A",
          ),
          mobileInfoRow(
            Icons.payments_outlined,
            "Total",
            money(toDouble(order['calculatedTotal'])),
          ),
          mobileInfoRow(
            Icons.access_time_rounded,
            "Date",
            formatDateTime(order['createdAtFormatted']),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeChip(String type) {
    final isManual = type == 'Manual';
    final color = isManual ? Colors.orange : Colors.blue;

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
}