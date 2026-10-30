import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';
import '../../../core/network/supabase_client_provider.dart';
import 'servant_providers.dart';
import 'servant_details_page.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/ui/phone_contact_actions.dart';

class ServantManagementPage extends ConsumerStatefulWidget {
  const ServantManagementPage({
    super.key,
    required this.serviceId,
    this.openAddOnLoad = false,
  });

  final String serviceId;
  final bool openAddOnLoad;

  @override
  ConsumerState<ServantManagementPage> createState() =>
      _ServantManagementPageState();
}

class _ServantManagementPageState extends ConsumerState<ServantManagementPage> {
  String search = '';
  String statusFilter = 'all';
  List<Stage> stages = [];
  List<ServiceClass> classes = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadHierarchy();
      if (widget.openAddOnLoad && mounted) _addServant();
    });
  }

  Future<void> _loadHierarchy() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final stageRows = await client
          .from('stages')
          .select('id,service_id,name')
          .eq('service_id', widget.serviceId)
          .order('name');
      final loadedStages = (stageRows as List)
          .map((row) => Stage(
                id: row['id'] as String,
                serviceId: row['service_id'] as String,
                name: row['name'] as String,
              ))
          .toList();
      final classRows = loadedStages.isEmpty
          ? <dynamic>[]
          : await client
              .from('classes')
              .select('id,stage_id,name')
              .inFilter('stage_id', loadedStages.map((stage) => stage.id).toList())
              .order('name');
      final loadedClasses = (classRows as List)
          .map((row) => ServiceClass(
                id: row['id'] as String,
                stageId: row['stage_id'] as String,
                name: row['name'] as String,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        stages = loadedStages;
        classes = loadedClasses;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل المراحل والفصول: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(servantRepositoryProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الخدام'),
        actions: [
          if (isSuperAdmin)
            IconButton(
              key: const Key('servants_add'),
              tooltip: 'إضافة خادم',
              onPressed: _addServant,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () async {
              await repository.refresh(widget.serviceId);
              await _loadHierarchy();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.5,
        child: StreamBuilder<List<ServantProfile>>(
          stream: repository.watchForService(widget.serviceId),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <ServantProfile>[];
            final filtered = all.where((servant) {
              final matchesSearch =
                  search.trim().isEmpty ||
                  servant.name.contains(search.trim()) ||
                  (servant.phone ?? '').contains(search.trim());
              final matchesStatus =
                  statusFilter == 'all' ||
                  servant.accountStatus == statusFilter;
              return matchesSearch && matchesStatus;
            }).toList();

            final activeCount = all
                .where((s) => s.accountStatus == 'active')
                .length;
            final pendingCount = all
                .where((s) => s.accountStatus == 'pending')
                .length;

            return AppContent(
              maxWidth: 900,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Metrics Ribbon
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4F46E5,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.people_outline_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إجمالي الخدام',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${all.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نشط',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '$activeCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'معلق',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search & Filter Card
                  GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(14),
                    hoverElevation: false,
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'بحث بالاسم أو الهاتف',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => search = ''),
                                  )
                                : null,
                          ),
                          onChanged: (value) => setState(() => search = value),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('الكل')),
                            ButtonSegment(value: 'active', label: Text('نشط')),
                            ButtonSegment(
                              value: 'pending',
                              label: Text('معلق'),
                            ),
                            ButtonSegment(
                              value: 'inactive',
                              label: Text('غير نشط'),
                            ),
                          ],
                          selected: {statusFilter},
                          onSelectionChanged: (value) =>
                              setState(() => statusFilter = value.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد بيانات مطابقة للبحث أو التصفية.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final servant in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ServantDetailsPage(servant: servant),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Initial Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: servant.accountStatus == 'active'
                                      ? [
                                          const Color(0xFF4F46E5),
                                          const Color(0xFF7C3AED),
                                        ]
                                      : servant.accountStatus == 'pending'
                                      ? [
                                          const Color(0xFFF59E0B),
                                          const Color(0xFFF97316),
                                        ]
                                      : [
                                          const Color(0xFF64748B),
                                          const Color(0xFF94A3B8),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  servant.name.isEmpty
                                      ? '?'
                                      : servant.name.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Servant Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    servant.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      GlassBadge(
                                        label: _roleLabel(servant.role),
                                        color: const Color(0xFF4F46E5),
                                        showDot: false,
                                      ),
                                      const SizedBox(width: 6),
                                      GlassBadge(
                                        label: _statusLabel(
                                          servant.accountStatus,
                                        ),
                                        color: servant.accountStatus == 'active'
                                            ? const Color(0xFF10B981)
                                            : servant.accountStatus == 'pending'
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                  if (servant.phone != null &&
                                      servant.phone!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: SelectableText(
                                            servant.phone!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        PhoneContactActions(phone: servant.phone!, compact: true),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Actions
                            IconButton(
                              tooltip: 'تعديل بيانات الخادم',
                              onPressed: () => _openEditor(servant),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            if (isSuperAdmin)
                              IconButton(
                                key: Key('servant_delete_${servant.id}'),
                                tooltip: 'حذف الخادم',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                ),
                                onPressed: () => _deleteServant(servant),
                              )
                            else
                              Icon(
                                Icons.chevron_left_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(ServantProfile servant) async {
    final result = await showDialog<_ServantEditResult>(
      context: context,
      builder: (_) => _ServantEditDialog(
        servant: servant,
        stages: stages,
        classes: classes,
      ),
    );

    if (result == null) return;

    try {
      await ref
          .read(servantRepositoryProvider)
          .updateProfile(
            servantId: servant.id,
            name: result.name,
            phone: result.phone,
            birthDate: result.birthDate,
            workStudy: result.workStudy,
            role: result.role,
            stageId: result.stageId,
            classId: result.classId,
            accountStatus: result.accountStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات الخادم بنجاح.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حفظ التعديل: $error')));
    }
  }

  Future<void> _addServant() async {
    final values = await showDialog<_NewServantValues>(
      context: context,
      builder: (_) => _NewServantDialog(stages: stages, classes: classes),
    );
    if (values == null || !mounted) return;
    try {
      await ref
          .read(servantRepositoryProvider)
          .createProfile(
            id: const Uuid().v4(),
            serviceId: widget.serviceId,
            authUserId: values.authUserId,
            name: values.name,
            phone: values.phone,
            role: values.role,
            stageId: values.stageId,
            classId: values.classId,
          );
      await ref.read(servantRepositoryProvider).refresh(widget.serviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الخادم وربط دوره بالخدمة.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذرت إضافة الخادم: $error')));
    }
  }

  Future<void> _deleteServant(ServantProfile servant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف ملف الخادم؟'),
        content: Text(
          'سيُحذف ${servant.name} من هذه الخدمة. لن يتم حذف حساب تسجيل الدخول نفسه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف الملف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(servantRepositoryProvider).deleteProfile(servant.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف ملف الخادم محليًا وستتم مزامنته.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حذف ملف الخادم: $error')));
      }
    }
  }

  String _roleLabel(String role) => formatRoleLabel(role);
  /*
        'overall_leader' => 'أمين الخدمة',
        'overall_helper' => 'أمين مساعد',
        'stage_leader' => 'أمين المرحلة',
        'class_leader' => 'أمين الفصل',
        'class_servant' => 'خادم الفصل',
        _ => role,
      };*/

  String _statusLabel(String status) => switch (status) {
    'pending' => 'معلق',
    'active' => 'نشط',
    'inactive' => 'غير نشط',
    _ => status,
  };
}

class _ServantEditResult {
  const _ServantEditResult({
    required this.name,
    required this.phone,
    required this.birthDate,
    required this.workStudy,
    required this.role,
    required this.stageId,
    required this.classId,
    required this.accountStatus,
  });

  final String name;
  final String phone;
  final DateTime birthDate;
  final String workStudy;
  final String role;
  final String? stageId;
  final String? classId;
  final String accountStatus;
}

class _NewServantValues {
  const _NewServantValues({
    required this.authUserId,
    required this.name,
    required this.phone,
    required this.role,
    this.stageId,
    this.classId,
  });
  final String authUserId;
  final String name;
  final String phone;
  final String role;
  final String? stageId;
  final String? classId;
}

class _NewServantDialog extends StatefulWidget {
  const _NewServantDialog({required this.stages, required this.classes});
  final List<Stage> stages;
  final List<ServiceClass> classes;

  @override
  State<_NewServantDialog> createState() => _NewServantDialogState();
}

class _NewServantDialogState extends State<_NewServantDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _authId = TextEditingController();
  String role = 'class_servant';
  String? stageId;
  String? classId;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _authId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classes = stageId == null
        ? widget.classes
        : widget.classes.where((item) => item.stageId == stageId).toList();
    return AlertDialog(
      title: const Text('إضافة خادم للخدمة'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'يجب أن يكون للخادم حساب مسجل مسبقًا. أدخل معرّف مستخدم Auth لربط الحساب بهذا الدور.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _authId,
                decoration: const InputDecoration(
                  labelText: 'معرّف مستخدم Auth *',
                ),
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الخادم *'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: const [
                  DropdownMenuItem(
                    value: 'overall_leader',
                    child: Text('أمين الخدمة'),
                  ),
                  DropdownMenuItem(
                    value: 'overall_helper',
                    child: Text('أمين مساعد'),
                  ),
                  DropdownMenuItem(
                    value: 'stage_leader',
                    child: Text('أمين المرحلة'),
                  ),
                  DropdownMenuItem(
                    value: 'class_leader',
                    child: Text('أمين الفصل'),
                  ),
                  DropdownMenuItem(
                    value: 'class_servant',
                    child: Text('خادم الفصل'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  role = value ?? role;
                  if (role != 'stage_leader') stageId = null;
                  if (role != 'class_leader' && role != 'class_servant') {
                    classId = null;
                  }
                }),
              ),
              if (role == 'stage_leader')
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(labelText: 'المرحلة'),
                  items: widget.stages
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    stageId = value;
                    classId = null;
                  }),
                ),
              if (role == 'class_leader' || role == 'class_servant') ...[
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(
                    labelText: 'تصفية حسب المرحلة (اختياري)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('كل المراحل'),
                    ),
                    ...widget.stages.map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    stageId = value;
                    classId = null;
                  }),
                ),
                DropdownButtonFormField<String>(
                  initialValue: classes.any((item) => item.id == classId)
                      ? classId
                      : null,
                  decoration: const InputDecoration(labelText: 'الفصل'),
                  items: classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => classId = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final authId = _authId.text.trim();
            final name = _name.text.trim();
            if (authId.isEmpty || name.isEmpty) return;
            if (role == 'stage_leader' && stageId == null) return;
            if ((role == 'class_leader' || role == 'class_servant') &&
                classId == null) {
              return;
            }
            Navigator.pop(
              context,
              _NewServantValues(
                authUserId: authId,
                name: name,
                phone: _phone.text.trim(),
                role: role,
                stageId: role == 'stage_leader' ? stageId : null,
                classId: role == 'class_leader' || role == 'class_servant'
                    ? classId
                    : null,
              ),
            );
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}

class _ServantEditDialog extends StatefulWidget {
  const _ServantEditDialog({
    required this.servant,
    required this.stages,
    required this.classes,
  });

  final ServantProfile servant;
  final List<Stage> stages;
  final List<ServiceClass> classes;

  @override
  State<_ServantEditDialog> createState() => _ServantEditDialogState();
}

class _ServantEditDialogState extends State<_ServantEditDialog> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController workStudy;
  late String role;
  late String status;
  late DateTime birthDate;
  String? stageId;
  String? classId;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.servant.name);
    phone = TextEditingController(text: widget.servant.phone ?? '');
    workStudy = TextEditingController(text: widget.servant.workStudy ?? '');
    role = widget.servant.role;
    status = widget.servant.accountStatus;
    birthDate = widget.servant.birthDate ?? DateTime(2000, 1, 1);
    stageId = widget.servant.stageId;
    classId = widget.servant.classId;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    workStudy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableClasses = stageId == null
        ? widget.classes
        : widget.classes.where((item) => item.stageId == stageId).toList();

    return AlertDialog(
      title: Text(widget.servant.isPending ? 'اعتماد خادم' : 'بيانات الخادم'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              TextField(
                controller: workStudy,
                decoration: const InputDecoration(labelText: 'الدراسة / العمل'),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: const [
                  DropdownMenuItem(
                    value: 'overall_leader',
                    child: Text('أمين الخدمة'),
                  ),
                  DropdownMenuItem(
                    value: 'overall_helper',
                    child: Text('أمين مساعد'),
                  ),
                  DropdownMenuItem(
                    value: 'stage_leader',
                    child: Text('أمين المرحلة'),
                  ),
                  DropdownMenuItem(
                    value: 'class_leader',
                    child: Text('أمين الفصل'),
                  ),
                  DropdownMenuItem(
                    value: 'class_servant',
                    child: Text('خادم الفصل'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    role = value;
                    if (role == 'overall_leader' || role == 'overall_helper') {
                      stageId = null;
                      classId = null;
                    } else if (role == 'stage_leader') {
                      classId = null;
                    } else {
                      stageId = null;
                    }
                  });
                },
              ),
              if (role == 'stage_leader')
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(labelText: 'المرحلة'),
                  items: widget.stages
                      .map(
                        (stage) => DropdownMenuItem(
                          value: stage.id,
                          child: Text(stage.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    stageId = value;
                    classId = null;
                  }),
                ),
              if (role == 'class_leader' || role == 'class_servant')
                DropdownButtonFormField<String>(
                  initialValue:
                      availableClasses.any((item) => item.id == classId)
                      ? classId
                      : null,
                  decoration: const InputDecoration(labelText: 'الفصل'),
                  items: availableClasses
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => classId = value),
                ),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'حالة الحساب'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('معلق')),
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                ],
                onChanged: (value) => setState(() => status = value!),
              ),
              ListTile(
                title: Text(
                  'تاريخ الميلاد: ${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: birthDate,
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null && context.mounted) {
                      setState(() => birthDate = selected);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty ||
                phone.text.trim().isEmpty ||
                workStudy.text.trim().isEmpty) {
              return;
            }
            if (role == 'stage_leader' && stageId == null) return;
            if ((role == 'class_leader' || role == 'class_servant') &&
                classId == null) {
              return;
            }

            Navigator.pop(
              context,
              _ServantEditResult(
                name: name.text.trim(),
                phone: phone.text.trim(),
                birthDate: birthDate,
                workStudy: workStudy.text.trim(),
                role: role,
                stageId: role == 'stage_leader' ? stageId : null,
                classId: role == 'class_leader' || role == 'class_servant'
                    ? classId
                    : null,
                accountStatus: status,
              ),
            );
          },
          child: Text(widget.servant.isPending ? 'اعتماد وحفظ' : 'حفظ'),
        ),
      ],
    );
  }
}
