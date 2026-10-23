// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../domain/entities/session_identity.dart';
import '../domain/entities/servant_profile.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../attendance/presentation/meeting_providers.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionIdentityProvider);
    return session.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'تعذر تحميل صلاحيات الحساب. تحقق من الاتصال ثم حاول مرة أخرى.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(currentSessionIdentityProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (identity) {
        if (identity == null) {
          return const _SessionError(
            message: 'الحساب غير مرتبط بدور نشط في الخدمة.',
          );
        }
        if (ref.read(offlineSyncEnabledProvider)) {
          ref.read(syncEngineProvider).start();
        }
        return switch (identity) {
          SuperAdminIdentity() => const _SessionHome(
            title: 'لوحة مسؤول النظام',
            subtitle: 'Super Admin',
          ),
          ServantIdentity(:final profile) => _ServiceEntry(profile: profile),
          MultiServiceServantIdentity(:final profiles) => _ServiceChooser(
            profiles: profiles,
          ),
          PendingServantIdentity(
            :final name,
            :final status,
            :final phone,
            :final birthDate,
            :final workStudy,
          ) =>
            _PendingRegistration(
              name: name,
              status: status,
              phone: phone,
              birthDate: birthDate,
              workStudy: workStudy,
            ),
        };
      },
    );
  }
}

class _ServiceEntry extends ConsumerStatefulWidget {
  const _ServiceEntry({required this.profile});
  final ServantProfile profile;

  @override
  ConsumerState<_ServiceEntry> createState() => _ServiceEntryState();
}

