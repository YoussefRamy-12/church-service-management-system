// Golden screenshot tests for all major screens.
// Covers: login, dashboard, attendance session, QR (success/already-present/not-found),
// students list, student details, add student (validation error), shell more sheet,
// follow-up hub, reports (filter open/closed), servants, sync center.
// Also renders dashboard, attendance session, students list at text scale 1.3.
//
// Images land in test/goldens/images/.
// Run: flutter test --update-goldens --tags golden test/goldens/full_app_golden_test.dart

@Tags(['golden'])
library;

import 'dart:async';

import 'package:church_service_management_system/app/app_shell.dart';
import 'package:church_service_management_system/app/theme.dart';
import 'package:church_service_management_system/core/config/config_provider.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/database/database_provider.dart';
import 'package:church_service_management_system/core/sync/sync_center_page.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/attendance_record.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/meeting.dart';
import 'package:church_service_management_system/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/domain/repositories/meeting_repository.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_session_page.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/qr_scan_page.dart';
import 'package:church_service_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/presentation/login_page.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_case_providers.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_hub_page.dart';
import 'package:church_service_management_system/features/reports/domain/report_filter.dart';
import 'package:church_service_management_system/features/reports/presentation/report_providers.dart';
import 'package:church_service_management_system/features/reports/presentation/reports_page.dart';
import 'package:church_service_management_system/features/servants/domain/repositories/servant_repository.dart';
import 'package:church_service_management_system/features/servants/presentation/servant_management_page.dart';
import 'package:church_service_management_system/features/servants/presentation/servant_providers.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';
import 'package:church_service_management_system/features/service/presentation/service_dashboard_page.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:church_service_management_system/features/students/presentation/add_student_page.dart';
import 'package:church_service_management_system/features/students/presentation/student_details_page.dart';
import 'package:church_service_management_system/features/students/presentation/student_providers.dart';
import 'package:church_service_management_system/features/students/presentation/students_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'golden_test_helper.dart';

// ─── Fake Repositories ────────────────────────────────────────────────────────

class _FakeServiceRepo implements ServiceRepository {
  @override
  Future<Service?> getService(String serviceId) async => const Service(
        id: goldenServiceId,
        name: 'خدمة الفتيان',
        churchName: 'كنيسة العذراء',
        meetingStartTime: '18:00',
      );

  @override
  Future<List<Stage>> getStages(String serviceId) async => const [
        Stage(id: goldenStageId, serviceId: goldenServiceId, name: 'ابتدائي'),
      ];

  @override
  Future<List<ServiceClass>> getClasses(String stageId) async => const [
        ServiceClass(
            id: goldenClassId, stageId: goldenStageId, name: 'فصل 5/1'),
        ServiceClass(id: 'class-2', stageId: goldenStageId, name: 'فصل 6/1'),
      ];

  @override
  Stream<List<Stage>> watchStages(String serviceId) => Stream.value(const [
        Stage(id: goldenStageId, serviceId: goldenServiceId, name: 'ابتدائي'),
      ]);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) =>
      Stream.value(const [
        ServiceClass(
            id: goldenClassId, stageId: goldenStageId, name: 'فصل 5/1'),
        ServiceClass(id: 'class-2', stageId: goldenStageId, name: 'فصل 6/1'),
      ]);

  @override
  Future<void> refreshStages(String serviceId) async {}

  @override
  Future<void> refreshClasses(String stageId) async {}

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(
          String serviceId) async =>
      const [];

  @override
  Future<void> refreshReportingPeriods(String serviceId) async {}

  @override
  Future<void> deleteStage(String id) async {}

  @override
  Future<void> deleteClass(String id) async {}

  @override
  Future<void> updateMeetingStartTime({
    required String serviceId,
    required String meetingStartTime,
  }) async {}

  @override
  Future<void> updateMeetingSchedule({
    required String serviceId,
    required String meetingStartTime,
    required String meetingFrequency,
    required int meetingWeekday,
    required int meetingMonthDay,
    required int earlyAttendanceMinutes,
  }) async {}

  @override
  Future<void> addReportingPeriod({
    required String serviceId,
    required String name,
    required String type,
    required String startDate,
    required String endDate,
  }) async {}
}

