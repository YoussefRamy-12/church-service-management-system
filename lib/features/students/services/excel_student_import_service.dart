import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/file_download_helper.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';
import '../data/offline_first_student_registration.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';

class ParsedStudentRow {
  ParsedStudentRow({
    required this.rowNumber,
    required this.name,
    this.birthDate,
    this.enrollmentDate,
    this.phone,
    this.school,
    this.grade,
    this.classId,
    this.className,
    this.isDeacon = false,
    this.photoPath,
    this.generalNotes,
    this.sensitiveData = const {},
    this.errors = const [],
    this.isDuplicate = false,
    this.duplicateReason,
  });

  final int rowNumber;
  String name;
  DateTime? birthDate;
  DateTime? enrollmentDate;
  String? phone;
  String? school;
  String? grade;
  String? classId;
  String? className;
  bool isDeacon;
  String? photoPath;
  String? generalNotes;
  Map<String, dynamic> sensitiveData;
  List<String> errors;
  bool isDuplicate;
  String? duplicateReason;

  bool get isValid => errors.isEmpty && !isDuplicate;

  StudentRegistrationInput toRegistrationInput({
    String? fallbackClassId,
    String? fallbackGrade,
    bool isTransfer = false,
  }) {
    final effectiveClassId = classId ?? fallbackClassId;
    final effectiveGrade = grade ?? fallbackGrade;
    return StudentRegistrationInput(
      name: name,
      currentClassId: isTransfer ? null : effectiveClassId,
      proposedClassId: isTransfer ? effectiveClassId : null,
      approvalStatus: isTransfer
          ? 'pending'
          : (effectiveClassId != null ? 'approved' : 'pending'),
      birthDate: birthDate,
      enrollmentAt: enrollmentDate ?? DateTime.now(),
      phone: phone,
      school: school,
      grade: effectiveGrade,
      isDeacon: isDeacon,
      photoPath: photoPath,
      notes: generalNotes,
      sensitiveData: sensitiveData,
    );
  }
}

class ExcelParseResult {
  const ExcelParseResult({required this.totalRows, required this.rows});

  final int totalRows;
  final List<ParsedStudentRow> rows;

  List<ParsedStudentRow> get validRows => rows.where((r) => r.isValid).toList();
  List<ParsedStudentRow> get errorRows =>
      rows.where((r) => r.errors.isNotEmpty).toList();
  List<ParsedStudentRow> get duplicateRows =>
      rows.where((r) => r.isDuplicate).toList();
  bool get hasErrors => errorRows.isNotEmpty || duplicateRows.isNotEmpty;
}

class ExcelStudentImportService {
  const ExcelStudentImportService();

  static const List<String> columnHeaders = [
    'الاسم الكامل',
    'المرحلة الدراسية',
    'الفصل',
    'تاريخ الميلاد (YYYY-MM-DD)',
    'رقم هاتف الطالب',
    'المدرسة',
    'شماس (نعم/لا)',
    'رقم العنوان',
    'شارع',
    'دور',
    'شقة',
    'وظيفة الأب',
    'تليفون الأب',
    'اسم الأم',
    'وظيفة الأم',
    'تليفون الأم',
    'عدد أفراد الأسرة',
    'ترتيب الطالب بين إخوته',
    'أب الاعتراف',
    'ملاحظات صحية أو حساسية',
    'الحالة المادية للأسرة (طبيعي / إخوة رب / أسرة مستترة)',
    'ملاحظات عامة',
  ];

  /// Generates the downloadable blank Excel template with confirmed header, guidelines, and synthetic sample row.
  Uint8List generateTemplateExcel() {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'الطلاب');
    final sheet = excel['الطلاب'];

    // Header Row
    sheet.appendRow([
      for (final header in columnHeaders) TextCellValue(header),
    ]);

