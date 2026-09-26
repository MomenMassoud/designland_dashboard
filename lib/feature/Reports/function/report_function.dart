import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> exportUsersExcel() async {
  var excel = Excel.createExcel();
  final sheetObject = excel['Users_Report'];
  excel.delete('Sheet1');

  sheetObject.appendRow([
    TextCellValue('User ID'),
    TextCellValue('Name'),
    TextCellValue('Email'),
    TextCellValue('Phone'),
  ]);

  final usersSnap = await FirebaseFirestore.instance.collection('users').get();

  for (final doc in usersSnap.docs) {
    final data = doc.data();

    sheetObject.appendRow([
      TextCellValue(doc.id),
      TextCellValue(data['name'] ?? data['customerName'] ?? data['fullName'] ?? 'N/A'),
      TextCellValue(data['email'] ?? 'N/A'),
      TextCellValue(data['phone'] ?? 'N/A'),
    ]);
  }

  _downloadExcelSheet(
    excel,
    'Users_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
  );
}

Future<void> exportOrdersExcel(DateTimeRange? selectedDateRange, [String searchQuery = ""]) async {
  var excel = Excel.createExcel();
  final sheetObject = excel['Orders_Report'];
  excel.delete('Sheet1');

  sheetObject.appendRow([
    TextCellValue('Order ID'),
    TextCellValue('Type'),
    TextCellValue('Customer Name'),
    TextCellValue('Total Price'),
    TextCellValue('Date & Time'),
    TextCellValue('Status'),
  ]);

  final allOrders = await fetchAllOrders(
    selectedDateRange,
    searchQuery,
  );

  for (final order in allOrders) {
    sheetObject.appendRow([
      TextCellValue(order['orderId'].toString()),
      TextCellValue(order['type'].toString()),
      TextCellValue(order['userName'].toString()),
      DoubleCellValue(toDouble(order['calculatedTotal'])),
      TextCellValue(
        formatDateTime(order['createdAtFormatted']),
      ),
      TextCellValue(order['status']?.toString() ?? 'Pending'),
    ]);
  }

  _downloadExcelSheet(
    excel,
    'Orders_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
  );
}

