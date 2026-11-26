import 'package:flutter/material.dart';

import '../domain/weekly_prep_permissions.dart';
import '../../auth/domain/entities/servant_profile.dart';

class WeeklyPrepViewSwitcher extends StatelessWidget {
  const WeeklyPrepViewSwitcher({
    super.key,
    required this.profile,
    required this.isSuperAdmin,
    required this.isServantView,
    required this.onChanged,
  });

  final ServantProfile profile;
  final bool isSuperAdmin;
  final bool isServantView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!WeeklyPrepPermissions.canViewLeadershipDashboard(
      profile: profile,
      isSuperAdmin: isSuperAdmin,
    )) {
      return const SizedBox.shrink();
    }
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('تحضيري')),
        ButtonSegment(value: false, label: Text('متابعة الخدام')),
      ],
      selected: {isServantView},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}