    // Example synthetic row with fictitious data
    sheet.appendRow([
      TextCellValue('كيرلس أمير عزيز'),
      TextCellValue('الابتدائية'),
      TextCellValue('فصل مارمرقس'),
      TextCellValue('2013-05-15'),
      TextCellValue('01224891045'),
      TextCellValue('مدرسة السلام الخاصة'),
      TextCellValue('نعم'),
      TextCellValue('14'),
      TextCellValue('شارع عياد بك'),
      TextCellValue('3'),
      TextCellValue('6'),
      TextCellValue('مهندس مدني'),
      TextCellValue('01224891045'),
      TextCellValue('مريم نبيل فوزي'),
      TextCellValue('معلمة لغة إنجليزية'),
      TextCellValue('01098342110'),
      const IntCellValue(5),
      const IntCellValue(2),
      TextCellValue('أبونا بيشوي'),
      TextCellValue('حساسية بسيطة من الفول السوداني'),
      TextCellValue('طبيعي'),
      TextCellValue('تلميذ منتظم في القداسات والاجتماع'),
    ]);

    // Instructions sheet
    final instructionsSheet = excel['تعليمات الاستيراد'];
    instructionsSheet.appendRow([
      TextCellValue('إرشادات استيراد الطلاب من ملف Excel:'),
    ]);
    instructionsSheet.appendRow([
      TextCellValue(
        '1. عمود الاسم الكامل إلزامي، ويجب ألا يقل عن اسم ثنائي أو ثلاثي.',
      ),
    ]);
    instructionsSheet.appendRow([
      TextCellValue(
        '2. التواريخ بالصيغة: سنة-شهر-يوم (مثال: 2013-05-15)، أو أعمدة منفصلة (يوم، شهر، سنة).',
      ),
    ]);
    instructionsSheet.appendRow([
      TextCellValue(
        '3. أرقام الهواتف تُحفظ كسلاسل نصية وتحافظ على الصفر في البداية (مثال: 01224891045).',
      ),
    ]);
    instructionsSheet.appendRow([TextCellValue('4. شماس يقبل: نعم أو لا.')]);
    instructionsSheet.appendRow([
      TextCellValue(
        '5. عدد أفراد الأسرة وترتيب الطالب أرقام موجبة، وترتيب الطالب لا يتجاوز عدد أفراد الأسرة.',
      ),
    ]);
    instructionsSheet.appendRow([
      TextCellValue(
        '6. الحالة المادية تقتصر حصريًا على: طبيعي، إخوة رب، أسرة مستترة.',
      ),
    ]);
    instructionsSheet.appendRow([
      TextCellValue('7. أب الاعتراف حقل واحد محدد.'),
    ]);
    instructionsSheet.appendRow([
      TextCellValue('8. لا تقم بتعديل أسماء الأعمدة في ورقة «الطلاب».'),
    ]);

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Downloads the Excel template through the browser.
  void downloadTemplate() {
    final bytes = generateTemplateExcel();
    FileDownloadHelper.downloadBytes(
      bytes: bytes,
      filename: 'csms_students_template.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  /// Parses an uploaded `.xlsx` file and validates each row against confirmed data model and business rules.
  ExcelParseResult parseExcelBytes({
    required List<int> bytes,
    required List<Student> existingStudents,
    String? defaultClassId,
    String? defaultStageId,
    String? defaultGrade,
    List<ServiceClass> availableClasses = const [],
    List<Stage> availableStages = const [],
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return const ExcelParseResult(totalRows: 0, rows: []);
    }

    var sheet = excel.tables['الطلاب'];
    if (sheet == null || sheet.rows.isEmpty) {
      for (final table in excel.tables.values) {
        if (table.rows.isNotEmpty) {
          sheet = table;
          break;
        }
      }
    }

    if (sheet == null || sheet.rows.isEmpty) {
      return const ExcelParseResult(totalRows: 0, rows: []);
    }

    final parsedRows = <ParsedStudentRow>[];
    final seenNamesInFile = <String, int>{};
    final seenPhonesInFile = <String, int>{};

    final existingNames = <String>{};
    final existingPhones = <String>{};
    for (final s in existingStudents) {
      existingNames.add(_normalizeArabic(s.name));
      if (s.phone != null && s.phone!.trim().isNotEmpty) {
        existingPhones.add(_cleanPhone(s.phone!));
      }
    }

    // Header index mapping
    final headerRow = sheet.rows.first;
    final Map<String, int> headerMap = {};
    for (var col = 0; col < headerRow.length; col++) {
      final headerStr = _normalizeHeader(_cellToString(headerRow[col]?.value));
      if (headerStr.isNotEmpty) {
        headerMap[headerStr] = col;
      }
    }

    if (sheet.rows.length <= 1) {
      return const ExcelParseResult(totalRows: 0, rows: []);
    }

    int? getCol(List<String> aliases) {
      for (final alias in aliases) {
        final norm = _normalizeHeader(alias);
        if (headerMap.containsKey(norm)) {
          return headerMap[norm];
        }
      }
      return null;
    }

    final colName = getCol([
      'الاسم الكامل',
      'الاسم بالكامل (إلزامي)',
      'الاسم بالكامل',
      'اسم الطالب',
      'الاسم',
    ]);

    final colGrade = getCol([
      'المرحلة الدراسية',
      'المرحله الدراسيه',
      'المرحلة',
      'المرحله',
      'الصف الدراسي',
      'الصف الدراسى',
      'الصف',
      'السنة الدراسية',
      'السنه الدراسيه',
      'المرحلة / الصف',
      'المرحلة العمرية',
      'مرحلة',
      'صف',
      'grade',
      'stage',
    ]);

    final colClass = getCol([
      'الفصل',
      'فصل',
      'اسم الفصل',
      'المجموعة',
      'المجموعه',
      'مجموعة',
      'اسم المجموعة',
      'الفصل / المجموعة',
      'class',
      'class name',
      'group',
    ]);

    final colBirthDate = getCol([
      'تاريخ الميلاد (YYYY-MM-DD)',
      'تاريخ الميلاد',
      'الميلاد',
    ]);
    final colBirthDay = getCol(['يوم الميلاد', 'اليوم', 'يوم']);
    final colBirthMonth = getCol(['شهر الميلاد', 'الشهر', 'شهر']);
    final colBirthYear = getCol(['سنة الميلاد', 'السنة', 'سنة']);
    final colPhone = getCol([
      'رقم هاتف الطالب',
      'تليفون الطالب',
      'هاتف الطالب',
      'الموبايل',
      'تليفون',
    ]);
    final colSchool = getCol(['المدرسة', 'مدرسة']);
    final colDeacon = getCol(['شماس (نعم/لا)', 'شماس']);
    final colAddressNum = getCol(['رقم العنوان', 'رقم العقار', 'رقم']);
    final colStreet = getCol(['شارع', 'الشارع']);
    final colFloor = getCol(['دور', 'الدور']);
    final colApt = getCol(['شقة', 'الشقة']);
    final colLegacyAddress = getCol([
      'العنوان السكني التفصيلي',
      'العنوان بالتفصيل',
      'العنوان',
    ]);
    final colFatherJob = getCol(['وظيفة الأب', 'عمل الأب']);
    final colFatherPhone = getCol([
      'تليفون الأب',
      'هاتف الأب',
      'هاتف ولي الأمر / واتساب',
      'هاتف ولي الأمر',
    ]);
    final colMotherName = getCol(['اسم الأم', 'الأم']);
    final colMotherJob = getCol(['وظيفة الأم', 'عمل الأم']);
    final colMotherPhone = getCol([
      'تليفون الأم',
      'هاتف الأم',
      'هاتف الطوارئ البديل',
      'هاتف الطوارئ',
    ]);
    final colFamilySize = getCol([
      'عدد أفراد الأسرة',
      'عدد الأسرة',
      'العدد',
    ]);
    final colBirthOrder = getCol([
      'ترتيب الطالب بين إخوته',
      'ترتيب الطالب',
      'الترتيب',
    ]);
    final colConfessor = getCol([
      'أب الاعتراف',
      'أب الاعتراف / المعمودية',
      'اب الاعتراف',
      'أبونا الاعتراف / المعمودية',
      'أبونا الاعتراف',
    ]);
    final colMedical = getCol([
      'ملاحظات صحية أو حساسية',
      'ملاحظات صحية',
      'الحالة الصحية',
    ]);
    final colFinancial = getCol([
      'الحالة المادية للأسرة (طبيعي / إخوة رب / أسرة مستترة)',
      'الحالة المادية للأسرة',
      'الحالة المادية',
    ]);
    final colNotes = getCol([
      'ملاحظات عامة',
      'ملاحظات عامة وافتقادية',
      'ملاحظات',
    ]);

    for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;

      String readVal(int? colIdx) {
        if (colIdx == null || colIdx < 0 || colIdx >= row.length) return '';
        return _cellToString(row[colIdx]?.value).trim();
      }

      final name = readVal(colName);
      final rawGrade = readVal(colGrade);
      final rawClass = readVal(colClass);
      final rawBirthDate = readVal(colBirthDate);
      final rawBirthDay = readVal(colBirthDay);
      final rawBirthMonth = readVal(colBirthMonth);
      final rawBirthYear = readVal(colBirthYear);
      final studentPhone = _cleanPhone(readVal(colPhone));
      final school = readVal(colSchool);
      final deaconStr = readVal(colDeacon);
      final addressNum = readVal(colAddressNum);
      final street = readVal(colStreet);
      final floor = readVal(colFloor);
      final apt = readVal(colApt);
      final legacyAddress = readVal(colLegacyAddress);
      final fatherJob = readVal(colFatherJob);
      final fatherPhone = _cleanPhone(readVal(colFatherPhone));
      final motherName = readVal(colMotherName);
      final motherJob = readVal(colMotherJob);
      final motherPhone = _cleanPhone(readVal(colMotherPhone));
      final familySizeStr = readVal(colFamilySize);
      final birthOrderStr = readVal(colBirthOrder);
      final confessor = readVal(colConfessor);
      final medicalNotes = readVal(colMedical);
      final financialStatus = readVal(colFinancial);
      final generalNotes = readVal(colNotes);

      // Skip row if completely empty
      if (name.isEmpty &&
          studentPhone.isEmpty &&
          fatherPhone.isEmpty &&
          school.isEmpty) {
        continue;
      }

      final errors = <String>[];

      // 1. Name validation
      if (name.isEmpty) {
        errors.add('اسم الطالب إلزامي.');
      } else if (name
              .split(RegExp(r'\s+'))
              .where((w) => w.trim().isNotEmpty)
              .length <
          2) {
        errors.add('يجب إدخال اسم ثنائي أو ثلاثي على الأقل.');
      }

      // 2. Birth date validation
      DateTime? birthDate;
      if (rawBirthDay.isNotEmpty &&
          rawBirthMonth.isNotEmpty &&
          rawBirthYear.isNotEmpty) {
        final d = int.tryParse(rawBirthDay);
        final m = int.tryParse(rawBirthMonth);
        final y = int.tryParse(rawBirthYear);
        if (d != null && m != null && y != null) {
          birthDate = _constructCalendarDate(y, m, d);
          if (birthDate == null) {
            errors.add(
              'تاريخ الميلاد المحدد غير صحيح تقويميًا ($rawBirthYear-$rawBirthMonth-$rawBirthDay).',
            );
          }
        } else {
          errors.add('أرقام اليوم/الشهر/السنة لتاريخ الميلاد غير صالحة.');
        }
      } else if (rawBirthDate.isNotEmpty) {
        birthDate = _parseDate(rawBirthDate);
        if (birthDate == null) {
          errors.add(
            'صيغة تاريخ الميلاد غير صالحة ($rawBirthDate). المطلوب: YYYY-MM-DD.',
          );
        }
      }

      if (birthDate != null && birthDate.isAfter(DateTime.now())) {
        errors.add('تاريخ الميلاد لا يمكن أن يكون في المستقبل.');
      }

      // 3. Deacon status
      final isDeacon = _parseBool(deaconStr);

      // 4. Phone numbers validation (preserve leading zeros)
      if (studentPhone.isNotEmpty && !_isValidPhone(studentPhone)) {
        errors.add('رقم هاتف الطالب ($studentPhone) غير صالح.');
      }
      if (fatherPhone.isNotEmpty && !_isValidPhone(fatherPhone)) {
        errors.add('تليفون الأب ($fatherPhone) غير صالح.');
      }
      if (motherPhone.isNotEmpty && !_isValidPhone(motherPhone)) {
        errors.add('تليفون الأم ($motherPhone) غير صالح.');
      }

      // 5. Family size & birth order validation
      int? familySize;
      if (familySizeStr.isNotEmpty) {
        familySize = int.tryParse(familySizeStr);
        if (familySize == null || familySize <= 0) {
          errors.add(
            'عدد أفراد الأسرة يجب أن يكون رقمًا صحيحًا موجبًا ($familySizeStr).',
          );
        }
      }

      int? birthOrder;
      if (birthOrderStr.isNotEmpty) {
        birthOrder = int.tryParse(birthOrderStr);
        if (birthOrder == null || birthOrder <= 0) {
          errors.add(
            'ترتيب الطالب بين إخوته يجب أن يكون رقمًا صحيحًا موجبًا ($birthOrderStr).',
          );
        }
      }

      if (familySize != null &&
          birthOrder != null &&
          familySize > 0 &&
          birthOrder > 0) {
        if (birthOrder > familySize) {
          errors.add(
            'ترتيب الطالب بين إخوته ($birthOrder) لا يمكن أن يتجاوز عدد أفراد الأسرة ($familySize).',
          );
        }
      }

      // 6. Financial status validation
      if (financialStatus.isNotEmpty &&
          !FinancialStatus.isValid(financialStatus)) {
        errors.add(
          'الحالة المادية ($financialStatus) غير مقبولة. الخيارات: طبيعي، إخوة رب، أسرة مستترة.',
        );
      }

      // 7. Duplicate Check
      bool isDuplicate = false;
      String? duplicateReason;
      final normalizedName = _normalizeArabic(name);

      if (normalizedName.isNotEmpty) {
        if (seenNamesInFile.containsKey(normalizedName)) {
          isDuplicate = true;
          duplicateReason =
              'مكرر داخل الملف (الصف ${seenNamesInFile[normalizedName]})';
        } else {
          seenNamesInFile[normalizedName] = rowIndex + 1;
        }
      }

      if (!isDuplicate && studentPhone.isNotEmpty) {
        if (seenPhonesInFile.containsKey(studentPhone)) {
          isDuplicate = true;
          duplicateReason =
              'رقم هاتف مكرر داخل الملف (الصف ${seenPhonesInFile[studentPhone]})';
        } else {
          seenPhonesInFile[studentPhone] = rowIndex + 1;
        }
      }

      if (!isDuplicate) {
        if (existingNames.contains(normalizedName)) {
          isDuplicate = true;
          duplicateReason = 'يوجد تلميذ مسجل بالفعل بنفس الاسم في الخدمة';
        } else if (studentPhone.isNotEmpty &&
            existingPhones.contains(studentPhone)) {
          isDuplicate = true;
          duplicateReason =
              'يوجد تلميذ مسجل بالفعل بنفس رقم الهاتف ($studentPhone)';
        }
      }

      // Combine structured address
      final sensitiveObj = SensitiveStudentData(
        studentId: '',
        fatherJob: fatherJob.isEmpty ? null : fatherJob,
        fatherPhone: fatherPhone.isEmpty ? null : fatherPhone,
        motherName: motherName.isEmpty ? null : motherName,
        motherJob: motherJob.isEmpty ? null : motherJob,
        motherPhone: motherPhone.isEmpty ? null : motherPhone,
        familySize: familySize,
        birthOrder: birthOrder,
        confessor: confessor.isEmpty ? null : confessor,
        medicalNotes: medicalNotes.isEmpty ? null : medicalNotes,
        financialStatus: financialStatus.isEmpty ? null : financialStatus,
        address: legacyAddress.isNotEmpty ? legacyAddress : null,
        addressBuilding: addressNum.isEmpty ? null : addressNum,
        addressStreet: street.isEmpty ? null : street,
        addressFloor: floor.isEmpty ? null : floor,
        addressApartment: apt.isEmpty ? null : apt,
        guardianName: fatherJob.isNotEmpty ? fatherJob : null,
        guardianPhone: fatherPhone.isNotEmpty ? fatherPhone : null,
        emergencyPhone: motherPhone.isNotEmpty ? motherPhone : null,
      );

      // Resolve class from Excel column
      String? resolvedClassId;
      String? resolvedClassName;
      if (rawClass.isNotEmpty) {
        final matchedClass = findMatchingClass(rawClass, availableClasses);
        if (matchedClass != null) {
          resolvedClassId = matchedClass.id;
          resolvedClassName = matchedClass.name;
        } else {
          errors.add(
            'لم يتم العثور على فصل مطابق للاسم "$rawClass" في الخدمة.',
          );
        }
      }

      // Resolve grade/stage
      String? resolvedGrade;
      if (rawGrade.isNotEmpty) {
        final matchedStage = findMatchingStage(rawGrade, availableStages);
        resolvedGrade = matchedStage?.name ?? rawGrade;
      } else if (resolvedClassId != null) {
        // Derive grade from class → stage
        final classObj = availableClasses
            .where((c) => c.id == resolvedClassId)
            .firstOrNull;
        if (classObj != null) {
          final stageObj = availableStages
              .where((s) => s.id == classObj.stageId)
              .firstOrNull;
          if (stageObj != null) {
            resolvedGrade = stageObj.name;
          }
        }
      }

      // Fall back to defaults from the import page selection
      if ((resolvedGrade == null || resolvedGrade.trim().isEmpty) &&
          defaultGrade != null &&
          defaultGrade.isNotEmpty) {
        resolvedGrade = defaultGrade;
      }
      if ((resolvedGrade == null || resolvedGrade.trim().isEmpty) &&
          defaultStageId != null) {
        final stageObj = availableStages
            .where((s) => s.id == defaultStageId)
            .firstOrNull;
        if (stageObj != null) {
          resolvedGrade = stageObj.name;
        }
      }

      if (resolvedGrade == null || resolvedGrade.trim().isEmpty) {
        errors.add('حقل المرحلة / الصف إلزامي (الصف ${rowIndex + 1}).');
      }

      parsedRows.add(
        ParsedStudentRow(
          rowNumber: rowIndex + 1,
          name: name,
          birthDate: birthDate,
          enrollmentDate: DateTime.now(),
          phone: studentPhone.isEmpty ? null : studentPhone,
          school: school.isEmpty ? null : school,
          grade: resolvedGrade,
          classId: resolvedClassId ?? defaultClassId,
          className: resolvedClassName,
          isDeacon: isDeacon,
          generalNotes: generalNotes.isEmpty ? null : generalNotes,
          sensitiveData: sensitiveObj.toMap(),
          errors: errors,
          isDuplicate: isDuplicate,
          duplicateReason: duplicateReason,
        ),
      );
    }

    return ExcelParseResult(totalRows: parsedRows.length, rows: parsedRows);
  }

  /// Generates a downloadable Excel report of problematic rows.
  Uint8List generateErrorReportExcel(List<ParsedStudentRow> problematicRows) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'أخطاء الاستيراد');
    final sheet = excel['أخطاء الاستيراد'];

