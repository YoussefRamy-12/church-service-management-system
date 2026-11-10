import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_priority.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_status.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/activity_type.dart';

void main() {
  group('CaseStatus enum and role transitions', () {
    test('fromString parses all statuses correctly with fallback', () {
      expect(CaseStatus.fromString('open'), CaseStatus.open);
      expect(CaseStatus.fromString('assigned'), CaseStatus.assigned);
      expect(CaseStatus.fromString('in_progress'), CaseStatus.inProgress);
      expect(CaseStatus.fromString('waiting'), CaseStatus.waiting);
      expect(CaseStatus.fromString('resolved'), CaseStatus.resolved);
      expect(CaseStatus.fromString('closed'), CaseStatus.closed);
      expect(CaseStatus.fromString('unknown_status'), CaseStatus.open);
      expect(CaseStatus.fromString(null), CaseStatus.open);
    });

    test('isActive returns true only for non-resolved and non-closed cases', () {
      expect(CaseStatus.open.isActive, isTrue);
      expect(CaseStatus.assigned.isActive, isTrue);
      expect(CaseStatus.inProgress.isActive, isTrue);
      expect(CaseStatus.waiting.isActive, isTrue);
      expect(CaseStatus.resolved.isActive, isFalse);
      expect(CaseStatus.closed.isActive, isFalse);
    });

    test('Class servant cannot resolve, close, or reopen cases', () {
      const servantRole = 'class_servant';

      // Open case: servant can advance to in_progress or waiting, but not resolved/closed
      final fromOpen = CaseStatus.open.allowedTransitions(role: servantRole);
      expect(fromOpen, contains(CaseStatus.inProgress));
      expect(fromOpen, contains(CaseStatus.waiting));
      expect(fromOpen, isNot(contains(CaseStatus.resolved)));
      expect(fromOpen, isNot(contains(CaseStatus.closed)));

      // Resolved case: servant cannot reopen or close
      final fromResolved = CaseStatus.resolved.allowedTransitions(role: servantRole);
      expect(fromResolved, isEmpty);

      // Closed case: servant cannot reopen
      final fromClosed = CaseStatus.closed.allowedTransitions(role: servantRole);
      expect(fromClosed, isEmpty);
    });

    test('Class leader, Stage leader, and Overall roles can resolve and reopen cases', () {
      final leaderRoles = ['class_leader', 'stage_leader', 'overall_leader', 'overall_helper', 'system_admin'];

      for (final role in leaderRoles) {
        final fromOpen = CaseStatus.open.allowedTransitions(role: role);
        expect(fromOpen, contains(CaseStatus.resolved), reason: '$role should be able to resolve');
        expect(fromOpen, contains(CaseStatus.closed), reason: '$role should be able to close');

        final fromResolved = CaseStatus.resolved.allowedTransitions(role: role);
        expect(fromResolved, contains(CaseStatus.open), reason: '$role should be able to reopen resolved case');
        expect(fromResolved, contains(CaseStatus.closed), reason: '$role should be able to close resolved case');

        final fromClosed = CaseStatus.closed.allowedTransitions(role: role);
        expect(fromClosed, contains(CaseStatus.open), reason: '$role should be able to reopen closed case');
      }
    });
  });

  group('CasePriority and ActivityType parsing', () {
    test('CasePriority parses properly', () {
      expect(CasePriority.fromString('low'), CasePriority.low);
      expect(CasePriority.fromString('medium'), CasePriority.medium);
      expect(CasePriority.fromString('high'), CasePriority.high);
      expect(CasePriority.fromString('urgent'), CasePriority.urgent);
      expect(CasePriority.fromString('other'), CasePriority.medium);
    });

    test('ActivityType parses properly with Arabic labels', () {
      expect(ActivityType.fromString('call').arabicLabel, 'اتصال هاتفي');
      expect(ActivityType.fromString('visit').arabicLabel, 'افتِقاد منزلي');
      expect(ActivityType.fromString('status_change').arabicLabel, 'تغيير حالة المتابعة');
      expect(ActivityType.fromString('assignment_change').arabicLabel, 'تحديث الخدام المكلفين');
    });
  });
}

