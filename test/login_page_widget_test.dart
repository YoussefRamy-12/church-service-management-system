import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:church_service_management_system/core/network/supabase_client_provider.dart';
import 'package:church_service_management_system/features/auth/presentation/login_page.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key');
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(client)],
      child: const MaterialApp(locale: Locale('ar'), home: LoginPage()),
    );
  }

  testWidgets('login page renders the required authentication controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('أسرة تلاميذ المسيح'), findsOneWidget);
    expect(find.text('خدمة 5 و6 ابتدائي بنين'), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets(
    'empty login submission shows validation errors without network access',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.ensureVisible(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();

      expect(find.text('أدخل البريد الإلكتروني'), findsOneWidget);
      expect(find.text('أدخل كلمة المرور'), findsOneWidget);
      expect(find.text('Invalid login credentials'), findsNothing);
    },
  );

  testWidgets(
    'email validation accepts non-empty input and only flags missing password',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byKey(const Key('login_email')), 'servant@example.com');
      await tester.ensureVisible(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();

      expect(find.text('أدخل البريد الإلكتروني'), findsNothing);
      expect(find.text('أدخل كلمة المرور'), findsOneWidget);
    },
  );
}
