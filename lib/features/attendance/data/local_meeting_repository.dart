import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/meeting.dart';

class LocalMeetingRepository {
  LocalMeetingRepository(this._db);
  final AppDatabase _db;

  Stream<List<Meeting>> watchMeetings(String serviceId) => (_db.select(_db.cachedMeetings)
    ..where((t) => t.serviceId.equals(serviceId))
    ..orderBy([(t) => OrderingTerm.desc(t.meetingDate)])).watch().map((rows) => rows.map((r) => Meeting(id: r.id, serviceId: r.serviceId, meetingDate: DateTime.parse(r.meetingDate), startTime: r.startTime)).toList());

  Future<void> cacheMeetings(List<Meeting> meetings) async {
    await _db.batch((batch) {
      for (final item in meetings) {
        batch.insert(_db.cachedMeetings, CachedMeetingsCompanion.insert(id: item.id, serviceId: item.serviceId, meetingDate: item.meetingDate.toIso8601String(), startTime: item.startTime, cachedAt: DateTime.now()), mode: InsertMode.insertOrReplace);
      }
    });
  }
}
