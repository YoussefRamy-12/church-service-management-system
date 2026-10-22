// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import '../../../core/database/app_database.dart';
import '../../service/domain/entities/service_class.dart';
import '../../students/domain/entities/student.dart';

class CsvExportRepository {
  CsvExportRepository([this._db]);

  final AppDatabase? _db;

  Future<void> exportStudentsFromData({
    required String serviceId,
    required List<dynamic> classes,
    required List<dynamic> students,
    String? stageId,
    String? classId,
    Set<String>? studentIds,
    bool graduationOnly = false,
  }) async {
    final classList = classes.cast<ServiceClass>();
    final studentList = students.cast<Student>();

    final classRows = classList.where(
      (row) => classId == null
          ? (stageId == null || row.stageId == stageId)
          : row.id == classId,
    );

    final allowedClassIds = classRows.map((row) => row.id).toSet();

    final scoped = studentList.where((student) {
      if (student.serviceId != serviceId) return false;
      if (studentIds != null && !studentIds.contains(student.id)) {
        return false;
      }
      if (classId != null) {
        return student.currentClassId == classId;
      }
      if (stageId != null) {
        return student.currentClassId != null &&
            allowedClassIds.contains(student.currentClassId);
      }
      return true;
    }).toList();

    final byClass = {for (final row in classList) row.id: row.name};
    final buffer = StringBuffer();
    if (graduationOnly) {
      buffer.writeln(
        _row(['ID', 'Name', 'Birth Date', 'Phone', 'School', 'Grade', 'Class']),
      );
    } else {
      buffer.writeln(
        _row([
          'ID',
          'Name',
          'Birth Date',
          'Phone',
          'School',
          'Grade',
          'Deacon',
          'Enrollment Date',
          'Approval Status',
          'Class',
          'Notes',
        ]),
      );
    }

    for (final student in scoped) {
      final values = graduationOnly
          ? [
              student.id,
              student.name,
              student.birthDate?.toIso8601String().split('T').first ?? '',
              student.phone ?? '',
              student.school ?? '',
              student.grade ?? '',
              byClass[student.currentClassId] ?? '',
            ]
          : [
              student.id,
              student.name,
              student.birthDate?.toIso8601String().split('T').first ?? '',
              student.phone ?? '',
              student.school ?? '',
              student.grade ?? '',
              student.isDeacon ? 'Yes' : 'No',
              student.enrollmentAt?.toIso8601String() ?? '',
              student.approvalStatus,
              byClass[student.currentClassId] ?? '',
              student.notes ?? '',
            ];
      buffer.writeln(_row(values));
    }

    _download(
      utf8.encode('\uFEFF$buffer'),
      'students_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  Future<void> exportStudents({
    required String serviceId,
    String? stageId,
    String? classId,
    Set<String>? studentIds,
    bool graduationOnly = false,
  }) async {
    final db = _db!;
    final classes = await db.select(db.cachedClasses).get();
    final classRows = classes.where(
      (row) => classId == null
          ? (stageId == null || _stageContains(row.id, stageId, classes))
          : row.id == classId,
    );

    final allowedClassIds = classRows.map((row) => row.id).toSet();
    final students = await (_db.select(
      _db.cachedStudents,
    )..where((t) => t.serviceId.equals(serviceId))).get();

    final scoped = students.where((student) {
      if (studentIds != null && !studentIds.contains(student.id)) {
        return false;
      }
      if (classId != null) {
        return student.currentClassId == classId;
      }
      if (stageId != null) {
        return student.currentClassId != null &&
            allowedClassIds.contains(student.currentClassId);
      }
      return true;
    }).toList();

    final byClass = {for (final row in classes) row.id: row.name};
    final buffer = StringBuffer();
    if (graduationOnly) {
      buffer.writeln(
        _row(['ID', 'Name', 'Birth Date', 'Phone', 'School', 'Grade', 'Class']),
      );
    } else {
      buffer.writeln(
        _row([
          'ID',
          'Name',
          'Birth Date',
          'Phone',
          'School',
          'Grade',
          'Deacon',
          'Enrollment Date',
          'Approval Status',
          'Class',
          'Notes',
        ]),
      );
    }

    for (final student in scoped) {
      final values = graduationOnly
          ? [
              student.id,
              student.name,
              student.birthDate ?? '',
              student.phone ?? '',
              student.school ?? '',
              student.grade ?? '',
              byClass[student.currentClassId] ?? '',
            ]
          : [
              student.id,
              student.name,
              student.birthDate ?? '',
              student.phone ?? '',
              student.school ?? '',
              student.grade ?? '',
              student.isDeacon ? 'Yes' : 'No',
              student.enrollmentAt ?? '',
              student.approvalStatus,
              byClass[student.currentClassId] ?? '',
              student.notes ?? '',
            ];
      buffer.writeln(_row(values));
    }

    _download(
      utf8.encode('\uFEFF$buffer'),
      'students_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  bool _stageContains(
    String classId,
    String stageId,
    List<CachedClassesData> classes,
  ) {
    return classes.any((row) => row.id == classId && row.stageId == stageId);
  }

  String _row(List<String> values) =>
      values.map((value) => '"${value.replaceAll('"', '""')}"').join(',');

  void _download(List<int> bytes, String filename) {
    final blob = html.Blob([
      Uint8List.fromList(bytes),
    ], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
