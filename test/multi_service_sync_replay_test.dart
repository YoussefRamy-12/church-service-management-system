import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';

class _Membership {
  const _Membership({
    required this.id,
    required this.studentId,
    required this.serviceId,
    this.status = 'active',
  });

  final String id;
  final String studentId;
  final String serviceId;
  final String status;
}

class _Profile {
  const _Profile({required this.authUserId, required this.serviceId});

  final String authUserId;
  final String serviceId;
}

/// Deterministic remote-contract double. It models the service/membership and
/// actor checks enforced by the Supabase sync handlers and RLS policies.
class _MembershipAwareTransport implements SyncTransport {
  final Map<String, _Membership> memberships = {};
  final Map<String, String> meetingServices = {};
  final Map<String, _Profile> profiles = {};
  final List<Map<String, dynamic>> attendanceWrites = [];
  final List<Map<String, dynamic>> followUpWrites = [];

  String? signedInUserId;

  _Membership? _resolveMembership({
    required String studentId,
    required String serviceId,
    String? membershipId,
  }) {
    if (membershipId != null && membershipId.isNotEmpty) {
      final membership = memberships[membershipId];
      if (membership == null ||
          membership.studentId != studentId ||
          membership.serviceId != serviceId) {
        return null;
      }
      return membership;
    }

    final matches = memberships.values
        .where((item) =>
            item.studentId == studentId && item.serviceId == serviceId)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation.entityType) {
      case 'attendance':
        final meetingId = payload['meeting_id'] as String;
        final meetingServiceId = meetingServices[meetingId];
        if (meetingServiceId == null) {
          throw StateError('Meeting is not available.');
        }
        final serviceId =
            payload['service_id'] as String? ?? meetingServiceId;
        if (serviceId != meetingServiceId) {
          throw const SyncConflictException('Meeting/service mismatch.');
        }
        final membership = _resolveMembership(
          studentId: payload['student_id'] as String,
          serviceId: serviceId,
          membershipId: payload['service_student_id'] as String?,
        );
        if (membership == null) {
          throw const SyncConflictException('Membership scope mismatch.');
        }
        // Inactive memberships are valid for historical attendance replay.
        attendanceWrites.add({
          ...payload,
          'service_id': serviceId,
          'service_student_id': membership.id,
        });
        return;

      case 'follow_up':
        final profileId = payload['created_by'] as String;
        final profile = profiles[profileId];
        if (profile == null || profile.authUserId != signedInUserId) {
          throw StateError('Queued operation belongs to another account.');
        }
        final serviceId =
            payload['service_id'] as String? ?? profile.serviceId;
        if (serviceId != profile.serviceId) {
          throw const SyncConflictException('Creator/service mismatch.');
        }
        final membership = _resolveMembership(
          studentId: payload['student_id'] as String,
          serviceId: serviceId,
          membershipId: payload['service_student_id'] as String?,
        );
        if (membership == null) {
          throw const SyncConflictException('Membership scope mismatch.');
        }
        followUpWrites.add({
          ...payload,
          'service_id': serviceId,
          'service_student_id': membership.id,
        });
        return;

      default:
        throw UnsupportedError('Unexpected test entity: ${operation.entityType}');
    }
  }
}