class _FakeStudentRepo implements StudentRepository {
  _FakeStudentRepo();
  final List<Student> _students = goldenStudentsList;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) =>
      Stream.value(_students.where((s) => s.currentClassId == classId).toList());

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) =>
      Stream.value(_students);

  @override
  Future<void> refreshStudents(String classId) async {}

  @override
  Future<void> refreshStudentsForService(String serviceId) async {}

  @override
  Future<Student> approvePending(String studentId,
          {String? membershipId}) async =>
      _students.first;

  @override
  Future<Student> assignClass(String studentId, String classId,
          {String? membershipId}) async =>
      _students.first;

  @override
  Future<void> deleteStudent(String studentId, {String? membershipId}) async {}

  @override
  Future<SensitiveStudentData?> getSensitiveData(
    String studentId, {
    String? serviceId,
    String? identityServiceId,
  }) async =>
      const SensitiveStudentData(
        studentId: 'student-1',
        address: '15 شارع الكنيسة - شبرا',
        fatherPhone: '01200112233',
        motherPhone: '01099887766',
        confessor: 'أبونا مرقس',
      );

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    String? membershipId,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool? isDeacon,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
    SensitiveStudentData? sensitiveData,
  }) async =>
      _students.first;
}

class _FakeAttendanceRepo implements AttendanceRepository {
  _FakeAttendanceRepo([List<AttendanceRecord>? records])
      : _records = List.of(records ?? goldenAttendanceRecords);

  final List<AttendanceRecord> _records;

  @override
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId) =>
      Stream.value(_records.where((r) => r.meetingId == meetingId).toList());

  @override
  Stream<List<AttendanceRecord>> watchForStudent(String studentId) =>
      Stream.value(_records.where((r) => r.studentId == studentId).toList());

  @override
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String serviceId,
    required String serviceStudentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  }) async =>
      _records.first;

  @override
  Future<AttendanceRecord> updateCheckedInAt({
    required String attendanceId,
    required DateTime checkedInAt,
  }) async =>
      _records.first;

  @override
  Future<void> refreshAttendanceForMeeting(String meetingId) async {}
}

class _FakeMeetingRepo implements MeetingRepository {
  @override
  Stream<List<Meeting>> watchMeetings(String serviceId) =>
      Stream.value([goldenTodayMeeting]);

  @override
  Future<void> refresh(String serviceId) async {}

  @override
  Future<Meeting> create({
    required String serviceId,
    required DateTime date,
    required String startTime,
    String name = 'اجتماع الخدمة',
    String? scheduleId,
    String? id,
  }) async =>
      goldenTodayMeeting;

  @override
  Future<void> ensureConfiguredSchedule(Service service) async {}
}

class _FakeServantRepo implements ServantRepository {
  @override
  Stream<List<ServantProfile>> watchForService(String serviceId) =>
      Stream.value(goldenServantsList);

  @override
  Future<void> refresh(String serviceId) async {}

  @override
  Future<void> createProfile({
    required String id,
    required String serviceId,
    required String authUserId,
    required String name,
    required String phone,
    required String role,
    String? stageId,
    String? classId,
  }) async {}

  @override
  Future<ServantProfile> updateProfile({
    required String servantId,
    required String name,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String role,
    String? stageId,
    String? classId,
    required String accountStatus,
  }) async =>
      goldenServantsList.first;

  @override
  Future<void> deleteProfile(String servantId) async {}
}

class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      Future.error('noop');

  @override
  Future<AuthUser> signUpServant({
    required String name,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String password,
  }) =>
      Future.error('noop');

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<bool> verifyCurrentPassword(String currentPassword) async => false;

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> signOut() async {}
}

class _FixedReportFilterNotifier extends ReportFilterNotifier {
  @override
  ReportFilter build() => ReportFilter(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 24),
        preset: ReportPeriodPreset.currentMonth,
      );
}

// ─── Provider Overrides ───────────────────────────────────────────────────────

