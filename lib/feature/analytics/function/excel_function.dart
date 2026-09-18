import 'dart:io';
import 'package:excel/excel.dart' as import_excel;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> exportToExcel({
  required int totalSessions,
  required int guestSessions,
  required int userSessions,
  required int totalSearches,
  required double avgDuration,
  required Map<String, int> searchQueries,
  required List<Map<String, dynamic>> liveProducts,
}) async {
  // 1. إنشاء ملف Excel جديد
  var excel = import_excel.Excel.createExcel();

  // 2. شيت الملخص العام (KPIs)
  import_excel.Sheet summarySheet = excel['ملخص المؤشرات'];
  excel.setDefaultSheet('ملخص المؤشرات');

  summarySheet.appendRow([
    import_excel.TextCellValue('المؤشر'),
    import_excel.TextCellValue('القيمة')
  ]);
  summarySheet.appendRow([
    import_excel.TextCellValue('إجمالي الجلسات'),
    import_excel.IntCellValue(totalSessions)
  ]);
  summarySheet.appendRow([
    import_excel.TextCellValue('جلسات الضيوف'),
    import_excel.IntCellValue(guestSessions)
  ]);
  summarySheet.appendRow([
    import_excel.TextCellValue('جلسات المستخدمين المسجلين'),
    import_excel.IntCellValue(userSessions)
  ]);
  summarySheet.appendRow([
    import_excel.TextCellValue('إجمالي عمليات البحث'),
    import_excel.IntCellValue(totalSearches)
  ]);
  summarySheet.appendRow([
    import_excel.TextCellValue('متوسط وقت البقاء (دقائق)'),
    import_excel.DoubleCellValue(double.parse(avgDuration.toStringAsFixed(2)))
  ]);

  // 3. شيت الكلمات الأكثر بحثاً
  import_excel.Sheet searchesSheet = excel['الأكثر بحثاً'];
  searchesSheet.appendRow([
    import_excel.TextCellValue('كلمة البحث'),
    import_excel.TextCellValue('عدد مرات البحث')
  ]);

  searchQueries.forEach((query, count) {
    searchesSheet.appendRow([
      import_excel.TextCellValue(query),
      import_excel.IntCellValue(count)
    ]);
  });

  // 4. شيت المنتجات الأكثر مشاهدة
  import_excel.Sheet productsSheet = excel['مشاهدات المنتجات'];
  productsSheet.appendRow([
    import_excel.TextCellValue('معرف/عنوان المنتج'),
    import_excel.TextCellValue('عدد المشاهدات')
  ]);

  for (var prod in liveProducts) {
    String title = prod['rawItem']['title'] ?? prod['id'];
    int views = prod['views'] ?? 0;
    productsSheet.appendRow([
      import_excel.TextCellValue(title),
      import_excel.IntCellValue(views)
    ]);
  }

  // 5. حفظ الملف على جهاز المستخدم
  final directory = await getApplicationDocumentsDirectory();
  final filePath = "${directory.path}/Analytics_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

  List<int>? fileBytes = excel.save();
  if (fileBytes != null) {
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    // فتح الملف تلقائياً بعد الحفظ
    await OpenFile.open(filePath);
  }
}