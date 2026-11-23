import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceStudentTile extends StatelessWidget {
  const AttendanceStudentTile({
    super.key,
    required this.student,
    required this.record,
    required this.isBusy,
    required this.readOnly,
    required this.classColor,
    required this.classLabel,
    required this.attendanceLabel,
    required this.attendanceColor,
    required this.onCheckIn,
    required this.onEditTime,
  });

  final Student student;
  final AttendanceRecord? record;
  final bool isBusy;
  final bool readOnly;
  final Color classColor;
  final String classLabel;
  final String attendanceLabel;
  final Color attendanceColor;
  final VoidCallback onCheckIn;
  final VoidCallback onEditTime;

  @override
  Widget build(BuildContext context) {
    final isPresent = record != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SolidCard(
      key: ValueKey(student.id),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      borderRadius: 12,
      child: Row(
        children: [
          // Avatar (Solid surface, no gradient/glow)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPresent
                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                  : (student.isPending
                      ? const Color(0xFFD97706).withValues(alpha: 0.10)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9))),
              border: Border.all(
                color: isPresent
                    ? const Color(0xFF059669).withValues(alpha: 0.30)
                    : (student.isPending
                        ? const Color(0xFFD97706).withValues(alpha: 0.25)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0))),
              ),
            ),
            alignment: Alignment.center,
            child: isPresent
                ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF059669),
                    size: 20,
                  )
                : Text(
                    student.name.isNotEmpty
                        ? student.name.characters.first
                        : 'ت',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: classColor.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: classColor.withValues(alpha: .30)),
                      ),
                      child: Text(
                        classLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: classColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (student.isPending)
                      const GlassBadge(
                        label: 'بانتظار الاعتماد',
                        color: Color(0xFFD97706),
                        showDot: true,
                      ),
                    if (isPresent) ...[
                      GlassBadge(
                        label: attendanceLabel,
                        color: attendanceColor,
                        showDot: false,
                      ),
                      Text(
                        TimeOfDay.fromDateTime(
                          record!.checkedInAt,
                        ).format(context),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'غير مسجل',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action Button
          if (isPresent)
            OutlinedButton.icon(
              onPressed: readOnly ? null : onEditTime,
              icon: const Icon(
                Icons.access_time_rounded,
                size: 16,
              ),
              label: const Text('تعديل'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: readOnly || isBusy ? null : onCheckIn,
              icon: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.how_to_reg_rounded,
                      size: 18,
                    ),
              label: const Text('تسجيل'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                minimumSize: const Size(88, 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
