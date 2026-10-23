import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/network/supabase_client_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'أدخل بريدًا إلكترونيًا صحيحًا.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إرسال الرابط الآن. تحقق من البريد وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('استعادة كلمة المرور')),
    body: AmbientBackground(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: GlassCard(padding: const EdgeInsets.all(28), child: _sent
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.mark_email_read_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('إذا كان البريد مسجلًا، ستصلك رسالة برابط لإعادة تعيين كلمة المرور. افتح الرابط من نفس المتصفح وأكمل الخطوات خلال فترة صلاحيته.'),
            const SizedBox(height: 16),
            TextButton(onPressed: () => context.go('/login'), child: const Text('العودة لتسجيل الدخول')),
          ])
        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('أدخل البريد المرتبط بحسابك وسنرسل رابطًا آمنًا لإعادة تعيين كلمة المرور.'),
            const SizedBox(height: 18),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 18),
            FilledButton(onPressed: _loading ? null : _send, child: _loading ? const CircularProgressIndicator() : const Text('إرسال رابط الاستعادة')),
          ])),
    ))),
  );
}

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_password.text.length < 8) { setState(() => _error = 'استخدم 8 أحرف على الأقل.'); return; }
    if (_password.text != _confirm.text) { setState(() => _error = 'كلمتا المرور غير متطابقتين.'); return; }
    if (ref.read(supabaseClientProvider).auth.currentSession == null) {
      setState(() => _error = 'الرابط غير صالح أو انتهت صلاحيته. اطلب رابط استعادة جديدًا.'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      await ref.read(supabaseClientProvider).auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور. سجّل الدخول بكلمتك الجديدة.')),
        );
        context.go('/login');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تغيير كلمة المرور. قد يكون الرابط منتهي الصلاحية؛ اطلب رابطًا جديدًا.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إنشاء كلمة مرور جديدة')),
    body: AmbientBackground(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: GlassCard(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('اختر كلمة مرور جديدة لحسابك.'),
        const SizedBox(height: 16),
        TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
        const SizedBox(height: 12),
        TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور')),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 18),
        FilledButton(onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator() : const Text('حفظ كلمة المرور')),
      ])),
    ))),
  );
}

class AuthCallbackPage extends ConsumerWidget {
  const AuthCallbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authUserProvider);
    final signedIn = ref.watch(supabaseClientProvider).auth.currentSession != null;
    return Scaffold(appBar: AppBar(title: const Text('تأكيد البريد الإلكتروني')), body: Center(child: Padding(
      padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(signedIn ? Icons.mark_email_read_outlined : Icons.info_outline, size: 52),
        const SizedBox(height: 16),
        Text(signedIn ? 'تم تأكيد بريدك الإلكتروني. يمكنك المتابعة لتسجيل الدخول.' : 'إذا أكدت بريدك الإلكتروني، يمكنك الآن تسجيل الدخول. إن لم يعمل الرابط، اطلب رسالة تأكيد جديدة.'),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.go(signedIn ? '/session' : '/login'), child: Text(signedIn ? 'متابعة' : 'تسجيل الدخول')),
      ]),
    )));
  }
}
