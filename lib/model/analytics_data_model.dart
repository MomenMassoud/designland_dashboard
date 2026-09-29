import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsDataModel {
  final int totalSessions;
  final int guestSessions;
  final int userSessions;
  final double avgSessionDuration;
  final int peakHour;
  final int maxHourCount;
  final int totalSearches;
  final int guestSearches;
  final int userSearches;
  final Map<String, int> platformCount;
  final Map<int, int> hourlyActivity;
  final Map<String, Map<String, dynamic>> productStatsMap;
  final Map<String, int> productViewsCount;
  final Map<String, int> searchQueriesCount;
  final List<QueryDocumentSnapshot> rawSessionDocs;
  final List<QueryDocumentSnapshot> rawSearchDocs;

  AnalyticsDataModel({
    required this.totalSessions,
    required this.guestSessions,
    required this.userSessions,
    required this.avgSessionDuration,
    required this.peakHour,
    required this.maxHourCount,
    required this.totalSearches,
    required this.guestSearches,
    required this.userSearches,
    required this.platformCount,
    required this.hourlyActivity,
    required this.productStatsMap,
    required this.productViewsCount,
    required this.searchQueriesCount,
    required this.rawSessionDocs,
    required this.rawSearchDocs,
  });

  factory AnalyticsDataModel.fromDocs(
      List<QueryDocumentSnapshot> sessionDocs,
      List<QueryDocumentSnapshot> searchDocs,
      ) {
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
          final duration = lastActiveTs.toDate().difference(startTs.toDate());
          totalDurationInMinutes += duration.inSeconds / 60.0;
        }
      }

      String platform = (data['platform'] ?? 'غير معروف').toString().toUpperCase();
      platformCount[platform] = (platformCount[platform] ?? 0) + 1;

      List<dynamic> visitedTabs = data['visitedTabs'] ?? [];
      for (var tab in visitedTabs) {
        String tabName = tab.toString();
        if (tabName.isNotEmpty) {
          visitedTabsCount[tabName] = (visitedTabsCount[tabName] ?? 0) + 1;
        }
      }

      List<dynamic> viewedProducts = data['viewedProducts'] ?? [];
      for (var item in viewedProducts) {
        if (item is Map<String, dynamic>) {
          String id = item['id'] ?? item['productId'] ?? item['title'] ?? '';
          if (id.isEmpty) continue;

          if (!productStatsMap.containsKey(id)) {
            productStatsMap[id] = {
              'id': id,
              'rawItem': item,
              'views': 1,
            };
          } else {
            productStatsMap[id]!['views'] = (productStatsMap[id]!['views'] as int) + 1;
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
        searchQueriesCount[query] = (searchQueriesCount[query] ?? 0) + 1;
      }
    }

    double avgSessionDuration = totalSessions > 0 ? (totalDurationInMinutes / totalSessions) : 0;

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

    return AnalyticsDataModel(
      totalSessions: totalSessions,
      guestSessions: guestSessions,
      userSessions: userSessions,
      avgSessionDuration: avgSessionDuration,
      peakHour: peakHour,
      maxHourCount: maxHourCount,
      totalSearches: totalSearches,
      guestSearches: guestSearches,
      userSearches: userSearches,
      platformCount: platformCount,
      hourlyActivity: hourlyActivity,
      productStatsMap: productStatsMap,
      productViewsCount: productViewsCount,
      searchQueriesCount: searchQueriesCount,
      rawSessionDocs: sessionDocs,
      rawSearchDocs: searchDocs,
    );
  }
}