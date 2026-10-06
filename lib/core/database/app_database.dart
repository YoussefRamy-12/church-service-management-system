import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get authUserId => text()();
  TextColumn get serviceId => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get birthDate => text().nullable()();
  TextColumn get workStudy => text().nullable()();
  TextColumn get accountStatus => text()();
  BoolColumn get mustChangePassword => boolean().withDefault(const Constant(false))();
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

class CachedMeetings extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get meetingDate => text()();
  TextColumn get startTime => text()();
  DateTimeColumn get cachedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedAttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get meetingId => text()();
  TextColumn get studentId => text()();
  TextColumn get classIdAtAttendance => text()();
  DateTimeColumn get checkedInAt => dateTime()();
  TextColumn get recordedBy => text()();
  TextColumn get clientOperationId => text()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedFollowUpRecords extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text()();
  TextColumn get createdBy => text()();
  TextColumn get followUpDate => text()();
  TextColumn get contactStatus => text()();
  TextColumn get contactMethod => text().nullable()();
  TextColumn get absenceReason => text().nullable()();
  TextColumn get studentResponse => text().nullable()();
  TextColumn get parentResponse => text().nullable()();
  TextColumn get actionRequired => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get anotherFollowUpNeeded => boolean().withDefault(const Constant(false))();
  TextColumn get nextFollowUpDate => text().nullable()();
  TextColumn get clientOperationId => text()();
  DateTimeColumn get cachedAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

class CachedReportingPeriods extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
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
    CachedMeetings,
    CachedAttendanceRecords,
    CachedFollowUpRecords,
    CachedReportingPeriods,
    SyncQueueEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'church_service'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedServices);
            await m.createTable(cachedStages);
            await m.createTable(cachedClasses);
            await m.createTable(cachedStudents);
          }
          if (from < 3) {
            await m.createTable(cachedMeetings);
            await m.createTable(cachedAttendanceRecords);
          }
          if (from < 4) {
            await m.createTable(cachedFollowUpRecords);
          }
          if (from < 6) {
            await m.createTable(cachedReportingPeriods);
          }
          if (from < 5) {
            await m.addColumn(cachedProfiles, cachedProfiles.phone);
            await m.addColumn(cachedProfiles, cachedProfiles.birthDate);
            await m.addColumn(cachedProfiles, cachedProfiles.workStudy);
            await m.addColumn(cachedProfiles, cachedProfiles.mustChangePassword);
          }
        },
      );
}
