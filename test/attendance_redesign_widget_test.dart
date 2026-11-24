import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/core/config/config_provider.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/attendance_record.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/meeting.dart';
import 'package:church_service_management_system/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/domain/repositories/meeting_repository.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_session_page.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/qr_scan_page.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:church_service_management_system/features/students/presentation/student_providers.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({List<AttendanceRecord>? initialRecords})
      : _records = List.of(initialRecords ?? const []);

  final List<AttendanceRecord> _records;
  final _controller = StreamController<List<AttendanceRecord>>.broadcast();

  int checkInCalls = 0;

  @override
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId) async* {
    yield _records.where((r) => r.meetingId == meetingId).toList();
    yield* _controller.stream.map(
      (list) => list.where((r) => r.meetingId == meetingId).toList(),
    );
  }

  @override
  Stream<List<AttendanceRecord>> watchForStudent(String studentId) async* {
    yield _records.where((r) => r.studentId == studentId).toList();
    yield* _controller.stream.map(
      (list) => list.where((r) => r.studentId == studentId).toList(),
    );
  }

  @override
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String serviceId,
    required String serviceStudentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  }) async {
    checkInCalls++;
    final record = AttendanceRecord(
      id: 'rec-$studentId',
      meetingId: meetingId,
      studentId: studentId,
      serviceId: serviceId,
      serviceStudentId: serviceStudentId,
      classIdAtAttendance: classIdAtAttendance,
      recordedBy: recordedBy,
      checkedInAt: checkedInAt,
      clientOperationId: 'op-$studentId',
      syncState: 'pending',
    );
    _records.add(record);
    _controller.add(List.of(_records));
    return record;
  }

  @override
  Future<AttendanceRecord> updateCheckedInAt({
    required String attendanceId,
    required DateTime checkedInAt,
  }) async {
    final index = _records.indexWhere((r) => r.id == attendanceId);
    final updated = _records[index].copyWith(checkedInAt: checkedInAt);
    _records[index] = updated;
    _controller.add(List.of(_records));
    return updated;
  }

  @override
  Future<void> refreshAttendanceForMeeting(String meetingId) async {}

  void dispose() {
    _controller.close();
  }
}

class FakeStudentRepository implements StudentRepository {
  FakeStudentRepository(this.students);
  final List<Student> students;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) =>
      Stream.value(students);

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) =>
      Stream.value(students);

  @override
  Future<void> refreshStudents(String classId) async {}

  @override
  Future<void> refreshStudentsForService(String serviceId) async {}

  @override
  Future<Student> approvePending(String studentId, {String? membershipId}) async =>
      students.first;

  @override
  Future<Student> assignClass(String studentId, String classId, {String? membershipId}) async =>
      students.first;

  @override
  Future<void> deleteStudent(String studentId, {String? membershipId}) async {}

  @override
  Future<SensitiveStudentData?> getSensitiveData(String studentId, {String? serviceId, String? identityServiceId}) async =>
      null;

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
  }) async => students.first;
}

class FakeMeetingRepository implements MeetingRepository {
  FakeMeetingRepository(this.meetings);
  final List<Meeting> meetings;

  @override
  Stream<List<Meeting>> watchMeetings(String serviceId) =>
      Stream.value(meetings);

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
  }) async => meetings.first;

  @override
  Future<void> ensureConfiguredSchedule(Service service) async {}
}

class FakeServiceRepository implements ServiceRepository {
  @override
  Future<Service?> getService(String serviceId) async => const Service(
        id: 'service-1',
        name: 'خدمة ابتدائي',
        churchName: 'كنيسة مارجرجس',
        meetingStartTime: '15:00',
        earlyAttendanceMinutes: 15,
      );

  @override
  Future<List<Stage>> getStages(String serviceId) async => [
        const Stage(id: 'stage-1', serviceId: 'service-1', name: 'المرحلة الابتدائية'),
      ];

  @override
  Future<List<ServiceClass>> getClasses(String stageId) async => [
        const ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'أولى ابتدائي'),
      ];

  @override
  Stream<List<Stage>> watchStages(String serviceId) => Stream.value(const []);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) => Stream.value(const []);

  @override
  Future<void> addReportingPeriod({required String serviceId, required String name, required String type, required String startDate, required String endDate}) async {}

  @override
  Future<void> deleteClass(String id) async {}

  @override
  Future<void> deleteStage(String id) async {}

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(String serviceId) async => [];

  @override
  Future<void> refreshClasses(String stageId) async {}

  @override
  Future<void> refreshReportingPeriods(String serviceId) async {}

  @override
  Future<void> refreshStages(String serviceId) async {}

  @override
  Future<void> updateMeetingSchedule({required String serviceId, required String meetingStartTime, required String meetingFrequency, required int meetingWeekday, required int meetingMonthDay, required int earlyAttendanceMinutes}) async {}

  @override
  Future<void> updateMeetingStartTime({required String serviceId, required String meetingStartTime}) async {}
}