List<Override> _makeBaseOverrides({
  AppDatabase? db,
  SyncQueueRepository? queue,
  SyncEngine? engine,
}) {
  final database = db ?? AppDatabase.forTesting();
  final syncQueue = queue ?? GoldenFakeSyncQueueRepository(database);
  final syncEngine = engine ??
      SyncEngine(
        queue: syncQueue,
        transport: GoldenNoopTransport(),
        enabled: false,
      );

  return [
    offlineSyncEnabledProvider.overrideWithValue(false),
    serviceRepositoryProvider.overrideWithValue(_FakeServiceRepo()),
    studentRepositoryProvider.overrideWithValue(_FakeStudentRepo()),
    attendanceRepositoryProvider.overrideWithValue(_FakeAttendanceRepo()),
    meetingRepositoryProvider.overrideWithValue(_FakeMeetingRepo()),
    servantRepositoryProvider.overrideWithValue(_FakeServantRepo()),
    authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
    currentServantProfileProvider
        .overrideWith((_) async => goldenLeaderProfile),
    isSuperAdminProvider.overrideWithValue(false),
    syncQueueRepositoryProvider.overrideWithValue(syncQueue),
    syncEngineProvider.overrideWithValue(syncEngine),
    appDatabaseProvider.overrideWithValue(database),
  ];
}

List<Override> _makeReportOverrides() => [
      ..._makeBaseOverrides(),
      reportUserScopeProvider(goldenServiceId).overrideWith(
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
      reportsAnalyticsProvider(goldenServiceId).overrideWith(
        (ref) async => goldenServiceReport,
      ),
    ];

List<Override> _makeFollowUpOverrides() => [
      ..._makeBaseOverrides(),
      followUpStudentItemsProvider(goldenServiceId).overrideWith(
        (ref) async => goldenFollowUpStudentItems,
      ),
      followUpCasesInScopeProvider(goldenServiceId).overrideWith(
        (ref) => Stream.value(goldenFollowUpCases),
      ),
      followUpActivitiesInScopeProvider(goldenServiceId).overrideWith(
        (ref) => Stream.value(goldenFollowUpActivities),
      ),
    ];

// ─── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildApp({
  required Widget home,
  required bool isDark,
  List<Override> overrides = const [],
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (ctx, child) {
        final mq = MediaQuery.of(ctx);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
      home: home,
    ),
  );
}

