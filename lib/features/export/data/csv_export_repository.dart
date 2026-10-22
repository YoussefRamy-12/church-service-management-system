import 'package:excel/excel.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/file_download_helper.dart';
import '../../service/domain/entities/service_class.dart';
import '../../students/domain/entities/student.dart';
import '../../students/domain/entities/sensitive_student_data.dart';

class ExportColumn {
  const ExportColumn(this.id, this.label);
  final String id;
  final String label;
}

class CsvExportRepository {
  CsvExportRepository([this._db]);
  final AppDatabase? _db;

  static const columns = <ExportColumn>[
    ExportColumn('id', 'معرّف التلميذ'),
    ExportColumn('name', 'الاسم'),
    ExportColumn('birthDate', 'تاريخ الميلاد'),
    ExportColumn('phone', 'الهاتف'),
    ExportColumn('school', 'المدرسة'),
    ExportColumn('grade', 'الصف الدراسي'),
    ExportColumn('deacon', 'خادم'),
    ExportColumn('enrollmentAt', 'تاريخ التسجيل'),
    ExportColumn('approvalStatus', 'حالة الاعتماد'),
    ExportColumn('class', 'الفصل'),
    ExportColumn('proposedClass', 'الفصل المقترح'),
    ExportColumn('notes', 'ملاحظات'),
    ExportColumn('photoPath', 'مسار الصورة'),
    ExportColumn('fatherJob', 'وظيفة الأب'),
    ExportColumn('fatherPhone', 'هاتف الأب'),
    ExportColumn('motherName', 'اسم الأم'),
    ExportColumn('motherJob', 'وظيفة الأم'),
    ExportColumn('motherPhone', 'هاتف الأم'),
    ExportColumn('familySize', 'عدد أفراد الأسرة'),
    ExportColumn('birthOrder', 'ترتيب الميلاد'),
    ExportColumn('confessor', 'أب الاعتراف'),
    ExportColumn('medicalNotes', 'ملاحظات صحية'),
    ExportColumn('financialStatus', 'الحالة المادية'),
    ExportColumn('address', 'العنوان'),
    ExportColumn('confidentialNotes', 'ملاحظات سرية'),
    ExportColumn('studyYear', 'السنة الدراسية'),
  ];
  static const graduationColumns = <String>{
    'id',
    'name',
    'birthDate',
    'phone',
    'school',
    'grade',
    'class',
  };

  Future<void> exportStudentsFromData({
    required String serviceId,
    required List<dynamic> classes,
    required List<dynamic> students,
    String? stageId,
    String? classId,
    Set<String>? studentIds,
    bool graduationOnly = false,
    Set<String>? selectedColumns,
    Map<String, SensitiveStudentData?> sensitiveData = const {},
  }) async {
    final classList = classes.cast<ServiceClass>();
    final classRows = classList.where(
      (row) => classId == null
          ? (stageId == null || row.stageId == stageId)
          : row.id == classId,
    );
    final allowedClassIds = classRows.map((row) => row.id).toSet();
    final scoped = students.cast<Student>().where((student) {
      if (student.serviceId != serviceId ||
          (studentIds != null && !studentIds.contains(student.id))) {
        return false;
      }
      if (classId != null) return student.currentClassId == classId;
      if (stageId != null) {
        return allowedClassIds.contains(student.currentClassId);
      }
      return true;
    }).toList();
    await _write(
      scoped,
      {for (final row in classList) row.id: row.name},
      graduationOnly,
      selectedColumns,
      sensitiveData,
    );
  }

