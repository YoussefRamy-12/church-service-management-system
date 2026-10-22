import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import '../../../app/ui/app_ui.dart';

class ServantSignUpPage extends ConsumerStatefulWidget {
  const ServantSignUpPage({super.key});

  @override
  ConsumerState<ServantSignUpPage> createState() => _ServantSignUpPageState();
}

class _ServantSignUpPageState extends ConsumerState<ServantSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _workStudy = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _workStudy.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'اختر تاريخ الميلاد',
      locale: const Locale('ar'),
    );
    if (selectedDate != null && mounted) {
      setState(() => _birthDate = selectedDate);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signUpServant(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            birthDate: _birthDate!,
            workStudy: _workStudy.text,
            password: _password.text,
          );
      if (!mounted) return;
      ref.invalidate(currentAuthUserProvider);
      ref.invalidate(currentSessionIdentityProvider);
      ref.invalidate(currentServantProfileProvider);
      if (ref.read(authRepositoryProvider).currentUser?.id == user.id) {
        context.go('/session');
        return;
      }
      setState(() => _submitted = true);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _error = message.contains('User already registered')
            ? 'هذا البريد مسجل بالفعل. سجّل الدخول أو استخدم بريدًا آخر.'
            : 'تعذر إنشاء الحساب. تحقق من البيانات وحاول مرة أخرى.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('servant_signup_page'),
      appBar: AppBar(title: const Text('إنشاء حساب خادم')),
      body: AmbientBackground(
        intensity: 0.9,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(28),
                hoverElevation: false,
                child: _submitted ? _success() : _form(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.volunteer_activism_rounded, size: 44),
        const SizedBox(height: 12),
        Text(
          'انضم إلى الخدمة',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'أدخل بياناتك الشخصية بنفسك. سيقتصر دور مسؤول النظام على مراجعة الطلب وربطك بالخدمة وتحديد دورك.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          key: const Key('signup_name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'الاسم بالكامل'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'أدخل الاسم بالكامل'
              : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('signup_birth_date'),
          onPressed: _loading ? null : _pickBirthDate,
          icon: const Icon(Icons.cake_outlined),
          label: Text(
            _birthDate == null
                ? 'تاريخ الميلاد *'
                : MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(_birthDate!),
          ),
        ),
        if (_birthDate == null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
            child: Text(
              'تاريخ الميلاد مطلوب',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('signup_work_study'),
          controller: _workStudy,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'العمل أو الدراسة',
            hintText: 'مثال: طالب جامعي أو مهندس',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'أدخل العمل أو الدراسة'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('signup_email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
          validator: (value) => value == null || !value.contains('@')
              ? 'أدخل بريدًا إلكترونيًا صحيحًا'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('signup_phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'رقم الهاتف'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'أدخل رقم الهاتف' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('signup_password'),
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة المرور'),
          validator: (value) => value == null || value.length < 8
              ? 'استخدم 8 أحرف على الأقل'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('signup_confirm_password'),
          controller: _confirmPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
          validator: (value) =>
              value != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('signup_submit'),
          onPressed: _loading || _birthDate == null ? null : _submit,
          child: _loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إنشاء الحساب وإرسال الطلب'),
        ),
        TextButton(
          onPressed: _loading ? null : () => context.go('/login'),
          child: const Text('لديك حساب؟ تسجيل الدخول'),
        ),
      ],
    ),
  );

  Widget _success() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.mark_email_read_outlined, size: 52),
      const SizedBox(height: 16),
      Text('تم إنشاء طلبك', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'راجع بريدك لتأكيد الحساب إذا طُلب ذلك. بعد التأكيد، ينتظر الحساب اعتماد مسؤول النظام وربطه بخدمة.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => context.go('/login'),
        child: const Text('العودة لتسجيل الدخول'),
      ),
    ],
  );
}
