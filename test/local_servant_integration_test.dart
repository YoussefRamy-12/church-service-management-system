import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/servants/data/local_servant_repository.dart';

void main() {
  late AppDatabase db;
  late LocalServantRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalServantRepository(db);
  });

  tearDown(() async => db.close());

  ServantProfile profile({
    required String id,
    required String serviceId,
    required String name,
    required String role,
    String? stageId,
    String? classId,
    String accountStatus = 'active',
  }) {
    return ServantProfile(
      id: id,
      authUserId: 'auth-$id',
      serviceId: serviceId,
      name: name,
      role: role,
      accountStatus: accountStatus,
      stageId: stageId,
      classId: classId,
      phone: '01000000000',
      birthDate: DateTime(2000, 1, 1),
      workStudy: 'student',
    );
  }

  test('watchForService scopes by service and sorts by name', () async {
    await repo.cacheProfiles([
      profile(
        id: 'servant-1',
        serviceId: 'service-1',
        name: 'Zack',
        role: 'class_servant',
        classId: 'class-1',
      ),
      profile(
        id: 'servant-2',
        serviceId: 'service-1',
        name: 'Adam',
        role: 'class_leader',
        classId: 'class-1',
      ),
      profile(
        id: 'servant-3',
        serviceId: 'service-2',
        name: 'Other',
        role: 'overall_helper',
      ),
    ]);

    final values = await repo.watchForService('service-1').firstWhere(
      (items) => items.length == 2,
    );

    expect(values.map((item) => item.name), ['Adam', 'Zack']);
  });

  test('cacheProfiles replaces the existing profile by id', () async {
    await repo.cacheProfiles([
      profile(
        id: 'servant-1',
        serviceId: 'service-1',
        name: 'Old Name',
        role: 'class_servant',
        classId: 'class-1',
      ),
    ]);

    await repo.cacheProfiles([
      profile(
        id: 'servant-1',
        serviceId: 'service-1',
        name: 'New Name',
        role: 'class_leader',
        classId: 'class-2',
      ),
    ]);

    final values = await repo.watchForService('service-1').firstWhere(
      (items) => items.length == 1,
    );

    expect(values.single.name, 'New Name');
    expect(values.single.role, 'class_leader');
    expect(values.single.classId, 'class-2');
  });

  test('updateProfile changes local profile fields and preserves identity', () async {
    await repo.cacheProfiles([
      profile(
        id: 'servant-1',
        serviceId: 'service-1',
        name: 'Peter',
        role: 'class_servant',
        stageId: 'stage-1',
        classId: 'class-1',
      ),
    ]);

    final updated = await repo.updateProfile(
      servantId: 'servant-1',
      name: 'Peter Updated',
      phone: '01111111111',
      birthDate: DateTime(2001, 2, 3),
      workStudy: 'engineer',
      role: 'stage_leader',
      stageId: 'stage-1',
      classId: null,
      accountStatus: 'active',
    );

    expect(updated.id, 'servant-1');
    expect(updated.authUserId, 'auth-servant-1');
    expect(updated.serviceId, 'service-1');
    expect(updated.name, 'Peter Updated');
    expect(updated.role, 'stage_leader');
    expect(updated.classId, isNull);
    expect(updated.birthDate, DateTime(2001, 2, 3));

    final cached = await repo.watchForService('service-1').firstWhere(
      (items) => items.length == 1,
    );
    expect(cached.single.name, 'Peter Updated');
    expect(cached.single.phone, '01111111111');
    expect(cached.single.workStudy, 'engineer');
  });

  test('updateProfile rejects an unknown servant', () async {
    expect(
      () => repo.updateProfile(
        servantId: 'missing',
        name: 'Missing',
        phone: '',
        birthDate: DateTime(2000),
        workStudy: '',
        role: 'class_servant',
        accountStatus: 'active',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
