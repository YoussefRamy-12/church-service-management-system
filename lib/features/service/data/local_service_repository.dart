import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/service.dart';
import '../domain/entities/service_class.dart';
import '../domain/entities/stage.dart';
import '../domain/repositories/service_repository.dart';

class LocalServiceRepository implements ServiceRepository {
  LocalServiceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Service?> getService(String serviceId) async {
    final row = await (_db.select(_db.cachedServices)
          ..where((t) => t.id.equals(serviceId)))
        .getSingleOrNull();

    if (row == null) return null;

    return Service(
      id: row.id,
      name: row.name,
      churchName: row.churchName,
      meetingStartTime: row.meetingStartTime,
    );
  }

  @override
  Stream<List<Stage>> watchStages(String serviceId) {
    return (_db.select(_db.cachedStages)
          ..where((t) => t.serviceId.equals(serviceId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => Stage(
                  id: row.id,
                  serviceId: row.serviceId,
                  name: row.name,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) {
    return (_db.select(_db.cachedClasses)
          ..where((t) => t.stageId.equals(stageId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ServiceClass(
                  id: row.id,
                  stageId: row.stageId,
                  name: row.name,
                ),
              )
              .toList(),
        );
  }

  Future<List<Stage>> getStages(String serviceId) =>
      watchStages(serviceId).first;

  Future<List<ServiceClass>> getClasses(String stageId) =>
      watchClasses(stageId).first;

  Future<void> cacheService(Service service) async {
    await _db.into(_db.cachedServices).insertOnConflictUpdate(
          CachedServicesCompanion.insert(
            id: service.id,
            name: service.name,
            churchName: service.churchName,
            meetingStartTime: service.meetingStartTime,
            cachedAt: DateTime.now(),
          ),
        );
  }

  Future<void> cacheStages(List<Stage> stages) async {
    await _db.batch((batch) {
      for (final stage in stages) {
        batch.insert(
          _db.cachedStages,
          CachedStagesCompanion.insert(
            id: stage.id,
            serviceId: stage.serviceId,
            name: stage.name,
            cachedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> cacheClasses(List<ServiceClass> classes) async {
    await _db.batch((batch) {
      for (final item in classes) {
        batch.insert(
          _db.cachedClasses,
          CachedClassesCompanion.insert(
            id: item.id,
            stageId: item.stageId,
            name: item.name,
            cachedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}
