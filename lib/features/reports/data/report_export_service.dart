import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/file_download_helper.dart';
import '../domain/report_filter.dart';
import '../domain/service_report.dart';

class ReportExportService {
  const ReportExportService();

  static pw.Font? _cachedFont;
  static pw.Font? _cachedBoldFont;

  static Future<pw.Font> _loadArabicFont() async {
    if (_cachedFont != null) return _cachedFont!;
    try {
      final bytes = await rootBundle.load('assets/fonts/arial.ttf');
      _cachedFont = pw.Font.ttf(bytes);
      return _cachedFont!;
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  static Future<pw.Font> _loadArabicBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    try {
      final bytes = await rootBundle.load('assets/fonts/arial.ttf');
      _cachedBoldFont = pw.Font.ttf(bytes);
      return _cachedBoldFont!;
    } catch (_) {
      return pw.Font.helveticaBold();
    }
  }

  /// Exports comprehensive PDF report.
  Future<Uint8List> generatePdf({
    required ServiceReport report,
    required ReportFilter filter,
    String churchName = 'كنيسة السيدة العذراء بعياد بك',
    String serviceName = 'أسرة تلاميذ المسيح (٥ و٦ ابتدائي بنين)',
  }) async {
    final pdf = pw.Document();
    final font = await _loadArabicFont();
    final boldFont = await _loadArabicBoldFont();
    final formatter = DateFormat('yyyy/MM/dd');

    final periodStr =
        'الفترة من ${formatter.format(filter.start)} إلى ${formatter.format(filter.end)}';
    final genDate = formatter.format(DateTime.now());

    // Page 1: Executive Summary & KPIs & Class comparison
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16 * PdfPageFormat.mm),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تاريخ الاستخراج: $genDate',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      churchName,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      serviceName,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.blue900),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'نظام إدارة الخدمة والافتقاد الرعوي الذكي',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // Title & Scope
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('EFF4FF'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.blue800, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    'التقرير التحليلي الدوري للحضور والافتقاد الرعوي',
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (report.scopedClassName != null)
                        pw.Text(
                          'نطاق الفصل: ${report.scopedClassName} • ',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blue800),
                        ),
                      if (report.scopedStageName != null)
                        pw.Text(
                          'المرحلة: ${report.scopedStageName} • ',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blue800),
                        ),
                      pw.Text(
                        periodStr,
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // KPI Grid Cards (2 rows x 3 cols)
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _kpiCell('إجمالي المخدومين', '${report.students}', font, boldFont),
                    _kpiCell('الاجتماعات المنعقدة', '${report.meetings}', font, boldFont),
                    _kpiCell('معدل الحضور العام', '${report.attendancePercentage.toStringAsFixed(1)}%', font, boldFont),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _kpiCell('حضور مبكر', '${report.earlyRate.toStringAsFixed(1)}%', font, boldFont),
                    _kpiCell('غياب متكرر (≥2)', '${report.repeatedAbsences.length}', font, boldFont),
                    _kpiCell('إنجاز الافتقاد', '${report.followUpAnalytics?.completionRate.toStringAsFixed(1) ?? "100"}%', font, boldFont),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Section: Class Comparison
            if (report.classComparisons.isNotEmpty) ...[
              pw.Text(
                'مقارنة الحضور والالتزام بين فصول الخدمة',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                  5: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('1E3A8A')),
                    children: [
                      _headerCell('الفصل والمرحلة', boldFont),
                      _headerCell('التلاميذ', boldFont),
                      _headerCell('الحضور', boldFont),
                      _headerCell('نسبة الحضور', boldFont),
                      _headerCell('غياب متكرر', boldFont),
                      _headerCell('إنجاز الافتقاد', boldFont),
                    ],
                  ),
                  for (final c in report.classComparisons)
                    pw.TableRow(
                      children: [
                        _dataCell('${c.className} (${c.stageName})', font),
                        _dataCell('${c.totalStudents}', font),
                        _dataCell('${c.presentCount}/${c.expectedAttendance}', font),
                        _dataCell('${c.attendanceRate.toStringAsFixed(1)}%', font),
                        _dataCell('${c.repeatedAbsencesCount}', font),
                        _dataCell('${c.followUpCompletionRate.toStringAsFixed(0)}%', font),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Section: Repeated Absences
            if (report.repeatedAbsences.isNotEmpty) ...[
              pw.Text(
                'قائمة التلاميذ ذوي الغياب المتكرر (تحتاج إلى افتقاد عاجل)',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.red900),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('991B1B')),
                    children: [
                      _headerCell('اسم التلميذ', boldFont),
                      _headerCell('الفصل', boldFont),
                      _headerCell('مرات الغياب', boldFont),
                      _headerCell('آخر اجتماع حضره', boldFont),
                      _headerCell('هاتف للتواصل', boldFont),
                    ],
                  ),
                  for (final r in report.repeatedAbsences.take(15))
                    pw.TableRow(
                      children: [
                        _dataCell(r.studentName, font),
                        _dataCell(r.className, font),
                        _dataCell('${r.consecutiveMissedMeetings} اجتماعات', font),
                        _dataCell(r.lastAttendedDate ?? 'لم يحضر مؤخراً', font),
                        _dataCell(r.phone ?? '-', font),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Section: Servant Workload
            if (report.servantWorkloads.isNotEmpty) ...[
              pw.Text(
                'ملخص متابعات وأعباء الخدام',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('1E3A8A')),
                    children: [
                      _headerCell('اسم الخادم', boldFont),
                      _headerCell('الفصل المسند', boldFont),
                      _headerCell('حالات الافتقاد', boldFont),
                      _headerCell('أنشطة منجزة', boldFont),
                    ],
                  ),
                  for (final sw in report.servantWorkloads)
                    pw.TableRow(
                      children: [
                        _dataCell(sw.servantName, font),
                        _dataCell(sw.className ?? 'إشراف عام', font),
                        _dataCell('${sw.assignedCasesCount}', font),
                        _dataCell('${sw.completedActivitiesCount}', font),
                      ],
                    ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Exports comprehensive multi-sheet Excel spreadsheet.
  Uint8List generateExcel({
    required ServiceReport report,
    required ReportFilter filter,
  }) {
    final excel = Excel.createExcel();
    final formatter = DateFormat('yyyy/MM/dd');

    // 1. Overview Sheet
    final overviewSheet = excel['ملخص التقرير'];
    excel.setDefaultSheet('ملخص التقرير');

    overviewSheet.appendRow([
      TextCellValue('التقرير التحليلي الدوري لخدمة التربية الكنسية'),
    ]);
    overviewSheet.appendRow([
      TextCellValue(
        'الفترة: ${formatter.format(filter.start)} - ${formatter.format(filter.end)}',
      ),
    ]);
    overviewSheet.appendRow([TextCellValue('')]);
    overviewSheet.appendRow([TextCellValue('المؤشر'), TextCellValue('القيمة')]);
    overviewSheet.appendRow([
      TextCellValue('إجمالي التلاميذ المسجلين'),
      IntCellValue(report.students),
    ]);
    overviewSheet.appendRow([
      TextCellValue('الاجتماعات المنعقدة'),
      IntCellValue(report.meetings),
    ]);
    overviewSheet.appendRow([
      TextCellValue('الحضور المتوقع الكلي'),
      IntCellValue(report.expectedAttendance),
    ]);
    overviewSheet.appendRow([
      TextCellValue('الحضور الفعلي'),
      IntCellValue(report.present),
    ]);
    overviewSheet.appendRow([
      TextCellValue('نسبة الحضور العام'),
      DoubleCellValue(double.parse(report.attendancePercentage.toStringAsFixed(1))),
    ]);
    overviewSheet.appendRow([
      TextCellValue('حضور مبكر'),
      IntCellValue(report.early + report.before),
    ]);
    overviewSheet.appendRow([
      TextCellValue('حضور عادي'),
      IntCellValue(report.normal),
    ]);
    overviewSheet.appendRow([
      TextCellValue('تلاميذ الغياب المتكرر'),
      IntCellValue(report.repeatedAbsences.length),
    ]);
    overviewSheet.appendRow([
      TextCellValue('إجمالي حالات الافتقاد'),
      IntCellValue(report.followUpAnalytics?.totalCases ?? report.followUps),
    ]);
    overviewSheet.appendRow([
      TextCellValue('نسبة إنجاز الافتقاد'),
      DoubleCellValue(double.parse((report.followUpAnalytics?.completionRate ?? 100.0).toStringAsFixed(1))),
    ]);

    // 2. Class Comparison Sheet
    if (report.classComparisons.isNotEmpty) {
      final classSheet = excel['مقارنة الفصول'];
      classSheet.appendRow([
        TextCellValue('الفصل'),
        TextCellValue('المرحلة'),
        TextCellValue('عدد التلاميذ'),
        TextCellValue('الحضور المتوقع'),
        TextCellValue('الحضور الفعلي'),
        TextCellValue('نسبة الحضور %'),
        TextCellValue('حضور مبكر %'),
        TextCellValue('الغياب المتكرر'),
        TextCellValue('حالات الافتقاد المفتوحة'),
        TextCellValue('حالات الافتقاد المحسومة'),
        TextCellValue('نسبة إنجاز الافتقاد %'),
      ]);

      for (final c in report.classComparisons) {
        classSheet.appendRow([
          TextCellValue(c.className),
          TextCellValue(c.stageName),
          IntCellValue(c.totalStudents),
          IntCellValue(c.expectedAttendance),
          IntCellValue(c.presentCount),
          DoubleCellValue(double.parse(c.attendanceRate.toStringAsFixed(1))),
          DoubleCellValue(double.parse(c.earlyRate.toStringAsFixed(1))),
          IntCellValue(c.repeatedAbsencesCount),
          IntCellValue(c.openCasesCount),
          IntCellValue(c.resolvedCasesCount),
          DoubleCellValue(double.parse(c.followUpCompletionRate.toStringAsFixed(1))),
        ]);
      }
    }

    // 3. Repeated Absences Sheet
    if (report.repeatedAbsences.isNotEmpty) {
      final absSheet = excel['الغياب المتكرر'];
      absSheet.appendRow([
        TextCellValue('اسم التلميذ'),
        TextCellValue('الفصل'),
        TextCellValue('عدد مرات الغياب المتتالية'),
        TextCellValue('آخر اجتماع حضره'),
        TextCellValue('رقم الهاتف'),
      ]);

      for (final r in report.repeatedAbsences) {
        absSheet.appendRow([
          TextCellValue(r.studentName),
          TextCellValue(r.className),
          IntCellValue(r.consecutiveMissedMeetings),
          TextCellValue(r.lastAttendedDate ?? 'لم يحضر'),
          TextCellValue(r.phone ?? ''),
        ]);
      }
    }

    // 4. Servant Workload Sheet
    if (report.servantWorkloads.isNotEmpty) {
      final servantSheet = excel['أعباء الخدام'];
      servantSheet.appendRow([
        TextCellValue('اسم الخادم'),
        TextCellValue('الفصل'),
        TextCellValue('الدور'),
        TextCellValue('حالات الافتقاد المسندة'),
        TextCellValue('الأنشطة الافتقادية المنجزة'),
      ]);

      for (final sw in report.servantWorkloads) {
        servantSheet.appendRow([
          TextCellValue(sw.servantName),
          TextCellValue(sw.className ?? 'إشراف عام'),
          TextCellValue(sw.role),
          IntCellValue(sw.assignedCasesCount),
          IntCellValue(sw.completedActivitiesCount),
        ]);
      }
    }

    // 5. Meetings History Sheet
    if (report.meetingHistory.isNotEmpty) {
      final meetingSheet = excel['سجل الاجتماعات'];
      meetingSheet.appendRow([
        TextCellValue('تاريخ الاجتماع'),
        TextCellValue('اسم الاجتماع'),
        TextCellValue('وقت البداية'),
        TextCellValue('حضور متوقع'),
        TextCellValue('حضور فعلي'),
        TextCellValue('نسبة الحضور %'),
        TextCellValue('حضور مبكر'),
        TextCellValue('حضور عادي'),
      ]);

      for (final m in report.meetingHistory) {
        meetingSheet.appendRow([
          TextCellValue(m.meetingDate),
          TextCellValue(m.meetingName),
          TextCellValue(m.startTime),
          IntCellValue(m.expectedCount),
          IntCellValue(m.presentCount),
          DoubleCellValue(double.parse(m.attendanceRate.toStringAsFixed(1))),
          IntCellValue(m.earlyCount + m.beforeCount),
          IntCellValue(m.normalCount),
        ]);
      }
    }

    // Remove default Sheet1 if exists and empty
    try {
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
    } catch (_) {}

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Exports CSV with UTF-8 BOM so Excel opens Arabic correctly.
  Uint8List generateCsv({
    required ServiceReport report,
    required String section, // 'classes', 'repeated_absences', 'meetings', 'servants'
  }) {
    final buffer = StringBuffer();
    // Add UTF-8 BOM
    buffer.write('\uFEFF');

    if (section == 'classes') {
      buffer.writeln(
        'الفصل,المرحلة,عدد التلاميذ,الحضور المتوقع,الحضور الفعلي,نسبة الحضور %,الغياب المتكرر,إنجاز الافتقاد %',
      );
      for (final c in report.classComparisons) {
        buffer.writeln(
          '"${c.className}","${c.stageName}",${c.totalStudents},${c.expectedAttendance},${c.presentCount},${c.attendanceRate.toStringAsFixed(1)},${c.repeatedAbsencesCount},${c.followUpCompletionRate.toStringAsFixed(1)}',
        );
      }
    } else if (section == 'repeated_absences') {
      buffer.writeln('اسم التلميذ,الفصل,مرات الغياب المتتالية,آخر حضور,الهاتف');
      for (final r in report.repeatedAbsences) {
        buffer.writeln(
          '"${r.studentName}","${r.className}",${r.consecutiveMissedMeetings},"${r.lastAttendedDate ?? ''}","${r.phone ?? ''}"',
        );
      }
    } else if (section == 'servants') {
      buffer.writeln('اسم الخادم,الفصل,الدور,الحالات المسندة,الأنشطة المنجزة');
      for (final sw in report.servantWorkloads) {
        buffer.writeln(
          '"${sw.servantName}","${sw.className ?? ''}","${sw.role}",${sw.assignedCasesCount},${sw.completedActivitiesCount}',
        );
      }
    } else {
      // Meetings
      buffer.writeln(
        'تاريخ الاجتماع,اسم الاجتماع,وقت البداية,المتوقع,الفعلي,نسبة الحضور %,مبكر,عادي',
      );
      for (final m in report.meetingHistory) {
        buffer.writeln(
          '"${m.meetingDate}","${m.meetingName}","${m.startTime}",${m.expectedCount},${m.presentCount},${m.attendanceRate.toStringAsFixed(1)},${m.earlyCount + m.beforeCount},${m.normalCount}',
        );
      }
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Triggers browser download.
  void download({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) {
    FileDownloadHelper.downloadBytes(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
  }

  // PDF cell helpers
  pw.Widget _kpiCell(String title, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.blue900),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _dataCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey900),
      ),
    );
  }
}

