import 'dart:async';
import 'dart:io';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/attendance_record.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/meeting.dart';
import 'package:church_service_management_system/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/domain/repositories/meeting_repository.dart';
import 'package:church_service_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/activity_type.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_priority.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_status.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_activity.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_case.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_student_item.dart';
import 'package:church_service_management_system/features/reports/domain/analytics_models.dart';
import 'package:church_service_management_system/features/reports/domain/report_filter.dart';
import 'package:church_service_management_system/features/reports/domain/service_report.dart';
import 'package:church_service_management_system/features/reports/presentation/report_providers.dart';
import 'package:church_service_management_system/features/servants/domain/repositories/servant_repository.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

bool _goldenFontsLoaded = false;

/// Loads IBM Plex Sans Arabic (and aliases it to Cairo too) + Arial into Flutter's
/// test font registry so Arabic text renders cleanly instead of Ahem tofu boxes.
Future<void> ensureGoldenTestSetup() async {
  if (_goldenFontsLoaded) return;
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);

  final fontFiles = [
    'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    'assets/fonts/IBMPlexSansArabic-Medium.ttf',
    'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    'assets/fonts/IBMPlexSansArabic-Bold.ttf',
  ];

  final ibmLoader = FontLoader('IBM Plex Sans Arabic');
  final cairoLoader = FontLoader('Cairo');
  for (final path in fontFiles) {
    ibmLoader.addFont(rootBundle.load(path));
    cairoLoader.addFont(rootBundle.load(path));
  }
  await ibmLoader.load();
  await cairoLoader.load();

  final arialLoader = FontLoader('Arial')
    ..addFont(rootBundle.load('assets/fonts/arial.ttf'));
  await arialLoader.load();

  final materialIconsFile = _findMaterialIconsFont();
  if (materialIconsFile != null) {
    final bytes = await materialIconsFile.readAsBytes();
    final materialLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await materialLoader.load();
  }

  _goldenFontsLoaded = true;
}

File? _findMaterialIconsFont() {
  const relativePath =
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final candidate = File(
      '$flutterRoot${Platform.pathSeparator}$relativePath',
    );
    if (candidate.existsSync()) return candidate;
  }

  // Walk up from Platform.resolvedExecutable (e.g. bin/cache/artifacts/engine/...)
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}${Platform.pathSeparator}$relativePath');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  // Fallback to locating `flutter` on PATH.
  try {
    final result = Process.runSync(
      Platform.isWindows ? 'where.exe' : 'which',
      ['flutter'],
    );
    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final root = File(trimmed).parent.parent;
        final candidate = File(
          '${root.path}${Platform.pathSeparator}$relativePath',
        );
        if (candidate.existsSync()) return candidate;
      }
    }
  } catch (_) {}
  return null;
}

class GoldenVariant {
  const GoldenVariant({
    required this.suffix,
    required this.size,
    required this.isDark,
    this.textScale = 1.0,
  });

  final String suffix;
  final Size size;
  final bool isDark;
  final double textScale;
}

const standardGoldenVariants = <GoldenVariant>[
  GoldenVariant(suffix: 'mobile_light', size: Size(390, 844), isDark: false),
  GoldenVariant(suffix: 'mobile_dark', size: Size(390, 844), isDark: true),
  GoldenVariant(suffix: 'desktop_light', size: Size(1280, 800), isDark: false),
  GoldenVariant(suffix: 'desktop_dark', size: Size(1280, 800), isDark: true),
];

const scale13GoldenVariants = <GoldenVariant>[
  GoldenVariant(
    suffix: 'mobile_scale13',
    size: Size(390, 844),
    isDark: false,
    textScale: 1.3,
  ),
  GoldenVariant(
    suffix: 'desktop_scale13',
    size: Size(1280, 800),
    isDark: false,
    textScale: 1.3,
  ),
];

Future<void> pumpGoldenWidget(
  WidgetTester tester, {
  required Widget home,
  required GoldenVariant variant,
  dynamic overrides = const [],
}) async {
  tester.view.physicalSize = variant.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: variant.isDark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(variant.textScale),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> expectGoldenImage(WidgetTester tester, String fileName) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('images/$fileName'),
  );
}

// --- Shared Fixtures ---

const goldenServiceId = 'service-1';
const goldenStageId = 'stage-1';
const goldenClassId = 'class-1';
const goldenMeetingId = 'meeting-1';

const goldenLeaderProfile = ServantProfile(
  id: 'servant-1',
  authUserId: 'user-1',
  serviceId: goldenServiceId,
  name: 'أبانوب عادل',
  phone: '01223344556',
  role: 'overall_leader',
  accountStatus: 'active',
);

const goldenServantsList = <ServantProfile>[
  goldenLeaderProfile,
  ServantProfile(
    id: 'servant-2',
    authUserId: 'user-2',
    serviceId: goldenServiceId,
    name: 'مارتينا سمير',
    phone: '01098765432',
    role: 'stage_leader',
    stageId: goldenStageId,
    accountStatus: 'active',
  ),
  ServantProfile(
    id: 'servant-3',
    authUserId: 'user-3',
    serviceId: goldenServiceId,
    name: 'بيشوي مجدي',
    phone: '01122334455',
    role: 'class_servant',
    stageId: goldenStageId,
    classId: goldenClassId,
    accountStatus: 'active',
  ),
];

