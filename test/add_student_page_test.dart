import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/database/database_provider.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/presentation/add_student_page.dart';

class _FakeServiceRepo implements ServiceRepository {
  @override
  Future<List<Stage>> getStages(String serviceId) async => [
    const Stage(id: 'stage-1', serviceId: 'service-1', name: 'مرحلة ابتدائي'),
  ];

  @override
  Future<List<ServiceClass>> getClasses(String stageId) async => [
    const ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'فصل 5/1'),
  ];

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(
    String serviceId,
  ) async => [];

  @override
  Future<void> refreshStages(String serviceId) async {}

  @override
  Future<void> refreshClasses(String stageId) async {}

  @override
  Future<void> refreshReportingPeriods(String serviceId) async {}

  @override
  Future<Service?> getService(String serviceId) async => null;

  @override
  Stream<List<Stage>> watchStages(String serviceId) => const Stream.empty();

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) =>
      const Stream.empty();

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

void main() {
  testWidgets(
    'AddStudentPage renders all 6 confirmed single-page sections and validates inputs',
    (tester) async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            serviceRepositoryProvider.overrideWithValue(_FakeServiceRepo()),
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
          child: const MaterialApp(
            home: AddStudentPage(serviceId: 'service-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('إضافة طالب جديد'), findsOneWidget);
      expect(find.text('1. بيانات الطالب الأساسية'), findsOneWidget);
      expect(find.text('2. العنوان'), findsOneWidget);
      expect(find.text('3. بيانات الأسرة'), findsOneWidget);
      expect(find.text('4. بيانات الدراسة والخدمة'), findsOneWidget);
      expect(find.text('5. البيانات الصحية والحساسة'), findsOneWidget);
      expect(find.text('6. ملاحظات'), findsOneWidget);

      // Verify Deacon switch is present
      expect(find.byKey(const Key('add_student_is_deacon')), findsOneWidget);

      // Verify Financial status dropdown is present
      expect(
        find.byKey(const Key('add_student_financial_status')),
        findsOneWidget,
      );

      // Attempt submission with empty name
      final submitButton = find.byKey(const Key('add_student_submit'));
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('الاسم بالكامل إلزامي'), findsOneWidget);
    },
  );

  test(
    'SensitiveStudentData domain validation enforces positive integers and birthOrder <= familySize',
    () {
      expect(
        SensitiveStudentData.validateFamilyAndFinance(familySize: -1),
        contains('رقمًا موجبًا'),
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(birthOrder: -1),
        contains('رقمًا موجبًا'),
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(
          familySize: 3,
          birthOrder: 4,
        ),
        contains('لا يمكن أن يتجاوز'),
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(
          familySize: 4,
          birthOrder: 2,
        ),
        isNull,
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(
          financialStatus: 'غير مقبول',
        ),
        contains('غير مقبولة'),
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(
          financialStatus: FinancialStatus.natural,
        ),
        isNull,
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(
          financialStatus: FinancialStatus.brothersOfLord,
        ),
        isNull,
      );
      expect(
        SensitiveStudentData.validateFamilyAndFinance(
          financialStatus: FinancialStatus.hiddenFamily,
        ),
        isNull,
      );
    },
  );
}
