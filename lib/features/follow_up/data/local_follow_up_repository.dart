import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/follow_up_record.dart';

class LocalFollowUpRepository {
  LocalFollowUpRepository(this.db);
  final AppDatabase db;
  final _uuid=const Uuid();

  Stream<List<FollowUpRecord>> watchForStudent(String studentId)=>
    (db.select(db.cachedFollowUpRecords)..where((t)=>t.studentId.equals(studentId))..orderBy([(t)=>OrderingTerm(expression:t.followUpDate,mode:OrderingMode.desc)])).watch().map((r)=>r.map(_map).toList());

  Future<FollowUpRecord> create({required String studentId,required String createdBy,required String followUpDate,required String contactStatus,String? contactMethod,String? absenceReason,String? studentResponse,String? parentResponse,String? actionRequired,String? notes,bool anotherFollowUpNeeded=false,String? nextFollowUpDate}) async {
    final id=_uuid.v4(), clientOperationId=_uuid.v4();
    await db.into(db.cachedFollowUpRecords).insert(CachedFollowUpRecordsCompanion.insert(
      id:id,studentId:studentId,createdBy:createdBy,followUpDate:followUpDate,contactStatus:contactStatus,
      contactMethod:Value(contactMethod),absenceReason:Value(absenceReason),studentResponse:Value(studentResponse),
      parentResponse:Value(parentResponse),actionRequired:Value(actionRequired),notes:Value(notes),
      anotherFollowUpNeeded:Value(anotherFollowUpNeeded),nextFollowUpDate:Value(nextFollowUpDate),
      clientOperationId:clientOperationId,cachedAt:DateTime.now()));
    return FollowUpRecord(id:id,studentId:studentId,createdBy:createdBy,followUpDate:followUpDate,contactStatus:contactStatus,contactMethod:contactMethod,absenceReason:absenceReason,studentResponse:studentResponse,parentResponse:parentResponse,actionRequired:actionRequired,notes:notes,anotherFollowUpNeeded:anotherFollowUpNeeded,nextFollowUpDate:nextFollowUpDate,clientOperationId:clientOperationId);
  }
  FollowUpRecord _map(CachedFollowUpRecord r)=>FollowUpRecord(id:r.id,studentId:r.studentId,createdBy:r.createdBy,followUpDate:r.followUpDate,contactStatus:r.contactStatus,contactMethod:r.contactMethod,absenceReason:r.absenceReason,studentResponse:r.studentResponse,parentResponse:r.parentResponse,actionRequired:r.actionRequired,notes:r.notes,anotherFollowUpNeeded:r.anotherFollowUpNeeded,nextFollowUpDate:r.nextFollowUpDate,clientOperationId:r.clientOperationId);
}
