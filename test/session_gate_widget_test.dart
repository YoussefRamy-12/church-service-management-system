import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/presentation/session_gate.dart';

void main() {
  testWidgets('session gate rejects an account without an active identity', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionIdentityProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: SessionGate()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('الحساب غير مرتبط بدور نشط في الخدمة.'), findsOneWidget);
  });
}
