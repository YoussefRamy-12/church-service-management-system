import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:church_service_management_system/features/students/domain/student_permissions.dart';

void main() {
  test('approval payload moves proposed class to current class', () {
    final payload = <String, dynamic>{
      'approval_status': 'approved',
      'current_class_id': 'class-1',
      'proposed_class_id': null,
    };
    expect(payload['approval_status'], 'approved');
    expect(payload['current_class_id'], 'class-1');
    expect(payload['proposed_class_id'], isNull);
  });

  test('student update payload is JSON serializable with is_deacon', () {
    final payload = <String, dynamic>{
      'id': 'student-1',
      'service_id': 'service-1',
      'current_class_id': 'class-1',
      'proposed_class_id': null,
      'name': 'Peter Updated',
      'birth_date': '2013-04-12',
      'phone': '01000000000',
      'school': 'School',
      'grade': '6',
      'is_deacon': true,
      'enrollment_at': '2026-10-01T12:00:00.000Z',
      'approval_status': 'approved',
      'photo_path': null,
      'notes': 'Updated note',
    };
    final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    expect(decoded['name'], 'Peter Updated');
    expect(decoded['birth_date'], '2013-04-12');
    expect(decoded['is_deacon'], true);
  });

  test(
    'SensitiveStudentData serializes confirmed fields and formats structured address',
    () {
      const sensitive = SensitiveStudentData(
        studentId: 'student-10',
        fatherJob: 'محاسب',
        fatherPhone: '01200000000',
        motherName: 'مريم بطرس',
        motherJob: 'معلمة',
        motherPhone: '01100000000',
        familySize: 5,
        birthOrder: 2,
        confessor: 'أبونا يوسف',
        medicalNotes: 'حساسية قمح',
        financialStatus: FinancialStatus.natural,
        addressBuilding: '15',
        addressStreet: 'شارع شبرا',
        addressFloor: '4',
        addressApartment: '12',
        studyYear: '2026/2027',
      );

      expect(sensitive.fullAddress, 'عقار 15، شارع شارع شبرا، الدور 4، شقة 12');
      expect(sensitive.effectiveFatherPhone, '01200000000');
      expect(sensitive.effectiveMotherPhone, '01100000000');

      final map = sensitive.toMap();
      expect(map['father_job'], 'محاسب');
      expect(map['financial_status'], 'طبيعي');
      expect(map['family_size'], 5);
      expect(map['birth_order'], 2);

      final fromMap = SensitiveStudentData.fromMap(
        map,
        studentId: 'student-10',
      );
      expect(fromMap.fatherJob, 'محاسب');
      expect(fromMap.motherName, 'مريم بطرس');
      expect(fromMap.financialStatus, 'طبيعي');
      expect(fromMap.familySize, 5);
      expect(fromMap.birthOrder, 2);
    },
  );

  test('Student entity default isDeacon is false and copyWith works', () {
    const student = Student(
      id: 'st-1',
      serviceId: 'srv-1',
      name: 'جورج رامي',
      approvalStatus: 'approved',
    );
    expect(student.isDeacon, isFalse);

    final updated = student.copyWith(isDeacon: true);
    expect(updated.isDeacon, isTrue);
  });

  group('canEditOrDeleteStudent permissions', () {
    const student = Student(
      id: 'st-1',
      serviceId: 'srv-1',
      currentClassId: 'cls-1',
      proposedClassId: 'cls-pending',
      name: 'مارك يوسف',
      approvalStatus: 'approved',
    );

    test('super admin always has edit/delete permission', () {
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: null,
          isSuperAdmin: true,
        ),
        isTrue,
      );
    });

    test('inactive or null profile has no permission', () {
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: null,
          isSuperAdmin: false,
        ),
        isFalse,
      );
      const inactive = ServantProfile(
        id: 'p-1',
        authUserId: 'u-1',
        serviceId: 'srv-1',
        name: 'خادم',
        role: 'overall_leader',
        accountStatus: 'inactive',
      );
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: inactive,
          isSuperAdmin: false,
        ),
        isFalse,
      );
    });

    test('different service servant has no permission', () {
      const otherService = ServantProfile(
        id: 'p-2',
        authUserId: 'u-2',
        serviceId: 'srv-2',
        name: 'خادم آخر',
        role: 'overall_leader',
        accountStatus: 'active',
      );
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: otherService,
          isSuperAdmin: false,
        ),
        isFalse,
      );
    });

    test('overall leader/helper has service-wide permission', () {
      const leader = ServantProfile(
        id: 'p-3',
        authUserId: 'u-3',
        serviceId: 'srv-1',
        name: 'أمين خدمة',
        role: 'overall_leader',
        accountStatus: 'active',
      );
      const helper = ServantProfile(
        id: 'p-4',
        authUserId: 'u-4',
        serviceId: 'srv-1',
        name: 'مساعد أمين',
        role: 'overall_helper',
        accountStatus: 'active',
      );
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: leader,
          isSuperAdmin: false,
        ),
        isTrue,
      );
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: helper,
          isSuperAdmin: false,
        ),
        isTrue,
      );
    });

    test('class servant can edit/delete student in their assigned current or proposed class', () {
      const servantCurrentClass = ServantProfile(
        id: 'p-5',
        authUserId: 'u-5',
        serviceId: 'srv-1',
        classId: 'cls-1',
        name: 'خادم فصل 1',
        role: 'servant',
        accountStatus: 'active',
      );
      const servantProposedClass = ServantProfile(
        id: 'p-6',
        authUserId: 'u-6',
        serviceId: 'srv-1',
        classId: 'cls-pending',
        name: 'خادم فصل مقترح',
        role: 'servant',
        accountStatus: 'active',
      );
      const servantOtherClass = ServantProfile(
        id: 'p-7',
        authUserId: 'u-7',
        serviceId: 'srv-1',
        classId: 'cls-other',
        name: 'خادم فصل آخر',
        role: 'servant',
        accountStatus: 'active',
      );

      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: servantCurrentClass,
          isSuperAdmin: false,
        ),
        isTrue,
      );
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: servantProposedClass,
          isSuperAdmin: false,
        ),
        isTrue,
      );
      expect(
        canEditOrDeleteStudent(
          student: student,
          profile: servantOtherClass,
          isSuperAdmin: false,
        ),
        isFalse,
      );
    });
  });
}