const goldenStudentsList = <Student>[
  Student(
    id: 'student-1',
    serviceId: goldenServiceId,
    name: 'مينا فايز',
    approvalStatus: 'approved',
    currentClassId: goldenClassId,
    phone: '01012345678',
    school: 'مدرسة السلام',
    grade: 'الخامس الابتدائي',
    isDeacon: true,
    notes: 'منتظم في الحضور والمشاركة.',
  ),
  Student(
    id: 'student-2',
    serviceId: goldenServiceId,
    name: 'كيرلس يوسف',
    approvalStatus: 'approved',
    currentClassId: goldenClassId,
    phone: '01234567890',
    school: 'مدرسة النور',
    grade: 'الخامس الابتدائي',
  ),
  Student(
    id: 'student-3',
    serviceId: goldenServiceId,
    name: 'مارينا مجدي',
    approvalStatus: 'approved',
    currentClassId: 'class-2',
    phone: '01155667788',
    school: 'مدرسة الأمل',
    grade: 'السادس الابتدائي',
  ),
];

final goldenTodayMeeting = Meeting(
  id: goldenMeetingId,
  serviceId: goldenServiceId,
  meetingDate: DateTime(2026, 11, 24),
  startTime: '18:00',
  name: 'اجتماع مدارس الأحد',
);

final goldenAttendanceRecords = <AttendanceRecord>[
  AttendanceRecord(
    id: 'rec-1',
    meetingId: goldenMeetingId,
    studentId: 'student-1',
    serviceId: goldenServiceId,
    classIdAtAttendance: goldenClassId,
    checkedInAt: DateTime(2026, 11, 24, 17, 45),
    recordedBy: 'servant-1',
    clientOperationId: 'op-1',
    syncState: 'synced',
  ),
];

final goldenFollowUpStudentItems = <FollowUpStudentItem>[
  FollowUpStudentItem(
    student: goldenStudentsList[0],
    className: 'فصل 5/1',
    absenceCount: 3,
    totalEligibleMeetings: 12,
    activeCasesCount: 1,
    totalCasesCount: 2,
    latestFollowUpDate: '2026-11-20',
    latestFollowUpAuthor: 'بيشوي مجدي',
  ),
  FollowUpStudentItem(
    student: goldenStudentsList[1],
    className: 'فصل 5/1',
    absenceCount: 1,
    totalEligibleMeetings: 12,
    activeCasesCount: 0,
    totalCasesCount: 1,
    latestFollowUpDate: '2026-11-18',
    latestFollowUpAuthor: 'مارتينا سمير',
  ),
];

final goldenFollowUpCases = <FollowUpCase>[
  FollowUpCase(
    id: 'case-1',
    serviceId: goldenServiceId,
    studentId: 'student-1',
    serviceStudentId: 'ss-1',
    classId: goldenClassId,
    title: 'غياب متكرر لمدة 3 أسابيع',
    status: CaseStatus.inProgress,
    priority: CasePriority.high,
    createdBy: 'servant-1',
    createdAt: DateTime(2026, 11, 18),
    updatedAt: DateTime(2026, 11, 22),
    clientOperationId: 'op-case-1',
    studentName: 'مينا فايز',
    className: 'فصل 5/1',
  ),
];

final goldenFollowUpActivities = <FollowUpActivity>[
  FollowUpActivity(
    id: 'act-1',
    caseId: 'case-1',
    activityType: ActivityType.call,
    description: 'تم الاتصال بوالدة المخدوم والاطمئنان عليه.',
    createdBy: 'servant-1',
    createdAt: DateTime(2026, 11, 20, 19, 30),
    activityDate: '2026-11-20',
    clientOperationId: 'op-act-1',
    authorName: 'أبانوب عادل',
    studentName: 'مينا فايز',
  ),
];

