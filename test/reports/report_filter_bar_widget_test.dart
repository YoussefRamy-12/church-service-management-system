import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/reports/presentation/report_providers.dart';
import 'package:church_service_management_system/features/reports/presentation/widgets/report_filter_bar.dart';

void main() {
  testWidgets('mobile report filters open in one bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
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
        ],
        child: const MaterialApp(
          home: Scaffold(
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تصفية'), findsOneWidget);
    expect(find.text('الفلاتر النشطة'), findsOneWidget);

    await tester.tap(find.text('تصفية'));
    await tester.pumpAndSettle();

    expect(find.text('تصفية التقارير'), findsOneWidget);
    expect(find.text('فترة مخصصة'), findsOneWidget);
    expect(find.text('إعادة ضبط'), findsOneWidget);
  });
}
