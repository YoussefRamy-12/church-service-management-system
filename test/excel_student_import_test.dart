import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/students/data/local_student_repository.dart';
import 'package:church_service_management_system/features/students/data/offline_first_student_registration.dart';
import 'package:church_service_management_system/features/students/domain/entities/sensitive_student_data.dart';
import 'package:church_service_management_system/features/students/services/excel_student_import_service.dart';

void main() {
  const service = ExcelStudentImportService();

  final sampleStages = [
    const Stage(id: 'stage-primary', serviceId: 'service-100', name: 'الابتدائية'),
    const Stage(id: 'stage-prep', serviceId: 'service-100', name: 'الإعدادية'),
  ];

  final sampleClasses = [
    const ServiceClass(
      id: 'class-primary-1',
      stageId: 'stage-primary',
      name: 'فصل مارمرقس',
    ),
    const ServiceClass(
      id: 'class-prep-1',
      stageId: 'stage-prep',
      name: 'فصل الملاك ميخائيل',
    ),
  ];

  group('ExcelStudentImportService', () {
    test(
      'generateTemplateExcel produces confirmed headers including stage and class and excludes removed fields',
      () {
        final bytes = service.generateTemplateExcel();
        expect(bytes, isNotEmpty);

        final excel = Excel.decodeBytes(bytes);
        expect(excel.tables.containsKey('الطلاب'), isTrue);

        final sheet = excel.tables['الطلاب']!;
        expect(sheet.rows.length, greaterThanOrEqualTo(2));

        final firstRow = sheet.rows.first;
        final headers = firstRow.map((c) => c?.value.toString()).toList();

        // Confirmed fields must be present
        expect(headers, contains('الاسم الكامل'));
        expect(headers, contains('المرحلة الدراسية'));
        expect(headers, contains('الفصل'));
        expect(headers, contains('رقم هاتف الطالب'));
        expect(headers, contains('شماس (نعم/لا)'));
        expect(headers, contains('رقم العنوان'));
        expect(headers, contains('شارع'));
        expect(headers, contains('دور'));
        expect(headers, contains('شقة'));
        expect(headers, contains('وظيفة الأب'));
        expect(headers, contains('تليفون الأب'));
        expect(headers, contains('اسم الأم'));
        expect(headers, contains('وظيفة الأم'));
        expect(headers, contains('تليفون الأم'));
        expect(headers, contains('عدد أفراد الأسرة'));
        expect(headers, contains('ترتيب الطالب بين إخوته'));
        expect(headers, contains('أب الاعتراف'));
        expect(
          headers,
          contains('الحالة المادية للأسرة (طبيعي / إخوة رب / أسرة مستترة)'),
        );

        // Explicitly removed fields must NOT appear
        expect(headers, isNot(contains('ح/ش')));
        expect(headers, isNot(contains('الأسرة')));
        expect(headers, isNot(contains('أب الاعتراف / المعمودية')));
      },
    );

    test(
      'parseExcelBytes parses confirmed student fields, stage, class, address, and deacon',
      () {
        final excel = Excel.createExcel();
        final sheet = excel['الطلاب'];
        sheet.appendRow([
          for (final h in ExcelStudentImportService.columnHeaders)
            TextCellValue(h),
        ]);
        sheet.appendRow([
          TextCellValue('مارك هاني جورج'),
          TextCellValue('الابتدائية'),
          TextCellValue('فصل مارمرقس'),
          TextCellValue('2014-03-20'),
          TextCellValue('01234567890'),
          TextCellValue('مدرسة النور'),
          TextCellValue('نعم'), // deacon
          TextCellValue('12'), // address building
          TextCellValue('شارع شبرا'), // address street
          TextCellValue('3'), // floor
          TextCellValue('7'), // apt
          TextCellValue('طبيب بشري'), // father job
          TextCellValue('01299998888'), // father phone
          TextCellValue('سارة فريد كمال'), // mother name
          TextCellValue('صيدلانية'), // mother job
          TextCellValue('01011112222'), // mother phone
          const IntCellValue(5), // family size
          const IntCellValue(2), // birth order
          TextCellValue('أبونا أنطونيوس'), // confessor
          TextCellValue('لا توجد حساسية'), // medical
          TextCellValue('طبيعي'), // financial
          TextCellValue('تلميذ متفوق'), // notes
        ]);

        final bytes = excel.save()!;
        final result = service.parseExcelBytes(
          bytes: bytes,
          existingStudents: [],
          availableClasses: sampleClasses,
          availableStages: sampleStages,
        );

        expect(result.totalRows, 1);
        expect(result.validRows.length, 1);
        expect(result.errorRows, isEmpty);
        expect(result.duplicateRows, isEmpty);

        final row = result.validRows.first;
        expect(row.name, 'مارك هاني جورج');
        expect(row.grade, 'الابتدائية');
        expect(row.classId, 'class-primary-1');
        expect(row.className, 'فصل مارمرقس');
        expect(row.phone, '01234567890');
        expect(row.birthDate, DateTime(2014, 3, 20));
        expect(row.school, 'مدرسة النور');
        expect(row.isDeacon, isTrue);

        expect(row.sensitiveData['father_job'], 'طبيب بشري');
        expect(row.sensitiveData['father_phone'], '01299998888');
        expect(row.sensitiveData['mother_name'], 'سارة فريد كمال');
        expect(row.sensitiveData['mother_job'], 'صيدلانية');
        expect(row.sensitiveData['mother_phone'], '01011112222');
        expect(row.sensitiveData['family_size'], 5);
        expect(row.sensitiveData['birth_order'], 2);
        expect(row.sensitiveData['confessor'], 'أبونا أنطونيوس');
        expect(row.sensitiveData['medical_notes'], 'لا توجد حساسية');
        expect(row.sensitiveData['financial_status'], 'طبيعي');
        expect(row.sensitiveData['address_building'], '12');
        expect(row.sensitiveData['address_street'], 'شارع شبرا');
        expect(row.sensitiveData['address_floor'], '3');
        expect(row.sensitiveData['address_apartment'], '7');
      },
    );

    test('parseExcelBytes resolves grade from class -> stage_id when grade column is empty', () {
      final excel = Excel.createExcel();
      final sheet = excel['الطلاب'];
      sheet.appendRow([
        TextCellValue('الاسم الكامل'),
        TextCellValue('الفصل'),
        TextCellValue('تاريخ الميلاد'),
      ]);
      sheet.appendRow([
        TextCellValue('مريم يوسف أسعد'),
        TextCellValue('فصل مارمرقس'),
        TextCellValue('2014-07-10'),
      ]);

      final bytes = excel.save()!;
      final result = service.parseExcelBytes(
        bytes: bytes,
        existingStudents: [],
        availableClasses: sampleClasses,
        availableStages: sampleStages,
      );

      expect(result.validRows.length, 1);
      final row = result.validRows.first;
      expect(row.name, 'مريم يوسف أسعد');
      expect(row.classId, 'class-primary-1');
      expect(row.grade, 'الابتدائية'); // derived from class-primary-1 -> stage-primary
    });

    test('parseExcelBytes falls back to defaultGrade or defaultStageId when grade column is empty', () {
      final excel = Excel.createExcel();
      final sheet = excel['الطلاب'];
      sheet.appendRow([
        TextCellValue('الاسم الكامل'),
        TextCellValue('تاريخ الميلاد'),
      ]);
      sheet.appendRow([
        TextCellValue('أنطون ماجد حبيب'),
        TextCellValue('2015-02-14'),
      ]);

      final bytes = excel.save()!;
      final result = service.parseExcelBytes(
        bytes: bytes,
        existingStudents: [],
        defaultStageId: 'stage-prep',
        availableStages: sampleStages,
      );

      expect(result.validRows.length, 1);
      final row = result.validRows.first;
      expect(row.name, 'أنطون ماجد حبيب');
      expect(row.grade, 'الإعدادية');
    });

    test('parseExcelBytes rejects row when grade cannot be resolved and no default is provided', () {
      final excel = Excel.createExcel();
      final sheet = excel['الطلاب'];
      sheet.appendRow([
        TextCellValue('الاسم الكامل'),
        TextCellValue('تاريخ الميلاد'),
      ]);
      sheet.appendRow([
        TextCellValue('جون سامي شكري'),
        TextCellValue('2015-06-20'),
      ]);

      final bytes = excel.save()!;
      final result = service.parseExcelBytes(
        bytes: bytes,
        existingStudents: [],
      );

      expect(result.totalRows, 1);
      expect(result.validRows, isEmpty);
      expect(result.errorRows.length, 1);
      expect(result.errorRows.first.errors.any((e) => e.contains('المرحلة / الصف إلزامي')), isTrue);
    });

    test('parseExcelBytes matches alternate Arabic header variations for grade and class', () {
      final excel = Excel.createExcel();
      final sheet = excel['الطلاب'];
      // Variations in spelling, hamza, taa marbuta, slashes, spacing
      sheet.appendRow([
        TextCellValue('اسم الطالب'),
        TextCellValue('المرحله الدراسيه'),
        TextCellValue('مجموعة'),
      ]);
      sheet.appendRow([
        TextCellValue('جورج مدحت نبيل'),
        TextCellValue('الإعدادية'),
        TextCellValue('الملاك ميخائيل'),
      ]);

      final bytes = excel.save()!;
      final result = service.parseExcelBytes(
        bytes: bytes,
        existingStudents: [],
        availableClasses: sampleClasses,
        availableStages: sampleStages,
      );

      expect(result.validRows.length, 1);
      final row = result.validRows.first;
      expect(row.name, 'جورج مدحت نبيل');
      expect(row.grade, 'الإعدادية');
      expect(row.classId, 'class-prep-1');
    });

    test('parseExcelBytes preserves leading zero in phone numbers', () {
      final excel = Excel.createExcel();
      final sheet = excel['الطلاب'];
      sheet.appendRow([
        for (final h in ExcelStudentImportService.columnHeaders)
          TextCellValue(h),
      ]);
      sheet.appendRow([
        TextCellValue('يوسف رامي سمير'),
        TextCellValue('الابتدائية'),
        TextCellValue('فصل مارمرقس'),
        TextCellValue('2012-01-10'),
        const IntCellValue(1224891045), // Excel stripped leading 0
        TextCellValue('مدرسة القديس يوسف'),
        TextCellValue('لا'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('مهندس'),
        const IntCellValue(1098342110), // Excel stripped leading 0
        TextCellValue('ماريان كمال'),
        TextCellValue(''),
        const IntCellValue(1145678901), // Excel stripped leading 0
        const IntCellValue(4),
        const IntCellValue(1),
        TextCellValue('أبونا ميخائيل'),
        TextCellValue(''),
        TextCellValue('إخوة رب'),
        TextCellValue(''),
      ]);

      final bytes = excel.save()!;
      final result = service.parseExcelBytes(
        bytes: bytes,
        existingStudents: [],
        availableClasses: sampleClasses,
        availableStages: sampleStages,
      );

      expect(result.validRows.length, 1);
      final row = result.validRows.first;
      expect(row.phone, '01224891045');
      expect(row.sensitiveData['father_phone'], '01098342110');
      expect(row.sensitiveData['mother_phone'], '01145678901');
      expect(row.sensitiveData['financial_status'], 'إخوة رب');
    });

    test(
      'parseExcelBytes rejects impossible calendar dates and birthOrder > familySize',
      () {
        final excel = Excel.createExcel();
        final sheet = excel['الطلاب'];
        sheet.appendRow([
          for (final h in ExcelStudentImportService.columnHeaders)
            TextCellValue(h),
        ]);

        // Row 1: invalid leap year date (Feb 29 on non-leap year 2023)
        sheet.appendRow([
          TextCellValue('فادي ماجد عزيز'),
          TextCellValue('الابتدائية'),
          TextCellValue('فصل مارمرقس'),
          TextCellValue('2023-02-29'),
          TextCellValue('01222223333'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          const IntCellValue(3),
          const IntCellValue(4), // birthOrder > familySize
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue('غير مقبولة'), // invalid financial status
          TextCellValue(''),
        ]);

        final bytes = excel.save()!;
        final result = service.parseExcelBytes(
          bytes: bytes,
          existingStudents: [],
          availableClasses: sampleClasses,
          availableStages: sampleStages,
        );

        expect(result.totalRows, 1);
        expect(result.errorRows.length, 1);
        final errors = result.errorRows.first.errors;
        expect(errors.any((e) => e.contains('تاريخ الميلاد')), isTrue);
        expect(errors.any((e) => e.contains('لا يمكن أن يتجاوز')), isTrue);
        expect(errors.any((e) => e.contains('الحالة المادية')), isTrue);
      },
    );

    test('parseExcelBytes safely maps legacy column headers with defaultGrade', () {
      final excel = Excel.createExcel();
      final sheet = excel['الطلاب'];
      // Older spreadsheet headers
      sheet.appendRow([
        TextCellValue('الاسم بالكامل (إلزامي)'),
        TextCellValue('تاريخ الميلاد (YYYY-MM-DD)'),
        TextCellValue('رقم هاتف الطالب'),
        TextCellValue('المدرسة'),
        TextCellValue('اسم ولي الأمر'),
        TextCellValue('هاتف ولي الأمر / واتساب'),
        TextCellValue('هاتف الطوارئ البديل'),
        TextCellValue('العنوان السكني التفصيلي'),
        TextCellValue('أب الاعتراف / المعمودية'),
        TextCellValue('ملاحظات عامة وافتقادية'),
      ]);

      sheet.appendRow([
        TextCellValue('بيتر عادل ميخائيل'),
        TextCellValue('2013-08-14'),
        TextCellValue('01233334444'),
        TextCellValue('مدرسة النصر'),
        TextCellValue('عادل ميخائيل'),
        TextCellValue('01277778888'),
        TextCellValue('01066665555'),
        TextCellValue('5 شارع جزيرة بدران، شبرا'),
        TextCellValue('أبونا متى'),
        TextCellValue('ملاحظة قديمة'),
      ]);

      final bytes = excel.save()!;
      final result = service.parseExcelBytes(
        bytes: bytes,
        existingStudents: [],
        defaultGrade: 'الابتدائية',
      );

      expect(result.validRows.length, 1);
      final row = result.validRows.first;
      expect(row.name, 'بيتر عادل ميخائيل');
      expect(row.grade, 'الابتدائية');
      expect(row.sensitiveData['father_phone'], '01277778888');
      expect(row.sensitiveData['mother_phone'], '01066665555');
      expect(row.sensitiveData['address'], '5 شارع جزيرة بدران، شبرا');
      expect(row.sensitiveData['confessor'], 'أبونا متى');
    });

    test(
      'registerBatch persists imported students to local database and sensitive data table with currentClassId',
      () async {
        final db = AppDatabase.forTesting();
        final local = LocalStudentRepository(db);
        final queue = SyncQueueRepository(db);
        final registration = OfflineFirstStudentRegistration(local, queue);

        try {
          final inputs = [
            const StudentRegistrationInput(
              name: 'فادي ماجد عزيز',
              grade: 'الابتدائية',
              phone: '01233334444',
              school: 'مدرسة القديس يوسف',
              isDeacon: true,
              sensitiveData: {
                'father_job': 'مهندس',
                'father_phone': '01055556666',
                'mother_name': 'مريم رزق',
                'family_size': 4,
                'birth_order': 2,
                'financial_status': FinancialStatus.natural,
                'address_street': 'شبرا مصر',
              },
            ),
          ];

          final created = await registration.registerBatch(
            serviceId: 'service-100',
            currentClassId: 'class-200',
            inputs: inputs,
          );

          expect(created.length, 1);
          expect(created.first.name, 'فادي ماجد عزيز');
          expect(created.first.grade, 'الابتدائية');
          expect(created.first.currentClassId, 'class-200');
          expect(created.first.proposedClassId, isNull);
          expect(created.first.approvalStatus, 'approved');
          expect(created.first.isDeacon, isTrue);

          final cachedStudents = await local
              .watchStudentsForClass('class-200')
              .first;
          expect(cachedStudents.length, 1);
          expect(cachedStudents.first.grade, 'الابتدائية');
          expect(cachedStudents.first.currentClassId, 'class-200');
          expect(cachedStudents.first.approvalStatus, 'approved');
          expect(cachedStudents.first.isDeacon, isTrue);

          final cachedSensitive = await local.findSensitiveData(
            created.first.id,
          );
          expect(cachedSensitive, isNotNull);
          expect(cachedSensitive!.fatherJob, 'مهندس');
          expect(cachedSensitive.familySize, 4);
          expect(cachedSensitive.birthOrder, 2);
          expect(cachedSensitive.financialStatus, 'طبيعي');

          final pendingSync = await queue.pending();
          expect(pendingSync.length, 1);

          final opPayload =
              jsonDecode(pendingSync.first.payloadJson) as Map<String, dynamic>;
          expect(opPayload['id'], created.first.id);
          expect(opPayload['grade'], 'الابتدائية');
          expect(opPayload['current_class_id'], 'class-200');
          expect(opPayload['proposed_class_id'], isNull);
          expect(opPayload['approval_status'], 'approved');
          expect(opPayload['is_deacon'], true);
          expect(opPayload['sensitive_data'], isNotNull);
          expect(opPayload['sensitive_data']['father_job'], 'مهندس');
          expect(opPayload['sensitive_data']['financial_status'], 'طبيعي');
        } finally {
          await db.close();
        }
      },
    );

    test('registerBatch throws ArgumentError when an input is missing grade', () async {
      final db = AppDatabase.forTesting();
      final local = LocalStudentRepository(db);
      final queue = SyncQueueRepository(db);
      final registration = OfflineFirstStudentRegistration(local, queue);

      try {
        final invalidInputs = [
          const StudentRegistrationInput(
            name: 'طالب بدون مرحلة',
            grade: null,
          ),
        ];

        expect(
          () => registration.registerBatch(
            serviceId: 'service-100',
            currentClassId: 'class-200',
            inputs: invalidInputs,
          ),
          throwsA(isA<ArgumentError>()),
        );
      } finally {
        await db.close();
      }
    });
  });
}
