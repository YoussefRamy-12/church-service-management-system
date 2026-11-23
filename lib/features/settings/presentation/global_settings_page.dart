import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/config/app_metadata.dart';
import '../../../core/utils/web_app_install.dart';
import '../../auth/domain/entities/session_identity.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/entities/app_settings.dart';
import 'settings_providers.dart';

/// Global application settings page accessible to **all** authenticated roles.
///
/// Sections:
///  1. Appearance (theme mode, font size)
///  2. User profile (read + edit name/phone)
///  3. Account security (change password, sign out)
///  4. Install app (PWA)
///  5. About
class GlobalSettingsPage extends ConsumerWidget {
  const GlobalSettingsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppContent(
        maxWidth: 780,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            // ── 1. Appearance ──────────────────────────────────
            const _SectionHeader(
              icon: Icons.palette_rounded,
              title: 'المظهر',
            ),
            const SizedBox(height: 8),
            const _AppearanceSection(),

            const SizedBox(height: 32),

            // ── 2. User Profile ───────────────────────────────
            const _SectionHeader(
              icon: Icons.person_rounded,
              title: 'الملف الشخصي',
            ),
            const SizedBox(height: 8),
            _ProfileSection(serviceId: serviceId),

            const SizedBox(height: 32),

            // ── 3. Account Security ───────────────────────────
            const _SectionHeader(
              icon: Icons.lock_rounded,
              title: 'الأمان',
            ),
            const SizedBox(height: 8),
            const _SecuritySection(),

            const SizedBox(height: 32),

            // ── 4. Install App ────────────────────────────────
            if (kIsWeb) ...[
              const _SectionHeader(
                icon: Icons.install_mobile_rounded,
                title: 'تثبيت التطبيق',
              ),
              const SizedBox(height: 8),
              const _InstallAppSection(),
              const SizedBox(height: 32),
            ],

            // ── 5. About ─────────────────────────────────────
            const _SectionHeader(
              icon: Icons.info_outline_rounded,
              title: 'عن التطبيق',
            ),
            const SizedBox(height: 8),
            const _AboutSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Section Header
// ════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  1. APPEARANCE
// ════════════════════════════════════════════════════════════════

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SolidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Theme Mode ──
          Text(
            'وضع العرض',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final mode in AppThemeMode.values)
                _ChoiceChipTile(
                  icon: mode.icon,
                  label: mode.label,
                  selected: settings.themeMode == mode,
                  onTap: () => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(mode),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 20),
          // ── Font Size ──
          Text(
            'حجم الخط',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final size in AppFontSize.values)
                _ChoiceChipTile(
                  icon: Icons.format_size_rounded,
                  label: size.label,
                  selected: settings.fontSize == size,
                  onTap: () => ref
                      .read(appSettingsProvider.notifier)
                      .setFontSize(size),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceChipTile extends StatelessWidget {
  const _ChoiceChipTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AnimatedPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.1)
              : (isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryColor
                : (isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1)),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? primaryColor
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? primaryColor
                    : (isDark ? const Color(0xFFCBD5E1) : appInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  2. USER PROFILE
// ════════════════════════════════════════════════════════════════

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.serviceId});
  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(currentSessionIdentityProvider);
    final profileAsync = ref.watch(currentServantProfileProvider);
    final authUser = ref.watch(currentAuthUserProvider);

    return identityAsync.when(
      loading: () => const SolidCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      ),
      error: (e, _) => SolidCard(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'تعذر تحميل الملف الشخصي',
          message: '$e',
        ),
      ),
      data: (identity) {
        if (identity == null) {
          return const SolidCard(
            child: EmptyState(
              icon: Icons.person_off_outlined,
              title: 'لا يوجد حساب نشط',
            ),
          );
        }

        // Super admin
        if (identity is SuperAdminIdentity) {
          return SolidCard(
            child: Column(
              children: [
                const _ProfileRow(
                  icon: Icons.badge_outlined,
                  label: 'الدور',
                  value: 'مسؤول النظام',
                ),
                if (authUser?.email != null)
                  _ProfileRow(
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني',
                    value: authUser!.email!,
                  ),
              ],
            ),
          );
        }

        // Servant
        final profile = profileAsync.hasValue ? profileAsync.value : null;
        if (profile == null) {
          return const SolidCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          );
        }

