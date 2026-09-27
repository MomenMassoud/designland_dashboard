import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:excel/excel.dart' as import_excel;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:universal_html/html.dart' as html;

class AnalyticsWidget extends StatefulWidget {
  @override
  State<AnalyticsWidget> createState() => _AnalyticsWidgetState();
}

class _AnalyticsWidgetState extends State<AnalyticsWidget> {
  String role = "staff";
  bool isLoadingRole = true;
  String selectedPeriod = "7days"; // 'today', '7days', 'all'

  // AI Analysis State
  bool _isAnalyzingAi = false;
  String? _aiAnalysisResult;

  String _geminiApiKey = "YOUR_GEMINI_API_KEY_HERE";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _GetGeminiApi() async {
    try {
      final docSnapshot = await _firestore.collection('app_info').doc("const").get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          _geminiApiKey = docSnapshot.get('gemini') ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, "Error", e.toString());
      }
    }
  }

  Future<void> _start() async {
    try {
      await _GetGeminiApi();
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
        showErrorDialog(context, "Error".tr, e.toString());
      }
    }
  }

  // -------------------------------------------------------------
  // Gemini AI Analysis Integration (Inline Screen Output)
  // -------------------------------------------------------------
  Future<void> _analyzeWithGemini({
    required int totalSessions,
    required int guestSessions,
    required int userSessions,
    required int totalSearches,
    required int guestSearches,
    required int userSearches,
    required double avgDuration,
    required int peakHour,
    required Map<String, int> searchQueries,
    required Map<String, int> platformCount,
    required List<Map<String, dynamic>> liveProducts,
  }) async {
    setState(() {
      _isAnalyzingAi = true;
      _aiAnalysisResult = null;
    });

    try {
      StringBuffer dataSummary = StringBuffer();
      dataSummary.writeln("=== E-COMMERCE LIVE METRICS & ANALYTICS DATA ===");
      dataSummary.writeln("Selected Time Filter: $selectedPeriod");
      dataSummary.writeln("• Total Traffic Sessions: $totalSessions (Registered Users: $userSessions, Guest Visitors: $guestSessions)");
      dataSummary.writeln("• Total Internal Searches: $totalSearches (User Searches: $userSearches, Guest Searches: $guestSearches)");
      dataSummary.writeln("• Average Dwell/Session Duration: ${avgDuration.toStringAsFixed(2)} minutes");
      dataSummary.writeln("• Peak Traffic Window: $peakHour:00 UTC/Local");

      dataSummary.writeln("\n=== DEVICE & PLATFORM DISTRIBUTION ===");
      if (platformCount.isEmpty) {
        dataSummary.writeln("No platform data recorded.");
      } else {
        platformCount.forEach((platform, count) {
          dataSummary.writeln("- $platform: $count sessions");
        });
      }

      dataSummary.writeln("\n=== TOP USER SEARCH QUERIES (CUSTOMER INTENT) ===");
      if (searchQueries.isEmpty) {
        dataSummary.writeln("- No search queries recorded for this period.");
      } else {
        searchQueries.forEach((term, count) {
          dataSummary.writeln("- Query: '$term' | Volume: $count");
        });
      }

      dataSummary.writeln("\n=== PRODUCT PERFORMANCE & ENGAGEMENT METRICS ===");
      if (liveProducts.isEmpty) {
        dataSummary.writeln("- No product view activity recorded.");
      } else {
        for (var prod in liveProducts) {
          String title = prod['rawItem']['title'] ?? prod['id'];
          int views = prod['views'] ?? 0;
          dataSummary.writeln("- Item: '$title' | Engagement Views: $views");
        }
      }

      final prompt = """
You are an expert Senior E-Commerce Growth Consultant & Business Intelligence Specialist.
Analyze the following store data completely and deeply, acting as an executive advisor to the platform Admin:

$dataSummary

### YOUR GOAL:
Deliver a high-impact, actionable Executive Advisory Report to optimize inventory, pricing, promotions, user retention, and overall platform revenue.

### REQUIRED ANALYSIS STRUCTURE:

1. **Executive Performance Diagnosis**:
   - Provide a concise assessment of visitor activity, registration conversion rate (Guests vs. Registered), and platform engagement efficiency.

2. **Customer Intent & Search Gap Analysis (Critical)**:
   - Cross-analyze what users are searching for against product engagement.
   - Highlight high-demand search terms that lack adequate inventory or visibility.
   - Recommend specific **NEW PRODUCTS** or categories the admin must stock/add immediately to capture unmet demand.

3. **Merchandising, Pricing & Discount Strategy**:
   - Identify high-view products vs. lower-demand products.
   - Recommend targeted **DISCOUNTS**, bundle deals, flash sales, or price adjustments to boost conversion rates on trending products.
   - Suggest cross-selling or up-selling strategies based on current product view patterns.

4. **Marketing & Conversion Rate Optimization (CRO)**:
   - Leverage the Peak Activity Hour ($peakHour:00) to recommend timing for push notifications, promotional email campaigns, and ad spend allocation.
   - Address guest visitor retention: how to convert high guest session volumes into registered buying users.

5. **Actionable Executive Checklist**:
   - 4 to 5 highly prioritized, bulleted action items for the Admin to execute today.

### RESPONSE FORMAT & CONSTRAINTS:
- **STRICT REQUIREMENT**: Respond STRICTLY AND ENTIRELY IN ENGLISH. Do NOT use any Arabic characters or words.
- Use professional executive formatting (bold headers, bullet points, clean structure).
- Be quantitative, clear, and business-driven in your advice.
""";

      final model = GenerativeModel(
        model: 'gemini-3.8-flash',
        apiKey: _geminiApiKey,
      );

      final response = await model.generateContent([Content.text(prompt)]);

      if (mounted) {
        setState(() {
          _isAnalyzingAi = false;
          _aiAnalysisResult = response.text ?? "No analysis generated from Gemini.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzingAi = false;
        });
        showErrorDialog(context, "AI Analysis Error", e.toString());
      }
    }
  }

  Widget _buildAiAnalysisCard(bool isDark) {
    if (!_isAnalyzingAi && _aiAnalysisResult == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
              : [Colors.deepPurple.shade900, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 12,
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
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Gemini AI Executive Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _aiAnalysisResult = null;
                  });
                },
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          if (_isAnalyzingAi)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.amberAccent),
                    SizedBox(height: 12),
                    Text(
                      "Analyzing platform analytics with Gemini AI...",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (_aiAnalysisResult != null)
            SelectableText(
              _aiAnalysisResult!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel({
    required int totalSessions,
    required int guestSessions,
    required int userSessions,
    required int totalSearches,
    required int guestSearches,
    required int userSearches,
    required double avgDuration,
    required Map<String, int> searchQueries,
    required List<Map<String, dynamic>> liveProducts,
  }) async {
    try {
      var excel = import_excel.Excel.createExcel();

      import_excel.Sheet summarySheet = excel['Executive Summary'];
      excel.setDefaultSheet('Executive Summary');

      summarySheet.appendRow([
        import_excel.TextCellValue('The Index'),
        import_excel.TextCellValue('Value'),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Total sessions'),
        import_excel.IntCellValue(totalSessions),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Guest seating areas'),
        import_excel.IntCellValue(guestSessions),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Registered user sessions'),
        import_excel.IntCellValue(userSessions),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Total searches'),
        import_excel.IntCellValue(totalSearches),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Search Guests'),
        import_excel.IntCellValue(guestSearches),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('User Search'),
        import_excel.IntCellValue(userSearches),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Average dwell time (minutes)'),
        import_excel.DoubleCellValue(
            double.parse(avgDuration.toStringAsFixed(2))),
      ]);

      import_excel.Sheet searchesSheet = excel['Most searched wordsً'];
      searchesSheet.appendRow([
        import_excel.TextCellValue('Search term'),
        import_excel.TextCellValue('Number of searches'),
      ]);

      searchQueries.forEach((query, count) {
        searchesSheet.appendRow([
          import_excel.TextCellValue(query),
          import_excel.IntCellValue(count),
        ]);
      });

      import_excel.Sheet productsSheet = excel['Product Views'];
      productsSheet.appendRow([
        import_excel.TextCellValue('Title / Identifier'),
        import_excel.TextCellValue('Number of views'),
      ]);

      for (var prod in liveProducts) {
        String title = prod['rawItem']['title'] ?? prod['id'];
        int views = prod['views'] ?? 0;
        productsSheet.appendRow([
          import_excel.TextCellValue(title),
          import_excel.IntCellValue(views),
        ]);
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = "Analytics_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

        if (kIsWeb) {
          final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final file = File(fileName);
          await file.writeAsBytes(fileBytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${"The Excel file has been successfully created and saved:".tr}$fileName')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, "Export error".tr, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;
    final Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textPrimaryColor = isDark ? Colors.white : Colors.black87;
    final Color textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey;

    if (isLoadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role != "admin") {
      return AccessDefindView();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('analytics_sessions').snapshots(),
      builder: (context, sessionSnap) {
        if (sessionSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (sessionSnap.hasError) {
          return Scaffold(
            body: Center(
                child: Text('${"An error occurred while loading the data:".tr}${sessionSnap.error}')),
          );
        }

        var sessionDocs = sessionSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('search_history').snapshots(),
          builder: (context, searchSnap) {
            if (searchSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            var searchDocs = searchSnap.data?.docs ?? [];

            DateTime now = DateTime.now();
            sessionDocs = sessionDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              Timestamp? startTs = data['startTime'] as Timestamp?;
              if (startTs == null) return true;
              DateTime dt = startTs.toDate();

              if (selectedPeriod == 'today') {
                return dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day;
              } else if (selectedPeriod == '7days') {
                return now.difference(dt).inDays <= 7;
              }
              return true;
            }).toList();

            searchDocs = searchDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              Timestamp? createTs = data['createdAt'] as Timestamp?;
              if (createTs == null) return true;
              DateTime dt = createTs.toDate();

              if (selectedPeriod == 'today') {
                return dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day;
              } else if (selectedPeriod == '7days') {
                return now.difference(dt).inDays <= 7;
              }
              return true;
            }).toList();

            int totalSessions = sessionDocs.length;
            int guestSessions = 0;
            int userSessions = 0;
            double totalDurationInMinutes = 0;

            Map<String, int> platformCount = {};
            Map<int, int> hourlyActivity = {};
            Map<String, Map<String, dynamic>> productStatsMap = {};
            Map<String, int> visitedTabsCount = {};

            for (var doc in sessionDocs) {
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
                  final duration =
                  lastActiveTs.toDate().difference(startTs.toDate());
                  totalDurationInMinutes += duration.inSeconds / 60.0;
                }
              }

              String platform =
              (data['platform'] ?? 'غير معروف').toString().toUpperCase();
              platformCount[platform] = (platformCount[platform] ?? 0) + 1;

              List<dynamic> visitedTabs = data['visitedTabs'] ?? [];
              for (var tab in visitedTabs) {
                String tabName = tab.toString();
                if (tabName.isNotEmpty) {
                  visitedTabsCount[tabName] =
                      (visitedTabsCount[tabName] ?? 0) + 1;
                }
              }

              List<dynamic> viewedProducts = data['viewedProducts'] ?? [];
              for (var item in viewedProducts) {
                if (item is Map<String, dynamic>) {
                  String id =
                      item['id'] ?? item['productId'] ?? item['title'] ?? '';
                  if (id.isEmpty) continue;

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

            int totalSearches = searchDocs.length;
            int guestSearches = 0;
            int userSearches = 0;
            Map<String, int> searchQueriesCount = {};

            for (var doc in searchDocs) {
              final data = doc.data() as Map<String, dynamic>;
              bool isGuest = data['gust'] ?? data['isGuest'] ?? false;
              if (isGuest) {
                guestSearches++;
              } else {
                userSearches++;
              }

              String query = (data['query'] ?? '').toString().trim();
              if (query.isNotEmpty) {
                searchQueriesCount[query] =
                    (searchQueriesCount[query] ?? 0) + 1;
              }
            }

            double avgSessionDuration = totalSessions > 0
                ? (totalDurationInMinutes / totalSessions)
                : 0;

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

            List<Map<String, dynamic>> recommendations =
            _generateRecommendations(
              totalSessions: totalSessions,
              guestSessions: guestSessions,
              avgDuration: avgSessionDuration,
              productViews: productViewsCount,
              peakHour: peakHour,
              searchQueriesCount: searchQueriesCount,
            );

            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
              appBar: AppBar(
                title: Text(
                  'Analytics and Business Management Center'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textPrimaryColor,
                  ),
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: cardBgColor,
                foregroundColor: textPrimaryColor,
                actions: [
                  ElevatedButton.icon(
                    onPressed: _isAnalyzingAi
                        ? null
                        : () {
                      _analyzeWithGemini(
                        totalSessions: totalSessions,
                        guestSessions: guestSessions,
                        userSessions: userSessions,
                        totalSearches: totalSearches,
                        guestSearches: guestSearches,
                        userSearches: userSearches,
                        avgDuration: avgSessionDuration,
                        peakHour: peakHour,
                        searchQueries: searchQueriesCount,
                        platformCount: platformCount,
                        liveProducts: productStatsMap.values.toList(),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                    label: const Text(
                      'Ask AI',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.table_chart_outlined,
                        color: Colors.green),
                    tooltip: 'Export to Excel'.tr,
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Preparing and saving the Excel file...'.tr)),
                      );

                      await _exportToExcel(
                        totalSessions: totalSessions,
                        guestSessions: guestSessions,
                        userSessions: userSessions,
                        totalSearches: totalSearches,
                        guestSearches: guestSearches,
                        userSearches: userSearches,
                        avgDuration: avgSessionDuration,
                        searchQueries: searchQueriesCount,
                        liveProducts: productStatsMap.values.toList(),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeFilterBar(isDark, cardBgColor, textPrimaryColor),
                    const SizedBox(height: 16),

                    _buildAiAnalysisCard(isDark),

                    if (recommendations.isNotEmpty) ...[
                      _buildSectionHeader('Business Growth Recommendations and Analyses 🚀'.tr, textPrimaryColor),
                      const SizedBox(height: 12),
                      _buildRecommendationsSection(recommendations, isDark),
                      const SizedBox(height: 24),
                    ],

                    _buildSectionHeader('Key Performance Indicators (KPIs)'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount:
                      MediaQuery.of(context).size.width > 800 ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildKpiCard(
                          title: 'Total sessions'.tr,
                          value: '$totalSessions',
                          subtitle:
                          '${"guests".tr}: $guestSessions | ${"Registered".tr}: $userSessions',
                          icon: Icons.bar_chart_rounded,
                          color: Colors.blue,
                          cardBgColor: cardBgColor,
                          textPrimaryColor: textPrimaryColor,
                          textSecondaryColor: textSecondaryColor,
                        ),
                        _buildKpiCard(
                          title: 'Total searches'.tr,
                          value: '$totalSearches',
                          subtitle: '${"Guest Research:".tr}$guestSearches',
                          icon: Icons.search_rounded,
                          color: Colors.orange,
                          cardBgColor: cardBgColor,
                          textPrimaryColor: textPrimaryColor,
                          textSecondaryColor: textSecondaryColor,
                        ),
                        _buildKpiCard(
                          title: 'Average dwell time'.tr,
                          value:
                          '${avgSessionDuration.toStringAsFixed(1)} ${"minute".tr}',
                          subtitle: 'Reaction rate'.tr,
                          icon: Icons.timer_outlined,
                          color: Colors.purple,
                          cardBgColor: cardBgColor,
                          textPrimaryColor: textPrimaryColor,
                          textSecondaryColor: textSecondaryColor,
                        ),
                        _buildKpiCard(
                          title: 'Peak hour'.tr,
                          value: '$peakHour:00',
                          subtitle: '$maxHourCount${"Visitor at this time".tr}',
                          icon: Icons.access_time_filled_sharp,
                          color: Colors.deepOrange,
                          cardBgColor: cardBgColor,
                          textPrimaryColor: textPrimaryColor,
                          textSecondaryColor: textSecondaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Most searched terms and categories 🔍'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildTopSearchesCard(searchQueriesCount, isDark, cardBgColor, textSecondaryColor),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Recent visitor and user search log'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildRecentSearchesList(searchDocs, cardBgColor, textPrimaryColor, textSecondaryColor),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                        'Visitor activity by time of day (Peak Hours)'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildHourlyActivityChart(hourlyActivity, isDark, cardBgColor, textSecondaryColor),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Distribution of Platforms and Devices (Pie Chart)'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildPieChartCard(platformCount, totalSessions, cardBgColor, textPrimaryColor),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                        'Bar chart of most-viewed products'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildProductBarChartCard(productViewsCount, isDark, cardBgColor, textSecondaryColor),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Product performance using live data'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildLiveProductsGrid(productStatsMap.values.toList(), isDark, cardBgColor, textPrimaryColor, textSecondaryColor),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Recent session log and details'.tr, textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildRecentSessionsList(sessionDocs, cardBgColor, textPrimaryColor, textSecondaryColor),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopSearchesCard(Map<String, int> searchQueries, bool isDark, Color cardBgColor, Color textSecondaryColor) {
    if (searchQueries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('There are no recorded searches for this period.'.tr,
              style: TextStyle(color: textSecondaryColor)),
        ),
      );
    }

    var sortedSearches = searchQueries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topList = sortedSearches.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topList.map((e) {
          return Chip(
            avatar: const CircleAvatar(
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.search, size: 12, color: Colors.white),
            ),
            label: Text(
              '${e.key} (${e.value})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.orange.shade100 : Colors.orange.shade900,
              ),
            ),
            backgroundColor: isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50,
            side: BorderSide(color: isDark ? Colors.orange.shade700 : Colors.orange.shade200),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSearchesList(List<QueryDocumentSnapshot> docs, Color cardBgColor, Color textPrimaryColor, Color textSecondaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length > 5 ? 5 : docs.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: textSecondaryColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          bool isGuest = data['gust'] ?? data['isGuest'] ?? false;
          String query = data['query'] ?? 'Empty search'.tr;
          String userId = data['userID'] ?? data['userId'] ?? 'guest';

          Timestamp? createdAt = data['createdAt'] as Timestamp?;
          String timeStr = createdAt != null
              ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
              : 'undefined'.tr;

          if (isGuest || userId == 'guest') {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
              title: Text(
                '"$query"',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
              ),
              subtitle: Text('Source: Guest'.tr, style: TextStyle(color: textSecondaryColor)),
              trailing: Text(
                timeStr,
                style: TextStyle(color: textSecondaryColor, fontSize: 12),
              ),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('user').doc(userId).get(),
            builder: (context, userSnapshot) {
              String userName = '${"User (".tr}$userId)';
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  userName =
                      userData['name'] ?? userData['username'] ?? userName;
                }
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  '"$query"',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
                ),
                subtitle: Text('${"user:".tr}$userName', style: TextStyle(color: textSecondaryColor)),
                trailing: Text(
                  timeStr,
                  style: TextStyle(color: textSecondaryColor, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations({
    required int totalSessions,
    required int guestSessions,
    required double avgDuration,
    required Map<String, int> productViews,
    required int peakHour,
    required Map<String, int> searchQueriesCount,
  }) {
    List<Map<String, dynamic>> list = [];

    if (searchQueriesCount.isNotEmpty) {
      var topSearch = searchQueriesCount.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (topSearch.value >= 2) {
        list.add({
          'title': 'High demand for a specific search term 🔍'.tr,
          'desc':
          '${"Visitors search frequently for".tr} "${topSearch.key}${"You can offer additional products that fall under this name or improve their visibility.".tr}',
          'icon': Icons.search_outlined,
          'color': Colors.amber.shade900,
        });
      }
    }

    if (peakHour > 0) {
      list.add({
        'title': 'The ideal time to send notifications and offers ⏰'.tr,
        'desc':
        '${"The peak period of visitor activity is at...".tr} $peakHour${"It is recommended to schedule flash sales and notifications for this time.".tr}',
        'icon': Icons.notifications_active_outlined,
        'color': Colors.deepOrange,
      });
    }

    if (productViews.isNotEmpty) {
      var topProduct =
      productViews.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topProduct.value >= 2) {
        list.add({
          'title': 'The most in-demand and sought-after product 🔥'.tr,
          'desc':
          '${"The Product".tr} "${topProduct.key}${"It receives the highest level of attention for (".tr}${topProduct.value}${"to watch).".tr}',
          'icon': Icons.local_fire_department_outlined,
          'color': Colors.redAccent,
        });
      }
    }

    return list;
  }

  Widget _buildTimeFilterBar(bool isDark, Color cardBgColor, Color textPrimaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Timeframe:'.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
          ),
          Row(
            children: [
              _buildFilterChip('today', 'today', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('7days', '7days', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('all', 'all', isDark),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    bool isSelected = selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue,
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.grey.shade300 : Colors.black87),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) setState(() => selectedPeriod = value);
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textPrimaryColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
    );
  }

  Widget _buildRecommendationsSection(
      List<Map<String, dynamic>> recommendations, bool isDark) {
    return Column(
      children: recommendations.map((rec) {
        final Color recColor = rec['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: recColor.withOpacity(isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: recColor.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: recColor,
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
                        color: isDark ? Colors.amber.shade300 : recColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec['desc'],
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
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

  Widget _buildHourlyActivityChart(Map<int, int> hourlyActivity, bool isDark, Color cardBgColor, Color textSecondaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visits are distributed throughout the 24-hour period.'.tr,
            style: TextStyle(fontSize: 13, color: textSecondaryColor),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (hourlyActivity.values.isEmpty
                    ? 5
                    : hourlyActivity.values
                    .reduce((a, b) => a > b ? a : b) +
                    2)
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
                          return Text('$hour:00',
                              style: TextStyle(fontSize: 9, color: textSecondaryColor));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                        color: count > 0
                            ? Colors.deepOrangeAccent
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
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

  Widget _buildLiveProductsGrid(List<Map<String, dynamic>> productStatsList, bool isDark, Color cardBgColor, Color textPrimaryColor, Color textSecondaryColor) {
    if (productStatsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No products have been viewed yet during this period.'.tr,
              style: TextStyle(color: textSecondaryColor)),
        ),
      );
    }

    productStatsList
        .sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

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

            final String title = data['title'] ?? 'Untitled Product'.tr;
            final num price = data['price'] ?? 0;
            final num avgRating = data['avgRating'] ?? 0;

            String imageUrl = '';
            if (data['images'] != null &&
                (data['images'] is List) &&
                (data['images'] as List).isNotEmpty) {
              imageUrl = data['images'][0].toString();
            } else if (data['image'] != null) {
              imageUrl = data['image'].toString();
            }

            return Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
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
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image_not_supported,
                                    color: textSecondaryColor),
                          )
                              : Icon(Icons.shopping_bag_outlined,
                              color: textSecondaryColor, size: 40),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price ${"EGP".tr}',
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
                                  int reviewsCount =
                                      reviewSnap.data?.docs.length ?? 0;

                                  return Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${avgRating.toStringAsFixed(1)} ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        '($reviewsCount)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined,
                                      size: 14, color: Colors.blue),
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

  Widget _buildProductBarChartCard(Map<String, int> productViews, bool isDark, Color cardBgColor, Color textSecondaryColor) {
    if (productViews.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('There are no product views yet to generate a graph.'.tr,
              style: TextStyle(color: textSecondaryColor)),
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
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
                getTooltipColor: (_) => isDark ? Colors.grey.shade800 : Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${topProducts[groupIndex].key}\n${rod.toY.toInt()}${"Views".tr}',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: textSecondaryColor),
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
                        style:
                        TextStyle(fontSize: 10, color: textSecondaryColor),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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

  Widget _buildPieChartCard(Map<String, int> platforms, int total, Color cardBgColor, Color textPrimaryColor) {
    if (platforms.isEmpty || total == 0) {
      return const SizedBox();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red
    ];
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
        color: cardBgColor,
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
                          color: colors[platforms.keys.toList().indexOf(e.key) %
                              colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.key}: ${e.value}${"session".tr}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: textPrimaryColor),
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
    required Color cardBgColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
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
                  style: TextStyle(fontSize: 12, color: textSecondaryColor),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsList(List<QueryDocumentSnapshot> docs, Color cardBgColor, Color textPrimaryColor, Color textSecondaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
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
        separatorBuilder: (context, index) => Divider(height: 1, color: textSecondaryColor.withOpacity(0.2)),
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
              title: Text(
                'Guest Visitor (Guest)'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
              ),
              subtitle:
              Text('${"Platform:".tr}$platform | ${"Views:".tr} ${viewedProducts.length}', style: TextStyle(color: textSecondaryColor)),
              trailing: Text(
                '${"It began".tr}$timeStr',
                style: TextStyle(color: textSecondaryColor, fontSize: 12),
              ),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('user').doc(userId).get(),
            builder: (context, userSnapshot) {
              String displayName = '${"Registered user (".tr}$userId)';
              String userEmail = '';

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  displayName =
                      userData['name'] ?? userData['username'] ?? displayName;
                  userEmail = userData['email'] ?? '';
                }
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child:
                  Icon(Icons.verified_user_outlined, color: Colors.white),
                ),
                title: Text(
                  displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: textPrimaryColor),
                ),
                subtitle: Text(
                  '${userEmail.isNotEmpty ? "$userEmail | " : ""}${"Platform:".tr} $platform | ${"Views".tr} ${viewedProducts.length}',
                  style: TextStyle(color: textSecondaryColor),
                ),
                trailing: Text(
                  '${"It began".tr} $timeStr',
                  style: TextStyle(color: textSecondaryColor, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}