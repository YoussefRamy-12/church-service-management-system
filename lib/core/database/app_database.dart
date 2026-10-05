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

class CachedServices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get churchName => text()();
  TextColumn get meetingStartTime => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedStages extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get name => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedClasses extends Table {
  TextColumn get id => text()();
  TextColumn get stageId => text()();
  TextColumn get name => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedStudents extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get currentClassId => text().nullable()();
  TextColumn get proposedClassId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get birthDate => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get school => text().nullable()();
  TextColumn get grade => text().nullable()();
  TextColumn get enrollmentAt => text().nullable()();
  TextColumn get approvalStatus => text()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();
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

@DriftDatabase(
  tables: [
    CachedProfiles,
    CachedServices,
    CachedStages,
    CachedClasses,
    CachedStudents,
    SyncQueueEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'church_service'));

  @override
  int get schemaVersion => 2;
}
