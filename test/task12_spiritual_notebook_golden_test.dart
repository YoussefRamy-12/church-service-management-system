@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/spiritual_notebook/data/spiritual_notebook_repository.dart';
import 'package:church_service_management_system/features/spiritual_notebook/domain/weekly_period.dart';
import 'package:church_service_management_system/features/spiritual_notebook/presentation/spiritual_notebook_page.dart';

import 'goldens/golden_test_helper.dart';

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

const _leader = ServantProfile(
  id: 'leader-1',
  authUserId: 'auth-leader-1',
  serviceId: 'service-1',
  name: 'أمين الخدمة',
  role: 'overall_leader',
  accountStatus: 'active',
);

class _NotebookGoldenRepository extends SpiritualNotebookRepository {
  _NotebookGoldenRepository({bool registeredFirst = false})
      : super(
          SupabaseClient(
            'http://localhost:54321',
            'test-anon-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        ) {
    if (registeredFirst) {
      _submissions.add(_submission('membership-1', 3));
    }
  }

  final List<Map<String, dynamic>> _students = List.generate(10, (index) {
    final number = index + 1;
    final classId = number <= 5 ? 'class-5' : 'class-6';
    return {
      'id': 'membership-$number',
      'membership_id': 'membership-$number',
      'name': 'مينا فايز $number',
      'current_class_id': classId,
      'classes': {
        'id': classId,
        'name': number <= 5 ? 'فصل 5/1' : 'فصل 6/1',
        'stages': {'name': 'المرحلة الابتدائية'},
      },
    };
  });

  final List<Map<String, dynamic>> _activities = [
    {
      'id': 'activity-1',
      'name': 'قراءة الإنجيل',
      'description': 'قراءة يومية من الكتاب المقدس',
      'points': 3,
    },
    {
      'id': 'activity-2',
      'name': 'الصلاة اليومية',
      'description': 'الالتزام بالصلاة كل يوم',
      'points': 2,
    },
    {
      'id': 'activity-3',
      'name': 'حضور القداس',
      'description': 'المشاركة في القداس',
      'points': 4,
    },
  ];

  final List<Map<String, dynamic>> _submissions = [];

  static Map<String, dynamic> _submission(String membershipId, int points) => {
    'student_id': membershipId,
    'period_start': _date(WeeklyPeriod.containing(DateTime.now()).start),
    'total_points': points,
    'bonus_points': 0,
    'submitted_at': DateTime.now().toIso8601String(),
  };

  @override
  Future<List<Map<String, dynamic>>> students(String serviceId) async =>
      _students;

  @override
  Future<List<Map<String, dynamic>>> activities(String serviceId) async =>
      _activities;

  @override
  Future<List<Map<String, dynamic>>> submissions(String serviceId) async =>
      _submissions;

  @override
  Future<Map<String, dynamic>?> settings(String serviceId) async => {
    'bonus_roles': ['overall_leader'],
    'max_bonus_points': 5,
    'allow_zero_submissions': false,
  };
}

List<Override> _overrides(_NotebookGoldenRepository repository) => [
  spiritualNotebookRepositoryProvider.overrideWithValue(repository),
  currentServantProfileProvider.overrideWith((ref) async => _leader),
  isSuperAdminProvider.overrideWith((ref) => false),
];

SpiritualNotebookStudentPage _form() => SpiritualNotebookStudentPage(
  serviceId: 'service-1',
  membershipId: 'membership-1',
  studentIds: const [
    'membership-1',
    'membership-2',
    'membership-3',
    'membership-4',
  ],
  studentIndex: 0,
);

void main() {
  setUpAll(ensureGoldenTestSetup);

  const variants = [
    GoldenVariant(
      suffix: 'light',
      size: Size(390, 844),
      isDark: false,
    ),
    GoldenVariant(
      suffix: 'dark',
      size: Size(390, 844),
      isDark: true,
    ),
  ];

  for (final variant in variants) {
    testWidgets('notebook roster — ${variant.suffix}', (tester) async {
      final repository = _NotebookGoldenRepository(registeredFirst: true);
      await pumpGoldenWidget(
        tester,
        home: const SpiritualNotebookPage(serviceId: 'service-1'),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_roster_${variant.suffix}.png',
      );
    });

    testWidgets('notebook class sheet — ${variant.suffix}', (tester) async {
      final repository = _NotebookGoldenRepository();
      await pumpGoldenWidget(
        tester,
        home: const SpiritualNotebookPage(serviceId: 'service-1'),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('جميع الفصول'));
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_class_sheet_${variant.suffix}.png',
      );
    });

    testWidgets('notebook form empty — ${variant.suffix}', (tester) async {
      final repository = _NotebookGoldenRepository();
      await pumpGoldenWidget(
        tester,
        home: _form(),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_form_empty_${variant.suffix}.png',
      );
    });

    testWidgets('notebook form three activities — ${variant.suffix}', (
      tester,
    ) async {
      final repository = _NotebookGoldenRepository();
      await pumpGoldenWidget(
        tester,
        home: _form(),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('قراءة الإنجيل'));
      await tester.tap(find.text('الصلاة اليومية'));
      await tester.tap(find.text('حضور القداس'));
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_form_three_activities_${variant.suffix}.png',
      );
    });

    testWidgets('notebook form bonus reason — ${variant.suffix}', (
      tester,
    ) async {
      final repository = _NotebookGoldenRepository();
      await pumpGoldenWidget(
        tester,
        home: _form(),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '2');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'مشاركة مميزة');
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_form_bonus_${variant.suffix}.png',
      );
    });

    testWidgets('notebook form registered — ${variant.suffix}', (
      tester,
    ) async {
      final repository = _NotebookGoldenRepository(registeredFirst: true);
      await pumpGoldenWidget(
        tester,
        home: _form(),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_form_registered_${variant.suffix}.png',
      );
    });

    testWidgets('notebook leaderboard — ${variant.suffix}', (tester) async {
      final repository = _NotebookGoldenRepository(registeredFirst: true);
      await pumpGoldenWidget(
        tester,
        home: const SpiritualNotebookPage(serviceId: 'service-1'),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('لوحة الشرف'));
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_leaderboard_${variant.suffix}.png',
      );
    });

    testWidgets('notebook settings — ${variant.suffix}', (tester) async {
      final repository = _NotebookGoldenRepository();
      await pumpGoldenWidget(
        tester,
        home: const SpiritualNotebookPage(serviceId: 'service-1'),
        variant: variant,
        overrides: _overrides(repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await expectGoldenImage(
        tester,
        'task12/notebook_settings_${variant.suffix}.png',
      );
    });
  }
}
