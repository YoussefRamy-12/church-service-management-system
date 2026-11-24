import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_student_item.dart';
import 'package:church_service_management_system/features/follow_up/presentation/widgets/follow_up_student_card.dart';
import 'package:church_service_management_system/features/reports/domain/report_filter.dart';
import 'package:church_service_management_system/features/reports/presentation/report_providers.dart';
import 'package:church_service_management_system/features/reports/presentation/widgets/report_filter_bar.dart';
import 'package:church_service_management_system/features/servants/presentation/servant_role_filter.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

class _FixedReportFilterNotifier extends ReportFilterNotifier {
  @override
  ReportFilter build() => ReportFilter(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 24),
        preset: ReportPeriodPreset.currentMonth,
      );
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _student = Student(
  id: 'student-1',
  serviceId: 'service-1',
  name: 'مينا فايز',
  approvalStatus: 'approved',
  currentClassId: 'class-1',
  phone: '01012345678',
);

const _studentItem = FollowUpStudentItem(
  student: _student,
  className: 'خامسة ابتدائي',
  absenceCount: 3,
  totalEligibleMeetings: 12,
  activeCasesCount: 1,
  totalCasesCount: 2,
  latestFollowUpDate: '2026-11-20',
  latestFollowUpAuthor: 'أمين الفصل',
);

Widget _reportFilterScreen(ThemeData theme) {
  return ProviderScope(
    overrides: [
      reportUserScopeProvider('service-1').overrideWith(
        (ref) async => const ReportUserScope(
          role: 'overall_leader',
          isServiceWide: true,
          stageId: null,
          classId: null,
          accessibleClassIds: null,
          accessibleStageIds: null,
        ),
      ),
      reportFilterProvider.overrideWith(_FixedReportFilterNotifier.new),
    ],
    child: MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: ReportFilterBar(
            serviceId: 'service-1',
            stages: [],
            classes: [],
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final mode in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('follow-up mobile card — ${mode.$1}', (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: mode.$2,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: FollowUpStudentCard(
                item: _studentItem,
                onTap: () {},
                onLogFollowUp: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/task6/follow_up_${mode.$1}.png'),
      );
    });

    testWidgets('servant role filters — ${mode.$1}', (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: mode.$2,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: ServantRoleFilter(
                selectedRole: 'stage_leader',
                onChanged: _ignoreRole,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/task6/servant_roles_${mode.$1}.png'),
      );
    });

    testWidgets('report filter panel — ${mode.$1}', (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(_reportFilterScreen(mode.$2));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/task6/report_filter_panel_${mode.$1}.png'),
      );

      await tester.tap(find.text('تصفية').first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/task6/report_filter_sheet_${mode.$1}.png'),
      );
    });
  }
}

void _ignoreRole(String _) {}