  Future<void> exportStudents({
    required String serviceId,
    String? stageId,
    String? classId,
    Set<String>? studentIds,
    bool graduationOnly = false,
    Set<String>? selectedColumns,
    Map<String, SensitiveStudentData?> sensitiveData = const {},
  }) async {
    final db = _db!;
    final classes = await db.select(db.cachedClasses).get();
    final students = await (db.select(
      db.cachedStudents,
    )..where((t) => t.serviceId.equals(serviceId))).get();
    final allowedClassIds = classes
        .where(
          (row) => classId == null
              ? (stageId == null || row.stageId == stageId)
              : row.id == classId,
        )
        .map((row) => row.id)
        .toSet();
    final scoped = students
        .where((student) {
          if (studentIds != null && !studentIds.contains(student.id)) {
            return false;
          }
          if (classId != null) return student.currentClassId == classId;
          if (stageId != null) {
            return allowedClassIds.contains(student.currentClassId);
          }
          return true;
        })
        .map(
          (row) => Student(
            id: row.id,
            serviceId: row.serviceId,
            name: row.name,
            approvalStatus: row.approvalStatus,
            currentClassId: row.currentClassId,
            proposedClassId: row.proposedClassId,
            birthDate: row.birthDate == null
                ? null
                : DateTime.tryParse(row.birthDate!),
            phone: row.phone,
            school: row.school,
            grade: row.grade,
            isDeacon: row.isDeacon,
            enrollmentAt: row.enrollmentAt == null
                ? null
                : DateTime.tryParse(row.enrollmentAt!),
            photoPath: row.photoPath,
            notes: row.notes,
          ),
        )
        .toList();
    final sensitiveRows = await (db.select(
      db.cachedStudentSensitiveData,
    )..where((t) => t.studentId.isIn(scoped.map((s) => s.id)))).get();
    final localSensitive = {
      for (final row in sensitiveRows)
        row.studentId: SensitiveStudentData(
          studentId: row.studentId,
          fatherJob: row.fatherJob,
          fatherPhone: row.fatherPhone,
          motherName: row.motherName,
          motherJob: row.motherJob,
          motherPhone: row.motherPhone,
          familySize: row.familySize,
          birthOrder: row.birthOrder,
          confessor: row.confessor,
          medicalNotes: row.medicalNotes,
          financialStatus: row.financialStatus,
          address: row.address,
          addressBuilding: row.addressBuilding,
          addressStreet: row.addressStreet,
          addressFloor: row.addressFloor,
          addressApartment: row.addressApartment,
          confidentialNotes: row.confidentialNotes,
          studyYear: row.studyYear,
        ),
    };
    await _write(
      scoped,
      {for (final row in classes) row.id: row.name},
      graduationOnly,
      selectedColumns,
      localSensitive,
    );
  }

  Future<void> _write(
    List<Student> students,
    Map<String, String> classNames,
    bool graduationOnly,
    Set<String>? selection,
    Map<String, SensitiveStudentData?> sensitiveData,
  ) async {
    final eligible = graduationOnly
        ? columns
              .where((column) => graduationColumns.contains(column.id))
              .toList()
        : columns;
    final chosen = eligible
        .where((column) => selection == null || selection.contains(column.id))
        .toList();
    final book = Excel.createExcel();
    final defaultSheet = book.getDefaultSheet() ?? 'Sheet1';
    book.rename(defaultSheet, 'الطلاب');
    final sheet = book['الطلاب'];
    sheet.appendRow(chosen.map((c) => TextCellValue(c.label)).toList());
    for (final student in students) {
      final values = <String, String>{
        'id': student.id,
        'name': student.name,
        'birthDate':
            student.birthDate?.toIso8601String().split('T').first ?? '',
        'phone': student.phone ?? '',
        'school': student.school ?? '',
        'grade': student.grade ?? '',
        'deacon': student.isDeacon ? 'نعم' : 'لا',
        'enrollmentAt':
            student.enrollmentAt?.toIso8601String().split('T').first ?? '',
        'approvalStatus': student.approvalStatus,
        'class': classNames[student.currentClassId] ?? '',
        'proposedClass': classNames[student.proposedClassId] ?? '',
        'notes': student.notes ?? '',
        'photoPath': student.photoPath ?? '',
      };
      final sensitive = sensitiveData[student.id];
      values.addAll({
        'fatherJob': sensitive?.fatherJob ?? '',
        'fatherPhone': sensitive?.effectiveFatherPhone ?? '',
        'motherName': sensitive?.motherName ?? '',
        'motherJob': sensitive?.motherJob ?? '',
        'motherPhone': sensitive?.effectiveMotherPhone ?? '',
        'familySize': sensitive?.familySize?.toString() ?? '',
        'birthOrder': sensitive?.birthOrder?.toString() ?? '',
        'confessor': sensitive?.confessor ?? '',
        'medicalNotes': sensitive?.medicalNotes ?? '',
        'financialStatus': sensitive?.financialStatus ?? '',
        'address': sensitive?.fullAddress ?? '',
        'confidentialNotes': sensitive?.confidentialNotes ?? '',
        'studyYear': sensitive?.studyYear ?? '',
      });
      sheet.appendRow(
        chosen.map((column) => TextCellValue(values[column.id] ?? '')).toList(),
      );
    }
    final bytes = book.save();
    if (bytes == null) throw StateError('تعذر إنشاء ملف Excel');
    FileDownloadHelper.downloadBytes(
      bytes: bytes,
      filename: 'students_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}
