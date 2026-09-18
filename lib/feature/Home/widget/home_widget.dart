import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_current_user.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {

  final CollectionReference _usersRef =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference _discountRef=FirebaseFirestore.instance.collection('promo_codes');
  final CollectionReference _clientsRef =
  FirebaseFirestore.instance.collection('user');
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');
  final CollectionReference _employeesRef =
  FirebaseFirestore.instance.collection('employees');
  final CollectionReference _analyticsSessionsRef =
  FirebaseFirestore.instance.collection('analytics_sessions');

  int _clientCount=0;
  int _staffCount = 0;

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    Start();
  }
  void Start() async {
    try {
      _currentUser=await GetCurrentUserData(context);
      await FirebaseFirestore.instance
          .collection('user')
          .where('role', isEqualTo: "staff")
          .get()
          .then((value) {
        setState(() {
          _staffCount = value.size;
          _currentUser;
        });
      });
    } catch (e) {
      showErrorDialog(context, "Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _currentUser!=null? Scaffold(
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

            _buildWelcomeBanner(),
            const SizedBox(height: 24),

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
    ):CircularProgressIndicator();
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Back, ${_currentUser!.role}! 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Here is what's happening with your platform today.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isMobile) const SizedBox(height: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                    SizedBox(width: 8),
                    Text(
                      "System: Online",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // 2. Primary Stats Grid
  Widget _buildPrimaryStatsGrid() {
    final DateTime now = DateTime.now();

    // بداية ونهاية اليوم الحالي
    final DateTime startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    // بداية ونهاية يوم أمس
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    final DateTime startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
    final DateTime endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: constraints.maxWidth < 400 ? 2.2 : 1.8,
          ),
          children: [
            // dynamic visitors stream (Today's vs Yesterday's Visitors)
            StreamBuilder<QuerySnapshot>(
              stream: _analyticsSessionsRef
                  .where('isGuest', isEqualTo: true)
                  .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
                  .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
                  .snapshots(),
              builder: (context, todaySnap) {
                final int todayVisitors = todaySnap.data?.docs.length ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: _analyticsSessionsRef
                      .where('isGuest', isEqualTo: true)
                      .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday))
                      .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfYesterday))
                      .snapshots(),
                  builder: (context, yesterdaySnap) {
                    final int yesterdayVisitors = yesterdaySnap.data?.docs.length ?? 0;

                    return _buildStatCard(
                      title: "Today's Visitors",
                      customValue: "$todayVisitors",
                      icon: Icons.remove_red_eye_outlined,
                      color: Colors.blue,
                      subtitle: "$yesterdayVisitors yesterday",
                    );
                  },
                );
              },
            ),
            _buildStatCard(
              title: "Total Customers",
              valueStream: _clientsRef.where('role',isEqualTo: "user").snapshots(),
              icon: Icons.people_alt_outlined,
              color: Colors.indigo,
            ),
            _buildStatCard(
              title: "Employees & Staff",
              valueStream: _clientsRef.where('role',isEqualTo: "staff").snapshots(),
              icon: Icons.badge_outlined,
              color: Colors.teal,
            ),
            _buildStatCard(
              title: "Total Products",
              valueStream: _productsRef.snapshots(),
              icon: Icons.inventory_2_outlined,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: "Total PromoCode",
              valueStream: _discountRef.snapshots(),
              icon: Icons.discount_outlined,
              color: Colors.blue,
            ),
            _buildCombinedCategoriesCard(),
          ],
        );
      },
    );
  }

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
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
              return Text(
                "${snapshot.data!.size}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              );
            },
          )
              : Text(
            customValue ?? "0",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

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
              const Expanded(
                child: Text(
                  "Categories & Sub",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_outlined,
                    color: Colors.purple, size: 20),
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
              const SizedBox(
                height: 30,
                child: VerticalDivider(width: 1),
              ),
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

  // 3. Financials (Net Monthly Income = Payments In - Expenses Out) & Orders Breakdown
  Widget _buildFinancialAndOrdersSection() {
    final DateTime now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: _usersRef.snapshots(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userDocs = usersSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          // 1. المقبوضات المالية
          stream: FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, paymentsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              // 2. المصروفات المالية
              stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
              builder: (context, expensesSnapshot) {
                num totalCollected = 0;
                num totalSpent = 0;

                // ------------------ حساب إجمالي المقبوضات ------------------
                if (paymentsSnapshot.hasData) {
                  for (var payDoc in paymentsSnapshot.data!.docs) {
                    final payData = payDoc.data() as Map<String, dynamic>;
                    final num amount = payData['amount'] ?? payData['price'] ?? payData['total'] ?? 0;

                    // جلب التاريخ بأي مسمى محتمل
                    dynamic dateVal = payData['paymentDate'] ??
                        payData['createdAt'] ??
                        payData['timestamp'] ??
                        payData['date'];

                    bool isCurrentMonth = true;

                    if (dateVal is Timestamp) {
                      final DateTime pDate = dateVal.toDate();
                      isCurrentMonth = (pDate.month == now.month && pDate.year == now.year);
                    } else if (dateVal is String) {
                      final DateTime? pDate = DateTime.tryParse(dateVal);
                      if (pDate != null) {
                        isCurrentMonth = (pDate.month == now.month && pDate.year == now.year);
                      }
                    }

                    if (isCurrentMonth) {
                      totalCollected += amount;
                    }
                  }
                }
                // ------------------ حساب إجمالي المصروفات ------------------
                if (expensesSnapshot.hasData) {
                  for (var expDoc in expensesSnapshot.data!.docs) {
                    final expData = expDoc.data() as Map<String, dynamic>;
                    final num amount = expData['amount'] ?? expData['price'] ?? expData['cost'] ?? 0;

                    // جلب التاريخ بأي مسمى محتمل
                    dynamic dateVal = expData['date'] ??
                        expData['createdAt'] ??
                        expData['timestamp'] ??
                        expData['expenseDate'];

                    bool isCurrentMonth = true;

                    if (dateVal is Timestamp) {
                      final DateTime eDate = dateVal.toDate();
                      isCurrentMonth = (eDate.month == now.month && eDate.year == now.year);
                    } else if (dateVal is String) {
                      final DateTime? eDate = DateTime.tryParse(dateVal);
                      if (eDate != null) {
                        isCurrentMonth = (eDate.month == now.month && eDate.year == now.year);
                      }
                    }

                    if (isCurrentMonth) {
                      totalSpent += amount;
                    }
                  }
                }
                final num netMonthlyIncome = totalCollected - totalSpent;
                print(netMonthlyIncome);
                return FutureBuilder<List<QuerySnapshot>>(
                  future: Future.wait(
                    userDocs.map((uDoc) => uDoc.reference.collection('orders').get()),
                  ),
                  builder: (context, ordersSnapshots) {
                    int activeOrders = 0;
                    int completedOrders = 0;
                    int cancelledOrders = 0;

                    if (ordersSnapshots.hasData) {
                      for (var orderSnap in ordersSnapshots.data!) {
                        for (var doc in orderSnap.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? 'pending').toString().toLowerCase();

                          if (status == 'completed' || status == 'delivered') {
                            completedOrders++;
                          } else if (status == 'cancelled') {
                            cancelledOrders++;
                          } else {
                            activeOrders++;
                          }
                        }
                      }
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 800;
                        return Flex(
                          direction: isDesktop ? Axis.horizontal : Axis.vertical,
                          children: [
                            // Net Monthly Income Card
                            Container(
                              width: isDesktop ? null : double.infinity,
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
                                      const Text("Net Monthly Income",
                                          style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (netMonthlyIncome >= 0 ? Colors.green : Colors.red).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          netMonthlyIncome >= 0 ? Icons.account_balance_wallet : Icons.money_off,
                                          color: netMonthlyIncome >= 0 ? Colors.green : Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "\$${netMonthlyIncome.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: netMonthlyIncome >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "In: \$${totalCollected.toStringAsFixed(0)} | Out: \$${totalSpent.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Orders Status Breakdown
                            Expanded(
                              flex: isDesktop ? 2 : 0,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSmallStatusCard(
                                      title: "Active",
                                      count: activeOrders,
                                      color: Colors.orange,
                                      icon: Icons.pending_actions,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildSmallStatusCard(
                                      title: "Completed",
                                      count: completedOrders,
                                      color: Colors.green,
                                      icon: Icons.check_circle_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
              },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            "$count",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Growth & Business Analytics
  Widget _buildGrowthAnalyticsSection() {
    final DateTime now = DateTime.now();
    final DateTime lastMonth = DateTime(now.year, now.month - 1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('analytics_sessions').snapshots(),
      builder: (context, sessionsSnapshot) {
        final totalSessionsCount = sessionsSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, paymentsSnapshot) {
            num currentMonthRevenue = 0;
            num previousMonthRevenue = 0;

            if (paymentsSnapshot.hasData) {
              for (var payDoc in paymentsSnapshot.data!.docs) {
                final payData = payDoc.data() as Map<String, dynamic>;
                dynamic dateVal = payData['createdAt'] ?? payData['timestamp'] ?? payData['paymentDate'] ?? payData['date'];

                if (dateVal is Timestamp) {
                  final DateTime pDate = dateVal.toDate();

                  if (pDate.month == now.month && pDate.year == now.year) {
                    currentMonthRevenue += (payData['amount'] ?? 0);
                  } else if (pDate.month == lastMonth.month && pDate.year == lastMonth.year) {
                    previousMonthRevenue += (payData['amount'] ?? 0);
                  }
                }
              }
            }

            double monthlyGrowthPercent = 0.0;
            if (previousMonthRevenue > 0) {
              monthlyGrowthPercent = ((currentMonthRevenue - previousMonthRevenue) / previousMonthRevenue) * 100;
            } else if (currentMonthRevenue > 0) {
              monthlyGrowthPercent = 100.0;
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _usersRef.snapshots(),
              builder: (context, usersSnapshot) {
                final userDocs = usersSnapshot.data?.docs ?? [];

                return FutureBuilder<List<QuerySnapshot>>(
                  future: Future.wait(
                    userDocs.map((uDoc) => uDoc.reference.collection('orders').get()),
                  ),
                  builder: (context, ordersSnapshots) {
                    double totalOrdersAmount = 0.0;
                    int totalOrdersCount = 0;

                    if (ordersSnapshots.hasData) {
                      for (var orderSnap in ordersSnapshots.data!) {
                        for (var doc in orderSnap.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          totalOrdersAmount += (data['totalAmount'] ?? data['totalPrice'] ?? 0.0).toDouble();
                          totalOrdersCount++;
                        }
                      }
                    }

                    final double avgOrderValue = totalOrdersCount > 0
                        ? totalOrdersAmount / totalOrdersCount
                        : 0.0;

                    final double conversionRate = totalSessionsCount > 0
                        ? (totalOrdersCount / totalSessionsCount) * 100
                        : 0.0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return Flex(
                          direction: isMobile ? Axis.vertical : Axis.horizontal,
                          children: [
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildAnalyticsMetricCard(
                                title: "Monthly Growth",
                                value: "${monthlyGrowthPercent >= 0 ? '+' : ''}${monthlyGrowthPercent.toStringAsFixed(1)}%",
                                icon: monthlyGrowthPercent >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: monthlyGrowthPercent >= 0 ? Colors.blueAccent : Colors.redAccent,
                                subtitle: "Revenue vs last month",
                              ),
                            ),
                            SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 12 : 0),
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildAnalyticsMetricCard(
                                title: "Avg Order Value",
                                value: "\$${avgOrderValue.toStringAsFixed(2)}",
                                icon: Icons.shopping_bag_outlined,
                                color: Colors.purpleAccent,
                                subtitle: "Across $totalOrdersCount total orders",
                              ),
                            ),
                            SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 12 : 0),
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildAnalyticsMetricCard(
                                title: "Conversion Rate",
                                value: "${conversionRate.toStringAsFixed(2)}%",
                                icon: Icons.pie_chart_outline,
                                color: Colors.teal,
                                subtitle: "$totalOrdersCount orders / $totalSessionsCount sessions",
                              ),
                            ),
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
      width: double.infinity,
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
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 5. Active Recent Orders
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
                "Active Orders In Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Icon(Icons.pending_actions_outlined, color: AppColors.primaryPurple, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _usersRef.snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userDocs = usersSnapshot.data?.docs ?? [];

              return FutureBuilder<List<QuerySnapshot>>(
                future: Future.wait(
                  userDocs.map((uDoc) => uDoc.reference.collection('orders').get()),
                ),
                builder: (context, ordersSnapshots) {
                  if (ordersSnapshots.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> activeOrders = [];

                  if (ordersSnapshots.hasData) {
                    for (var orderSnap in ordersSnapshots.data!) {
                      for (var doc in orderSnap.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = (data['status'] ?? '').toString().toLowerCase();

                        if (status != 'cancelled' &&
                            status != 'completed' &&
                            status != 'delivered') {
                          data['id'] = doc.id;
                          activeOrders.add(data);
                        }
                      }
                    }
                  }

                  if (activeOrders.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "No active orders currently in progress.",
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  activeOrders.sort((a, b) {
                    Timestamp? tA = a['createdAt'] as Timestamp?;
                    Timestamp? tB = b['createdAt'] as Timestamp?;
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tB.compareTo(tA);
                  });

                  final recentActive = activeOrders.take(4).toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActive.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final data = recentActive[index];
                      final orderId = data['id'] ?? '';
                      final status = data['status'] ?? 'In Progress';

                      double price = (data['totalPrice'] ?? 0.0).toDouble();
                      if (price == 0.0 && data['items'] is List) {
                        for (var item in (data['items'] as List)) {
                          final itemPrice = (item['price'] ?? 0).toDouble();
                          final itemQty = (item['quantity'] ?? 1).toDouble();
                          price += (itemPrice * itemQty);
                        }
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                          _getStatusColor(status).withOpacity(0.15),
                          child: Icon(Icons.shopping_bag,
                              color: _getStatusColor(status), size: 18),
                        ),
                        title: Text(
                          "Order #${orderId.length > 6 ? orderId.substring(0, 6) : orderId}",
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
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
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