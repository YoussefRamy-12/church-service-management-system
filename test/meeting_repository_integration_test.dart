import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/attendance/data/local_meeting_repository.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/meeting.dart';

void main() {
  late AppDatabase db;
  late LocalMeetingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalMeetingRepository(db);
  });

  tearDown(() async => db.close());

  test('meetings are cached and streamed newest first', () async {
    await repo.cacheMeetings([
      Meeting(
        id: 'meeting-old',
        serviceId: 'service-1',
        meetingDate: DateTime(2026, 9, 28),
        startTime: '10:00:00',
      ),
      Meeting(
        id: 'meeting-new',
        serviceId: 'service-1',
        meetingDate: DateTime(2026, 10, 5),
        startTime: '10:00:00',
      ),
    ]);

    final rows = await repo.watchMeetings('service-1').firstWhere(
      (items) => items.length == 2,
    );

    expect(rows.map((item) => item.id), ['meeting-new', 'meeting-old']);
  });

  test('meetings from another service are excluded', () async {
    await repo.cacheMeetings([
      Meeting(
        id: 'meeting-1',
        serviceId: 'service-1',
        meetingDate: DateTime(2026, 10, 5),
        startTime: '10:00:00',
      ),
      Meeting(
        id: 'meeting-2',
        serviceId: 'service-2',
        meetingDate: DateTime(2026, 10, 5),
        startTime: '10:00:00',
      ),
    ]);

    final rows = await repo.watchMeetings('service-1').firstWhere(
      (items) => items.length == 1,
    );

    expect(rows.single.id, 'meeting-1');
  });

  test('caching the same meeting id replaces the local copy', () async {
    await repo.cacheMeetings([
      Meeting(
        id: 'meeting-1',
        serviceId: 'service-1',
        meetingDate: DateTime(2026, 10, 5),
        startTime: '10:00:00',
      ),
    ]);

    await repo.cacheMeetings([
      Meeting(
        id: 'meeting-1',
        serviceId: 'service-1',
        meetingDate: DateTime(2026, 10, 12),
        startTime: '11:30:00',
      ),
    ]);

    final rows = await repo.watchMeetings('service-1').firstWhere(
      (items) => items.length == 1,
    );

    expect(rows.single.meetingDate, DateTime(2026, 10, 12));
    expect(rows.single.startTime, '11:30:00');
  });
}
