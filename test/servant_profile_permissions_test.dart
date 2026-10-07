import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/entities/system_admin_profile.dart';

void main() {
  const active = ServantProfile(
    id: 'servant-1',
    authUserId: 'auth-1',
    serviceId: 'service-1',
    name: 'Peter',
    role: 'class_leader',
    accountStatus: 'active',
    classId: 'class-1',
  );

  test('servant account status predicates are mutually consistent', () {
    expect(active.isActive, isTrue);
    expect(active.isPending, isFalse);
    expect(active.isInactive, isFalse);

    const pending = ServantProfile(
      id: 'servant-2',
      authUserId: 'auth-2',
      serviceId: 'service-1',
      name: 'Mark',
      role: 'class_servant',
      accountStatus: 'pending',
    );
    expect(pending.isPending, isTrue);
    expect(pending.isActive, isFalse);

    const inactive = ServantProfile(
      id: 'servant-3',
      authUserId: 'auth-3',
      serviceId: 'service-1',
      name: 'John',
      role: 'stage_leader',
      accountStatus: 'inactive',
    );
    expect(inactive.isInactive, isTrue);
    expect(inactive.isActive, isFalse);
  });

  test('scoped roles retain stage and class assignment', () {
    expect(active.role, 'class_leader');
    expect(active.stageId, isNull);
    expect(active.classId, 'class-1');

    const stageLeader = ServantProfile(
      id: 'servant-4',
      authUserId: 'auth-4',
      serviceId: 'service-1',
      name: 'Luke',
      role: 'stage_leader',
      accountStatus: 'active',
      stageId: 'stage-1',
    );
    expect(stageLeader.stageId, 'stage-1');
    expect(stageLeader.classId, isNull);
  });

  test('system administrator is active only for active status', () {
    const admin = SystemAdminProfile(
      id: 'admin-1',
      authUserId: 'auth-admin',
      status: 'active',
    );
    const inactive = SystemAdminProfile(
      id: 'admin-2',
      authUserId: 'auth-admin-2',
      status: 'inactive',
    );

    expect(admin.isActive, isTrue);
    expect(inactive.isActive, isFalse);
  });
}