    sheet.appendRow([
      TextCellValue('رقم الصف في الملف الأصلي'),
      TextCellValue('الاسم'),
      TextCellValue('سبب الرفض / المشكلة'),
      TextCellValue('الهاتف'),
      TextCellValue('المدرسة'),
    ]);

    for (final r in problematicRows) {
      final reason = r.errors.isNotEmpty
          ? r.errors.join(' | ')
          : (r.duplicateReason ?? 'مكرر');

      sheet.appendRow([
        IntCellValue(r.rowNumber),
        TextCellValue(r.name),
        TextCellValue(reason),
        TextCellValue(r.phone ?? ''),
        TextCellValue(r.school ?? ''),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  static String _cellToString(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) {
      if (value.value == value.value.roundToDouble()) {
        return value.value.toInt().toString();
      }
      return value.value.toString();
    }
    if (value is DateCellValue) {
      return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    return value.toString().trim();
  }

  static String _cleanPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10 && digits.startsWith('1')) {
      // Excel stripped leading 0 from Egyptian mobile
      digits = '0$digits';
    }
    return digits;
  }

  static bool _isValidPhone(String phone) {
    if (phone.isEmpty) return true;
    return phone.length >= 8 && phone.length <= 15;
  }

  static bool _parseBool(String raw) {
    final clean = raw.trim().toLowerCase();
    return clean == 'نعم' || clean == 'true' || clean == '1' || clean == 'شماس';
  }

  static DateTime? _constructCalendarDate(int year, int month, int day) {
    if (year < 1900 || year > 2100) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null; // Invalid date like Feb 29 on non-leap year or April 31
    }
    return candidate;
  }

