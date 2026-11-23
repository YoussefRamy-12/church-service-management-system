import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_scope.dart';
import 'package:church_service_management_system/features/service/domain/entities/service_class.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/service/domain/repositories/service_repository.dart';

class _FakeServiceRepository implements ServiceRepository {
  final List<Stage> stages;
  final Map<String, List<ServiceClass>> classesByStage;

  _FakeServiceRepository({required this.stages, required this.classesByStage});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Stage>> getStages(String serviceId) async => stages;

  @override
  Future<List<ServiceClass>> getClasses(String stageId) async =>
      classesByStage[stageId] ?? const [];

  @override
  Future<void> refreshStages(String serviceId) async {}

  @override
  Future<void> refreshClasses(String stageId) async {}

  @override
  Stream<List<Stage>> watchStages(String serviceId) => Stream.value(stages);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) =>
      Stream.value(classesByStage[stageId] ?? const []);
}

void main() {
  const serviceId = 'service-1';
  final fakeRepo = _FakeServiceRepository(
    stages: [
      const Stage(
        id: 'stage-5',
        serviceId: serviceId,
        name: 'مرحلة خامسة ابتدائي',
      ),
      const Stage(
        id: 'stage-6',
        serviceId: serviceId,
        name: 'مرحلة سادسة ابتدائي',
      ),
    ],
    classesByStage: {
      'stage-5': [
        const ServiceClass(
          id: 'class-5a',
          stageId: 'stage-5',
          name: 'فصل 5 أول',
        ),
        const ServiceClass(
          id: 'class-5b',
          stageId: 'stage-5',
          name: 'فصل 5 ثان',
        ),
      ],
      'stage-6': [
        const ServiceClass(
          id: 'class-6a',
          stageId: 'stage-6',
          name: 'فصل 6 أول',
        ),
        const ServiceClass(
          id: 'class-6b',
          stageId: 'stage-6',
          name: 'فصل 6 ثان',
        ),
      ],
    },
  );

  group('Scope Resolution', () {
    test('Overall Leader sees all classes (classIds: null)', () async {
      const profile = ServantProfile(
        id: 'p-overall',
        authUserId: 'u-1',
        serviceId: serviceId,
        name: 'قائد الخدمة',
        role: 'overall_leader',
        accountStatus: 'active',
      );

      final scope = await resolveFollowUpClassScope(
        services: fakeRepo,
        serviceId: serviceId,
        profile: profile,
      );

      expect(scope.classIds, isNull);
      expect(scope.stageIds, isNull);
    });

    test('Overall Helper sees all classes (classIds: null)', () async {
      const profile = ServantProfile(
        id: 'p-helper',
        authUserId: 'u-2',
        serviceId: serviceId,
        name: 'مساعد عام',
        role: 'overall_helper',
        accountStatus: 'active',
      );

      final scope = await resolveFollowUpClassScope(
        services: fakeRepo,
        serviceId: serviceId,
        profile: profile,
      );

      expect(scope.classIds, isNull);
      expect(scope.stageIds, isNull);
    });

    test('Stage Leader sees all classes belonging to their stage', () async {
      const profile = ServantProfile(
        id: 'p-stage-5',
        authUserId: 'u-3',
        serviceId: serviceId,
        name: 'أمين مرحلة 5',
        role: 'stage_leader',
        accountStatus: 'active',
        stageId: 'stage-5',
      );

      final scope = await resolveFollowUpClassScope(
        services: fakeRepo,
        serviceId: serviceId,
        profile: profile,
      );

      expect(scope.classIds, {'class-5a', 'class-5b'});
      expect(scope.stageIds, {'stage-5'});
      expect(scope.classIds, isNot(contains('class-6a')));
    });

    test('Class Leader sees only their assigned class', () async {
      const profile = ServantProfile(
        id: 'p-class-5a',
        authUserId: 'u-4',
        serviceId: serviceId,
        name: 'أمين فصل 5 أول',
        role: 'class_leader',
        accountStatus: 'active',
        classId: 'class-5a',
      );

      final scope = await resolveFollowUpClassScope(
        services: fakeRepo,
        serviceId: serviceId,
        profile: profile,
      );

      expect(scope.classIds, {'class-5a'});
      expect(scope.stageIds, {'stage-5'});
      expect(scope.classIds, isNot(contains('class-5b')));
      expect(scope.classIds, isNot(contains('class-6a')));
    });

    test('Class Servant sees only their assigned class', () async {
      const profile = ServantProfile(
        id: 'p-servant-5a',
        authUserId: 'u-5',
        serviceId: serviceId,
        name: 'خادم فصل 5 أول',
        role: 'class_servant',
        accountStatus: 'active',
        classId: 'class-5a',
      );

      final scope = await resolveFollowUpClassScope(
        services: fakeRepo,
        serviceId: serviceId,
        profile: profile,
      );

      expect(scope.classIds, {'class-5a'});
      expect(scope.stageIds, {'stage-5'});
    });

    test('Inactive or mismatching profile returns empty scope', () async {
      const inactive = ServantProfile(
        id: 'p-inactive',
        authUserId: 'u-6',
        serviceId: serviceId,
        name: 'خادم غير نشط',
        role: 'class_servant',
        accountStatus: 'inactive',
        classId: 'class-5a',
      );

      final scope = await resolveFollowUpClassScope(
        services: fakeRepo,
        serviceId: serviceId,
        profile: inactive,
      );

      expect(scope.classIds, isEmpty);
      expect(scope.stageIds, isEmpty);
    });
  });
}
