import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/spiritual_notebook/data/spiritual_notebook_repository.dart';
import 'package:church_service_management_system/features/spiritual_notebook/domain/weekly_period.dart';
import 'package:church_service_management_system/features/spiritual_notebook/presentation/spiritual_notebook_page.dart';

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

class _FakeSpiritualNotebookRepository extends SpiritualNotebookRepository {
  _FakeSpiritualNotebookRepository({
    bool registeredFirst = false,
    this.failStudents = false,
  }) : super(
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

  final bool failStudents;
  int submitCount = 0;

  final List<Map<String, dynamic>> _students = List.generate(10, (index) {
    final number = index + 1;
    final classId = number <= 5 ? 'class-5' : 'class-6';
    final className = number <= 5 ? 'فصل 5/1' : 'فصل 6/1';
    return {
      'id': 'membership-$number',
      'membership_id': 'membership-$number',
      'name': 'مينا فايز $number',
      'current_class_id': classId,
      'classes': {
        'id': classId,
        'name': className,
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
  Future<List<Map<String, dynamic>>> students(String serviceId) async {
    if (failStudents) throw StateError('RAW_DATABASE_FAILURE');
    return _students;
  }

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

  @override
  Future<void> submit({
    required String membershipId,
    required WeeklyPeriod period,
    required List<String> activityIds,
    required int bonusPoints,
    String? bonusReason,
  }) async {
    submitCount++;
    final activityPoints = _activities
        .where((activity) => activityIds.contains(activity['id']))
        .fold<int>(0, (sum, activity) => sum + (activity['points'] as int));
    _submissions.add({
      'student_id': membershipId,
      'period_start': _date(period.start),
      'total_points': activityPoints + bonusPoints,
      'bonus_points': bonusPoints,
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }
}

Future<void> _pumpNotebook(
  WidgetTester tester, {
  required Widget home,
  required _FakeSpiritualNotebookRepository repository,
  double width = 390,
  double textScale = 1,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        spiritualNotebookRepositoryProvider.overrideWithValue(repository),
        currentServantProfileProvider.overrideWithValue(AsyncData(_leader)),
        isSuperAdminProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              viewInsets: EdgeInsets.only(bottom: bottomInset),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SpiritualNotebookStudentPage _studentForm({
  String membershipId = 'membership-1',
  List<String> studentIds = const [],
  int studentIndex = 0,
}) => SpiritualNotebookStudentPage(
  serviceId: 'service-1',
  membershipId: membershipId,
  studentIds: studentIds,
  studentIndex: studentIndex,
);

IconButton _iconButtonWithTooltip(
  WidgetTester tester,
  String tooltip,
) {
  final button = find.ancestor(
    of: find.byTooltip(tooltip),
    matching: find.byType(IconButton),
  );
  return tester.widget<IconButton>(button.first);
}

void main() {
  testWidgets('roster defaults to pending and class selection uses a sheet', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository(registeredFirst: true);
    await _pumpNotebook(
      tester,
      repository: repository,
      home: const SpiritualNotebookPage(serviceId: 'service-1'),
    );

    expect(find.text('الحالي'), findsOneWidget);
    expect(find.text('مينا فايز 1'), findsNothing);
    expect(find.text('مينا فايز 2'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ),
      findsWidgets,
    );

    await tester.tap(find.text('تم التسجيل (1)'));
    await tester.pumpAndSettle();
    expect(find.text('مينا فايز 1'), findsOneWidget);
    expect(find.text('مينا فايز 2'), findsNothing);

    await tester.tap(find.text('الكل (10)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('جميع الفصول'));
    await tester.pumpAndSettle();
    expect(find.text('اختيار الفصل'), findsOneWidget);

    await tester.tap(find.text('فصل 6/1'));
    await tester.pumpAndSettle();
    expect(find.text('مينا فايز 6'), findsOneWidget);
    expect(find.text('مينا فايز 1'), findsNothing);
  });
  testWidgets('mobile form reveals bonus reason only after entering points', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      home: _studentForm(),
    );

    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('سبب الإضافة (مطلوب)'), findsNothing);

    await tester.tap(find.text('قراءة الإنجيل'));
    await tester.pumpAndSettle();
    expect(find.text('3 نقطة'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pumpAndSettle();
    expect(find.text('سبب الإضافة (مطلوب)'), findsOneWidget);
    expect(find.text('5 نقطة'), findsWidgets);
  });
  testWidgets('saving one student submits once and renders registered state', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      home: _studentForm(),
    );

    await tester.tap(find.text('قراءة الإنجيل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('مراجعة النوتة قبل الحفظ'), findsOneWidget);
    expect(find.text('قراءة الإنجيل'), findsWidgets);
    expect(find.text('3 نقطة'), findsWidgets);

    await tester.tap(find.text('حفظ النوتة'));
    await tester.pumpAndSettle();

    expect(repository.submitCount, 1);
    expect(find.text('تم حفظ النوتة الروحية لهذا الأسبوع'), findsOneWidget);
    expect(find.text('حفظ'), findsNothing);
  });
  testWidgets('student navigation disables previous/next at list boundaries', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      home: _studentForm(
        studentIds: const ['membership-1', 'membership-2'],
        studentIndex: 0,
      ),
    );

    expect(
      _iconButtonWithTooltip(tester, 'التلميذ السابق').onPressed,
      isNull,
    );
    expect(
      _iconButtonWithTooltip(tester, 'التلميذ التالي').onPressed,
      isNotNull,
    );
    expect(find.text('حفظ والتالي'), findsOneWidget);
  });
  testWidgets('save and next submits once then opens the next roster student', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    final router = GoRouter(
      initialLocation: '/service/service-1/spiritual-notebook',
      routes: [
        GoRoute(
          path: '/service/:serviceId/spiritual-notebook',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.go(
                  '/service/service-1/spiritual-notebook/student/membership-1',
                  extra: {
                    'studentIds': const ['membership-1', 'membership-2'],
                    'studentIndex': 0,
                  },
                ),
                child: const Text('فتح النوتة'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/service/:serviceId/spiritual-notebook/student/:membershipId',
          builder: (context, state) {
            final extra = state.extra;
            final navigation = extra is Map<String, dynamic>
                ? extra
                : const <String, dynamic>{};
            return SpiritualNotebookStudentPage(
              serviceId: state.pathParameters['serviceId']!,
              membershipId: state.pathParameters['membershipId']!,
              studentIds:
                  (navigation['studentIds'] as List<dynamic>? ?? const [])
                      .whereType<String>()
                      .toList(),
              studentIndex: navigation['studentIndex'] as int? ?? 0,
            );
          },
        ),
      ],
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spiritualNotebookRepositoryProvider.overrideWithValue(repository),
          currentServantProfileProvider.overrideWith((ref) async => _leader),
          isSuperAdminProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('فتح النوتة'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('قراءة الإنجيل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ والتالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ النوتة'));
    await tester.pumpAndSettle();

    expect(repository.submitCount, 1);
    expect(find.text('مينا فايز 2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('حفظ والتالي'), findsNothing);
  });
  testWidgets('last student keeps save action without a next target', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      home: _studentForm(
        membershipId: 'membership-2',
        studentIds: const ['membership-1', 'membership-2'],
        studentIndex: 1,
      ),
    );

    expect(
      tester.widget<IconButton>(find.byTooltip('التلميذ السابق')).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<IconButton>(find.byTooltip('التلميذ التالي')).onPressed,
      isNull,
    );
    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('حفظ والتالي'), findsNothing);
  });
  testWidgets('registered notebook does not expose editable save controls', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository(registeredFirst: true);
    await _pumpNotebook(
      tester,
      repository: repository,
      home: _studentForm(),
    );

    expect(find.text('تم حفظ النوتة الروحية لهذا الأسبوع'), findsOneWidget);
    expect(find.text('إجمالي النقاط المسجلة'), findsOneWidget);
    expect(find.text('حفظ'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });
  testWidgets('student loading errors never expose raw exception text', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository(failStudents: true);
    await _pumpNotebook(
      tester,
      repository: repository,
      home: _studentForm(),
    );

    expect(find.textContaining('RAW_DATABASE_FAILURE'), findsNothing);
    expect(
      find.text('تعذر تحميل بيانات التلميذ. تحقق من الاتصال ثم أعد المحاولة.'),
      findsOneWidget,
    );
  });
  testWidgets('390px roster shows at least seven rows without overflow', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      home: const SpiritualNotebookPage(serviceId: 'service-1'),
    );

    final visibleNames = find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data?.startsWith('مينا فايز ') ?? false),
    );
    expect(visibleNames.evaluate().length, greaterThanOrEqualTo(7));
    expect(tester.takeException(), isNull);
  });
  testWidgets('student form has no overflow with keyboard and 1.3 text scale', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      textScale: 1.3,
      bottomInset: 280,
      home: _studentForm(),
    );

    expect(find.text('حفظ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('leaderboard and settings remain available as mobile tabs', (
    tester,
  ) async {
    final repository = _FakeSpiritualNotebookRepository();
    await _pumpNotebook(
      tester,
      repository: repository,
      home: const SpiritualNotebookPage(serviceId: 'service-1'),
    );

    await tester.tap(find.text('لوحة الشرف'));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا توجد درجات مسجلة'), findsOneWidget);

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة نشاط روحي جديد'), findsOneWidget);
  });
}
