import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/report_filter.dart';
import '../../domain/service_report.dart';
import '../report_providers.dart';

class ReportExportDialog extends ConsumerStatefulWidget {
  const ReportExportDialog({
    super.key,
    required this.report,
    required this.filter,
  });

  final ServiceReport report;
  final ReportFilter filter;

  @override
  ConsumerState<ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends ConsumerState<ReportExportDialog> {
  String selectedFormat = 'pdf'; // 'pdf', 'excel', 'csv'
  String csvSection = 'classes';
  bool exporting = false;

  Future<void> _export() async {
    setState(() => exporting = true);
    final exportService = ref.read(reportExportServiceProvider);
    final formatter = DateFormat('yyyyMMdd');
    final dateSuffix =
        '${formatter.format(widget.filter.start)}_${formatter.format(widget.filter.end)}';

    try {
      if (selectedFormat == 'pdf') {
        final bytes = await exportService.generatePdf(
          report: widget.report,
          filter: widget.filter,
        );
        exportService.download(
          bytes: bytes,
          filename: 'تقرير_الخدمة_$dateSuffix.pdf',
          mimeType: 'application/pdf',
        );
      } else if (selectedFormat == 'excel') {
        final bytes = exportService.generateExcel(
          report: widget.report,
          filter: widget.filter,
        );
        exportService.download(
          bytes: bytes,
          filename: 'إحصائيات_الخدمة_$dateSuffix.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        final bytes = exportService.generateCsv(
          report: widget.report,
          section: csvSection,
        );
        exportService.download(
          bytes: bytes,
          filename: 'بيانات_${csvSection}_$dateSuffix.csv',
          mimeType: 'text/csv;charset=utf-8;',
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استخراج وتنزيل التقرير بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر استخراج التقرير: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF131D33) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00236F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.file_download_rounded,
                    color: Color(0xFF00236F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصدير تقرير الخدمة والإحصائيات',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اختر الصيغة المناسبة لتصدير بيانات الفترة المحددة',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Format Selector Cards
            _formatOption(
              id: 'pdf',
              title: 'مستند PDF رسمي ملون',
              subtitle: 'جاهز للطباعة والمشاركة، يتضمن ملخص المؤشرات والجداول',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _formatOption(
              id: 'excel',
              title: 'ملف Excel (XLSX) متعدد الصفحات',
              subtitle: 'يتضمن صفحات منفصلة للحضور، الفصول، والغياب المتكرر',
              icon: Icons.table_view_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _formatOption(
              id: 'csv',
              title: 'ملف بيانات جدولية (CSV)',
              subtitle: 'تصدير جدول محدد بترميز UTF-8 مع دعم كامل للعربية',
              icon: Icons.grid_on_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
            if (selectedFormat == 'csv') ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: csvSection,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'الجدول المراد تصديره',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'classes',
                    child: Text('مقارنة فصول الخدمة'),
                  ),
                  DropdownMenuItem(
                    value: 'repeated_absences',
                    child: Text('سجل الغياب المتكرر'),
                  ),
                  DropdownMenuItem(
                    value: 'meetings',
                    child: Text('تاريخ الحضور بالاجتماعات'),
                  ),
                  DropdownMenuItem(
                    value: 'servants',
                    child: Text('أعباء ومتابعات الخدام'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => csvSection = val);
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: exporting ? null : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: exporting ? null : _export,
                  icon: exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(exporting ? 'جاري التصدير...' : 'تنزيل التقرير'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = selectedFormat == id;
    return InkWell(
      onTap: () => setState(() => selectedFormat = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF182234) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? color
                  : (isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8)),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

