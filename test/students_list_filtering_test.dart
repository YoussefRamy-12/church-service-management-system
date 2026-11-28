import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/domain/repositories/student_repository.dart';
import 'package:church_service_management_system/features/students/presentation/student_providers.dart';
import 'package:church_service_management_system/features/students/presentation/students_page.dart';

class _FakeServiceRepository implements ServiceRepository {
  @override
  Future<Service?> getService(String serviceId) async => const Service(
    id: 'service-1',
    name: 'خدمة تجريبية',
    churchName: 'كنيسة تجريبية',
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
    String serviceId,
  ) async => [];

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

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository(this._students);
  final List<Student> _students;

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) =>
      Stream.value(_students);

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) => Stream.value(
    _students.where((s) => s.currentClassId == classId).toList(),
  );

  @override
  Future<void> refreshStudentsForService(String serviceId) async {}

  @override
  Future<void> refreshStudents(String classId) async {}

  @override
  Future<Student> approvePending(
    String studentId, {
    String? membershipId,
  }) async => _students.firstWhere((s) => s.id == studentId);

  @override
  Future<Student> assignClass(
    String studentId,
    String classId, {
    String? membershipId,
  }) async => _students.firstWhere((s) => s.id == studentId);

  @override
  Future<void> deleteStudent(String studentId, {String? membershipId}) async {}

  @override
  Future<SensitiveStudentData?> getSensitiveData(
    String studentId, {
    String? serviceId,
    String? identityServiceId,
  }) async => null;

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
  }) async => _students.firstWhere((s) => s.id == studentId);
}

void main() {
  final sampleStudents = [
    const Student(
      id: 'student-1',
      serviceId: 'service-1',
      name: 'كيرلس أمير',
      phone: '01234567890',
      approvalStatus: 'approved',
      currentClassId: 'class-1',
    ),
    const Student(
      id: 'student-2',
      serviceId: 'service-1',
      name: 'مينا سمير',
      phone: '01112223334',
      approvalStatus: 'pending',
      proposedClassId: 'class-1',
    ),
    const Student(
      id: 'student-3',
      serviceId: 'service-1',
      name: 'بيشوي رزق',
      phone: '01099887766',
      approvalStatus: 'approved',
      currentClassId: 'class-1',
    ),
  ];

  Widget createWidget({List<Student>? students, double width = 390}) {
    return ProviderScope(
      overrides: [
        serviceRepositoryProvider.overrideWithValue(_FakeServiceRepository()),
        studentRepositoryProvider.overrideWithValue(
          _FakeStudentRepository(students ?? sampleStudents),
        ),
        currentServantProfileProvider.overrideWith(
          (ref) => Future.value(
            const ServantProfile(
              id: 'servant-1',
              authUserId: 'user-1',
              serviceId: 'service-1',
              name: 'خادم تجريبي',
              role: 'overall_leader',
              accountStatus: 'active',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: const StudentsPage(serviceId: 'service-1'),
        ),
      ),
    );
  }

  testWidgets('StudentsPage renders all students and count row', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('كيرلس أمير'), findsOneWidget);
    expect(find.text('مينا سمير'), findsOneWidget);
    expect(find.text('بيشوي رزق'), findsOneWidget);
    expect(find.text('الكل (3)'), findsOneWidget);
    expect(find.text('معتمد (2)'), findsOneWidget);
    expect(find.text('بانتظار الاعتماد (1)'), findsOneWidget);
    expect(find.text('النتائج'), findsOneWidget);
  });

  testWidgets('StudentsPage filters by status chip', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap "معتمد" filter chip
    await tester.tap(find.byKey(const Key('student_filter_approved')));
    await tester.pumpAndSettle();

    expect(find.text('كيرلس أمير'), findsOneWidget);
    expect(find.text('بيشوي رزق'), findsOneWidget);
    expect(find.text('مينا سمير'), findsNothing);

    // Tap "بانتظار الاعتماد" filter chip
    await tester.tap(find.byKey(const Key('student_filter_pending')));
    await tester.pumpAndSettle();

    expect(find.text('مينا سمير'), findsOneWidget);
    expect(find.text('كيرلس أمير'), findsNothing);
    expect(find.text('بيشوي رزق'), findsNothing);
  });

  testWidgets('StudentsPage filters by search text', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Search by name
    await tester.enterText(
      find.byKey(const Key('service_student_search')),
      'مينا',
    );
    await tester.pumpAndSettle();

    expect(find.text('مينا سمير'), findsOneWidget);
    expect(find.text('كيرلس أمير'), findsNothing);
    expect(find.text('بيشوي رزق'), findsNothing);

    // Search by phone
    await tester.enterText(
      find.byKey(const Key('service_student_search')),
      '012345',
    );
    await tester.pumpAndSettle();

    expect(find.text('كيرلس أمير'), findsOneWidget);
    expect(find.text('مينا سمير'), findsNothing);
  });

  testWidgets(
    'StudentsPage shows empty search results with clear-search button',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('service_student_search')),
        'اسم غير موجود',
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
      expect(find.byKey(const Key('clear_student_search')), findsOneWidget);

      // Tap clear search button
      await tester.tap(find.byKey(const Key('clear_student_search')));
      await tester.pumpAndSettle();

      expect(find.text('كيرلس أمير'), findsOneWidget);
      expect(find.text('مينا سمير'), findsOneWidget);
    },
  );

  testWidgets('StudentsPage distinguishes genuinely empty roster', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget(students: []));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد تلاميذ في هذه الخدمة'), findsOneWidget);
    expect(find.byKey(const Key('empty_add_student_button')), findsOneWidget);
  });

  testWidgets('StudentsPage renders table on desktop width', (tester) async {
    await tester.pumpWidget(createWidget(width: 1200));
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('الاسم'), findsOneWidget);
    expect(find.text('المرحلة والفصل'), findsOneWidget);
    expect(find.text('الحالة'), findsOneWidget);
    expect(find.text('الهاتف'), findsOneWidget);
  });
}
