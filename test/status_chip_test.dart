import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/app/ui/components/status_chip.dart';

void main() {
  testWidgets('StatusChip renders icon and Arabic label for every status', (tester) async {
    for (final status in AppStatus.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: StatusChip(status: status))),
        ),
      );

      expect(find.byIcon(status.icon), findsOneWidget);
      expect(find.text(status.arabicLabel), findsOneWidget);
    }
  });
}
