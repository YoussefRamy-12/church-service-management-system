@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/spiritual_notebook/data/spiritual_notebook_repository.dart';
import 'package:church_service_management_system/features/spiritual_notebook/presentation/spiritual_notebook_page.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/servant/servant_prep_view.dart';

import 'goldens/golden_test_helper.dart';

class _FakeSpiritualNotebookRepository extends SpiritualNotebookRepository {
  _FakeSpiritualNotebookRepository()
      : super(
          SupabaseClient(
            'http://localhost:54321',
            'test-anon-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  @override
  Future<List<Map<String, dynamic>>> students(String serviceId) async => [];

  @override
  Future<List<Map<String, dynamic>>> activities(String serviceId) async => [];

  @override
  Future<List<Map<String, dynamic>>> submissions(String serviceId) async => [];

  @override
  Future<Map<String, dynamic>?> settings(String serviceId) async => null;
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _leader = ServantProfile(
  id: 'leader-1',
  authUserId: 'auth-leader-1',
  serviceId: 'service-1',
  name: 'أمين الخدمة',
  role: 'overall_leader',
  accountStatus: 'active',
);

void main() {
  setUpAll(() async {
    await ensureGoldenTestSetup();
    await initializeDateFormatting('ar', null);
  });

  for (final mode in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('spiritual notebook mobile — ${mode.$1}', (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spiritualNotebookRepositoryProvider.overrideWithValue(
              _FakeSpiritualNotebookRepository(),
            ),
            currentServantProfileProvider.overrideWith(
              (ref) async => _leader,
            ),
            isSuperAdminProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            theme: mode.$2,
            home: const SpiritualNotebookPage(serviceId: 'service-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/task7/spiritual_notebook_mobile_${mode.$1}.png',
        ),
      );
    });

    testWidgets('servant preparation mobile — ${mode.$1}', (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          theme: mode.$2,
          home: ServantPrepView(
            serviceId: 'service-1',
            profile: _leader.copyWith(role: 'class_servant', stageId: 'stage-5'),
            lessons: const [],
            stages: const [
              Stage(
                id: 'stage-5',
                serviceId: 'service-1',
                name: 'الصف الخامس الابتدائي',
              ),
            ],
            currentWeekMonday: DateTime.utc(2026, 11, 23),
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/task7/servant_prep_mobile_${mode.$1}.png',
        ),
      );
    });
  }
}
