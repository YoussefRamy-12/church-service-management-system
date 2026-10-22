import 'sync_operation.dart';

/// Strategy interface for handling sync operations per entity type (OCP).
///
/// Each entity type registers its own handler so new entities can be
/// added without modifying the transport dispatch logic.
abstract interface class EntitySyncHandler {
  /// The entity type string this handler is responsible for (e.g. 'meeting').
  String get entityType;

  /// Applies [operation] with the decoded [payload] to the remote backend.
  Future<void> apply(SyncOperation operation, Map<String, dynamic> payload);
}
