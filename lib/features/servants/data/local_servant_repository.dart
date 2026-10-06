import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../auth/domain/entities/servant_profile.dart';

class LocalServantRepository {
  LocalServantRepository(this._db);

  final AppDatabase _db;

  Stream<List<ServantProfile>> watchForService(String serviceId) {
    return (_db.select(_db.cachedProfiles)
          ..where((t) => t.serviceId.equals(serviceId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch()
        .map((rows) => rows.map(_map).toList());
  }

  Future<void> cacheProfiles(List<ServantProfile> profiles) async {
    await _db.batch((batch) {
      for (final profile in profiles) {
        batch.insert(
          _db.cachedProfiles,
          CachedProfilesCompanion.insert(
            id: profile.id,
            authUserId: profile.authUserId,
            serviceId: profile.serviceId,
            name: profile.name,
            role: profile.role,
            phone: Value(profile.phone),
            birthDate: Value(profile.birthDate?.toIso8601String().split('T').first),
            workStudy: Value(profile.workStudy),
            accountStatus: profile.accountStatus,
            stageId: Value(profile.stageId),
            classId: Value(profile.classId),
            mustChangePassword: Value(profile.mustChangePassword),
            cachedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<ServantProfile> updateProfile({
    required String servantId,
    required String name,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String role,
    String? stageId,
    String? classId,
    required String accountStatus,
  }) async {
    final row = await (_db.select(_db.cachedProfiles)
          ..where((t) => t.id.equals(servantId)))
        .getSingle();

    final updated = ServantProfile(
      id: row.id,
      authUserId: row.authUserId,
      serviceId: row.serviceId,
      name: name,
      phone: phone,
      birthDate: birthDate,
      workStudy: workStudy,
      role: role,
      accountStatus: accountStatus,
      stageId: stageId,
      classId: classId,
      mustChangePassword: row.mustChangePassword,
    );

    await (_db.update(_db.cachedProfiles)..where((t) => t.id.equals(servantId))).write(
      CachedProfilesCompanion(
        name: Value(name),
        phone: Value(phone),
        birthDate: Value(birthDate.toIso8601String().split('T').first),
        workStudy: Value(workStudy),
        role: Value(role),
        stageId: Value(stageId),
        classId: Value(classId),
        accountStatus: Value(accountStatus),
      ),
    );

    return updated;
  }

  ServantProfile _map(CachedProfile row) => ServantProfile(
        id: row.id,
        authUserId: row.authUserId,
        serviceId: row.serviceId,
        name: row.name,
        role: row.role,
        accountStatus: row.accountStatus,
        phone: row.phone,
        birthDate: row.birthDate == null ? null : DateTime.parse(row.birthDate!),
        workStudy: row.workStudy,
        stageId: row.stageId,
        classId: row.classId,
        mustChangePassword: row.mustChangePassword,
      );
}
