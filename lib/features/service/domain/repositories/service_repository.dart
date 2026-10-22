import '../../../../core/database/app_database.dart';
import '../entities/service.dart';
import '../entities/stage.dart';
import '../entities/service_class.dart';

abstract interface class ServiceRepository {
  Future<Service?> getService(String serviceId);
  Stream<List<Stage>> watchStages(String serviceId);
  Stream<List<ServiceClass>> watchClasses(String stageId);
  Future<List<Stage>> getStages(String serviceId);
  Future<List<ServiceClass>> getClasses(String stageId);
  Future<void> deleteStage(String id);
  Future<void> deleteClass(String id);
  Future<void> updateMeetingStartTime({
    required String serviceId,
    required String meetingStartTime,
  });
  Future<void> updateMeetingSchedule({
    required String serviceId,
    required String meetingStartTime,
    required String meetingFrequency,
    required int meetingWeekday,
    required int meetingMonthDay,
    required int earlyAttendanceMinutes,
  });
  Future<void> refreshStages(String serviceId);
  Future<void> refreshClasses(String stageId);
  Future<void> refreshReportingPeriods(String serviceId);
  Future<List<CachedReportingPeriod>> getReportingPeriods(String serviceId);
  Future<void> addReportingPeriod({
    required String serviceId,
    required String name,
    required String type,
    required String startDate,
    required String endDate,
  });
}
