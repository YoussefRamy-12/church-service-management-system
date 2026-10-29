import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_providers.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _emailConfirmationRequired = false;
  bool _resendingConfirmation = false;
  bool _rememberMe = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final email = preferences.getString('remembered_login_email');
      if (!mounted || email == null) return;
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _emailConfirmationRequired = false;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

      try {
        final preferences = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await preferences.setString('remembered_login_email', _emailController.text.trim());
        } else {
          await preferences.remove('remembered_login_email');
        }
      } catch (_) {}

      ref.invalidate(currentServantProfileProvider);
      ref.invalidate(currentSessionIdentityProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل الدخول بنجاح.')));

      // The session gate resolves the authenticated user's role/profile
      // before rendering the appropriate authenticated area.
      context.go('/session');
    } catch (error) {
      if (!mounted) return;
      final confirmationRequired = _isEmailNotConfirmed(error);
      setState(() {
        _error = _friendlyError(error);
        _emailConfirmationRequired = confirmationRequired;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEmailNotConfirmed(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('email not confirmed') ||
        message.contains('email_not_confirmed');
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _resendingConfirmation = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .auth
          .resend(type: OtpType.signup, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أُعيد إرسال رابط تأكيد البريد. افحص صندوق الوارد والرسائل غير المرغوب فيها.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إعادة إرسال رسالة التأكيد: ${_friendlyError(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _resendingConfirmation = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (message.toLowerCase().contains('email not confirmed') ||
        message.toLowerCase().contains('email_not_confirmed')) {
      return 'أكد بريدك الإلكتروني من رسالة التفعيل التي أُرسلت عند التسجيل، ثم حاول تسجيل الدخول مرة أخرى.';
    }
    if (message.toLowerCase().contains('too many requests') ||
        message.toLowerCase().contains('rate limit')) {
      return 'محاولات كثيرة خلال وقت قصير. انتظر قليلًا ثم حاول مرة أخرى.';
    }
    if (message.contains('Supabase is not configured')) {
      return 'إعدادات الاتصال بالنظام غير مكتملة.';
    }
    return 'حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF131D33).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.85);
    final cardBorder = isDark
        ? const Color(0x33818CF8)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      key: const Key('login_page'),
      body: AmbientBackground(
        intensity: 1.2,
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                key: const Key('login_theme_toggle'),
                tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF4F46E5),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: cardBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: isDark ? 0.15 : 0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4338CA),
                                        Color(0xFF6366F1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4F46E5,
                                        ).withValues(alpha: 0.38),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.church_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'أسرة تلاميذ المسيح',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'خدمة 5 و6 ابتدائي بنين',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'كنيسة السيدة العذراء بعياد بك',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                key: const Key('login_email'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) {
                                  if (_emailConfirmationRequired) {
                                    setState(
                                      () => _emailConfirmationRequired = false,
                                    );
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'أدخل البريد الإلكتروني'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('login_password'),
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                                    onPressed: () => setState(() => _showPassword = !_showPassword),
                                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'أدخل كلمة المرور'
                                    : null,
                              ),
                              CheckboxListTile(
                                key: const Key('login_remember_me'),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('تذكرني'),
                                value: _rememberMe,
                                onChanged: _loading ? null : (value) => setState(() => _rememberMe = value ?? false),
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  key: const Key('forgot_password'),
                                  onPressed: _loading
                                      ? null
                                      : () => context.go('/forgot-password'),
                                  child: const Text('نسيت كلمة المرور؟'),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 20,
                                        color: Color(0xFFDC2626),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_emailConfirmationRequired) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  key: const Key('resend_signup_confirmation'),
                                  onPressed: _resendingConfirmation
                                      ? null
                                      : _resendConfirmation,
                                  icon: _resendingConfirmation
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.mark_email_unread_outlined,
                                        ),
                                  label: const Text('إعادة إرسال رابط التأكيد'),
                                ),
                              ],
                              const SizedBox(height: 28),
                              FilledButton(
                                key: const Key('login_submit'),
                                onPressed: _loading ? null : _login,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'تسجيل الدخول',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 14),
                              TextButton(
                                key: const Key('login_signup'),
                                onPressed: _loading
                                    ? null
                                    : () => context.go('/signup'),
                                child: const Text(
                                  'خادم جديد؟ أنشئ حسابًا واطلب الانضمام',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