void _downloadExcelSheet(Excel excel, String fileName) {
  final fileBytes = excel.save();

  if (fileBytes != null && kIsWeb) {
    final blob = html.Blob(
      [fileBytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.xlsx")
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}

Future<void> exportFinancialExcel() async {
  var excel = Excel.createExcel();
  final sheetObject = excel['Financial_Ledger'];
  excel.delete('Sheet1');

  sheetObject.appendRow([
    TextCellValue('Transaction ID'),
    TextCellValue('Category'),
    TextCellValue('Notes'),
    TextCellValue('Order ID'),
    TextCellValue('Customer Name'),
    TextCellValue('Amount'),
    TextCellValue('Date & Time'),
  ]);

  // جلب المستخدمين لبناء خريطة بالأسماء
  final usersSnap = await FirebaseFirestore.instance.collection('users').get();
  final Map<String, String> usersMap = {};
  for (var doc in usersSnap.docs) {
    final uData = doc.data();
    final name = (uData['name'] ?? uData['customerName'] ?? uData['fullName'] ?? '').toString();
    usersMap[doc.id] = name;
    if (uData['uid'] != null) {
      usersMap[uData['uid'].toString()] = name;
    }
  }

  // جلب الطلبات لمعرفة رقم الاوردر واسم العميل
  final ordersSnap = await FirebaseFirestore.instance.collectionGroup('orders').get();
  final Map<String, Map<String, String>> ordersInfoMap = {};

  for (var doc in ordersSnap.docs) {
    final oData = doc.data();
    final orderNo = getDisplayOrderId(doc.id, oData);

    String userId = (oData['userId'] ?? '').toString();
    if (userId.isEmpty) {
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 4 && pathSegments[0] == 'users' && pathSegments[2] == 'orders') {
        userId = pathSegments[1];
      }
    }

    String customerName = '';
    if (oData['customerName'] != null && oData['customerName'].toString().isNotEmpty) {
      customerName = oData['customerName'].toString();
    } else if (oData['selectedAddress'] != null && oData['selectedAddress'] is Map) {
      final addr = oData['selectedAddress'] as Map<String, dynamic>;
      customerName = (addr['fullName'] ?? addr['name'] ?? '').toString();
    }

    if (customerName.isEmpty && userId.isNotEmpty) {
      customerName = usersMap[userId] ?? '';
    }

    ordersInfoMap[doc.id] = {
      'orderNumber': orderNo,
      'customerName': customerName,
    };
  }

  final paymentsSnap = await FirebaseFirestore.instance.collection('payments').get();

  for (final doc in paymentsSnap.docs) {
    final data = doc.data();
    final rawOrderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
    final rawUserId = (data['userId'] ?? '').toString();

    String displayOrderNo = '';
    String customerName = '';

    if (rawOrderId.isNotEmpty && ordersInfoMap.containsKey(rawOrderId)) {
      displayOrderNo = ordersInfoMap[rawOrderId]!['orderNumber'] ?? '';
      customerName = ordersInfoMap[rawOrderId]!['customerName'] ?? '';
    }

    if (customerName.isEmpty && rawUserId.isNotEmpty) {
      customerName = usersMap[rawUserId] ?? '';
    }

    sheetObject.appendRow([
      TextCellValue(doc.id),
      TextCellValue('Payment In'),
      TextCellValue(data['notes'] ?? 'Order Payment'),
      TextCellValue(displayOrderNo.isEmpty ? (rawOrderId.isNotEmpty ? shortId(rawOrderId) : '-') : displayOrderNo),
      TextCellValue(customerName.isEmpty ? 'N/A' : customerName),
      DoubleCellValue(toDouble(data['amount'])),
      TextCellValue(
        formatDateTime(
          data['createdAt'] ?? data['timestamp'] ?? data['date'],
        ),
      ),
    ]);
  }

  final incomesSnap = await FirebaseFirestore.instance.collection('incomes').get();

  for (final doc in incomesSnap.docs) {
    final data = doc.data();
    final rawOrderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
    final rawUserId = (data['userId'] ?? '').toString();

    String displayOrderNo = '';
    String customerName = '';

    if (rawOrderId.isNotEmpty && ordersInfoMap.containsKey(rawOrderId)) {
      displayOrderNo = ordersInfoMap[rawOrderId]!['orderNumber'] ?? '';
      customerName = ordersInfoMap[rawOrderId]!['customerName'] ?? '';
    }

    if (customerName.isEmpty && rawUserId.isNotEmpty) {
      customerName = usersMap[rawUserId] ?? '';
    }

    sheetObject.appendRow([
      TextCellValue(doc.id),
      TextCellValue('General Income'),
      TextCellValue(data['notes'] ?? data['title'] ?? 'Income'),
      TextCellValue(displayOrderNo.isEmpty ? (rawOrderId.isNotEmpty ? shortId(rawOrderId) : '-') : displayOrderNo),
      TextCellValue(customerName.isEmpty ? 'N/A' : customerName),
      DoubleCellValue(toDouble(data['amount'])),
      TextCellValue(
        formatDateTime(data['createdAt'] ?? data['date']),
      ),
    ]);
  }

  final expensesSnap = await FirebaseFirestore.instance.collection('expenses').get();

  for (final doc in expensesSnap.docs) {
    final data = doc.data();
    final rawOrderId = (data['orderId'] ?? data['order_id'] ?? '').toString();
    final rawUserId = (data['userId'] ?? '').toString();

    String displayOrderNo = '';
    String customerName = '';

    if (rawOrderId.isNotEmpty && ordersInfoMap.containsKey(rawOrderId)) {
      displayOrderNo = ordersInfoMap[rawOrderId]!['orderNumber'] ?? '';
      customerName = ordersInfoMap[rawOrderId]!['customerName'] ?? '';
    }

    if (customerName.isEmpty && rawUserId.isNotEmpty) {
      customerName = usersMap[rawUserId] ?? '';
    }

    sheetObject.appendRow([
      TextCellValue(doc.id),
      TextCellValue(
        rawOrderId.isNotEmpty ? 'Order Expense' : 'General Expense',
      ),
      TextCellValue(data['notes'] ?? data['title'] ?? 'Expense'),
      TextCellValue(displayOrderNo.isEmpty ? (rawOrderId.isNotEmpty ? shortId(rawOrderId) : '-') : displayOrderNo),
      TextCellValue(customerName.isEmpty ? 'N/A' : customerName),
      DoubleCellValue(toDouble(data['amount']) * -1),
      TextCellValue(
        formatDateTime(data['createdAt'] ?? data['date']),
      ),
    ]);
  }

  _downloadExcelSheet(
    excel,
    'Financial_Ledger_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
  );
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 700;
}

String formatDateTime(dynamic timestamp) {
  final date = parseDate(timestamp);
  if (date == null) return "N/A";
  return DateFormat('yyyy-MM-dd hh:mm a').format(date);
}

DateTime? parseDate(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is DateTime) return timestamp;
  if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
  if (timestamp is String) return DateTime.tryParse(timestamp);
  return null;
}

bool matchesDateFilter(dynamic timestamp, DateTimeRange? selectedDateRange) {
  if (selectedDateRange == null) return true;

  final date = parseDate(timestamp);
  if (date == null) return false;

  final start = DateTime(
    selectedDateRange.start.year,
    selectedDateRange.start.month,
    selectedDateRange.start.day,
  );

  final end = DateTime(
    selectedDateRange.end.year,
    selectedDateRange.end.month,
    selectedDateRange.end.day,
    23,
    59,
    59,
    999,
  );

  return !date.isBefore(start) && !date.isAfter(end);
}

bool matchesSearch(List<String> values, String searchQuery) {
  if (searchQuery.trim().isEmpty) return true;

  final query = searchQuery.toLowerCase().trim();

  return values.any(
        (value) => value.toLowerCase().contains(query),
  );
}

Future<List<Map<String, dynamic>>> fetchAllOrders(
    DateTimeRange? selectedDateRange, [
      String searchQuery = "",
    ]) async {
  final allOrders = <Map<String, dynamic>>[];

  // 1. جلب خريطة المستخدمين
  final userSnap = await FirebaseFirestore.instance.collection('users').get();
  final Map<String, String> usersMap = {};
  for (var doc in userSnap.docs) {
    final uData = doc.data();
    final name = (uData['name'] ?? uData['customerName'] ?? uData['fullName'] ?? '').toString();
    usersMap[doc.id] = name;
    if (uData['uid'] != null) {
      usersMap[uData['uid'].toString()] = name;
    }
  }

  // 2. جلب جميع الأوردرات المانويل والفرعية باستخدام collectionGroup
  final ordersSnap = await FirebaseFirestore.instance.collectionGroup('orders').get();

  for (final doc in ordersSnap.docs) {
    final data = Map<String, dynamic>.from(doc.data());
    final createdAt = data['createdAt'] ?? data['date'] ?? data['timestamp'];

    if (!matchesDateFilter(createdAt, selectedDateRange)) continue;

    final bool isManual = data['isManual'] == true || !doc.reference.path.contains('/users/');

    // استخراج الـ userId بأمان
    String userId = (data['userId'] ?? '').toString();
    if (userId.isEmpty) {
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 4 && pathSegments[0] == 'users' && pathSegments[2] == 'orders') {
        userId = pathSegments[1];
      }
    }

    // استخراج اسم العميل
    String customerName = '';
    if (data['customerName'] != null && data['customerName'].toString().isNotEmpty) {
      customerName = data['customerName'].toString();
    } else if (data['selectedAddress'] != null && data['selectedAddress'] is Map) {
      final addr = data['selectedAddress'] as Map<String, dynamic>;
      customerName = (addr['fullName'] ?? addr['name'] ?? '').toString();
    }

    if (customerName.isEmpty && userId.isNotEmpty) {
      customerName = usersMap[userId] ?? '';
    }

    if (customerName.isEmpty) {
      customerName = 'Customer';
    }

    final displayOrderNo = getDisplayOrderId(doc.id, data);
    final status = data['status']?.toString() ?? "Pending";
    final totalAmount = toDouble(
      data['totalPrice'] ?? data['subtotal'] ?? data['total'] ?? data['totalAmount'] ?? data['price'],
    );

    final typeStr = isManual ? 'Manual' : 'Customer';

    if (!matchesSearch([
      doc.id,
      displayOrderNo,
      customerName,
      typeStr,
      status,
    ], searchQuery)) {
      continue;
    }

    data['orderId'] = displayOrderNo;
    data['docId'] = doc.id;
    data['userName'] = customerName;
    data['type'] = typeStr;
    data['calculatedTotal'] = totalAmount;
    data['createdAtFormatted'] = createdAt;

    allOrders.add(data);
  }

  // ترتيب التواريخ من الأحدث للأقدم
  allOrders.sort((a, b) {
    final dateA = parseDate(a['createdAtFormatted']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateB = parseDate(b['createdAtFormatted']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dateB.compareTo(dateA);
  });

  return allOrders;
}

String getDisplayOrderId(dynamic value, [Map<String, dynamic>? rawData]) {
  if (rawData != null) {
    final orderNum = rawData['orderNumber'] ??
        rawData['order_number'] ??
        rawData['orderNo'] ??
        rawData['order_id'];
    if (orderNum != null && orderNum.toString().trim().isNotEmpty) {
      return "#${orderNum.toString()}";
    }
  }

  final id = value?.toString() ?? "";
  if (id.isEmpty) return "-";
  if (id.length <= 10) return "#$id";
  return "#${id.substring(0, 8)}";
}

String shortId(dynamic value) {
  final id = value?.toString() ?? "";
  if (id.isEmpty) return "-";
  if (id.length <= 8) return "$id";
  return "#${id.substring(0, 8)}";
}

double toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String money(double value) {
  return "${value.toStringAsFixed(2)} EGP";
}