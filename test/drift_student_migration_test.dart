import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/students/data/local_student_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

void main() {
  group('Drift Student Migration & Compatibility Tests', () {
    test(
      'Fresh installation initializes schema version 16 with per-service membership, attendance and follow-up ownership cache',
      () async {
        final db = AppDatabase.forTesting();
        try {
          expect(db.schemaVersion, 16);

          final local = LocalStudentRepository(db);

          const student = Student(
            id: 'test-student-v7',
            serviceId: 'srv-1',
            name: 'تلميذ الإصدار السابع',
            approvalStatus: 'approved',
            currentClassId: 'cls-1',
            isDeacon: true,
            phone: '01200000000',
          );

          await local.cacheStudents([student]);

          final fetched = await local.findById('test-student-v7');
          expect(fetched, isNotNull);
          expect(fetched!.name, 'تلميذ الإصدار السابع');
          expect(fetched.isDeacon, isTrue);

          const sensitive = SensitiveStudentData(
            studentId: 'test-student-v7',
            fatherJob: 'محاسب',
            fatherPhone: '01211111111',
            motherName: 'مريم بولس',
            motherJob: 'معلمة',
            motherPhone: '01022222222',
            familySize: 5,
            birthOrder: 2,
            confessor: 'أبونا مرقس',
            medicalNotes: 'سليم تمامًا',
            financialStatus: FinancialStatus.natural,
            addressBuilding: '10',
            addressStreet: 'شارع الترعة',
            addressFloor: '2',
            addressApartment: '4',
          );

          await local.cacheSensitiveData(sensitive);

          final fetchedSensitive = await local.findSensitiveData(
            'test-student-v7',
          );
          expect(fetchedSensitive, isNotNull);
          expect(fetchedSensitive!.fatherJob, 'محاسب');
          expect(fetchedSensitive.fatherPhone, '01211111111');
          expect(fetchedSensitive.motherName, 'مريم بولس');
          expect(fetchedSensitive.familySize, 5);
          expect(fetchedSensitive.birthOrder, 2);
          expect(fetchedSensitive.confessor, 'أبونا مرقس');
          expect(fetchedSensitive.financialStatus, 'طبيعي');
          expect(fetchedSensitive.addressBuilding, '10');
          expect(fetchedSensitive.addressStreet, 'شارع الترعة');
          expect(fetchedSensitive.fullAddress, contains('عقار 10'));
        } finally {
          await db.close();
        }
      },
    );

    test(
      'Version 16 database exposes membership identity fields for attendance and follow-up',
      () async {
        final db = AppDatabase.forTesting();
        try {
          expect(db.schemaVersion, 15);
          expect(db.migration.onUpgrade, isNotNull);

          final students = await db.select(db.cachedStudents).get();
          expect(students, isA<List<CachedStudent>>());

          final sensitive = await db
              .select(db.cachedStudentSensitiveData)
              .get();
          expect(sensitive, isA<List<CachedStudentSensitiveDataData>>());
          expect(await db.select(db.cachedFollowUpCases).get(), isEmpty);
          expect(
            await db.select(db.cachedFollowUpCaseAssignments).get(),
            isEmpty,
          );
          expect(await db.select(db.cachedFollowUpActivities).get(), isEmpty);
          expect(await db.select(db.cachedServiceStudents).get(), isEmpty);
          final attendance = await db.select(db.cachedAttendanceRecords).get();
          expect(attendance, isEmpty);
        } finally {
          await db.close();
        }
      },
    );

    test(
      'Archiving a membership preserves global identity and sensitive history',
      () async {
        final db = AppDatabase.forTesting();
        final local = LocalStudentRepository(db);
        try {
          const student = Student(
            id: 'archive-student-1',
            membershipId: 'archive-membership-1',
            serviceId: 'srv-1',
            name: 'تلميذ للأرشفة',
            approvalStatus: 'approved',
          );
          const sensitive = SensitiveStudentData(
            studentId: 'archive-student-1',
            fatherJob: 'وظيفة',
            financialStatus: FinancialStatus.brothersOfLord,
          );

          await local.cacheStudents([student]);
          await local.cacheSensitiveData(sensitive);
          await local.archiveMembership(student.id);

          final archived = await local.findById(student.id);
          expect(archived, isNotNull);
          expect(archived!.membershipStatus, 'inactive');
          expect(await local.findSensitiveData(student.id), isNotNull);
        } finally {
          await db.close();
        }
      },
    );
  });
}
