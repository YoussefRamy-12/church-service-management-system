@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/app/ui/app_ui.dart';
import 'package:church_service_management_system/app/ui/components/status_chip.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/attendance_record.dart';
import 'package:church_service_management_system/features/attendance/presentation/widgets/attendance_student_tile.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_student_item.dart';
import 'package:church_service_management_system/features/follow_up/presentation/widgets/follow_up_student_card.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

import 'goldens/golden_test_helper.dart';

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrapScaled(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

const _student = Student(
  id: 'student-1',
  serviceId: 'service-1',
  name: 'مينا فايز',
  approvalStatus: 'approved',
  currentClassId: 'class-1',
  phone: '01012345678',
);

final _attendanceRecord = AttendanceRecord(
  id: 'rec-1',
  meetingId: 'meeting-1',
  studentId: 'student-1',
  classIdAtAttendance: 'class-1',
  checkedInAt: DateTime(2026, 11, 24, 9, 15),
  recordedBy: 'servant-1',
  clientOperationId: 'op-1',
  syncState: 'synced',
);

const _followUpItem = FollowUpStudentItem(
  student: _student,
  className: 'خامسة ابتدائي',
  absenceCount: 3,
  totalEligibleMeetings: 12,
  activeCasesCount: 1,
  totalCasesCount: 2,
  latestFollowUpDate: '2026-11-20',
  latestFollowUpAuthor: 'أمين الفصل',
);

void main() {
  setUpAll(() async {
    await ensureGoldenTestSetup();
  });

  testWidgets('text scale 1.3 — dashboard KPI header', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapScaled(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لوحة الخدمة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            ResponsiveMetricGrid(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجمالي المخدومين'),
                      SizedBox(height: 6),
                      Text(
                        '148',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('نسبة الحضور'),
                      SizedBox(height: 6),
                      Text(
                        '86%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/scale13_dashboard.png'),
    );
  });

  testWidgets('text scale 1.3 — AttendanceStudentTile', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapScaled(
        AttendanceStudentTile(
          student: _student,
          record: _attendanceRecord,
          isBusy: false,
          readOnly: false,
          classColor: const Color(0xFF1D4ED8),
          classLabel: 'خامسة ابتدائي',
          attendanceTimingLabel: 'في الموعد',
          onCheckIn: () {},
          onEditTime: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/scale13_attendance_student_tile.png'),
    );
  });

  testWidgets('text scale 1.3 — StatusChip all 8 states', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapScaled(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in AppStatus.values) StatusChip(status: status),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/scale13_status_chip.png'),
    );
  });

  testWidgets('text scale 1.3 — FollowUpStudentCard', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapScaled(
        FollowUpStudentCard(
          item: _followUpItem,
          onTap: () {},
          onLogFollowUp: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/scale13_follow_up_student_card.png'),
    );
  });
}