        return SolidCard(
          child: Column(
            children: [
              _ProfileRow(
                icon: Icons.person_outlined,
                label: 'الاسم',
                value: profile.name,
              ),
              if (authUser?.email != null)
                _ProfileRow(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: authUser!.email!,
                ),
              if (profile.phone != null && profile.phone!.isNotEmpty)
                _ProfileRow(
                  icon: Icons.phone_outlined,
                  label: 'الهاتف',
                  value: profile.phone!,
                ),
              _ProfileRow(
                icon: Icons.badge_outlined,
                label: 'الدور',
                value: formatRoleLabel(profile.role),
              ),
              _ProfileRow(
                icon: Icons.circle,
                label: 'حالة الحساب',
                value: _statusLabel(profile.accountStatus),
                valueColor: profile.isActive
                    ? const Color(0xFF059669)
                    : const Color(0xFFDC2626),
                iconSize: 10,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const Key('edit_profile_btn'),
                  onPressed: () => _showEditProfile(context, ref, profile),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('تعديل البيانات الشخصية'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) => switch (status) {
        'active' => 'نشط',
        'pending' => 'بانتظار التفعيل',
        'inactive' => 'غير نشط',
        _ => status,
      };

  void _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditProfileDialog(
        profile: profile,
        ref: ref,
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconSize,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: iconSize ?? 20,
            color: subtextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Dialog ──

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.ref});
  final dynamic profile;
  final WidgetRef ref;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = widget.ref.read(servantProfileRepositoryProvider);
      await repo.updatePersonalProfile(
        servantId: widget.profile.id,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
      );
      // Refresh identity / profile providers so the UI reflects the change.
      widget.ref.invalidate(currentSessionIdentityProvider);
      widget.ref.invalidate(currentServantProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات الشخصية بنجاح.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل البيانات الشخصية'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                StatusBanner(
                  icon: Icons.error_outline,
                  title: 'خطأ',
                  message: _error!,
                  tone: StatusTone.error,
                ),
              ],
              const SizedBox(height: 8),
              const StatusBanner(
                icon: Icons.info_outline,
                title: 'ملاحظة',
                message:
                    'لا يمكن تغيير الدور أو المرحلة أو الفصل من هنا. تواصل مع مسؤول الخدمة.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  3. ACCOUNT SECURITY
// ════════════════════════════════════════════════════════════════

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SolidCard(
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key_rounded),
              title: const Text(
                'تغيير كلمة المرور',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('تحديث كلمة مرور الحساب'),
              trailing: const Icon(Icons.chevron_left),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => _showChangePassword(context, ref),
            ),
          ),
          Divider(
            height: 1,
            color:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _ChangePasswordDialog(ref: ref),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              signOutAndGoToLogin(ref, context);
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

// ── Change Password Dialog ──

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final authRepo = widget.ref.read(authRepositoryProvider);
      final verified = await authRepo.verifyCurrentPassword(
        _currentCtrl.text,
      );
      if (!verified) {
        setState(() => _error = 'كلمة المرور الحالية غير صحيحة.');
        return;
      }
      await authRepo.updatePassword(_newCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر التحديث: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة المرور'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentCtrl,
                obscureText: !_showCurrent,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrent
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _showCurrent = !_showCurrent),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'مطلوب' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newCtrl,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_showNew
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _showNew = !_showNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v.length < 6) return 'يجب ألا تقل عن ٦ أحرف';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (v != _newCtrl.text) return 'كلمة المرور غير متطابقة';
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                StatusBanner(
                  icon: Icons.error_outline,
                  title: 'خطأ',
                  message: _error!,
                  tone: StatusTone.error,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Text('تحديث'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  4. INSTALL APP (PWA)
// ════════════════════════════════════════════════════════════════

class _InstallAppSection extends StatefulWidget {
  const _InstallAppSection();

  @override
  State<_InstallAppSection> createState() => _InstallAppSectionState();
}

class _InstallAppSectionState extends State<_InstallAppSection> {
  bool _installing = false;

  Future<void> _install() async {
    if (canPromptToInstall) {
      setState(() => _installing = true);
      final installed = await promptToInstall();
      if (!mounted) return;
      setState(() => _installing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            installed
                ? 'تم تثبيت التطبيق بنجاح.'
                : 'يمكنك تثبيت التطبيق لاحقًا من قائمة المتصفح.',
          ),
        ),
      );
      return;
    }
    // iOS / unsupported: show instructions
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة التطبيق إلى الهاتف'),
        content: const Text(
          'في متصفح Safari:\n'
          '1. اضغط على أيقونة المشاركة (⬆️) أسفل الشاشة.\n'
          '2. اختر "إضافة إلى الشاشة الرئيسية".\n\n'
          'في متصفحات أخرى:\n'
          'ابحث عن خيار "تثبيت التطبيق" أو "إضافة إلى الشاشة الرئيسية" في قائمة المتصفح.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInstalled = isRunningAsInstalledApp;

    return SolidCard(
      child: Column(
        children: [
          if (isInstalled)
            const StatusBanner(
              icon: Icons.check_circle_outline_rounded,
              title: 'التطبيق مُثبّت',
              message: 'التطبيق يعمل حاليًا كتطبيق مستقل.',
              tone: StatusTone.success,
            )
          else ...[
            const Text(
              'قم بتثبيت التطبيق على هاتفك لاستخدامه كتطبيق مستقل بدون شريط المتصفح.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const Key('install_app_btn'),
                onPressed: _installing ? null : _install,
                icon: _installing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.install_mobile_rounded, size: 18),
                label: const Text('تثبيت التطبيق'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  5. ABOUT
// ════════════════════════════════════════════════════════════════

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SolidCard(
      child: Column(
        children: [
          const _AboutRow(
            icon: Icons.apps_rounded,
            label: 'اسم التطبيق',
            value: AppMetadata.appName,
          ),
          const _AboutRow(
            icon: Icons.verified_outlined,
            label: 'الإصدار',
            value: AppMetadata.versionDisplay,
          ),
          const _AboutRow(
            icon: Icons.language_rounded,
            label: 'رابط الاستضافة',
            value: AppMetadata.hostingUrl,
          ),
          const _AboutRow(
            icon: Icons.description_outlined,
            label: 'الوصف',
            value: AppMetadata.description,
          ),
          const SizedBox(height: 8),
          Text(
            AppMetadata.copyright,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subtextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: subtextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