void main() {
  final testStudents = [
    const Student(
      id: 'student-1',
      serviceId: 'service-1',
      name: 'مارينا مجدي',
      approvalStatus: 'approved',
      membershipId: 'mem-1',
      currentClassId: 'class-1',
      phone: '01234567890',
    ),
    const Student(
      id: 'student-2',
      serviceId: 'service-1',
      name: 'كيرلس يوسف',
      approvalStatus: 'approved',
      membershipId: 'mem-2',
      currentClassId: 'class-1',
      phone: '01234567891',
    ),
  ];

  Widget buildTestableWidget({
    required AttendanceRepository attendanceRepo,
    required List<Meeting> meetings,
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
          studentRepositoryProvider.overrideWithValue(FakeStudentRepository(testStudents)),
          meetingRepositoryProvider.overrideWithValue(FakeMeetingRepository(meetings)),
          serviceRepositoryProvider.overrideWithValue(FakeServiceRepository()),
          offlineSyncEnabledProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AttendanceSessionPage(
            serviceId: 'service-1',
            classId: 'class-1',
            meetingId: 'meeting-today',
            recordedBy: 'servant-1',
          ),
        ),
      ),
    );
  }

  group('Attendance Redesign Tests', () {
    testWidgets('Header renders class name, date, live counters and SyncBadge', (tester) async {
      final today = DateTime.now();
      final meetings = [
        Meeting(
          id: 'meeting-today',
          serviceId: 'service-1',
          meetingDate: DateTime(today.year, today.month, today.day),
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
      ];
      final repo = FakeAttendanceRepository();

      await tester.pumpWidget(
        buildTestableWidget(attendanceRepo: repo, meetings: meetings),
      );
      await tester.pumpAndSettle();

      expect(find.text('أولى ابتدائي'), findsWidgets);
      expect(find.textContaining('اجتماع مدارس الأحد'), findsWidgets);
      expect(find.text('حاضر: '), findsOneWidget);
      expect(find.text('غير مسجل: '), findsOneWidget);
      expect(find.text('إجمالي: '), findsOneWidget);
      expect(find.text('تمت المزامنة'), findsOneWidget);
    });

    testWidgets('One tap checks in student with no confirmation and updates status', (tester) async {
      final today = DateTime.now();
      final meetings = [
        Meeting(
          id: 'meeting-today',
          serviceId: 'service-1',
          meetingDate: DateTime(today.year, today.month, today.day),
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
      ];
      final repo = FakeAttendanceRepository();

      await tester.pumpWidget(
        buildTestableWidget(attendanceRepo: repo, meetings: meetings),
      );
      await tester.pumpAndSettle();

      // Initially both students in roster have status 'غير مسجل'
      expect(find.text('غير مسجل'), findsNWidgets(2));

      // Exactly ONE tap on student row
      await tester.tap(find.byKey(const ValueKey('student_tile_student-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.checkInCalls, 1);
      expect(find.text('تم تسجيل حضور مارينا مجدي بنجاح.'), findsOneWidget);

      await tester.pumpAndSettle();
      // Marina is now marked Present
      expect(find.textContaining('حاضر'), findsWidgets);
    });

    testWidgets('Filter chips filter roster between All, Present, and Not Marked', (tester) async {
      final today = DateTime.now();
      final meetings = [
        Meeting(
          id: 'meeting-today',
          serviceId: 'service-1',
          meetingDate: DateTime(today.year, today.month, today.day),
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
      ];
      final record = AttendanceRecord(
        id: 'rec-1',
        meetingId: 'meeting-today',
        studentId: 'student-1',
        classIdAtAttendance: 'class-1',
        recordedBy: 'servant-1',
        checkedInAt: DateTime.now(),
        clientOperationId: 'op-1',
        syncState: 'synced',
      );
      final repo = FakeAttendanceRepository(initialRecords: [record]);

      await tester.pumpWidget(
        buildTestableWidget(attendanceRepo: repo, meetings: meetings),
      );
      await tester.pumpAndSettle();

      // In All mode: both Marina and Kirollos are visible
      expect(find.text('مارينا مجدي'), findsOneWidget);
      expect(find.text('كيرلس يوسف'), findsOneWidget);

      // Tap 'حاضر' filter chip
      await tester.tap(find.byKey(const Key('attendance_filter_present')));
      await tester.pumpAndSettle();

      expect(find.text('مارينا مجدي'), findsOneWidget);
      expect(find.text('كيرلس يوسف'), findsNothing);

      // Tap 'غير مسجل' filter chip
      await tester.tap(find.byKey(const Key('attendance_filter_absent')));
      await tester.pumpAndSettle();

      expect(find.text('مارينا مجدي'), findsNothing);
      expect(find.text('كيرلس يوسف'), findsOneWidget);

      // Tap 'الكل' filter chip
      await tester.tap(find.byKey(const Key('attendance_filter_all')));
      await tester.pumpAndSettle();

      expect(find.text('مارينا مجدي'), findsOneWidget);
      expect(find.text('كيرلس يوسف'), findsOneWidget);
    });

    testWidgets('Read-only meeting renders banner and disables check-in controls', (tester) async {
      final pastDate = DateTime(2025, 1, 1);
      final today = DateTime.now();
      // Two meetings: today (active) and past (read-only)
      final meetings = [
        Meeting(
          id: 'meeting-past',
          serviceId: 'service-1',
          meetingDate: pastDate,
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
        Meeting(
          id: 'meeting-today',
          serviceId: 'service-1',
          meetingDate: DateTime(today.year, today.month, today.day),
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
      ];
      final repo = FakeAttendanceRepository();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: ProviderScope(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(repo),
              studentRepositoryProvider.overrideWithValue(FakeStudentRepository(testStudents)),
              meetingRepositoryProvider.overrideWithValue(FakeMeetingRepository(meetings)),
              serviceRepositoryProvider.overrideWithValue(FakeServiceRepository()),
              offlineSyncEnabledProvider.overrideWithValue(true),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const AttendanceSessionPage(
                serviceId: 'service-1',
                classId: 'class-1',
                meetingId: 'meeting-past',
                recordedBy: 'servant-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only banner is displayed
      expect(find.byKey(const Key('attendance_read_only_banner')), findsOneWidget);
      expect(find.textContaining('عرض فقط'), findsOneWidget);

      // Tapping student row does NOT check in
      await tester.tap(find.byKey(const ValueKey('student_tile_student-1')));
      await tester.pumpAndSettle();

      expect(repo.checkInCalls, 0);

      // Scan QR button in bottom action bar is disabled
      final scanQrButton = tester.widget<FilledButton>(find.byKey(const Key('attendance_scan_qr_bottom')));
      expect(scanQrButton.onPressed, isNull);
    });

    testWidgets('QR scan screen shows clear review panel for student, already present, and manual fallback', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: QrScanPage(
            students: testStudents,
            presentStudentIds: const {'student-1'},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Large Close/Back control is present
      expect(find.byTooltip('إغلاق الكاميرا'), findsOneWidget);
      expect(find.byKey(const Key('qr_manual_search_btn')), findsOneWidget);

      // Tap manual search fallback
      await tester.tap(find.byKey(const Key('qr_manual_search_btn')));
      await tester.pumpAndSettle();

      expect(find.text('بحث وتحديد تلميذ يدويًا'), findsOneWidget);
      expect(find.text('مارينا مجدي'), findsOneWidget);
      expect(find.text('كيرلس يوسف'), findsOneWidget);

      // Select student-1 who is already present
      await tester.tap(find.text('مارينا مجدي'));
      await tester.pumpAndSettle();

      // Already present panel is shown
      expect(find.byKey(const ValueKey('qr_already_present_panel')), findsOneWidget);
      expect(find.text('تم تسجيل حضور هذا التلميذ مسبقًا في هذا الاجتماع'), findsOneWidget);
      expect(find.text('مسح تلميذ آخر'), findsOneWidget);

      // Reset and select student-2 who is not yet present
      await tester.tap(find.text('مسح تلميذ آخر'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('qr_manual_search_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('كيرلس يوسف'));
      await tester.pumpAndSettle();

      // Success panel is shown with check-in button
      expect(find.byKey(const ValueKey('qr_success_panel')), findsOneWidget);
      expect(find.text('تسجيل الحضور'), findsOneWidget);
    });

    testWidgets('Renders without overflow at 360x640 with text scale 1.3', (tester) async {
      final today = DateTime.now();
      final meetings = [
        Meeting(
          id: 'meeting-today',
          serviceId: 'service-1',
          meetingDate: DateTime(today.year, today.month, today.day),
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
      ];
      final repo = FakeAttendanceRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          attendanceRepo: repo,
          meetings: meetings,
          size: const Size(360, 640),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('attendance_session')), findsOneWidget);
    });

    testWidgets('Renders without overflow at 390x844 with text scale 1.3', (tester) async {
      final today = DateTime.now();
      final meetings = [
        Meeting(
          id: 'meeting-today',
          serviceId: 'service-1',
          meetingDate: DateTime(today.year, today.month, today.day),
          startTime: '15:00',
          name: 'اجتماع مدارس الأحد',
        ),
      ];
      final repo = FakeAttendanceRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          attendanceRepo: repo,
          meetings: meetings,
          size: const Size(390, 844),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('attendance_session')), findsOneWidget);
    });
  });
}
