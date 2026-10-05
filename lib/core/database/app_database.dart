import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get authUserId => text()();
  TextColumn get serviceId => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get accountStatus => text()();
  TextColumn get stageId => text().nullable()();
  TextColumn get classId => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

@DriftDatabase(tables: [CachedProfiles, SyncQueueEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'church_service'));

  @override
  int get schemaVersion => 1;
}
