class SyncOperation {
  const SyncOperation({
    required this.operationId,
    required this.entityType,
    required this.operationType,
    required this.payloadJson,
  });
  final String operationId;
  final String entityType;
  final String operationType;
  final String payloadJson;
}
