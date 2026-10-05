import '../entities/service.dart';
import '../entities/stage.dart';
import '../entities/service_class.dart';

abstract interface class ServiceRepository {
  Future<Service?> getService(String serviceId);
  Stream<List<Stage>> watchStages(String serviceId);
  Stream<List<ServiceClass>> watchClasses(String stageId);
}
