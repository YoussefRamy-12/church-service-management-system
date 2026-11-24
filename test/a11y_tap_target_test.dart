import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/app/ui/components/sync_badge.dart';
import 'package:church_service_management_system/features/attendance/presentation/widgets/attendance_student_tile.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

List<String> findSmallTapTargets(WidgetTester tester, {double minSize = 44}) {
  final smallTargets = <String>[];
  final targetTypes = <Type>[
    GestureDetector,
    InkWell,
    IconButton,
    TextButton,
    OutlinedButton,
    ElevatedButton,
  ];

  for (final type in targetTypes) {
    final finder = find.byType(type);
    for (final element in finder.evaluate()) {
      final renderObject = element.renderObject;
      if (renderObject is RenderBox && renderObject.hasSize) {
        final size = renderObject.size;
        if (size.width < minSize || size.height < minSize) {
          smallTargets.add(
            '$type (${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)})',
          );
        }
      }
    }
  }

  if (smallTargets.isNotEmpty) {
    // ignore: avoid_print
    print('Small tap targets found (< $minSize): $smallTargets');
  }
  return smallTargets;
}

void main() {
  testWidgets('AttendanceStudentTile meets minimum 44x44 tap target size', (
    tester,
  ) async {
    const student = Student(
      id: 'student-1',
      serviceId: 'service-1',
      name: 'مينا فايز',
      approvalStatus: 'approved',
      currentClassId: 'class-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AttendanceStudentTile(
            student: student,
            record: null,
            isBusy: false,
            readOnly: false,
            classColor: Colors.blue,
            classLabel: 'خامسة ابتدائي',
            attendanceTimingLabel: '',
            onCheckIn: () {},
            onEditTime: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final smallTargets = findSmallTapTargets(tester);
    expect(smallTargets, isEmpty);
  });

  testWidgets('SyncBadge meets minimum 44x44 tap target size when interactive', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SyncBadge(
              state: SyncState.pending,
              count: 3,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final smallTargets = findSmallTapTargets(tester);
    expect(smallTargets, isEmpty);
  });
}
