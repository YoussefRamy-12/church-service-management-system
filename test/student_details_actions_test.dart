import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_theme.dart';
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
import 'package:church_service_management_system/features/students/presentation/student_details_page.dart';
import 'package:church_service_management_system/features/students/presentation/student_providers.dart';

class _FakeServiceRepo implements ServiceRepository {
  @override
  Future<Service?> getService(String serviceId) async => const Service(
    id: 'service-1',
    name: 'خدمة تجريبية',
    churchName: 'كنيسة تجريبية',
    meetingStartTime: '18:00',
  );

  @override
  Future<List<Stage>> getStages(String serviceId) async => const [
    Stage(id: 'stage-1', serviceId: 'service-1', name: 'ابتدائي'),
  ];

  @override
  Future<List<ServiceClass>> getClasses(String stageId) async => const [
    ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'فصل 5/1'),
  ];

  @override
  Stream<List<Stage>> watchStages(String serviceId) => Stream.value(const [
    Stage(id: 'stage-1', serviceId: 'service-1', name: 'ابتدائي'),
  ]);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) => Stream.value(const [
    ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'فصل 5/1'),
  ]);

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(String serviceId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentRepo implements StudentRepository {
  @override
  Future<SensitiveStudentData?> getSensitiveData(
    String studentId, {
    String? serviceId,
    String? identityServiceId,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const approvedStudent = Student(
    id: 'student-1',
    serviceId: 'service-1',
    name: 'يوسف مينا',
    phone: '01012345678',
    approvalStatus: 'approved',
    currentClassId: 'class-1',
  );

  const pendingStudent = Student(
    id: 'student-2',
    serviceId: 'service-1',
    name: 'مارك بطرس',
    phone: '01098765432',
    approvalStatus: 'pending',
    proposedClassId: 'class-1',
  );

  const leaderProfile = ServantProfile(
    id: 'servant-1',
    authUserId: 'user-1',
    serviceId: 'service-1',
    name: 'أمين الخدمة',
    role: 'overall_leader',
    accountStatus: 'active',
  );

  Widget buildTestApp(Student student) {
    return ProviderScope(
      overrides: [
        currentServantProfileProvider.overrideWith(
          (ref) async => leaderProfile,
        ),
        isSuperAdminProvider.overrideWith((ref) => false),
        serviceRepositoryProvider.overrideWithValue(_FakeServiceRepo()),
        studentRepositoryProvider.overrideWithValue(_FakeStudentRepo()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StudentDetailsPage(student: student),
        ),
      ),
    );
  }

  testWidgets('approved student shows edit, overflow archive, header contact, and QR below basic data', (tester) async {
    await tester.pumpWidget(buildTestApp(approvedStudent));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('student_edit')), findsOneWidget);
    expect(find.byKey(const Key('student_approve')), findsNothing);
    expect(find.byKey(const Key('student_overflow_menu')), findsOneWidget);
    expect(find.text('أرشفة عضوية التلميذ'), findsNothing);

    // Tap overflow menu to verify archive is inside
    await tester.tap(find.byKey(const Key('student_overflow_menu')));
    await tester.pumpAndSettle();
    expect(find.text('أرشفة عضوية التلميذ'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Header has call and WhatsApp quick actions
    expect(find.byIcon(Icons.call_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chat_rounded), findsOneWidget);

    // Basic data appears above QR section
    final basicDataFinder = find.text('بيانات الطالب الأساسية');
    final qrFinder = find.text('رمز QR الخاص بالطالب');
    expect(basicDataFinder, findsOneWidget);
    expect(qrFinder, findsOneWidget);
    expect(
      tester.getTopLeft(basicDataFinder).dy,
      lessThan(tester.getTopLeft(qrFinder).dy),
    );
  });

  testWidgets('pending student shows approve action for role that can approve', (tester) async {
    await tester.pumpWidget(buildTestApp(pendingStudent));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('student_approve')), findsOneWidget);
    expect(find.byKey(const Key('student_edit')), findsNothing);
  });
}