SyncOperation _operation(
  String id,
  String entityType,
  Map<String, dynamic> payload,
) {
  return SyncOperation(
    operationId: id,
    entityType: entityType,
    operationType: 'upsert',
    payloadJson: jsonEncode(payload),
  );
}

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late _MembershipAwareTransport remote;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    remote = _MembershipAwareTransport()
      ..signedInUserId = 'user-a'
      ..memberships.addAll({
        'membership-a': const _Membership(
          id: 'membership-a',
          studentId: 'shared-student',
          serviceId: 'service-a',
        ),
        'membership-b': const _Membership(
          id: 'membership-b',
          studentId: 'shared-student',
          serviceId: 'service-b',
        ),
      })
      ..meetingServices.addAll({
        'meeting-a': 'service-a',
        'meeting-b': 'service-b',
      })
      ..profiles.addAll({
        'profile-a': const _Profile(
          authUserId: 'user-a',
          serviceId: 'service-a',
        ),
        'profile-b': const _Profile(
          authUserId: 'user-a',
          serviceId: 'service-b',
        ),
      });
  });

  tearDown(() async => db.close());

  SyncEngine engine() => SyncEngine(
        queue: queue,
        transport: remote,
        connectivityChecker: () async => [ConnectivityResult.wifi],
      );

  test('replays shared identity operations against each original service membership',
      () async {
    await queue.enqueue(_operation('attendance-a', 'attendance', {
      'id': 'attendance-a',
      'meeting_id': 'meeting-a',
      'student_id': 'shared-student',
      'service_id': 'service-a',
      'service_student_id': 'membership-a',
    }));
    await queue.enqueue(_operation('attendance-b', 'attendance', {
      'id': 'attendance-b',
      'meeting_id': 'meeting-b',
      'student_id': 'shared-student',
      'service_id': 'service-b',
      'service_student_id': 'membership-b',
    }));
    await queue.enqueue(_operation('follow-up-a', 'follow_up', {
      'id': 'follow-up-a',
      'student_id': 'shared-student',
      'service_id': 'service-a',
      'service_student_id': 'membership-a',
      'created_by': 'profile-a',
    }));
    await queue.enqueue(_operation('follow-up-b', 'follow_up', {
      'id': 'follow-up-b',
      'student_id': 'shared-student',
      'service_id': 'service-b',
      'service_student_id': 'membership-b',
      'created_by': 'profile-b',
    }));

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), isEmpty);
    expect(await queue.countByStatus('conflict'), 0);
    expect(remote.attendanceWrites.map((row) => row['service_student_id']),
        ['membership-a', 'membership-b']);
    expect(remote.followUpWrites.map((row) => row['service_student_id']),
        ['membership-a', 'membership-b']);
    sync.dispose();
  });

  test('legacy queue payloads resolve membership only within their service',
      () async {
    await queue.enqueue(_operation('legacy-attendance', 'attendance', {
      'id': 'legacy-attendance',
      'meeting_id': 'meeting-a',
      'student_id': 'shared-student',
      'service_id': 'service-a',
    }));
    await queue.enqueue(_operation('legacy-follow-up', 'follow_up', {
      'id': 'legacy-follow-up',
      'student_id': 'shared-student',
      'service_id': 'service-b',
      'created_by': 'profile-b',
    }));

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), isEmpty);
    expect(await queue.countByStatus('conflict'), 0);
    expect(remote.attendanceWrites.single['service_student_id'], 'membership-a');
    expect(remote.followUpWrites.single['service_student_id'], 'membership-b');
    sync.dispose();
  });

  test('account mismatch defers follow-up and owner can replay it later',
      () async {
    remote.signedInUserId = 'user-b';
    await queue.enqueue(_operation('follow-up-owner-a', 'follow_up', {
      'id': 'follow-up-owner-a',
      'student_id': 'shared-student',
      'service_id': 'service-a',
      'service_student_id': 'membership-a',
      'created_by': 'profile-a',
    }));

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), hasLength(1));
    expect(await queue.countByStatus('conflict'), 0);
    final deferred = await (db.select(db.syncQueueEntries)
          ..where((row) => row.operationId.equals('follow-up-owner-a')))
        .getSingle();
    expect(deferred.attempts, 1);

    remote.signedInUserId = 'user-a';
    await sync.syncNow();

    expect(await queue.pending(), isEmpty);
    expect(remote.followUpWrites, hasLength(1));
    sync.dispose();
  });

  test('inactive membership still accepts historical attendance replay',
      () async {
    remote.memberships['membership-a'] = const _Membership(
      id: 'membership-a',
      studentId: 'shared-student',
      serviceId: 'service-a',
      status: 'inactive',
    );
    await queue.enqueue(_operation('historical-attendance', 'attendance', {
      'id': 'historical-attendance',
      'meeting_id': 'meeting-a',
      'student_id': 'shared-student',
      'service_id': 'service-a',
      'service_student_id': 'membership-a',
    }));

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), isEmpty);
    expect(await queue.countByStatus('conflict'), 0);
    expect(remote.attendanceWrites.single['service_student_id'], 'membership-a');
    sync.dispose();
  });

  test('foreign membership ID becomes a conflict and never writes across services',
      () async {
    await queue.enqueue(_operation('cross-service-attack', 'attendance', {
      'id': 'cross-service-attack',
      'meeting_id': 'meeting-a',
      'student_id': 'shared-student',
      'service_id': 'service-a',
      'service_student_id': 'membership-b',
    }));

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), isEmpty);
    expect(await queue.countByStatus('conflict'), 1);
    expect(remote.attendanceWrites, isEmpty);
    sync.dispose();
  });
}