Future<void> _snap(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('images/$name'),
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);

    final ibm = FontLoader('IBM Plex Sans Arabic');
    final cairo = FontLoader('Cairo');
    for (final path in const [
      'assets/fonts/IBMPlexSansArabic-Regular.ttf',
      'assets/fonts/IBMPlexSansArabic-Medium.ttf',
      'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
      'assets/fonts/IBMPlexSansArabic-Bold.ttf',
    ]) {
      ibm.addFont(rootBundle.load(path));
      cairo.addFont(rootBundle.load(path));
    }
    await ibm.load();
    await cairo.load();

    final arial = FontLoader('Arial')
      ..addFont(rootBundle.load('assets/fonts/arial.ttf'));
    await arial.load();

    // Mock mobile_scanner channels so QrScanPage doesn't throw MissingPluginException
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in const [
      'dev.steenbakker.mobile_scanner/scanner/method',
      'dev.steenbakker.mobile_scanner/scanner/event',
      'dev.steenbakker.mobile_scanner/scanner/deviceOrientation',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async {
          if (call.method == 'start') {
            return <String, dynamic>{
              'textureId': 1,
              'size': <String, dynamic>{'width': 390.0, 'height': 844.0},
              'numberOfCameras': 1,
              'currentTorchState': 0,
            };
          }
          return null;
        },
      );
    }
  });

  // ─── 1. Login ─────────────────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'login_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'login_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'login_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'login_desktop_dark'),
  ]) {
    testWidgets('login — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const LoginPage(),
        isDark: tc.dark,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 2. Dashboard ─────────────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'dashboard_mobile_light', scale: 1.0),
    (size: const Size(390, 844), dark: true, name: 'dashboard_mobile_dark', scale: 1.0),
    (size: const Size(1280, 800), dark: false, name: 'dashboard_desktop_light', scale: 1.0),
    (size: const Size(1280, 800), dark: true, name: 'dashboard_desktop_dark', scale: 1.0),
    (size: const Size(390, 844), dark: false, name: 'dashboard_mobile_scale13', scale: 1.3),
    (size: const Size(1280, 800), dark: false, name: 'dashboard_desktop_scale13', scale: 1.3),
  ]) {
    testWidgets('dashboard — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const ServiceDashboardPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        textScale: tc.scale,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 3. Attendance Session ────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'attendance_session_mobile_light', scale: 1.0),
    (size: const Size(390, 844), dark: true, name: 'attendance_session_mobile_dark', scale: 1.0),
    (size: const Size(1280, 800), dark: false, name: 'attendance_session_desktop_light', scale: 1.0),
    (size: const Size(1280, 800), dark: true, name: 'attendance_session_desktop_dark', scale: 1.0),
    (size: const Size(390, 844), dark: false, name: 'attendance_session_mobile_scale13', scale: 1.3),
    (size: const Size(1280, 800), dark: false, name: 'attendance_session_desktop_scale13', scale: 1.3),
  ]) {
    testWidgets('attendance session — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const AttendanceSessionPage(
          serviceId: goldenServiceId,
          classId: goldenClassId,
          meetingId: goldenMeetingId,
          recordedBy: 'servant-1',
        ),
        isDark: tc.dark,
        textScale: tc.scale,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 4. QR Scan ───────────────────────────────────────────────────────────

  for (final vp in [
    (size: const Size(390, 844), label: 'mobile'),
    (size: const Size(1280, 800), label: 'desktop'),
  ]) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('qr success panel — ${vp.label} $mode', (tester) async {
        await _setViewport(tester, vp.size);
        await tester.pumpWidget(_buildApp(
          home: const QrScanPage(
            students: goldenStudentsList,
            presentStudentIds: {},
          ),
          isDark: dark,
          overrides: _makeBaseOverrides(),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final manualBtn = find.byKey(const Key('qr_manual_search_btn'));
        if (tester.any(manualBtn)) {
          await tester.tap(manualBtn);
          await tester.pumpAndSettle();
          final kerlisBtn = find.text('كيرلس يوسف');
          if (tester.any(kerlisBtn)) {
            await tester.tap(kerlisBtn.first);
            await tester.pumpAndSettle();
          }
        }
        await _snap(tester, 'qr_success_${vp.label}_$mode.png');
      });

      testWidgets('qr already present — ${vp.label} $mode', (tester) async {
        await _setViewport(tester, vp.size);
        await tester.pumpWidget(_buildApp(
          home: const QrScanPage(
            students: goldenStudentsList,
            presentStudentIds: {'student-1'},
          ),
          isDark: dark,
          overrides: _makeBaseOverrides(),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final manualBtn = find.byKey(const Key('qr_manual_search_btn'));
        if (tester.any(manualBtn)) {
          await tester.tap(manualBtn);
          await tester.pumpAndSettle();
          final marinaBtn = find.text('مينا فايز');
          if (tester.any(marinaBtn)) {
            await tester.tap(marinaBtn.first);
            await tester.pumpAndSettle();
          }
        }
        await _snap(tester, 'qr_already_present_${vp.label}_$mode.png');
      });

      testWidgets('qr not found — ${vp.label} $mode', (tester) async {
        await _setViewport(tester, vp.size);
        await tester.pumpWidget(_buildApp(
          home: const QrScanPage(
            students: goldenStudentsList,
            presentStudentIds: {},
          ),
          isDark: dark,
          overrides: _makeBaseOverrides(),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        scanner.onDetect?.call(
          const BarcodeCapture(
            barcodes: [Barcode(rawValue: 'unknown-student-id')],
          ),
        );
        await tester.pumpAndSettle();
        await _snap(tester, 'qr_not_found_${vp.label}_$mode.png');
      });
    }
  }

  // ─── 5. Students List ─────────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'students_list_mobile_light', scale: 1.0),
    (size: const Size(390, 844), dark: true, name: 'students_list_mobile_dark', scale: 1.0),
    (size: const Size(1280, 800), dark: false, name: 'students_list_desktop_light', scale: 1.0),
    (size: const Size(1280, 800), dark: true, name: 'students_list_desktop_dark', scale: 1.0),
    (size: const Size(390, 844), dark: false, name: 'students_list_mobile_scale13', scale: 1.3),
    (size: const Size(1280, 800), dark: false, name: 'students_list_desktop_scale13', scale: 1.3),
  ]) {
    testWidgets('students list — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const StudentsPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        textScale: tc.scale,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 6. Student Details ───────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'student_details_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'student_details_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'student_details_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'student_details_desktop_dark'),
  ]) {
    testWidgets('student details — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: StudentDetailsPage(student: goldenStudentsList.first),
        isDark: tc.dark,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 7. Add Student (validation error) ───────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'add_student_validation_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'add_student_validation_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'add_student_validation_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'add_student_validation_desktop_dark'),
  ]) {
    testWidgets('add student validation — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const AddStudentPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Try to submit without filling required fields to show validation error
      final saveBtn = find.text('حفظ');
      if (tester.any(saveBtn)) {
        await tester.tap(saveBtn.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 8. Shell More Sheet ──────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'shell_more_sheet_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'shell_more_sheet_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'shell_more_sheet_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'shell_more_sheet_desktop_dark'),
  ]) {
    testWidgets('shell more sheet — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);

      final router = GoRouter(
        initialLocation: '/service/$goldenServiceId/dashboard',
        routes: [
          GoRoute(
            path: '/service/:serviceId',
            redirect: (_, _) => null,
            routes: [
              ShellRoute(
                builder: (ctx, state, child) => AppShell(
                  serviceId: state.pathParameters['serviceId']!,
                  child: Scaffold(body: child),
                ),
                routes: [
                  for (final seg in [
                    'dashboard',
                    'attendance',
                    'students',
                    'follow-up',
                    'reports',
                    'servants',
                    'sync',
                  ])
                    GoRoute(
                      path: seg,
                      builder: (_, _) => const SizedBox.expand(),
                    ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SizedBox.expand(),
                    routes: [
                      GoRoute(
                        path: 'structure',
                        builder: (_, _) => const SizedBox.expand(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _makeBaseOverrides(),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(),
            darkTheme: buildAppDarkTheme(),
            themeMode: tc.dark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open "more" sheet — tap the المزيد / more nav tab
      final moreTabs = find.byKey(const Key('nav_tab_more'));
      if (tester.any(moreTabs)) {
        await tester.tap(moreTabs.first);
        await tester.pumpAndSettle();
      }

      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 9. Follow-up Hub ─────────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'follow_up_hub_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'follow_up_hub_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'follow_up_hub_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'follow_up_hub_desktop_dark'),
  ]) {
    testWidgets('follow-up hub — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const FollowUpHubPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        overrides: _makeFollowUpOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 10. Reports (filter closed) ─────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'reports_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'reports_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'reports_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'reports_desktop_dark'),
  ]) {
    testWidgets('reports — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const ReportsPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        overrides: _makeReportOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 11. Reports (filter sheet open) ─────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'reports_filter_open_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'reports_filter_open_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'reports_filter_open_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'reports_filter_open_desktop_dark'),
  ]) {
    testWidgets('reports filter open — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const ReportsPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        overrides: _makeReportOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final filterBtns = find.text('تصفية');
      if (tester.any(filterBtns)) {
        await tester.tap(filterBtns.first);
        await tester.pumpAndSettle();
      }
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 12. Servants ────────────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'servants_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'servants_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'servants_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'servants_desktop_dark'),
  ]) {
    testWidgets('servants — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      await tester.pumpWidget(_buildApp(
        home: const ServantManagementPage(serviceId: goldenServiceId),
        isDark: tc.dark,
        overrides: _makeBaseOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }

  // ─── 13. Sync Center ─────────────────────────────────────────────────────

  for (final tc in [
    (size: const Size(390, 844), dark: false, name: 'sync_center_mobile_light'),
    (size: const Size(390, 844), dark: true, name: 'sync_center_mobile_dark'),
    (size: const Size(1280, 800), dark: false, name: 'sync_center_desktop_light'),
    (size: const Size(1280, 800), dark: true, name: 'sync_center_desktop_dark'),
  ]) {
    testWidgets('sync center — ${tc.name}', (tester) async {
      await _setViewport(tester, tc.size);
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final queue = GoldenFakeSyncQueueRepository(db);
      final engine = SyncEngine(
        queue: queue,
        transport: GoldenNoopTransport(),
        enabled: false,
      );
      addTearDown(engine.dispose);

      await tester.pumpWidget(_buildApp(
        home: const SyncCenterPage(),
        isDark: tc.dark,
        overrides: _makeBaseOverrides(db: db, queue: queue, engine: engine),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _snap(tester, '${tc.name}.png');
    });
  }
}
