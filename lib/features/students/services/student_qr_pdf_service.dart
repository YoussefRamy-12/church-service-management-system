import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/file_download_helper.dart';
import '../domain/entities/student.dart';

class StudentQrPdfService {
  const StudentQrPdfService();

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

  /// Generates a printable card PDF for a single student.
  Future<Uint8List> generateSingleStudentCardPdf({
    required Student student,
    String? serviceName,
    String? className,
  }) async {
    final pdf = pw.Document();
    final font = await _loadArabicFont();
    final boldFont = await _loadArabicBoldFont();

    // ID Card page: 85.6mm x 54mm (standard CR80 card size)
    const cardWidth = 85.6 * PdfPageFormat.mm;
    const cardHeight = 54.0 * PdfPageFormat.mm;
    const pageFormat = PdfPageFormat(
      cardWidth,
      cardHeight,
      marginAll: 2 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: PdfColor.fromHex('00236F'),
                width: 1.5,
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Row(
              children: [
                // Right Column: QR Code + Student ID
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: student.id,
                          width: 82,
                          height: 82,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        student.id,
                        style: const pw.TextStyle(
                          fontSize: 5,
                          color: PdfColors.grey700,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 6),
                // Left Column: Identity & Service Info (RTL)
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Header Badge
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('EFF4FF'),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(3),
                          ),
                        ),
                        child: pw.Text(
                          serviceName != null && serviceName.isNotEmpty
                              ? serviceName
                              : 'خدمة التربية الكنسية',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 7.5,
                            color: PdfColor.fromHex('00236F'),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      // Student Name directly highlighted
                      pw.Text(
                        student.name,
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          color: PdfColor.fromHex('0D1C2E'),
                        ),
                        maxLines: 2,
                      ),
                      pw.SizedBox(height: 2),
                      if (className != null && className.isNotEmpty)
                        pw.Text(
                          'الفصل: $className',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 7.5,
                            color: PdfColors.grey800,
                          ),
                        ),
                      if (student.grade != null && student.grade!.isNotEmpty)
                        pw.Text(
                          'الصف: ${student.grade}',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 7,
                            color: PdfColors.grey700,
                          ),
                        ),
                      pw.SizedBox(height: 4),
                      // Card footer note
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(2),
                          ),
                        ),
                        child: pw.Text(
                          'بطاقة الحضور والافتقاد الذكية',
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 5.5,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a printable A4 sheet with multiple cards in an 8-card grid.
  Future<Uint8List> generateClassCardsPdf({
    required List<Student> students,
    String? serviceName,
    String? className,
  }) async {
    final pdf = pw.Document();
    final font = await _loadArabicFont();
    final boldFont = await _loadArabicBoldFont();

    // 8 cards per A4 page (2 columns x 4 rows)
    const cardsPerPage = 8;
    final pageCount = (students.length / cardsPerPage).ceil();

    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final startIndex = pageIndex * cardsPerPage;
      final pageStudents = students
          .skip(startIndex)
          .take(cardsPerPage)
          .toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (context) {
            return pw.Column(
              children: [
                // Page Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'صفحة ${pageIndex + 1} من $pageCount',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'بطاقات حضور الطلاب - ${className ?? ''} (${serviceName ?? 'خدمة التربية الكنسية'})',
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          color: PdfColor.fromHex('00236F'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid of cards
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    childAspectRatio: 85.6 / 54.0,
                    crossAxisSpacing: 8 * PdfPageFormat.mm,
                    mainAxisSpacing: 6 * PdfPageFormat.mm,
                    children: [
                      for (final s in pageStudents)
                        _buildGridCard(
                          student: s,
                          font: font,
                          boldFont: boldFont,
                          serviceName: serviceName,
                          className: className,
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

    return pdf.save();
  }

  pw.Widget _buildGridCard({
    required Student student,
    required pw.Font font,
    required pw.Font boldFont,
    String? serviceName,
    String? className,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('00236F'), width: 1.2),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Row(
        children: [
          // QR Column
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: student.id,
                    width: 76,
                    height: 76,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  student.id,
                  style: const pw.TextStyle(
                    fontSize: 4.5,
                    color: PdfColors.grey700,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          // Info Column
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('EFF4FF'),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(3),
                    ),
                  ),
                  child: pw.Text(
                    serviceName ?? 'خدمة التربية الكنسية',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 7,
                      color: PdfColor.fromHex('00236F'),
                    ),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  student.name,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: PdfColor.fromHex('0D1C2E'),
                  ),
                  maxLines: 2,
                ),
                pw.SizedBox(height: 2),
                if (className != null)
                  pw.Text(
                    'الفصل: $className',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 7,
                      color: PdfColors.grey800,
                    ),
                  ),
                if (student.grade != null && student.grade!.isNotEmpty)
                  pw.Text(
                    'الصف: ${student.grade}',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 6.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'بطاقة حضور ذكية',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 5.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Downloads the PDF bytes through browser file download.
  void downloadPdf({required Uint8List bytes, required String filename}) {
    FileDownloadHelper.downloadBytes(
      bytes: bytes,
      filename: filename,
      mimeType: 'application/pdf',
    );
  }
}
