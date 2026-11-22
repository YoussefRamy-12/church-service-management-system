import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/students/data/local_service_student_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/service_student.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late LocalServiceStudentRepository memberships;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    memberships = LocalServiceStudentRepository(db, queue);
  });

  tearDown(() async {
    await db.close();
  });

  test('service directory RPC maps membership and global identity fields', () {
    final membership = ServiceStudent.fromMap({
      'membership_id': 'membership-rpc-1',
      'student_id': 'global-student-rpc-1',
      'service_id': 'service-b',
      'class_id': 'class-b',
      'proposed_class_id': null,
      'enrollment_date': '2026-11-20T00:00:00.000Z',
      'membership_status': 'active',
      'school': 'مدرسة',
      'grade': 'السادس',
      'is_deacon': false,
      'membership_notes': 'ملاحظة خاصة بالخدمة',
      'student_name': 'تلميذ مشترك',
      'birth_date': '2015-03-12',
      'phone': '01000000000',
      'photo_path': null,
    });

    expect(membership.id, 'membership-rpc-1');
    expect(membership.status, 'active');
    expect(membership.studentName, 'تلميذ مشترك');
    expect(membership.birthDate, DateTime(2015, 3, 12));
    expect(membership.notes, 'ملاحظة خاصة بالخدمة');
  });

  test('membership remains available offline and queues an idempotent sync payload', () async {
    final membership = ServiceStudent(
      id: 'membership-a-1',
      studentId: 'global-student-1',
      serviceId: 'service-a',
      classId: 'class-a',
      enrollmentDate: DateTime.utc(2026, 11, 20),
      status: 'active',
      school: 'مدرسة الخدمة أ',
      grade: 'الخامس',
      studentName: 'طالب متعدد الخدمات',
      birthDate: DateTime(2015, 3, 12),
      phone: '01000000000',
    );

    await memberships.saveOffline(membership);

    final cached = await memberships.findById(membership.id);
    final pending = await queue.pending();

    expect(cached, isNotNull);
    expect(cached!.studentId, membership.studentId);
    expect(cached.serviceId, 'service-a');
    expect(cached.classId, 'class-a');
    expect(cached.studentName, 'طالب متعدد الخدمات');
    expect(cached.birthDate, DateTime(2015, 3, 12));
    expect(cached.phone, '01000000000');
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'service_student');
    expect(pending.single.operationType, 'upsert');

    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;
    expect(payload['id'], membership.id);
    expect(payload['student_id'], membership.studentId);
    expect(payload['service_id'], membership.serviceId);
  });

  test('same global student can have isolated cached memberships in two services', () async {
    await memberships.cache([
      ServiceStudent(
        id: 'membership-a-2',
        studentId: 'global-student-2',
        serviceId: 'service-a',
        enrollmentDate: DateTime.utc(2026, 11, 20),
        status: 'active',
      ),
      ServiceStudent(
        id: 'membership-b-2',
        studentId: 'global-student-2',
        serviceId: 'service-b',
        enrollmentDate: DateTime.utc(2026, 11, 21),
        status: 'pending',
      ),
    ]);

    final serviceA = await memberships.watchForService('service-a').first;
    final serviceB = await memberships.watchForService('service-b').first;

    expect(serviceA.map((m) => m.id), ['membership-a-2']);
    expect(serviceB.map((m) => m.id), ['membership-b-2']);
    expect(serviceA.single.studentId, serviceB.single.studentId);
  });

  test('offline archive changes only membership status and queues it', () async {
    final membership = ServiceStudent(
      id: 'membership-archive-1',
      studentId: 'global-student-3',
      serviceId: 'service-a',
      enrollmentDate: DateTime.utc(2026, 11, 20),
      status: 'active',
    );

    await memberships.cache([membership]);
    await memberships.archiveOffline(membership);

    final archived = await memberships.findById(membership.id);
    final pending = await queue.pending();

    expect(archived?.status, 'inactive');
    expect(pending, hasLength(1));
    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;
    expect(payload['status'], 'inactive');
    expect(payload['student_id'], membership.studentId);
  });
}
