@Tags(['golden'])
library;

import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/presentation/password_recovery_pages.dart';
import 'package:church_service_management_system/features/auth/presentation/servant_sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(ensureGoldenTestSetup);

  final screens = <({String name, Widget widget})>[
    (name: 'servant_sign_up', widget: const ServantSignUpPage()),
    (name: 'forgot_password', widget: const ForgotPasswordPage()),
    (name: 'reset_password', widget: const ResetPasswordPage()),
  ];

  for (final screen in screens) {
    for (final variant in standardGoldenVariants) {
      testWidgets('${screen.name} — ${variant.suffix}', (tester) async {
        await pumpGoldenWidget(
          tester,
          home: screen.widget,
          variant: variant,
          overrides: [
            authRepositoryProvider.overrideWithValue(GoldenFakeAuthRepository()),
          ],
        );
        await expectGoldenImage(
          tester,
          '${screen.name}_${variant.suffix}.png',
        );
      });
    }
  }
}
