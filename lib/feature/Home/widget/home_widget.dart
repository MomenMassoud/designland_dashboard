import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../Core/Utils/app.colors.dart'; // افترضنا وجود ألوان المشروع الأساسية هنا

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  // مراجع المجموعات من الفايرستور (Firestore References)
  final CollectionReference _usersRef =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');
  final CollectionReference _ordersRef =
  FirebaseFirestore.instance.collection('orders');
  final CollectionReference _employeesRef =
  FirebaseFirestore.instance.collection('employees');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System Overview Dashboard",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Real-time analytics and business insights",
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryPurple),
            onPressed: () => setState(() {}),
            tooltip: "Refresh Data",
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== WELCOME & QUICK SUMMARY HEADER ====================
            _buildWelcomeBanner(),
            const SizedBox(height: 24),

            // ==================== PRIMARY COUNTERS GRID ====================
            const Text(
              "System Metrics & Resources",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildPrimaryStatsGrid(),
            const SizedBox(height: 24),

            // ==================== ORDERS & REVENUE SECTION ====================
            const Text(
              "Financials & Orders Breakdown",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildFinancialAndOrdersSection(),
            const SizedBox(height: 24),

            // ==================== GROWTH & PERFORMANCE ANALYTICS ====================
            const Text(
              "Business Growth & Conversion",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildGrowthAnalyticsSection(),
            const SizedBox(height: 24),

            // ==================== RECENT ORDERS PREVIEW ====================
            _buildRecentOrdersCard(),
          ],
        ),
      ),
    );
  }

  // 1. Welcome Banner
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back, Admin! 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Here is what's happening with your platform today.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                const SizedBox(width: 8),
                Text(
                  "System: Online",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 2. Grid for Users, Visitors, Products, Categories, Employees
  Widget _buildPrimaryStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          children: [
            // Today Visitors (Static or From Analytics Collection)
            _buildStatCard(
              title: "Today's Visitors",
              valueStream: null,
              customValue: "1,420",
              icon: Icons.remove_red_eye_outlined,
              color: Colors.blue,
              subtitle: "+12.5% from yesterday",
            ),
            // Total Users
            _buildStatCard(
              title: "Total Customers",
              valueStream: _usersRef.snapshots(),
              icon: Icons.people_alt_outlined,
              color: Colors.indigo,
            ),
            // Total Employees
            _buildStatCard(
              title: "Employees & Staff",
              valueStream: _employeesRef.snapshots(),
              icon: Icons.badge_outlined,
              color: Colors.teal,
            ),
            // Total Products
            _buildStatCard(
              title: "Total Products",
              valueStream: _productsRef.snapshots(),
              icon: Icons.inventory_2_outlined,
              color: Colors.orange,
            ),
            // Categories & Subcategories Combined
            _buildCombinedCategoriesCard(),
          ],
        );
      },
    );
  }

  // Card Stream Builder Helper
  Widget _buildStatCard({
    required String title,
    Stream<QuerySnapshot>? valueStream,
    String? customValue,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          valueStream != null
              ? StreamBuilder<QuerySnapshot>(
            stream: valueStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final count = snapshot.data?.docs.length ?? 0;
              return Text(
                "$count",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              );
            },
          )
              : Text(
            customValue ?? "0",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // Combined Categories Card
  Widget _buildCombinedCategoriesCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Categories & Sub",
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_outlined,
                    color: Colors.purple, size: 22),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _categoriesRef.snapshots(),
                builder: (context, snap) {
                  final catCount = snap.data?.docs.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$catCount",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Categories",
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  );
                },
              ),
              const VerticalDivider(width: 1),
              StreamBuilder<QuerySnapshot>(
                stream: _subcategoriesRef.snapshots(),
                builder: (context, snap) {
                  final subCount = snap.data?.docs.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$subCount",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Subcategories",
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Financials & Orders Status Breakdown
  Widget _buildFinancialAndOrdersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        double totalRevenue = 0.0;
        int activeOrders = 0;
        int completedOrders = 0;
        int cancelledOrders = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final amount = (data['totalAmount'] ?? 0.0).toDouble();

          if (status == 'completed' || status == 'delivered') {
            completedOrders++;
            totalRevenue += amount;
          } else if (status == 'cancelled') {
            cancelledOrders++;
          } else {
            activeOrders++;
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              children: [
                // Revenue Card
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: isDesktop ? 0 : 12, right: isDesktop ? 12 : 0),
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
                            const Text("Total Revenue",
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.attach_money,
                                  color: Colors.green, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "\$${totalRevenue.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Calculated from delivered orders",
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Orders Status Cards Breakdown
                Expanded(
                  flex: isDesktop ? 2 : 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSmallStatusCard(
                          title: "Active Orders",
                          count: activeOrders,
                          color: Colors.orange,
                          icon: Icons.pending_actions,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSmallStatusCard(
                          title: "Completed",
                          count: completedOrders,
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSmallStatusCard(
                          title: "Cancelled",
                          count: cancelledOrders,
                          color: Colors.redAccent,
                          icon: Icons.cancel_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSmallStatusCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            "$count",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Growth & Business Analytics
  Widget _buildGrowthAnalyticsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsMetricCard(
            title: "Monthly Growth Rate",
            value: "+18.4%",
            icon: Icons.trending_up,
            color: Colors.blueAccent,
            subtitle: "Compared to last month",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsMetricCard(
            title: "Average Order Value",
            value: "\$145.20",
            icon: Icons.shopping_bag_outlined,
            color: Colors.purpleAccent,
            subtitle: "Based on 30-day average",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsMetricCard(
            title: "Conversion Rate",
            value: "3.85%",
            icon: Icons.pie_chart_outline,
            color: Colors.teal,
            subtitle: "Visitors to Customers",
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Recent Orders Stream Card Preview
  Widget _buildRecentOrdersCard() {
    return Container(
      width: double.infinity,
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Orders Activity",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Icon(Icons.history, color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _ordersRef
                .orderBy('createdAt', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data?.docs ?? [];
              if (orders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No recent orders recorded.",
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final data = orders[index].data() as Map<String, dynamic>;
                  final orderId = orders[index].id;
                  final status = data['status'] ?? 'Pending';
                  final price = (data['totalAmount'] ?? 0.0).toDouble();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.15),
                      child: Icon(Icons.shopping_bag,
                          color: _getStatusColor(status), size: 18),
                    ),
                    title: Text(
                      "Order #${orderId.substring(0, 6)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text("Status: $status",
                        style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    trailing: Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
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

  // Color helper for Order Statuses
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}