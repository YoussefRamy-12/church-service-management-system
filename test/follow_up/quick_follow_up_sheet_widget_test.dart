import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_case.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_case_providers.dart';
import 'package:church_service_management_system/features/follow_up/presentation/widgets/quick_follow_up_sheet.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_student_item.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

void main() {
  const serviceId = 'service-1';
  const student = Student(
    id: 'student-1',
    serviceId: serviceId,
    name: 'مينا',
    approvalStatus: 'approved',
    currentClassId: 'class-1',
  );
  const item = FollowUpStudentItem(
    student: student,
    className: 'خامسة ابتدائي',
    absenceCount: 2,
    totalEligibleMeetings: 8,
    activeCasesCount: 0,
    totalCasesCount: 0,
  );

  Widget buildSubject(
    Stream<List<FollowUpCase>> stream,
  ) {
    return ProviderScope(
      overrides: [
        studentCasesProvider((
          serviceId: serviceId,
          studentId: student.id,
        )).overrideWith((ref) => stream),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: QuickFollowUpSheet(
            serviceId: serviceId,
            item: item,
          ),
        ),
      ),
    );
  }

  testWidgets('shows a loading state while student cases load', (tester) async {
    final controller = StreamController<List<FollowUpCase>>();
    await tester.pumpWidget(buildSubject(controller.stream));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await controller.close();
  });

  testWidgets('explains when there is no open case', (tester) async {
    await tester.pumpWidget(buildSubject(Stream.value(const [])));
    await tester.pumpAndSettle();

    expect(
      find.text('لا توجد حالة متابعة مفتوحة لهذا التلميذ.'),
      findsOneWidget,
    );
    expect(find.text('فتح حالة متابعة'), findsOneWidget);
  });

  testWidgets('shows retry feedback when cases fail to load', (tester) async {
    await tester.pumpWidget(
      buildSubject(Stream.error(StateError('offline'))),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('تعذر تحميل حالات المتابعة المرتبطة بالتلميذ.'),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
