import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/servants/presentation/servant_role_filter.dart';

void main() {
  testWidgets('servant role filter reports the selected role', (tester) async {
    var selectedRole = 'all';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ServantRoleFilter(
              selectedRole: selectedRole,
              onChanged: (value) => setState(() => selectedRole = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('أمين المرحلة'));
    await tester.pumpAndSettle();

    expect(selectedRole, 'stage_leader');
    expect(find.text('أمين المرحلة'), findsOneWidget);
  });
}
