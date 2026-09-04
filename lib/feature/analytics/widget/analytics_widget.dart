import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsWidget extends StatefulWidget {
  const AnalyticsWidget({Key? key}) : super(key: key);

  @override
  State<AnalyticsWidget> createState() => _AnalyticsWidgetState();
}

class _AnalyticsWidgetState extends State<AnalyticsWidget> {
  String role = "staff";
  bool isLoadingRole = true;
  String selectedPeriod = "7days"; // 'today', '7days', 'all'

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final userDoc = await _firestore
          .collection('user')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          role = userDoc.get('role') ?? 'staff';
          isLoadingRole = false;
        });
      } else {
        setState(() => isLoadingRole = false);
      }
    } catch (e) {
      setState(() => isLoadingRole = false);
      if (mounted) {
        showErrorDialog(context, "Error", e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role != "admin") {
      return  AccessDefindView();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'مركز إدارة التحليلات والبزنس',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent),
            tooltip: 'تصدير التقرير',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري إعداد تقرير البزنس المطبوع...')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('analytics_sessions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل البيانات: ${snapshot.error}'));
          }

          var docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد بيانات تحليلات مجهزة حالياً',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // تطبيق فلترة الفترة الزمنية
          DateTime now = DateTime.now();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            Timestamp? startTs = data['startTime'] as Timestamp?;
            if (startTs == null) return true;
            DateTime dt = startTs.toDate();

            if (selectedPeriod == 'today') {
              return dt.year == now.year && dt.month == now.month && dt.day == now.day;
            } else if (selectedPeriod == '7days') {
              return now.difference(dt).inDays <= 7;
            }
            return true;
          }).toList();

          int totalSessions = docs.length;
          int guestSessions = 0;
          int userSessions = 0;
          double totalDurationInMinutes = 0;

          Map<String, int> platformCount = {};
          Map<int, int> hourlyActivity = {}; // ساعات الذروة (0 -> 23)
          Map<String, Map<String, dynamic>> productStatsMap = {};

          int totalProductViewsCount = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            bool isGuest = data['isGuest'] ?? true;
            if (isGuest) {
              guestSessions++;
            } else {
              userSessions++;
            }

            Timestamp? startTs = data['startTime'] as Timestamp?;
            Timestamp? lastActiveTs = data['lastActiveTime'] as Timestamp?;
            if (startTs != null) {
              int hour = startTs.toDate().hour;
              hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;

              if (lastActiveTs != null) {
                final duration = lastActiveTs.toDate().difference(startTs.toDate());
                totalDurationInMinutes += duration.inSeconds / 60.0;
              }
            }

            String platform = (data['platform'] ?? 'غير معروف').toString().toUpperCase();
            platformCount[platform] = (platformCount[platform] ?? 0) + 1;

            List<dynamic> viewedProducts = data['viewedProducts'] ?? [];
            for (var item in viewedProducts) {
              if (item is Map<String, dynamic>) {
                String id = item['id'] ?? item['productId'] ?? item['title'] ?? '';
                if (id.isEmpty) continue;

                totalProductViewsCount++;

                if (!productStatsMap.containsKey(id)) {
                  productStatsMap[id] = {
                    'id': id,
                    'rawItem': item,
                    'views': 1,
                  };
                } else {
                  productStatsMap[id]!['views'] =
                      (productStatsMap[id]!['views'] as int) + 1;
                }
              }
            }
          }

          double avgSessionDuration =
          totalSessions > 0 ? (totalDurationInMinutes / totalSessions) : 0;

          // العثور على ساعة الذروة
          int peakHour = 0;
          int maxHourCount = 0;
          hourlyActivity.forEach((hour, count) {
            if (count > maxHourCount) {
              maxHourCount = count;
              peakHour = hour;
            }
          });

          Map<String, int> productViewsCount = {};
          productStatsMap.forEach((key, value) {
            String title = value['rawItem']['title'] ?? key;
            productViewsCount[title] = value['views'] as int;
          });

          List<Map<String, dynamic>> recommendations = _generateRecommendations(
            totalSessions: totalSessions,
            guestSessions: guestSessions,
            avgDuration: avgSessionDuration,
            productViews: productViewsCount,
            peakHour: peakHour,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- شريط الفلترة الزمنية ---
                _buildTimeFilterBar(),
                const SizedBox(height: 16),

                // --- 1. قسم التوصيات الذكية للبزنس ---
                if (recommendations.isNotEmpty) ...[
                  _buildSectionHeader('توصيات وتحليلات نمو البزنس 🚀'),
                  const SizedBox(height: 12),
                  _buildRecommendationsSection(recommendations),
                  const SizedBox(height: 24),
                ],

                // --- 2. كروت المؤشرات الأساسية (KPIs) ---
                _buildSectionHeader('مؤشرات الأداء الرئيسية (KPIs)'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildKpiCard(
                      title: 'إجمالي الجلسات',
                      value: '$totalSessions',
                      subtitle: 'زيارة إجمالية',
                      icon: Icons.bar_chart_rounded,
                      color: Colors.blue,
                    ),
                    _buildKpiCard(
                      title: 'متوسط وقت البقاء',
                      value: '${avgSessionDuration.toStringAsFixed(1)} دقيقة',
                      subtitle: 'معدل التفاعل',
                      icon: Icons.timer_outlined,
                      color: Colors.purple,
                    ),
                    _buildKpiCard(
                      title: 'ساعة الذروة (Peak)',
                      value: '$peakHour:00',
                      subtitle: '$maxHourCount زائر في هذا الوقت',
                      icon: Icons.access_time_filled_sharp,
                      color: Colors.deepOrange,
                    ),
                    _buildKpiCard(
                      title: 'مشاهدات المنتجات',
                      value: '$totalProductViewsCount',
                      subtitle: 'تفاعل مع الكتالوج',
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 3. تحليل ساعات الذروة والنشاط ---
                _buildSectionHeader('نشاط الزوار حسب ساعات اليوم (Peak Hours)'),
                const SizedBox(height: 12),
                _buildHourlyActivityChart(hourlyActivity),
                const SizedBox(height: 24),

                // --- 4. الرسم البياني الدائري للمنصات (Pie Chart) ---
                _buildSectionHeader('توزيع المنصات والأجهزة (Pie Chart)'),
                const SizedBox(height: 12),
                _buildPieChartCard(platformCount, totalSessions),
                const SizedBox(height: 24),

                // --- 5. الرسم البياني الشريطي للمنتجات (Bar Chart) ---
                _buildSectionHeader('رسم بياني لأعلى المنتجات مشاهدة (Bar Chart)'),
                const SizedBox(height: 12),
                _buildProductBarChartCard(productViewsCount),
                const SizedBox(height: 24),

                // --- 6. شبكة المنتجات الحية المسحوبة من Firestore ---
                _buildSectionHeader('أداء المنتجات بالبيانات الحية'),
                const SizedBox(height: 12),
                _buildLiveProductsGrid(productStatsMap.values.toList()),
                const SizedBox(height: 24),

                // --- 7. سجل الجلسات الأخيرة ---
                _buildSectionHeader('سجل الجلسات الأخيرة والتفاصيل'),
                const SizedBox(height: 12),
                _buildRecentSessionsList(docs),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- شريط الفلترة الزمنية ---
  Widget _buildTimeFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'النطاق الزمني:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Row(
            children: [
              _buildFilterChip('اليوم', 'today'),
              const SizedBox(width: 8),
              _buildFilterChip('آخر 7 أيام', '7days'),
              const SizedBox(width: 8),
              _buildFilterChip('الكل', 'all'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) setState(() => selectedPeriod = value);
      },
    );
  }

  // --- رسم بياني لساعات الذروة ---
  Widget _buildHourlyActivityChart(Map<int, int> hourlyActivity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزع الزيارات طوال الـ 24 ساعة',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (hourlyActivity.values.isEmpty
                    ? 5
                    : hourlyActivity.values.reduce((a, b) => a > b ? a : b) + 2)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        int hour = val.toInt();
                        if (hour % 4 == 0) {
                          return Text('$hour:00', style: const TextStyle(fontSize: 9));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(24, (index) {
                  int count = hourlyActivity[index] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: count > 0 ? Colors.deepOrangeAccent : Colors.grey.shade300,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- محرك التوصيات للبزنس ---
  List<Map<String, dynamic>> _generateRecommendations({
    required int totalSessions,
    required int guestSessions,
    required double avgDuration,
    required Map<String, int> productViews,
    required int peakHour,
  }) {
    List<Map<String, dynamic>> list = [];

    if (peakHour > 0) {
      list.add({
        'title': 'الوقت المثالي لإرسال الإشعارات والعروض ⏰',
        'desc': 'أعلى فترة نشاط للزوار هي الساعة $peakHour:00. يُنصح ببرمجة العروض الخاطفة والإشعارات في هذا الوقت لضمان أعلى نسبة فتح وقراءة.',
        'icon': Icons.notifications_active_outlined,
        'color': Colors.deepOrange,
      });
    }

    if (productViews.isNotEmpty) {
      var topProduct = productViews.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topProduct.value >= 2) {
        list.add({
          'title': 'المنتج الأكثر طلبًا واهتمامًا 🔥',
          'desc': 'المنتج "${topProduct.key}" يحظى بأعلى معدل اهتمام بـ (${topProduct.value} مشاهدة). يُفضل وضعه في البانر الرئيسي للتطبيق.',
          'icon': Icons.local_fire_department_outlined,
          'color': Colors.redAccent,
        });
      }
    }

    if (totalSessions > 0 && (guestSessions / totalSessions) > 0.5) {
      list.add({
        'title': 'استراتيجية تحويل الزوار إلى عملاء مسجلين 🎯',
        'desc': 'أكثر من 50% من الزوار ضيوف (Guests). يمكنك إنشاء خصم حصري عند التسجيل لأول مرة لتشجيعهم على إنشاء حساب.',
        'icon': Icons.card_giftcard_outlined,
        'color': Colors.blue,
      });
    }

    return list;
  }

  // --- 5. شبكة الكروت بالبيانات الحية ---
  Widget _buildLiveProductsGrid(List<Map<String, dynamic>> productStatsList) {
    if (productStatsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('لا توجد منتجات تم تصفحها بعد في هذه الفترة',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    productStatsList.sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900
            ? 4
            : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: productStatsList.length,
      itemBuilder: (context, index) {
        final itemStat = productStatsList[index];
        final rawItem = itemStat['rawItem'] as Map<String, dynamic>;
        final String docId = itemStat['id'];
        final int views = itemStat['views'] ?? 0;

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('products').doc(docId).snapshots(),
          builder: (context, productSnap) {
            Map<String, dynamic> data = rawItem;

            if (productSnap.hasData && productSnap.data!.exists) {
              data = productSnap.data!.data() as Map<String, dynamic>;
            }

            final String title = data['title'] ?? 'منتج بدون عنوان';
            final num price = data['price'] ?? 0;
            final num avgRating = data['avgRating'] ?? 0;

            String imageUrl = '';
            if (data['images'] != null && (data['images'] is List) && (data['images'] as List).isNotEmpty) {
              imageUrl = data['images'][0].toString();
            } else if (data['image'] != null) {
              imageUrl = data['image'].toString();
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, color: Colors.grey),
                          )
                              : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 40),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price ج.م',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('products')
                                    .doc(docId)
                                    .collection('reviews')
                                    .snapshots(),
                                builder: (context, reviewSnap) {
                                  int reviewsCount = reviewSnap.data?.docs.length ?? 0;

                                  return Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${avgRating.toStringAsFixed(1)} ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '($reviewsCount)',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.blue),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$views',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- بقية عناصر الواجهة والرسوم البيانية ---
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRecommendationsSection(List<Map<String, dynamic>> recommendations) {
    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (rec['color'] as Color).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (rec['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: rec['color'],
                radius: 20,
                child: Icon(rec['icon'], color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: rec['color'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec['desc'],
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductBarChartCard(Map<String, int> productViews) {
    if (productViews.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('لا توجد مشاهدات منتجات بعد لتوليد رسم بياني',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    var sortedEntries = productViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topProducts = sortedEntries.take(5).toList();

    double maxY = topProducts
        .map((e) => e.value.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY + 2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${topProducts[groupIndex].key}\n${rod.toY.toInt()} مشاهدة',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < topProducts.length) {
                      String title = topProducts[index].key;
                      if (title.length > 8) {
                        title = '${title.substring(0, 7)}...';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 == 0) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: topProducts.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.value.toDouble(),
                    color: Colors.blueAccent,
                    width: 18,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, int> platforms, int total) {
    if (platforms.isEmpty || total == 0) {
      return const SizedBox();
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    int colorIndex = 0;

    List<PieChartSectionData> sections = platforms.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final currentColor = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: currentColor,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 35,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: platforms.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[platforms.keys.toList().indexOf(e.key) % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.key}: ${e.value} جلسة',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsList(List<QueryDocumentSnapshot> docs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length > 5 ? 5 : docs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          bool isGuest = data['isGuest'] ?? true;
          String userId = data['userId'] ?? 'guest';
          String platform = data['platform'] ?? 'Web';
          List viewedProducts = data['viewedProducts'] ?? [];

          Timestamp? start = data['startTime'] as Timestamp?;
          String timeStr = start != null
              ? '${start.toDate().hour.toString().padLeft(2, '0')}:${start.toDate().minute.toString().padLeft(2, '0')}'
              : 'غير محدد';

          if (isGuest || userId == 'guest') {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
              title: const Text(
                'زائر ضيف (Guest)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text('المنصة: $platform | المشاهدات: ${viewedProducts.length}'),
              trailing: Text(
                'بدأت $timeStr',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('user').doc(userId).get(),
            builder: (context, userSnapshot) {
              String displayName = 'مستخدم مسجل ($userId)';
              String userEmail = '';

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  displayName = userData['name'] ?? userData['username'] ?? displayName;
                  userEmail = userData['email'] ?? '';
                }
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.verified_user_outlined, color: Colors.white),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${userEmail.isNotEmpty ? "$userEmail | " : ""}المنصة: $platform | المشاهدات: ${viewedProducts.length}',
                ),
                trailing: Text(
                  'بدأت $timeStr',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}