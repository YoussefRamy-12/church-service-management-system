import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import 'attendance_counters.dart';

class AttendanceSessionHeader extends StatelessWidget {
  const AttendanceSessionHeader({
    super.key,
    required this.readOnly,
    required this.allStudentsMode,
    required this.meetingTime,
    required this.earlyAttendanceMinutes,
    required this.openingQrScanner,
    required this.onOpenQrScanner,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.earlyCount,
    required this.beforeMeetingCount,
    required this.normalCount,
  });

  final bool readOnly;
  final bool allStudentsMode;
  final TimeOfDay meetingTime;
  final int earlyAttendanceMinutes;
  final bool openingQrScanner;
  final VoidCallback onOpenQrScanner;
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int earlyCount;
  final int beforeMeetingCount;
  final int normalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اجتماع سابق — العرض فقط، تم إيقاف تعديل وتسجيل الحضور.',
                  ),
                ),
              ],
            ),
          ),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 14),
          borderRadius: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00236F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00236F).withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Color(0xFF00236F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allStudentsMode
                              ? 'جلسة حضور الخدمة العامة'
                              : 'جلسة الحضور الميداني',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'بداية الاجتماع: ${meetingTime.format(context)} • الحضور المبكر حتى ${TimeOfDay.fromDateTime(DateTime(2020, 1, 1, meetingTime.hour, meetingTime.minute).add(Duration(minutes: earlyAttendanceMinutes))).format(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!readOnly)
                    FilledButton.icon(
                      onPressed: openingQrScanner ? null : onOpenQrScanner,
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 20,
                      ),
                      label: const Text('مسح QR'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AttendanceCounters(
                totalCount: totalCount,
                presentCount: presentCount,
                absentCount: absentCount,
                earlyCount: earlyCount,
                beforeMeetingCount: beforeMeetingCount,
                normalCount: normalCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
