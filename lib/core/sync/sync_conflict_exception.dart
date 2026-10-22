/// Exception thrown when a sync operation encounters a conflict or business-rule rejection.
class SyncConflictException implements Exception {
  const SyncConflictException(this.message);
  final String message;

  @override
  String toString() => 'SyncConflictException: $message';
}
