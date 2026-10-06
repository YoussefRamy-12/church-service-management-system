class FollowUpRecord {
  const FollowUpRecord({required this.id,required this.studentId,required this.createdBy,required this.followUpDate,required this.contactStatus,required this.clientOperationId,this.contactMethod,this.absenceReason,this.studentResponse,this.parentResponse,this.actionRequired,this.notes,this.anotherFollowUpNeeded=false,this.nextFollowUpDate});
  final String id,studentId,createdBy,followUpDate,contactStatus,clientOperationId;
  final String? contactMethod,absenceReason,studentResponse,parentResponse,actionRequired,notes,nextFollowUpDate;
  final bool anotherFollowUpNeeded;
}
