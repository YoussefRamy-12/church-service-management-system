@Tags(['golden'])
library;

import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/presentation/password_recovery_pages.dart';
import 'package:church_service_management_system/features/auth/presentation/servant_sign_up_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(ensureGoldenTestSetup);

  final screens = <({String name, WidgetBuilder builder})>[
    (
      name: 'servant_sign_up',
      builder: (_) => const ServantSignUpPage(),
    ),
    (
      name: 'forgot_password',
      builder: (_) => const ForgotPasswordPage(),
    ),
    (
      name: 'reset_password',
      builder: (_) => const ResetPasswordPage(),
    ),
  ];

  for (final screen in screens) {
    for (final variant in standardGoldenVariants) {
      testWidgets('${screen.name} — ${variant.suffix}', (tester) async {
        await pumpGoldenWidget(
          tester,
          home: switch (screen.name) {\n            'servant_sign_up' => const ServantSignUpPage(),\n            'forgot_password' => const ForgotPasswordPage(),\n            _ => const ResetPasswordPage(),\n          },
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