const goldenServiceReport = ServiceReport(
  students: 48,
  meetings: 4,
  expectedAttendance: 192,
  present: 164,
  early: 92,
  before: 18,
  normal: 54,
  followUps: 14,
  previousPeriodAttendanceRate: 81.5,
  meetingHistory: [
    MeetingAttendanceItem(
      meetingId: 'm-1',
      meetingDate: '2026-11-03',
      meetingName: 'اجتماع 3 نوفمبر',
      startTime: '18:00',
      expectedCount: 48,
      presentCount: 39,
      earlyCount: 25,
      beforeCount: 4,
      normalCount: 10,
    ),
    MeetingAttendanceItem(
      meetingId: 'm-2',
      meetingDate: '2026-11-10',
      meetingName: 'اجتماع 10 نوفمبر',
      startTime: '18:00',
      expectedCount: 48,
      presentCount: 42,
      earlyCount: 28,
      beforeCount: 5,
      normalCount: 9,
    ),
    MeetingAttendanceItem(
      meetingId: 'm-3',
      meetingDate: '2026-11-17',
      meetingName: 'اجتماع 17 نوفمبر',
      startTime: '18:00',
      expectedCount: 48,
      presentCount: 41,
      earlyCount: 26,
      beforeCount: 4,
      normalCount: 11,
    ),
    MeetingAttendanceItem(
      meetingId: 'm-4',
      meetingDate: '2026-11-24',
      meetingName: 'اجتماع 24 نوفمبر',
      startTime: '18:00',
      expectedCount: 48,
      presentCount: 42,
      earlyCount: 31,
      beforeCount: 5,
      normalCount: 6,
    ),
  ],
  classComparisons: [
    ClassComparisonMetric(
      classId: 'class-1',
      className: 'فصل 5/1',
      stageId: goldenStageId,
      stageName: 'ابتدائي',
      totalStudents: 24,
      expectedAttendance: 96,
      presentCount: 86,
      earlyCount: 58,
      normalCount: 28,
      repeatedAbsencesCount: 2,
      openCasesCount: 1,
      resolvedCasesCount: 3,
    ),
    ClassComparisonMetric(
      classId: 'class-2',
      className: 'فصل 6/1',
      stageId: goldenStageId,
      stageName: 'ابتدائي',
      totalStudents: 24,
      expectedAttendance: 96,
      presentCount: 78,
      earlyCount: 52,
      normalCount: 26,
      repeatedAbsencesCount: 3,
      openCasesCount: 2,
      resolvedCasesCount: 2,
    ),
  ],
  repeatedAbsences: [
    RepeatedAbsenceRecord(
      studentId: 'student-1',
      studentName: 'مينا فايز',
      classId: 'class-1',
      className: 'فصل 5/1',
      consecutiveMissedMeetings: 3,
      lastAttendedDate: '2026-11-03',
      phone: '01012345678',
    ),
  ],
  servantWorkloads: [
    ServantWorkloadMetric(
      servantId: 'servant-1',
      servantName: 'أبانوب عادل',
      role: 'overall_leader',
      assignedCasesCount: 4,
      activeCasesCount: 1,
      completedActivitiesCount: 8,
    ),
  ],
  actionableInsights: [
    ActionableInsight(
      id: 'insight-1',
      title: 'ارتفاع نسبة الحضور المبكر',
      description: 'ارتفع الحضور المبكر بنسبة 5% مقارنة بالشهر الماضي.',
      severity: InsightSeverity.info,
    ),
  ],
);

// --- Shared Fakes ---

class GoldenFakeServiceRepository implements ServiceRepository {
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
        ServiceClass(id: goldenClassId, stageId: goldenStageId, name: 'فصل 5/1'),
        ServiceClass(id: 'class-2', stageId: goldenStageId, name: 'فصل 6/1'),
      ];

  @override
  Stream<List<Stage>> watchStages(String serviceId) => Stream.value(const [
        Stage(id: goldenStageId, serviceId: goldenServiceId, name: 'ابتدائي'),
      ]);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) => Stream.value(const [
        ServiceClass(id: goldenClassId, stageId: goldenStageId, name: 'فصل 5/1'),
        ServiceClass(id: 'class-2', stageId: goldenStageId, name: 'فصل 6/1'),
      ]);

  @override
  Future<void> refreshStages(String serviceId) async {}

  @override
  Future<void> refreshClasses(String stageId) async {}

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(String serviceId) async =>
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

class GoldenFakeStudentRepository implements StudentRepository {
  GoldenFakeStudentRepository([this._students = goldenStudentsList]);
  final List<Student> _students;

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
  Future<Student> approvePending(String studentId, {String? membershipId}) async =>
      _students.first;

  @override
  Future<Student> assignClass(
    String studentId,
    String classId, {
    String? membershipId,
  }) async =>
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

class GoldenFakeAttendanceRepository implements AttendanceRepository {
  GoldenFakeAttendanceRepository([List<AttendanceRecord>? records])
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

class GoldenFakeMeetingRepository implements MeetingRepository {
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

class GoldenFakeServantRepository implements ServantRepository {
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

class GoldenFakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser =>
      const AuthUser(id: 'user-1', email: 'leader@church.org');

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async =>
      currentUser!;

  @override
  Future<AuthUser> signUpServant({
    required String name,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String password,
  }) async =>
      currentUser!;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<bool> verifyCurrentPassword(String currentPassword) async => true;

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> signOut() async {}
}

class GoldenFakeSyncQueueRepository extends SyncQueueRepository {
  GoldenFakeSyncQueueRepository(super.database);

  @override
  Stream<int> watchCountByStatus(String status) => const Stream.empty();

  @override
  Future<List<SyncOperation>> pending() async => const [];
}

class GoldenNoopTransport implements SyncTransport {
  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {}
}

class GoldenFixedReportFilterNotifier extends ReportFilterNotifier {
  @override
  ReportFilter build() => ReportFilter(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 24),
        preset: ReportPeriodPreset.currentMonth,
      );
}