  static DateTime? _parseDate(String raw) {
    final cleaned = raw.replaceAll('/', '-').trim();
    try {
      final parts = cleaned.split('-');
      if (parts.length == 3) {
        final p0 = int.tryParse(parts[0]);
        final p1 = int.tryParse(parts[1]);
        final p2 = int.tryParse(parts[2]);
        if (p0 != null && p1 != null && p2 != null) {
          // If YYYY-MM-DD
          if (p0 > 1900) {
            return _constructCalendarDate(p0, p1, p2);
          }
          // If DD-MM-YYYY
          if (p2 > 1900) {
            return _constructCalendarDate(p2, p1, p0);
          }
        }
      }
      final direct = DateTime.tryParse(raw);
      if (direct != null) return direct;
      final format = DateFormat('yyyy-MM-dd');
      return format.parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeHeader(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\(\)\[\]\{\}\-_/\\,،:.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeArabic(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\(\)\[\]\{\}\-_/\\,،:.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tries to match a raw class name from Excel against available classes.
  static ServiceClass? findMatchingClass(
    String rawName,
    List<ServiceClass> classes,
  ) {
    final cleanRaw = _normalizeArabic(rawName);
    if (cleanRaw.isEmpty) return null;

    for (final c in classes) {
      if (_normalizeArabic(c.name) == cleanRaw || c.id == rawName.trim()) {
        return c;
      }
    }

    // Strip common prefixes like فصل / مجموعة
    final strippedRaw = cleanRaw
        .replaceFirst(RegExp(r'^(فصل|مجموعه)\s+'), '')
        .replaceAll(RegExp(r'\s+'), '');
    for (final c in classes) {
      final strippedClass = _normalizeArabic(c.name)
          .replaceFirst(RegExp(r'^(فصل|مجموعه)\s+'), '')
          .replaceAll(RegExp(r'\s+'), '');
      if (strippedClass.isNotEmpty && strippedClass == strippedRaw) {
        return c;
      }
    }

    return null;
  }

  /// Tries to match a raw stage/grade name from Excel against available stages.
  static Stage? findMatchingStage(
    String rawName,
    List<Stage> stages,
  ) {
    final cleanRaw = _normalizeArabic(rawName);
    if (cleanRaw.isEmpty) return null;

    for (final s in stages) {
      if (_normalizeArabic(s.name) == cleanRaw || s.id == rawName.trim()) {
        return s;
      }
    }

    final strippedRaw = cleanRaw
        .replaceFirst(RegExp(r'^(مرحله|صف|المرحله|الصف)\s+'), '')
        .replaceAll(RegExp(r'\s+'), '');
    for (final s in stages) {
      final strippedStage = _normalizeArabic(s.name)
          .replaceFirst(RegExp(r'^(مرحله|صف|المرحله|الصف)\s+'), '')
          .replaceAll(RegExp(r'\s+'), '');
      if (strippedStage.isNotEmpty && strippedStage == strippedRaw) {
        return s;
      }
    }

    return null;
  }
}
