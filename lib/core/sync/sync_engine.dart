import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/connectivity_service.dart';
import '../network/connectivity_service_impl.dart';
import 'entity_sync_handler.dart';
import 'handlers/attendance_sync_handler.dart';
import 'handlers/follow_up_sync_handler.dart';
import 'handlers/meeting_sync_handler.dart';
import 'handlers/reporting_period_sync_handler.dart';
import 'handlers/servant_sync_handler.dart';
import 'handlers/service_sync_handler.dart';
import 'handlers/student_sync_handler.dart';
import 'sync_conflict_exception.dart';
import 'sync_operation.dart';
import 'sync_queue_repository.dart';
import 'sync_status.dart';

export 'sync_conflict_exception.dart';

abstract interface class SyncTransport {
  Future<void> apply(SyncOperation operation, Map<String, dynamic> payload);
}

/// Strategy-based sync transport.
///
/// Dispatches sync operations to registered [EntitySyncHandler] strategies,
/// satisfying the Open-Closed Principle (OCP) and Single Responsibility (SRP).
class SupabaseSyncTransport implements SyncTransport {
  SupabaseSyncTransport(this.client, [Map<String, EntitySyncHandler>? handlers])
    : _handlers = handlers ?? _defaultHandlers(client);

  final SupabaseClient client;
  final Map<String, EntitySyncHandler> _handlers;

  static Map<String, EntitySyncHandler> _defaultHandlers(
    SupabaseClient client,
  ) {
    final list = <EntitySyncHandler>[
      MeetingSyncHandler(client),
      StudentSyncHandler(client),
      AttendanceSyncHandler(client),
      FollowUpSyncHandler(client),
      ServantSyncHandler(client),
      ServiceSyncHandler(client),
      ReportingPeriodSyncHandler(client),
    ];
    return {for (final handler in list) handler.entityType: handler};
  }

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    final handler = _handlers[operation.entityType];
    if (handler == null) {
      throw UnsupportedError(
        'Unsupported sync entity: ${operation.entityType}',
      );
    }
    return handler.apply(operation, payload);
  }
}

/// Compatibility adapter for legacy connectivityChecker function in tests.
class _CheckerConnectivityService implements ConnectivityService {
  _CheckerConnectivityService(this._checker, [this._onChanged]);

  final Future<List<ConnectivityResult>> Function() _checker;
  final Stream<List<ConnectivityResult>>? _onChanged;

  @override
  Future<bool> get isOnline async {
    final results = await _checker();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _onChanged
          ?.map((results) => results.any((r) => r != ConnectivityResult.none))
          .distinct() ??
      const Stream.empty();
}

/// Orchestrates sync between the local offline queue and the remote backend.
///
/// Implements [ChangeNotifier] and exposes [onStatusChanged] (Observer pattern)
/// so UI widgets react to status changes without manual polling.
class SyncEngine extends ChangeNotifier {
  SyncEngine({
    required this.queue,
    SupabaseClient? client,
    SyncTransport? transport,
    ConnectivityService? connectivityService,
    Connectivity? connectivity,
    Future<List<ConnectivityResult>> Function()? connectivityChecker,
    bool enabled = true,
  }) : _enabled = enabled,
       _connectivityService =
           connectivityService ??
           (connectivityChecker != null
               ? _CheckerConnectivityService(
                   connectivityChecker,
                   connectivity?.onConnectivityChanged,
                 )
               : ConnectivityServiceImpl(connectivity)),
       _transport = transport ?? SupabaseSyncTransport(client!);

  final SyncQueueRepository queue;
  final bool _enabled;
  final ConnectivityService _connectivityService;
  final SyncTransport _transport;
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  StreamSubscription<bool>? _subscription;
  bool _running = false;
  SyncStatus _status = SyncStatus.idle;
  Object? lastError;

  bool get isEnabled => _enabled;
  bool get enabled => _enabled;
  SyncStatus get status => _status;

  Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  set status(SyncStatus value) {
    if (_status != value) {
      _status = value;
      _statusController.add(value);
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (!_enabled) return;
    _subscription ??= _connectivityService.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        syncNow();
      } else {
        status = SyncStatus.offline;
      }
    });
    await syncNow();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _statusController.close();
    super.dispose();
  }

  Future<void> syncNow() async {
    if (!_enabled) return;
    if (_running) return;
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      status = SyncStatus.offline;
      return;
    }

    status = SyncStatus.syncing;
    lastError = null;
    _running = true;
    try {
      // Reconcile old duplicate-meeting conflicts before processing ordinary
      // pending work. The transport drops them when the shared meeting exists.
      await queue.retryMeetingConflicts();
      for (final operation in await queue.pending()) {
        try {
          final payload = queue.decode(operation.payloadJson);
          await _transport.apply(operation, payload);
          await queue.markDone(operation.operationId);
        } catch (error) {
          // A pending meeting can become obsolete when another service member
          // has already created that same shared meeting. A class servant also
          // cannot publish meetings, so retaining a rejected meeting insert as
          // a conflict would make the conflict screen permanently noisy.
          if (operation.entityType == 'meeting' &&
              error is PostgrestException &&
              (error.code == '23505' || error.code == '42501')) {
            await queue.markDone(operation.operationId);
            continue;
          }
          if (error is PostgrestException &&
              (error.code == '23505' ||
                  error.code == '23503' ||
                  error.code == '42501')) {
            await queue.markConflict(operation.operationId);
          } else if (error is SyncConflictException) {
            await queue.markConflict(operation.operationId);
          } else {
            await queue.markRetry(operation.operationId);
          }
        }
      }
    } catch (error) {
      lastError = error;
      status = SyncStatus.error;
    } finally {
      _running = false;
      if (lastError == null) status = SyncStatus.idle;
    }
  }
}
