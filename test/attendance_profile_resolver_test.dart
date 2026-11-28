import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/attendance/data/attendance_profile_resolver.dart';

void main() {
  group('selectAttendanceRecorderProfileId', () {
    test('preserves the original recorder when it belongs to the signed-in account',
        () {
      final selected = selectAttendanceRecorderProfileId(
        preferredProfileId: 'profile-original',
        eligibleProfiles: [
          {'id': 'profile-current'},
          {'id': 'profile-original'},
        ],
      );

      expect(selected, 'profile-original');
    });

    test('does not attribute a queued check-in to another active profile', () {
      expect(
        () => selectAttendanceRecorderProfileId(
          preferredProfileId: 'profile-from-another-account',
          eligibleProfiles: [
            {'id': 'profile-current-account'},
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('does not replay when the signed-in account has no active service profile',
        () {
      expect(
        () => selectAttendanceRecorderProfileId(
          preferredProfileId: 'profile-original',
          eligibleProfiles: const [],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
