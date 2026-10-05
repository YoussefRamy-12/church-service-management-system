import '../domain/entities/service.dart';
import '../domain/entities/service_class.dart';
import '../domain/entities/stage.dart';
import '../domain/repositories/service_repository.dart';
import 'local_service_repository.dart';
import 'supabase_service_repository.dart';

class OfflineFirstServiceRepository implements ServiceRepository {
  OfflineFirstServiceRepository({
    required this.local,
    required this.remote,
  });

  final LocalServiceRepository local;
  final SupabaseServiceRepository remote;

  @override
  Future<Service?> getService(String serviceId) async {
    final cached = await local.getService(serviceId);
    if (cached != null) return cached;

    final remoteValue = await remote.getService(serviceId);
    if (remoteValue != null) {
      await local.cacheService(remoteValue);
    }
    return remoteValue;
  }

  @override
  Stream<List<Stage>> watchStages(String serviceId) => local.watchStages(serviceId);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) => local.watchClasses(stageId);

  Future<void> refreshStages(String serviceId) async {
    final values = await remote.fetchStages(serviceId);
    await local.cacheStages(values);
  }

  Future<void> refreshClasses(String stageId) async {
    final values = await remote.fetchClasses(stageId);
    await local.cacheClasses(values);
  }
}
