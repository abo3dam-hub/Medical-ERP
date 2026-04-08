// lib/data/services/export_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'services.dart';

class ExportService {
  static const String clinicName = 'عيادة الصحة والشفاء';

  // ── تصدير PDF للتقرير ──
  static Future<void> exportReportToPdf(PeriodReport report) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // رأس الصفحة
          pw.Center(
            child: pw.Text(
              clinicName,
              style: pw.TextStyle(font: fontBold, fontSize: 20),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'تقرير ${report.type}: ${DateFormat('yyyy/MM/dd').format(report.from)} - ${DateFormat('yyyy/MM/dd').format(report.to)}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // جدول الملخص
          pw.TableHelper.fromTextArray(
            headers: ['البيان', 'المبلغ (د.ع)'],
            data: [
              ['إجمالي الإيرادات', _formatNum(report.totalIncome)],
              ['إجمالي المصاريف', _formatNum(report.totalExpenses)],
              ['صافي الربح', _formatNum(report.netProfit)],
            ],
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 11),
            cellStyle: pw.TextStyle(font: font, fontSize: 11),
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerRight,
          ),

          pw.SizedBox(height: 16),

          // تقرير الأطباء
          if (report.doctorRevenues.isNotEmpty) ...[
            pw.Text('أداء الأطباء',
                style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['الطبيب', 'التخصص', 'إجمالي الإيرادات', 'العمولة', 'الصافي'],
              data: report.doctorRevenues.map((r) => [
                r.doctor.name,
                r.doctor.specialty ?? '-',
                _formatNum(r.totalRevenue),
                '${r.doctor.commission}%',
                _formatNum(r.netRevenue),
              ]).toList(),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              border: pw.TableBorder.all(),
            ),
          ],

          pw.Spacer(),

          // تذييل
          pw.Divider(),
          pw.Text(
            'تم الإنشاء بتاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ── تصدير Excel ──
  static Future<void> exportToExcel({
    required List<Payment> payments,
    required List<Expense> expenses,
    required String title,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['التقرير'];

    // رأس الجدول
    sheet.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('النوع'),
      TextCellValue('المبلغ'),
      TextCellValue('ملاحظات'),
    ]);

    for (final p in payments) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy/MM/dd').format(p.date)),
        const TextCellValue('إيراد'),
        DoubleCellValue(p.amount),
        TextCellValue(p.notes ?? ''),
      ]);
    }

    for (final e in expenses) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy/MM/dd').format(e.date)),
        const TextCellValue('مصروف'),
        DoubleCellValue(e.amount),
        TextCellValue(e.title),
      ]);
    }

    final saveDir = await FilePicker.platform.getDirectoryPath();
    if (saveDir == null) return;

    final path = '$saveDir/$title.xlsx';
    final bytes = excel.encode();
    if (bytes != null) {
      await File(path).writeAsBytes(bytes);
    }
  }

  static String _formatNum(double n) =>
      NumberFormat('#,##0.00', 'ar').format(n);
}
