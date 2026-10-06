import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/follow_up_record.dart';
import 'local_follow_up_repository.dart';

class OfflineFirstFollowUpRepository {
  OfflineFirstFollowUpRepository({required this.local,required this.queue});
  final LocalFollowUpRepository local;
  final SyncQueueRepository queue;
  Stream<List<FollowUpRecord>> watchForStudent(String id)=>local.watchForStudent(id);
  Future<FollowUpRecord> create({required String studentId,required String createdBy,required String followUpDate,required String contactStatus,String? contactMethod,String? absenceReason,String? studentResponse,String? parentResponse,String? actionRequired,String? notes,bool anotherFollowUpNeeded=false,String? nextFollowUpDate}) async {
    final r=await local.create(studentId:studentId,createdBy:createdBy,followUpDate:followUpDate,contactStatus:contactStatus,contactMethod:contactMethod,absenceReason:absenceReason,studentResponse:studentResponse,parentResponse:parentResponse,actionRequired:actionRequired,notes:notes,anotherFollowUpNeeded:anotherFollowUpNeeded,nextFollowUpDate:nextFollowUpDate);
    await queue.enqueue(SyncOperation(operationId:const Uuid().v4(),entityType:'follow_up',operationType:'insert',payloadJson:jsonEncode({
      'id':r.id,'student_id':r.studentId,'created_by':r.createdBy,'follow_up_date':r.followUpDate,'contact_status':r.contactStatus,'contact_method':r.contactMethod,'absence_reason':r.absenceReason,'student_response':r.studentResponse,'parent_response':r.parentResponse,'action_required':r.actionRequired,'notes':r.notes,'another_follow_up_needed':r.anotherFollowUpNeeded,'next_follow_up_date':r.nextFollowUpDate,'client_operation_id':r.clientOperationId,
    })));
    return r;
  }
}
