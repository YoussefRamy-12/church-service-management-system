import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';
import 'package:church_service_management_system/features/service/presentation/service_dashboard_page.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:church_service_management_system/features/students/presentation/student_providers.dart';

class _FakeServiceRepository implements ServiceRepository {
  @override
  Future<Service?> getService(String serviceId) async => const Service(
        id: 'service-1',
        name: 'خدمة الفتيان',
        churchName: 'كنيسة العذراء',
        meetingStartTime: '18:00',
      );

  @override
  Future<List<Stage>> getStages(String serviceId) async => [
        const Stage(id: 'stage-1', serviceId: 'service-1', name: 'ابتدائي'),
      ];

  @override
  Future<List<ServiceClass>> getClasses(String stageId) async => [
        const ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'فصل 5/1'),
      ];

  @override
  Stream<List<Stage>> watchStages(String serviceId) => Stream.value([
        const Stage(id: 'stage-1', serviceId: 'service-1', name: 'ابتدائي'),
      ]);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) => Stream.value([
        const ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'فصل 5/1'),
      ]);

  @override
  Future<void> refreshStages(String serviceId) async {}

  @override
  Future<void> refreshClasses(String stageId) async {}

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(
          String serviceId) async =>
      [];

  @override
  Future<void> refreshReportingPeriods(String serviceId) async {}

  @override
  Future<void> deleteStage(String id) async {}

  @override
  Future<void> deleteClass(String id) async {}

  @override
  Future<void> updateMeetingStartTime(
      {required String serviceId, required String meetingStartTime}) async {}

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

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository(this._students);
  final List<Student> _students;

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) =>
      Stream.value(_students);

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) =>
      Stream.value(_students.where((s) => s.currentClassId == classId).toList());

  @override
  Future<void> refreshStudentsForService(String serviceId) async {}

  @override
  Future<void> refreshStudents(String classId) async {}

  @override
  Future<Student> approvePending(String studentId, {String? membershipId}) async =>
      _students.firstWhere((s) => s.id == studentId);

  @override
  Future<Student> assignClass(String studentId, String classId,
          {String? membershipId}) async =>
      _students.firstWhere((s) => s.id == studentId);

  @override
  Future<void> deleteStudent(String studentId, {String? membershipId}) async {}

  @override
  Future<SensitiveStudentData?> getSensitiveData(String studentId,
          {String? serviceId, String? identityServiceId}) async =>
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
  }) async =>
      _students.firstWhere((s) => s.id == studentId);
}

class _FakeSyncQueueRepository extends SyncQueueRepository {
  _FakeSyncQueueRepository(super.db, {this.conflictCount = 0})
      : super(enabled: false);

  final int conflictCount;

  @override
  Stream<int> watchCountByStatus(String status) =>
      Stream.value(status == 'conflict' ? conflictCount : 0);
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting();
  });

  tearDown(() async {
    await database.close();
  });

  Widget createWidget({
    required String role,
    bool isSuperAdmin = false,
    String? classId,
    List<Student>? students,
    int conflictCount = 0,
  }) {
    return ProviderScope(
      overrides: [
        serviceRepositoryProvider.overrideWithValue(_FakeServiceRepository()),
        studentRepositoryProvider.overrideWithValue(
          _FakeStudentRepository(students ?? []),
        ),
        syncQueueRepositoryProvider.overrideWithValue(
          _FakeSyncQueueRepository(database, conflictCount: conflictCount),
        ),
        isSuperAdminProvider.overrideWith((ref) => isSuperAdmin),
        currentServantProfileProvider.overrideWith(
          (ref) => Future.value(
            ServantProfile(
              id: 'servant-1',
              authUserId: 'user-1',
              serviceId: 'service-1',
              name: 'خادم الاختبار',
              role: role,
              classId: classId,
              accountStatus: 'active',
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        home: ServiceDashboardPage(serviceId: 'service-1'),
      ),
    );
  }

  testWidgets(
      'ServiceDashboardPage renders service identity and primary attendance CTA',
      (tester) async {
    await tester.pumpWidget(createWidget(role: 'overall_leader'));
    await tester.pumpAndSettle();

    expect(find.text('خدمة الفتيان'), findsOneWidget);
    expect(find.text('كنيسة العذراء'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_attendance')), findsOneWidget);
    expect(find.text('تسجيل الحضور'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'ServiceDashboardPage renders role-scoped actions for overall_leader',
      (tester) async {
    await tester.pumpWidget(createWidget(role: 'overall_leader'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_students')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_add_student')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_reports')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_servants')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_add_servant')), findsNothing);
    expect(find.text('المراحل والفصول'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ServiceDashboardPage renders add_servant for super admin',
      (tester) async {
    await tester.pumpWidget(
      createWidget(role: 'overall_leader', isSuperAdmin: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_add_servant')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'ServiceDashboardPage renders scoped view for class_servant and hides leadership controls',
      (tester) async {
    await tester.pumpWidget(
      createWidget(role: 'class_servant', classId: 'class-1'),
    );
    await tester.pumpAndSettle();

    // Scoped cards
    expect(find.byKey(const Key('class_servant_dashboard_scope')), findsOneWidget);
    expect(
        find.byKey(const Key('class_servant_students_overview')), findsOneWidget);

    // Leadership actions hidden
    expect(find.byKey(const Key('dashboard_reports')), findsNothing);
    expect(find.byKey(const Key('dashboard_servants')), findsNothing);
    expect(find.text('المراحل والفصول'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'ServiceDashboardPage shows Needs attention card when pending approvals or unassigned students exist',
      (tester) async {
    final studentsWithAttention = [
      const Student(
        id: 's-1',
        serviceId: 'service-1',
        name: 'طالب بانتظار الاعتماد',
        approvalStatus: 'pending',
      ),
      const Student(
        id: 's-2',
        serviceId: 'service-1',
        name: 'طالب غير مسكن',
        approvalStatus: 'approved',
        currentClassId: null,
        proposedClassId: null,
      ),
    ];

    await tester.pumpWidget(
      createWidget(role: 'overall_leader', students: studentsWithAttention),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_needs_attention')), findsOneWidget);
    expect(find.text('يحتاج متابعة'), findsOneWidget);
    expect(find.textContaining('بانتظار الاعتماد'), findsWidgets);
    expect(find.textContaining('غير مسكن بفصل'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'ServiceDashboardPage hides Needs attention card when no items require attention',
      (tester) async {
    final cleanStudents = [
      const Student(
        id: 's-1',
        serviceId: 'service-1',
        name: 'طالب معتمد ومسكن',
        approvalStatus: 'approved',
        currentClassId: 'class-1',
      ),
    ];

    await tester.pumpWidget(
      createWidget(role: 'overall_leader', students: cleanStudents),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_needs_attention')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
