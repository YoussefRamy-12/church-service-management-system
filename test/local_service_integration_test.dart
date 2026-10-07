import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/service/data/local_service_repository.dart';
import 'package:church_service_management_system/features/service/domain/entities/service.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';

void main() {
  late AppDatabase db;
  late LocalServiceRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalServiceRepository(db);
  });

  tearDown(() async => db.close());

  test('service cache can be read and updated locally', () async {
    await repo.cacheService(const Service(
      id: 'service-1',
      name: 'Primary Service',
      churchName: 'Church',
      meetingStartTime: '10:00:00',
    ));

    expect((await repo.getService('service-1'))?.meetingStartTime, '10:00:00');

    await repo.updateMeetingStartTime(
      serviceId: 'service-1',
      meetingStartTime: '10:30:00',
    );

    final service = await repo.getService('service-1');
    expect(service?.name, 'Primary Service');
    expect(service?.meetingStartTime, '10:30:00');
  });

  test('stages are scoped to service and sorted by name', () async {
    await repo.cacheStages([
      const Stage(id: 'stage-2', serviceId: 'service-1', name: 'Youth'),
      const Stage(id: 'stage-1', serviceId: 'service-1', name: 'Primary'),
      const Stage(id: 'stage-3', serviceId: 'service-2', name: 'Other'),
    ]);

    final stages = await repo.getStages('service-1');
    expect(stages.map((item) => item.name), ['Primary', 'Youth']);
  });

  test('classes are scoped to stage and sorted by name', () async {
    await repo.cacheClasses([
      const ServiceClass(id: 'class-2', stageId: 'stage-1', name: 'Class B'),
      const ServiceClass(id: 'class-1', stageId: 'stage-1', name: 'Class A'),
      const ServiceClass(id: 'class-3', stageId: 'stage-2', name: 'Other'),
    ]);

    final classes = await repo.getClasses('stage-1');
    expect(classes.map((item) => item.name), ['Class A', 'Class B']);
  });

  test('reporting periods are cached and scoped by service', () async {
    await repo.cacheReportingPeriods([
      CachedReportingPeriodsCompanion.insert(
        id: 'period-2',
        serviceId: 'service-1',
        name: 'October',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        cachedAt: DateTime(2026, 10, 1),
      ),
      CachedReportingPeriodsCompanion.insert(
        id: 'period-1',
        serviceId: 'service-2',
        name: 'Other',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        cachedAt: DateTime(2026, 10, 1),
      ),
    ]);

    final periods = await repo.getReportingPeriods('service-1');
    expect(periods.length, 1);
    expect(periods.single.name, 'October');
  });
}
