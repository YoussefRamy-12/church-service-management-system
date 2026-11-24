@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/app/ui/app_ui.dart' hide EmptyState;
import 'package:church_service_management_system/app/ui/components/empty_state.dart';
import 'package:church_service_management_system/app/ui/components/status_chip.dart';
import 'package:church_service_management_system/app/ui/components/sync_badge.dart';

import 'goldens/golden_test_helper.dart';

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrapDark(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await ensureGoldenTestSetup();
  });

  testWidgets('dark_status_chip_present', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(_wrapDark(const StatusChip(status: AppStatus.present)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_status_chip_present.png'),
    );
  });

  testWidgets('dark_status_chip_absent', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(_wrapDark(const StatusChip(status: AppStatus.absent)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_status_chip_absent.png'),
    );
  });

  testWidgets('dark_status_chip_synced', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(_wrapDark(const StatusChip(status: AppStatus.synced)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_status_chip_synced.png'),
    );
  });

  testWidgets('dark_app_card', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapDark(
        AppCard(
          onTap: () {},
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('فصل خامسة ابتدائي'),
              SizedBox(height: 6),
              Text('عدد المخدومين: 24 • نسبة الحضور: 92%'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_app_card.png'),
    );
  });

  testWidgets('dark_sync_badge_synced', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(_wrapDark(const SyncBadge(state: SyncState.synced)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_sync_badge_synced.png'),
    );
  });

  testWidgets('dark_sync_badge_conflict', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapDark(
        SyncBadge(
          state: SyncState.conflict,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_sync_badge_conflict.png'),
    );
  });

  testWidgets('dark_empty_state', (tester) async {
    _setMobileViewport(tester);
    await tester.pumpWidget(
      _wrapDark(
        EmptyState(
          icon: Icons.inbox_outlined,
          title: 'لا توجد بيانات بعد',
          message: 'سيظهر المحتوى هنا بمجرد إضافة سجلات جديدة.',
          action: FilledButton(
            onPressed: () {},
            child: const Text('إضافة سجل'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/task8/dark_empty_state.png'),
    );
  });
}
