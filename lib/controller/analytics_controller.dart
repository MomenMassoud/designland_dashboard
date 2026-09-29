import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:excel/excel.dart' as import_excel;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:universal_html/html.dart' as html;

import '../model/analytics_data_model.dart';

class AnalyticsController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var role = "staff".obs;
  var isLoadingRole = true.obs;
  var selectedPeriod = "7days".obs; // 'today', '7days', 'all'

  var isAnalyzingAi = false.obs;
  var aiAnalysisResult = Rxn<String>();
  String _geminiApiKey = "";

  var analyticsData = Rxn<AnalyticsDataModel>();
  var isLoadingData = true.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  @override
  void onInit() {
    super.onInit();
    initController();
  }

  Future<void> initController() async {
    await fetchGeminiApiKey();
    await fetchUserRole();
    if (role.value == "admin") {
      bindAnalyticsStreams();
    }
  }

  Future<void> fetchGeminiApiKey() async {
    try {
      final docSnapshot = await firestore.collection('app_info').doc("const").get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        _geminiApiKey = docSnapshot.get('gemini') ?? '';
      }
    } catch (e) {
      if (Get.context != null) showErrorDialog(Get.context!, "Error", e.toString());
    }
  }

  Future<void> fetchUserRole() async {
    try {
      final userDoc = await firestore.collection('user').doc(auth.currentUser?.uid).get();
      if (userDoc.exists) {
        role.value = userDoc.get('role') ?? 'staff';
      }
    } catch (e) {
      if (Get.context != null) showErrorDialog(Get.context!, "Error".tr, e.toString());
    } finally {
      isLoadingRole.value = false;
    }
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    bindAnalyticsStreams();
  }

  void bindAnalyticsStreams() {
    isLoadingData.value = true;

    // دمج الـ Streams للحصول على أداء فائق وسريع
    firestore.collection('analytics_sessions').snapshots().listen((sessionSnap) {
      firestore.collection('search_history').snapshots().listen((searchSnap) {
        try {
          DateTime now = DateTime.now();

          var filteredSessions = sessionSnap.docs.where((doc) {
            final data = doc.data();
            Timestamp? startTs = data['startTime'] as Timestamp?;
            if (startTs == null) return true;
            DateTime dt = startTs.toDate();

            if (selectedPeriod.value == 'today') {
              return dt.year == now.year && dt.month == now.month && dt.day == now.day;
            } else if (selectedPeriod.value == '7days') {
              return now.difference(dt).inDays <= 7;
            }
            return true;
          }).toList();

          var filteredSearches = searchSnap.docs.where((doc) {
            final data = doc.data();
            Timestamp? createTs = data['createdAt'] as Timestamp?;
            if (createTs == null) return true;
            DateTime dt = createTs.toDate();

            if (selectedPeriod.value == 'today') {
              return dt.year == now.year && dt.month == now.month && dt.day == now.day;
            } else if (selectedPeriod.value == '7days') {
              return now.difference(dt).inDays <= 7;
            }
            return true;
          }).toList();

          analyticsData.value = AnalyticsDataModel.fromDocs(filteredSessions, filteredSearches);
          hasError.value = false;
        } catch (e) {
          hasError.value = true;
          errorMessage.value = e.toString();
        } finally {
          isLoadingData.value = false;
        }
      }, onError: (err) {
        hasError.value = true;
        errorMessage.value = err.toString();
        isLoadingData.value = false;
      });
    }, onError: (err) {
      hasError.value = true;
      errorMessage.value = err.toString();
      isLoadingData.value = false;
    });
  }

  Future<void> analyzeWithGemini() async {
    final data = analyticsData.value;
    if (data == null) return;

    isAnalyzingAi.value = true;
    aiAnalysisResult.value = null;

    try {
      StringBuffer dataSummary = StringBuffer();
      dataSummary.writeln("=== E-COMMERCE LIVE METRICS & ANALYTICS DATA ===");
      dataSummary.writeln("Selected Time Filter: ${selectedPeriod.value}");
      dataSummary.writeln("• Total Traffic Sessions: ${data.totalSessions} (Registered Users: ${data.userSessions}, Guest Visitors: ${data.guestSessions})");
      dataSummary.writeln("• Total Internal Searches: ${data.totalSearches} (User Searches: ${data.userSearches}, Guest Searches: ${data.guestSearches})");
      dataSummary.writeln("• Average Dwell/Session Duration: ${data.avgSessionDuration.toStringAsFixed(2)} minutes");
      dataSummary.writeln("• Peak Traffic Window: ${data.peakHour}:00 UTC/Local");

      dataSummary.writeln("\n=== DEVICE & PLATFORM DISTRIBUTION ===");
      if (data.platformCount.isEmpty) {
        dataSummary.writeln("No platform data recorded.");
      } else {
        data.platformCount.forEach((platform, count) {
          dataSummary.writeln("- $platform: $count sessions");
        });
      }

      dataSummary.writeln("\n=== TOP USER SEARCH QUERIES (CUSTOMER INTENT) ===");
      if (data.searchQueriesCount.isEmpty) {
        dataSummary.writeln("- No search queries recorded for this period.");
      } else {
        data.searchQueriesCount.forEach((term, count) {
          dataSummary.writeln("- Query: '$term' | Volume: $count");
        });
      }

      dataSummary.writeln("\n=== PRODUCT PERFORMANCE & ENGAGEMENT METRICS ===");
      final liveProducts = data.productStatsMap.values.toList();
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
   - Leverage the Peak Activity Hour (${data.peakHour}:00) to recommend timing for push notifications, promotional email campaigns, and ad spend allocation.
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
      aiAnalysisResult.value = response.text ?? "No analysis generated from Gemini.";
    } catch (e) {
      if (Get.context != null) {
        showErrorDialog(Get.context!, "AI Analysis Error", e.toString());
      }
    } finally {
      isAnalyzingAi.value = false;
    }
  }

  Future<void> exportToExcel() async {
    final data = analyticsData.value;
    if (data == null) return;

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
        import_excel.IntCellValue(data.totalSessions),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Guest seating areas'),
        import_excel.IntCellValue(data.guestSessions),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Registered user sessions'),
        import_excel.IntCellValue(data.userSessions),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Total searches'),
        import_excel.IntCellValue(data.totalSearches),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Search Guests'),
        import_excel.IntCellValue(data.guestSearches),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('User Search'),
        import_excel.IntCellValue(data.userSearches),
      ]);
      summarySheet.appendRow([
        import_excel.TextCellValue('Average dwell time (minutes)'),
        import_excel.DoubleCellValue(double.parse(data.avgSessionDuration.toStringAsFixed(2))),
      ]);

      import_excel.Sheet searchesSheet = excel['Most searched wordsً'];
      searchesSheet.appendRow([
        import_excel.TextCellValue('Search term'),
        import_excel.TextCellValue('Number of searches'),
      ]);

      data.searchQueriesCount.forEach((query, count) {
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

      for (var prod in data.productStatsMap.values) {
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

        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(content: Text('${"The Excel file has been successfully created and saved:".tr}$fileName')),
          );
        }
      }
    } catch (e) {
      if (Get.context != null) {
        showErrorDialog(Get.context!, "Export error".tr, e.toString());
      }
    }
  }

  List<Map<String, dynamic>> generateRecommendations() {
    final data = analyticsData.value;
    if (data == null) return [];

    List<Map<String, dynamic>> list = [];

    if (data.searchQueriesCount.isNotEmpty) {
      var topSearch = data.searchQueriesCount.entries.reduce((a, b) => a.value > b.value ? a : b);
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

    if (data.peakHour > 0) {
      list.add({
        'title': 'The ideal time to send notifications and offers ⏰'.tr,
        'desc':
        '${"The peak period of visitor activity is at...".tr} ${data.peakHour}${"It is recommended to schedule flash sales and notifications for this time.".tr}',
        'icon': Icons.notifications_active_outlined,
        'color': Colors.deepOrange,
      });
    }

    if (data.productViewsCount.isNotEmpty) {
      var topProduct = data.productViewsCount.entries.reduce((a, b) => a.value > b.value ? a : b);
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
}