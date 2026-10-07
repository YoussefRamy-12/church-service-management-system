import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/students/data/local_student_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

Student _student({
  String id = 'student-1',
  String name = '  Peter  ',
  String approvalStatus = 'approved',
  String? currentClassId = 'class-1',
  String? proposedClassId,
  String? phone = ' 01000000000 ',
  String? notes = ' note ',
}) {
  return Student(
    id: id,
    serviceId: 'service-1',
    currentClassId: currentClassId,
    proposedClassId: proposedClassId,
    name: name,
    approvalStatus: approvalStatus,
    phone: phone,
    notes: notes,
    birthDate: DateTime(2014, 5, 10),
    school: 'School',
    grade: '6',
    enrollmentAt: DateTime(2026, 9, 1),
  );
}

void main() {
  late AppDatabase db;
  late LocalStudentRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalStudentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('cache and find preserve the student record', () async {
    await repo.cacheStudents([_student()]);

    final found = await repo.findById('student-1');

    expect(found, isNotNull);
    expect(found!.id, 'student-1');
    expect(found.name, '  Peter  ');
    expect(found.currentClassId, 'class-1');
  });

  test('updateStudent trims name and normalizes blank optional fields', () async {
    await repo.cacheStudents([_student()]);

    final updated = await repo.updateStudent(
      studentId: 'student-1',
      name: '  Peter Updated  ',
      phone: '   ',
      school: '  ',
      grade: '  6  ',
      notes: '   ',
    );

    expect(updated.name, 'Peter Updated');
    expect(updated.phone, isNull);
    expect(updated.school, isNull);
    expect(updated.grade, '6');
    expect(updated.notes, isNull);

    final persisted = await repo.findById('student-1');
    expect(persisted!.name, 'Peter Updated');
  });

  test('updateStudent rejects unknown students', () async {
    expect(
      () => repo.updateStudent(
        studentId: 'missing',
        name: 'Peter',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('approvePending moves proposed class to current class', () async {
    await repo.cacheStudents([
      _student(
        approvalStatus: 'pending',
        currentClassId: null,
        proposedClassId: 'class-2',
      ),
    ]);

    final approved = await repo.approvePending('student-1');

    expect(approved.approvalStatus, 'approved');
    expect(approved.currentClassId, 'class-2');
    expect(approved.proposedClassId, isNull);

    final persisted = await repo.findById('student-1');
    expect(persisted!.currentClassId, 'class-2');
    expect(persisted.proposedClassId, isNull);
  });

  test('approvePending rejects a non-pending student', () async {
    await repo.cacheStudents([_student()]);

    expect(
      () => repo.approvePending('student-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('approvePending rejects pending student without proposed class', () async {
    await repo.cacheStudents([
      _student(
        approvalStatus: 'pending',
        currentClassId: null,
        proposedClassId: null,
      ),
    ]);

    expect(
      () => repo.approvePending('student-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('watchStudentsForClass includes current and proposed class students', () async {
    final stream = repo.watchStudentsForClass('class-2');

    await repo.cacheStudents([
      _student(id: 'current', currentClassId: 'class-2', proposedClassId: null),
      _student(id: 'proposed', currentClassId: null, proposedClassId: 'class-2'),
      _student(id: 'other', currentClassId: 'class-1', proposedClassId: 'class-3'),
    ]);

    final rows = await stream.firstWhere((items) => items.length == 2);

    expect(rows.map((s) => s.id), containsAll(<String>['current', 'proposed']));
    expect(rows.map((s) => s.id), isNot(contains('other')));
  });

  test('cacheStudents replaces an existing student by id', () async {
    final stream = repo.watchStudentsForClass('class-1');

    await repo.cacheStudents([_student(name: 'Original')]);
    await repo.cacheStudents([_student(name: 'Updated')]);

    final rows = await stream.firstWhere((items) => items.length == 1);

    expect(rows.single.name, 'Updated');
  });
}
