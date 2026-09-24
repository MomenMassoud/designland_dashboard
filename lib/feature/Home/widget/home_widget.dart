import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_current_user.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  final CollectionReference _discountRef = FirebaseFirestore.instance
      .collection('promo_codes');

  final CollectionReference _clientsRef = FirebaseFirestore.instance.collection(
    'user',
  );

  final CollectionReference _productsRef = FirebaseFirestore.instance
      .collection('products');

  final CollectionReference _categoriesRef = FirebaseFirestore.instance
      .collection('categories');

  final CollectionReference _subcategoriesRef = FirebaseFirestore.instance
      .collection('subcategories');

  final CollectionReference _employeesRef = FirebaseFirestore.instance
      .collection('employees');

  final CollectionReference _analyticsSessionsRef = FirebaseFirestore.instance
      .collection('analytics_sessions');

  int _clientCount = 0;
  int _staffCount = 0;

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    Start();
  }

  void Start() async {
    try {
      _currentUser = await GetCurrentUserData(context);

      await FirebaseFirestore.instance
          .collection('user')
          .where('role', isEqualTo: "staff")
          .get()
          .then((value) {
            if (!mounted) return;

            setState(() {
              _staffCount = value.size;
            });
          });
    } catch (e) {
      if (!mounted) return;

      showErrorDialog(context, "Error".tr, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _currentUser != null
        ? Scaffold(
            backgroundColor: AppColors.bgLight,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "System Overview Dashboard".tr,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Real-time analytics and business insights".tr,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.primaryPurple,
                  ),
                  onPressed: () => setState(() {}),
                  tooltip: "Refresh Data".tr,
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

                  Text(
                    "System Metrics & Resources".tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildPrimaryStatsGrid(),

                  const SizedBox(height: 24),

                  Text(
                    "Financials & Orders Breakdown".tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildFinancialAndOrdersSection(),

                  const SizedBox(height: 24),

                  Text(
                    "Business Growth & Conversion".tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildGrowthAnalyticsSection(),

                  const SizedBox(height: 24),

                  _buildRecentOrdersCard(),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  // ============================================================
  // 1. Welcome Banner
  // ============================================================

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
          ),
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
                      "${"Welcome Back,".tr} ${_currentUser!.role}! 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Here is what's happening with your platform today.".tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMobile) const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Colors.greenAccent,
                      size: 10,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "System: Online".tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // 2. Primary Stats Grid
  // ============================================================

  Widget _buildPrimaryStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;

        if (constraints.maxWidth > 1100) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

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
            // ==================================================
            // TODAY / YESTERDAY VISITORS
            // ==================================================
            _buildVisitorsStatCard(),

            // ==================================================
            // TOTAL CUSTOMERS
            // ==================================================
            _buildStatCard(
              title: "Total Customers".tr,
              valueStream: _clientsRef
                  .where('role', isEqualTo: "user")
                  .snapshots(),
              icon: Icons.people_alt_outlined,
              color: Colors.indigo,
            ),

            // ==================================================
            // EMPLOYEES
            // ==================================================
            _buildStatCard(
              title: "Employees & Staff".tr,
              valueStream: _clientsRef
                  .where('role', isEqualTo: "staff")
                  .snapshots(),
              icon: Icons.badge_outlined,
              color: Colors.teal,
            ),

            // ==================================================
            // PRODUCTS
            // ==================================================
            _buildStatCard(
              title: "Total Products".tr,
              valueStream: _productsRef.snapshots(),
              icon: Icons.inventory_2_outlined,
              color: Colors.orange,
            ),

            // ==================================================
            // PROMO CODES
            // ==================================================
            _buildStatCard(
              title: "Total PromoCode".tr,
              valueStream: _discountRef.snapshots(),
              icon: Icons.discount_outlined,
              color: Colors.blue,
            ),

            // ==================================================
            // CATEGORIES
            // ==================================================
            _buildCombinedCategoriesCard(),
          ],
        );
      },
    );
  }

  // ============================================================
  // VISITORS CARD
  // ============================================================

  Widget _buildVisitorsStatCard() {
    final DateTime now = DateTime.now();

    // بداية اليوم
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

    // بداية بكرة
    final DateTime startOfTomorrow = startOfToday.add(const Duration(days: 1));

    // بداية امبارح
    final DateTime startOfYesterday = startOfToday.subtract(
      const Duration(days: 1),
    );

    return StreamBuilder<QuerySnapshot>(
      stream: _analyticsSessionsRef
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(startOfTomorrow))
          .snapshots(),
      builder: (context, snapshot) {
        int todayVisitors = 0;
        int yesterdayVisitors = 0;

        int todayGuests = 0;
        int todayRegistered = 0;

        int yesterdayGuests = 0;
        int yesterdayRegistered = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            final dynamic startTimeValue = data['startTime'];

            if (startTimeValue is! Timestamp) {
              continue;
            }

            final DateTime startTime = startTimeValue.toDate();

            final bool isToday =
                !startTime.isBefore(startOfToday) &&
                startTime.isBefore(startOfTomorrow);

            final bool isYesterday =
                !startTime.isBefore(startOfYesterday) &&
                startTime.isBefore(startOfToday);

            final bool isGuest = data['isGuest'] == true;

            if (isToday) {
              todayVisitors++;

              if (isGuest) {
                todayGuests++;
              } else {
                todayRegistered++;
              }
            } else if (isYesterday) {
              yesterdayVisitors++;

              if (isGuest) {
                yesterdayGuests++;
              } else {
                yesterdayRegistered++;
              }
            }
          }
        }

        return _buildVisitorsCard(
          todayVisitors: todayVisitors,
          yesterdayVisitors: yesterdayVisitors,
          todayGuests: todayGuests,
          todayRegistered: todayRegistered,
          yesterdayGuests: yesterdayGuests,
          yesterdayRegistered: yesterdayRegistered,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  // ============================================================
  // VISITORS CARD UI
  // ============================================================

  Widget _buildVisitorsCard({
    required int todayVisitors,
    required int yesterdayVisitors,
    required int todayGuests,
    required int todayRegistered,
    required int yesterdayGuests,
    required int yesterdayRegistered,
    required bool isLoading,
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
                  "Today's Visitors".tr,
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
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              "$todayVisitors",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.history_rounded, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  "$yesterdayVisitors ${"yesterday".tr}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildVisitorMiniStat(
                  label: "Guests",
                  value: todayGuests,
                  icon: Icons.person_outline,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVisitorMiniStat(
                  label: "Users",
                  value: todayRegistered,
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL VISITOR STAT
  // ============================================================

  Widget _buildVisitorMiniStat({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERIC STAT CARD
  // ============================================================

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
                      "${snapshot.data?.docs.length ?? 0}",
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

  // ============================================================
  // CATEGORIES
  // ============================================================

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
              Expanded(
                child: Text(
                  "Categories & Sub".tr,
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
                child: const Icon(
                  Icons.category_outlined,
                  color: Colors.purple,
                  size: 20,
                ),
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
                      Text(
                        "$catCount",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Categories".tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30, child: VerticalDivider(width: 1)),

              StreamBuilder<QuerySnapshot>(
                stream: _subcategoriesRef.snapshots(),
                builder: (context, snap) {
                  final subCount = snap.data?.docs.length ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$subCount",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Subcategories".tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
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

  // ============================================================
  // 3. Financials
  // ============================================================

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
          stream: FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, paymentsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incomes')
                  .snapshots(),
              builder: (context, generalIncomeSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('expenses')
                      .snapshots(),
                  builder: (context, expensesSnapshot) {
                    num totalCollected = 0;
                    num totalGeneralIncome = 0;
                    num totalSpent = 0;

                    if (paymentsSnapshot.hasData) {
                      for (var payDoc in paymentsSnapshot.data!.docs) {
                        final payData = payDoc.data() as Map<String, dynamic>;

                        final num amount =
                            payData['amount'] ??
                            payData['price'] ??
                            payData['total'] ??
                            0;

                        dynamic dateVal =
                            payData['paymentDate'] ??
                            payData['createdAt'] ??
                            payData['timestamp'] ??
                            payData['date'];

                        bool isCurrentMonth = true;

                        if (dateVal is Timestamp) {
                          final DateTime pDate = dateVal.toDate();

                          isCurrentMonth =
                              pDate.month == now.month &&
                              pDate.year == now.year;
                        } else if (dateVal is String) {
                          final DateTime? pDate = DateTime.tryParse(dateVal);

                          if (pDate != null) {
                            isCurrentMonth =
                                pDate.month == now.month &&
                                pDate.year == now.year;
                          }
                        }

                        if (isCurrentMonth) {
                          totalCollected += amount;
                        }
                      }
                    }

                    if (generalIncomeSnapshot.hasData) {
                      for (var giDoc in generalIncomeSnapshot.data!.docs) {
                        final giData = giDoc.data() as Map<String, dynamic>;

                        final num amount = giData['amount'] ?? 0;

                        dynamic dateVal =
                            giData['createdAt'] ??
                            giData['timestamp'] ??
                            giData['date'];

                        bool isCurrentMonth = true;

                        if (dateVal is Timestamp) {
                          final DateTime giDate = dateVal.toDate();

                          isCurrentMonth =
                              giDate.month == now.month &&
                              giDate.year == now.year;
                        } else if (dateVal is String) {
                          final DateTime? giDate = DateTime.tryParse(dateVal);

                          if (giDate != null) {
                            isCurrentMonth =
                                giDate.month == now.month &&
                                giDate.year == now.year;
                          }
                        }

                        if (isCurrentMonth) {
                          totalGeneralIncome += amount;
                        }
                      }
                    }

                    if (expensesSnapshot.hasData) {
                      for (var expDoc in expensesSnapshot.data!.docs) {
                        final expData = expDoc.data() as Map<String, dynamic>;

                        final num amount =
                            expData['amount'] ??
                            expData['price'] ??
                            expData['cost'] ??
                            0;

                        dynamic dateVal =
                            expData['date'] ??
                            expData['createdAt'] ??
                            expData['timestamp'] ??
                            expData['expenseDate'];

                        bool isCurrentMonth = true;

                        if (dateVal is Timestamp) {
                          final DateTime eDate = dateVal.toDate();

                          isCurrentMonth =
                              eDate.month == now.month &&
                              eDate.year == now.year;
                        } else if (dateVal is String) {
                          final DateTime? eDate = DateTime.tryParse(dateVal);

                          if (eDate != null) {
                            isCurrentMonth =
                                eDate.month == now.month &&
                                eDate.year == now.year;
                          }
                        }

                        if (isCurrentMonth) {
                          totalSpent += amount;
                        }
                      }
                    }

                    final num totalIncome = totalCollected + totalGeneralIncome;

                    final num netMonthlyIncome = totalIncome - totalSpent;

                    return FutureBuilder<List<QuerySnapshot>>(
                      future: Future.wait(
                        userDocs.map(
                          (uDoc) => uDoc.reference.collection('orders').get(),
                        ),
                      ),
                      builder: (context, ordersSnapshots) {
                        int activeOrders = 0;
                        int completedOrders = 0;
                        int cancelledOrders = 0;

                        if (ordersSnapshots.hasData) {
                          for (var orderSnap in ordersSnapshots.data!) {
                            for (var doc in orderSnap.docs) {
                              final data = doc.data() as Map<String, dynamic>;

                              final status = (data['status'] ?? 'pending')
                                  .toString()
                                  .toLowerCase();

                              if (status == 'completed' ||
                                  status == 'delivered') {
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
                            final bool isDesktop = constraints.maxWidth > 800;

                            return Flex(
                              direction: isDesktop
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              children: [
                                Container(
                                  width: isDesktop ? null : double.infinity,
                                  margin: EdgeInsets.only(
                                    bottom: isDesktop ? 0 : 12,
                                    right: isDesktop ? 12 : 0,
                                  ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Net Monthly Income".tr,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  (netMonthlyIncome >= 0
                                                          ? Colors.green
                                                          : Colors.red)
                                                      .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              netMonthlyIncome >= 0
                                                  ? Icons.account_balance_wallet
                                                  : Icons.money_off,
                                              color: netMonthlyIncome >= 0
                                                  ? Colors.green
                                                  : Colors.red,
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
                                          color: netMonthlyIncome >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${"In:".tr} \$${totalIncome.toStringAsFixed(0)} | ${"Out:".tr} \$${totalSpent.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  flex: isDesktop ? 2 : 0,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSmallStatusCard(
                                          title: "Active".tr,
                                          count: activeOrders,
                                          color: Colors.orange,
                                          icon: Icons.pending_actions,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSmallStatusCard(
                                          title: "Completed".tr,
                                          count: completedOrders,
                                          color: Colors.green,
                                          icon: Icons.check_circle_outline,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSmallStatusCard(
                                          title: "Cancelled".tr,
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
      },
    );
  }

  // ============================================================
  // SMALL STATUS CARD
  // ============================================================

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

  // ============================================================
  // 4. Growth & Business Analytics
  // ============================================================

  Widget _buildGrowthAnalyticsSection() {
    final DateTime now = DateTime.now();
    final DateTime lastMonth = DateTime(now.year, now.month - 1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('analytics_sessions')
          .snapshots(),
      builder: (context, sessionsSnapshot) {
        final totalSessionsCount = sessionsSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, paymentsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incomes')
                  .snapshots(),
              builder: (context, generalIncomeSnapshot) {
                num currentMonthRevenue = 0;
                num previousMonthRevenue = 0;

                if (paymentsSnapshot.hasData) {
                  for (var payDoc in paymentsSnapshot.data!.docs) {
                    final payData = payDoc.data() as Map<String, dynamic>;

                    dynamic dateVal =
                        payData['createdAt'] ??
                        payData['timestamp'] ??
                        payData['paymentDate'] ??
                        payData['date'];

                    if (dateVal is Timestamp) {
                      final DateTime pDate = dateVal.toDate();

                      if (pDate.month == now.month && pDate.year == now.year) {
                        currentMonthRevenue += (payData['amount'] ?? 0);
                      } else if (pDate.month == lastMonth.month &&
                          pDate.year == lastMonth.year) {
                        previousMonthRevenue += (payData['amount'] ?? 0);
                      }
                    }
                  }
                }

                if (generalIncomeSnapshot.hasData) {
                  for (var giDoc in generalIncomeSnapshot.data!.docs) {
                    final giData = giDoc.data() as Map<String, dynamic>;

                    dynamic dateVal =
                        giData['createdAt'] ??
                        giData['timestamp'] ??
                        giData['date'];

                    if (dateVal is Timestamp) {
                      final DateTime giDate = dateVal.toDate();

                      if (giDate.month == now.month &&
                          giDate.year == now.year) {
                        currentMonthRevenue += (giData['amount'] ?? 0);
                      } else if (giDate.month == lastMonth.month &&
                          giDate.year == lastMonth.year) {
                        previousMonthRevenue += (giData['amount'] ?? 0);
                      }
                    }
                  }
                }

                double monthlyGrowthPercent = 0.0;

                if (previousMonthRevenue > 0) {
                  monthlyGrowthPercent =
                      ((currentMonthRevenue - previousMonthRevenue) /
                          previousMonthRevenue) *
                      100;
                } else if (currentMonthRevenue > 0) {
                  monthlyGrowthPercent = 100.0;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _usersRef.snapshots(),
                  builder: (context, usersSnapshot) {
                    final userDocs = usersSnapshot.data?.docs ?? [];

                    return FutureBuilder<List<QuerySnapshot>>(
                      future: Future.wait(
                        userDocs.map(
                          (uDoc) => uDoc.reference.collection('orders').get(),
                        ),
                      ),
                      builder: (context, ordersSnapshots) {
                        double totalOrdersAmount = 0.0;
                        int totalOrdersCount = 0;

                        if (ordersSnapshots.hasData) {
                          for (var orderSnap in ordersSnapshots.data!) {
                            for (var doc in orderSnap.docs) {
                              final data = doc.data() as Map<String, dynamic>;

                              totalOrdersAmount +=
                                  (data['totalAmount'] ??
                                          data['totalPrice'] ??
                                          0.0)
                                      .toDouble();

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
                              direction: isMobile
                                  ? Axis.vertical
                                  : Axis.horizontal,
                              children: [
                                Expanded(
                                  flex: isMobile ? 0 : 1,
                                  child: _buildAnalyticsMetricCard(
                                    title: "Monthly Growth".tr,
                                    value:
                                        "${monthlyGrowthPercent >= 0 ? '+' : ''}${monthlyGrowthPercent.toStringAsFixed(1)}%",
                                    icon: monthlyGrowthPercent >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: monthlyGrowthPercent >= 0
                                        ? Colors.blueAccent
                                        : Colors.redAccent,
                                    subtitle: "Revenue vs last month".tr,
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? 0 : 12,
                                  height: isMobile ? 12 : 0,
                                ),
                                Expanded(
                                  flex: isMobile ? 0 : 1,
                                  child: _buildAnalyticsMetricCard(
                                    title: "Avg Order Value".tr,
                                    value:
                                        "\$${avgOrderValue.toStringAsFixed(2)}",
                                    icon: Icons.shopping_bag_outlined,
                                    color: Colors.purpleAccent,
                                    subtitle:
                                        "${"Across".tr} $totalOrdersCount ${"total orders".tr}",
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? 0 : 12,
                                  height: isMobile ? 12 : 0,
                                ),
                                Expanded(
                                  flex: isMobile ? 0 : 1,
                                  child: _buildAnalyticsMetricCard(
                                    title: "Conversion Rate".tr,
                                    value:
                                        "${conversionRate.toStringAsFixed(2)}%",
                                    icon: Icons.pie_chart_outline,
                                    color: Colors.teal,
                                    subtitle:
                                        "$totalOrdersCount ${"orders".tr} / $totalSessionsCount ${"sessions".tr}",
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
      },
    );
  }

  // ============================================================
  // ANALYTICS METRIC CARD
  // ============================================================

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

  // ============================================================
  // 5. Active Recent Orders
  // ============================================================

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Active Orders In Progress".tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.pending_actions_outlined,
                color: AppColors.primaryPurple,
                size: 20,
              ),
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
                  userDocs.map(
                    (uDoc) => uDoc.reference.collection('orders').get(),
                  ),
                ),
                builder: (context, ordersSnapshots) {
                  if (ordersSnapshots.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> activeOrders = [];

                  if (ordersSnapshots.hasData) {
                    for (var orderSnap in ordersSnapshots.data!) {
                      for (var doc in orderSnap.docs) {
                        final data = doc.data() as Map<String, dynamic>;

                        final status = (data['status'] ?? '')
                            .toString()
                            .toLowerCase();

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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "No active orders currently in progress.".tr,
                          style: const TextStyle(color: AppColors.textMuted),
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
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final data = recentActive[index];

                      final orderId = data['id'] ?? '';

                      final status = data['status'] ?? 'In Progress';

                      double price = (data['totalPrice'] ?? 0.0).toDouble();

                      if (price == 0.0 && data['items'] is List) {
                        for (var item in (data['items'] as List)) {
                          final itemPrice = (item['price'] ?? 0).toDouble();

                          final itemQty = (item['quantity'] ?? 1).toDouble();

                          price += itemPrice * itemQty;
                        }
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(
                            status,
                          ).withOpacity(0.15),
                          child: Icon(
                            Icons.shopping_bag,
                            color: _getStatusColor(status),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          "${"Order".tr} #${orderId.length > 6 ? orderId.substring(0, 6) : orderId}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "${"Status:".tr} $status",
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  // ============================================================
  // STATUS COLOR
  // ============================================================

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
