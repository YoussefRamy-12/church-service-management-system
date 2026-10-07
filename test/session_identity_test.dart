import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/domain/entities/system_admin_profile.dart';

void main() {
  test('servant identity exposes the servant profile', () {
    const profile = ServantProfile(
      id: 'servant-1',
      authUserId: 'auth-1',
      serviceId: 'service-1',
      name: 'Peter',
      role: 'class_leader',
      accountStatus: 'active',
      classId: 'class-1',
    );

    const identity = ServantIdentity(profile);

    expect(identity.profile.id, 'servant-1');
    expect(identity.profile.serviceId, 'service-1');
    expect(identity.profile.role, 'class_leader');
    expect(identity.profile.classId, 'class-1');
  });

  test('super admin identity preserves the active admin profile', () {
    const profile = SystemAdminProfile(
      id: 'admin-1',
      authUserId: 'auth-admin',
      status: 'active',
    );

    const identity = SuperAdminIdentity(profile);

    expect(identity.profile.id, 'admin-1');
    expect(identity.profile.authUserId, 'auth-admin');
    expect(identity.profile.isActive, isTrue);
  });

  test('session identities are distinct sealed variants', () {
    const profile = ServantProfile(
      id: 'servant-1',
      authUserId: 'auth-1',
      serviceId: 'service-1',
      name: 'Peter',
      role: 'overall_leader',
      accountStatus: 'active',
    );
    const servant = ServantIdentity(profile);
    const admin = SuperAdminIdentity(
      SystemAdminProfile(
        id: 'admin-1',
        authUserId: 'auth-admin',
        status: 'active',
      ),
    );

    expect(servant, isA<ServantIdentity>());
    expect(admin, isA<SuperAdminIdentity>());
    expect(servant, isNot(isA<SuperAdminIdentity>()));
    expect(admin, isNot(isA<ServantIdentity>()));
  });
}
