import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:church_service_management_system/core/network/supabase_client_provider.dart';
import 'package:church_service_management_system/features/auth/presentation/login_page.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_service_management_system/features/auth/domain/repositories/auth_repository.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://example.supabase.co', 'test-key');
  });

  Widget buildSubject({AuthRepository? authRepository}) {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
      ],
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
  testWidgets('login error is shown inline and entered values are retained', (
    tester,
  ) async {
    final fake = _FakeAuthRepository(
      signInAction: () async => throw Exception('Invalid login credentials'),
    );
    await tester.pumpWidget(buildSubject(authRepository: fake));
    await tester.enterText(find.byKey(const Key('login_email')), 'servant@example.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'wrong-pass');
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة.'), findsOneWidget);
    expect(find.text('servant@example.com'), findsOneWidget);
    expect(find.text('wrong-pass'), findsNothing);
    expect(tester.widget<TextFormField>(find.byKey(const Key('login_password'))).controller!.text, 'wrong-pass');
  });

  testWidgets('login loading state retains the button and prevents duplicate submits', (
    tester,
  ) async {
    final completer = Completer<AuthUser>();
    final fake = _FakeAuthRepository(signInAction: () => completer.future);
    await tester.pumpWidget(buildSubject(authRepository: fake));
    await tester.enterText(find.byKey(const Key('login_email')), 'servant@example.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'password-123');
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('جارٍ تسجيل الدخول...'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('login_submit'))).onPressed, isNull);

    completer.completeError(Exception('Invalid login credentials'));
    await tester.pumpAndSettle();
    expect(find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة.'), findsOneWidget);
  });

}


class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.signInAction});

  final Future<AuthUser> Function() signInAction;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream<AuthUser?>.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      signInAction();

  @override
  Future<AuthUser> signUpServant({
    required String name,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<bool> verifyCurrentPassword(String currentPassword) async => true;

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> signOut() async {}
}