class _ServiceEntryState extends ConsumerState<_ServiceEntry> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshAndEnterService);
  }

  Future<void> _refreshAndEnterService() async {
    // Pull the shared meeting list before opening the service. This is a
    // best-effort online refresh; cached data remains available offline.
    try {
      await ref
          .read(meetingRepositoryProvider)
          .refresh(widget.profile.serviceId);
    } catch (_) {}
    if (mounted) {
      context.go('/service/' + widget.profile.serviceId + '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _SessionHome extends StatefulWidget {
  const _SessionHome({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  State<_SessionHome> createState() => _SessionHomeState();
}

class _ServiceChooser extends ConsumerStatefulWidget {
  const _ServiceChooser({required this.profiles});
  final List<ServantProfile> profiles;

  @override
  ConsumerState<_ServiceChooser> createState() => _ServiceChooserState();
}

class _ServiceChooserState extends ConsumerState<_ServiceChooser> {
  late Future<Map<String, String>> _serviceNames;

  @override
  void initState() {
    super.initState();
    _serviceNames = _loadServiceNames();
  }

  Future<Map<String, String>> _loadServiceNames() async {
    final ids = widget.profiles
        .map((profile) => profile.serviceId)
        .toSet()
        .toList();
    final rows = await ref
        .read(supabaseClientProvider)
        .from('services')
        .select('id, name')
        .inFilter('id', ids);
    return {for (final row in rows) row['id'] as String: row['name'] as String};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('اختر الخدمة'),
      actions: [
        IconButton(
          tooltip: 'تسجيل الخروج',
          onPressed: () async {
            await signOutAndGoToLogin(ref, context);
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: AmbientBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(
                'حسابك مرتبط بأكثر من خدمة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('اختر الخدمة التي تريد فتحها الآن.'),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, String>>(
                future: _serviceNames,
                builder: (context, snapshot) => Column(
                  children: [
                    for (final profile in widget.profiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4338CA),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.church_rounded,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              snapshot.data?[profile.serviceId] ?? 'الخدمة',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${profile.name} • ${_roleLabel(profile.role)}',
                            ),
                            trailing: const Icon(Icons.chevron_left_rounded),
                            onTap: () async {
                              ref
                                      .read(
                                        selectedServantProfileProvider.notifier,
                                      )
                                      .state =
                                  profile;
                              try {
                                await ref
                                    .read(meetingRepositoryProvider)
                                    .refresh(profile.serviceId);
                              } catch (_) {}
                              if (!context.mounted) return;
                              context.go(
                                '/service/${profile.serviceId}/dashboard',
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _roleLabel(String role) => formatRoleLabel(role);
  /*
        'overall_leader' => 'أمين الخدمة',
        'overall_helper' => 'أمين مساعد',
        'stage_leader' => 'أمين المرحلة',
        'class_leader' => 'أمين الفصل',
        'class_servant' => 'خادم الفصل',
        _ => role,
      };*/
}

class _PendingRegistration extends ConsumerStatefulWidget {
  const _PendingRegistration({
    required this.name,
    required this.status,
    required this.phone,
    required this.birthDate,
    required this.workStudy,
  });
  final String name;
  final String status;
  final String? phone;
  final DateTime? birthDate;
  final String? workStudy;

  @override
  ConsumerState<_PendingRegistration> createState() =>
      _PendingRegistrationState();
}

class _PendingRegistrationState extends ConsumerState<_PendingRegistration> {
  late final TextEditingController _workStudy;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.name == 'خادم جديد' ? '' : widget.name,
    );
    _phone = TextEditingController(text: widget.phone ?? '');
    _workStudy = TextEditingController(text: widget.workStudy ?? '');
    _birthDate = widget.birthDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _workStudy.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      locale: const Locale('ar'),
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  Future<void> _saveProfileDetails() async {
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _birthDate == null ||
        _workStudy.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .rpc(
            'complete_servant_registration_profile',
            params: {
              'p_full_name': _name.text.trim(),
              'p_phone': _phone.text.trim(),
              'p_birth_date': _formatDate(_birthDate!),
              'p_work_study': _workStudy.text.trim(),
            },
          );
      ref.invalidate(currentSessionIdentityProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حفظ البيانات: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool get _needsProfile =>
      widget.status == 'pending' &&
      (widget.name == 'خادم جديد' ||
          widget.phone == null ||
          widget.phone!.trim().isEmpty ||
          widget.birthDate == null ||
          (widget.workStudy ?? '').trim().isEmpty);

  bool get _profileComplete =>
      widget.status == 'pending' &&
      widget.name != 'خادم جديد' &&
      (widget.phone ?? '').trim().isNotEmpty &&
      widget.birthDate != null &&
      (widget.workStudy ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AmbientBackground(
      intensity: 0.8,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: GlassCard(
              borderRadius: 28,
              padding: const EdgeInsets.all(32),
              hoverElevation: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.status == 'rejected'
                            ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                            : [
                                const Color(0xFFF59E0B),
                                const Color(0xFFFBBF24),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (widget.status == 'rejected'
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.status == 'rejected'
                          ? Icons.cancel_rounded
                          : Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'أهلًا ${widget.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Status badge
                  GlassBadge(
                    label: widget.status == 'rejected'
                        ? 'مرفوض'
                        : 'في انتظار المراجعة',
                    color: widget.status == 'rejected'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.status == 'rejected'
                        ? 'لم تتم الموافقة على طلب التسجيل. تواصل مع مسؤول النظام لمزيد من المعلومات.'
                        : 'تم تسجيل حسابك. ينتظر طلبك مراجعة مسؤول النظام وربطك بالخدمة المناسبة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  if (_needsProfile) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'أكمل بيانات ملفك الشخصي',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'هذه البيانات تساعد مسؤول النظام في تحديد هويتك.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالكامل',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _workStudy,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'العمل أو الدراسة',
                        hintText: 'مثال: طالب جامعي أو مهندس',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickBirthDate,
                        icon: const Icon(Icons.cake_outlined),
                        label: Text(
                          _birthDate == null
                              ? 'تاريخ الميلاد'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_birthDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _saving ||
                                _name.text.trim().isEmpty ||
                                _phone.text.trim().isEmpty ||
                                _birthDate == null ||
                                _workStudy.text.trim().isEmpty
                            ? null
                            : _saveProfileDetails,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('حفظ البيانات'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_profileComplete)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              ref.invalidate(currentSessionIdentityProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('تحديث حالة الطلب'),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        await signOutAndGoToLogin(ref, context);
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('تسجيل الخروج'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SessionHomeState extends State<_SessionHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/admin');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: const Center(child: CircularProgressIndicator()),
  );
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AmbientBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(32),
            hoverElevation: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 32,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
