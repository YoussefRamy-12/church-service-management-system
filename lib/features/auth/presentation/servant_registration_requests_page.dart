import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/supabase_client_provider.dart';

class ServantRegistrationRequestsPage extends ConsumerStatefulWidget {
  const ServantRegistrationRequestsPage({super.key});

  @override
  ConsumerState<ServantRegistrationRequestsPage> createState() =>
      _ServantRegistrationRequestsPageState();
}

class _ServantRegistrationRequestsPageState
    extends ConsumerState<ServantRegistrationRequestsPage> {
  late Future<List<Map<String, dynamic>>> _requests;
  late Future<List<Map<String, dynamic>>> _services;
  late Future<Map<String, List<String>>> _assignments;

  @override
  void initState() {
    super.initState();
    _requests = _loadRequests();
    _services = _loadServices();
    _assignments = _loadAssignments();
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final rows = await ref
        .read(supabaseClientProvider)
        .from('servant_registration_requests')
        .select(
          'auth_user_id, full_name, email, phone, birth_date, work_study, status, created_at',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> _loadServices() async {
    final rows = await ref
        .read(supabaseClientProvider)
        .from('services')
        .select('id, name, church_name')
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, List<String>>> _loadAssignments() async {
    final client = ref.read(supabaseClientProvider);
    final rows = await client
        .from('servant_profiles')
        .select('auth_user_id, service_id');
    final serviceIds = rows
        .map((row) => row['service_id'] as String)
        .toSet()
        .toList();
    if (serviceIds.isEmpty) return {};
    final services = await client
        .from('services')
        .select('id, name')
        .inFilter('id', serviceIds);
    final names = {
      for (final row in services) row['id'] as String: row['name'] as String,
    };
    final result = <String, List<String>>{};
    for (final row in rows) {
      final authId = row['auth_user_id'] as String;
      final name = names[row['service_id']] ?? 'خدمة';
      (result[authId] ??= []).add(name);
    }
    return result;
  }

  void _reload() => setState(() {
    _requests = _loadRequests();
    _services = _loadServices();
    _assignments = _loadAssignments();
  });

  Future<void> _enroll(Map<String, dynamic> request) async {
    try {
      final services = await _services;
      if (!mounted) return;
      if (services.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أنشئ خدمة أولًا ثم أعد المحاولة.')),
        );
        return;
      }
      final client = ref.read(supabaseClientProvider);
      final authUserId = request['auth_user_id'] as String;
      if ((request['full_name'] as String? ?? '').trim().isEmpty ||
          request['full_name'] == 'خادم جديد' ||
          (request['phone'] as String? ?? '').trim().isEmpty ||
          request['birth_date'] == null ||
          (request['work_study'] as String? ?? '').trim().isEmpty ||
          (request['phone'] as String? ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب على الخادم استكمال بيانات ملفه قبل الربط.'),
          ),
        );
        return;
      }
      final serviceIds = services
          .map((service) => service['id'].toString())
          .toList();
      final stageRows = await client
          .from('stages')
          .select('id, service_id, name')
          .inFilter('service_id', serviceIds);
      final stageNames = {
        for (final stage in stageRows)
          stage['id'] as String: stage['name']?.toString() ?? 'مرحلة',
      };
      final stageIds = stageNames.keys.toList();
      final classRows = stageIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await client
                  .from('classes')
                  .select('id, stage_id, name')
                  .inFilter('stage_id', stageIds),
            );
      final stagesByService = <String, List<Map<String, dynamic>>>{};
      for (final stage in stageRows) {
        (stagesByService[stage['service_id'] as String] ??= []).add(
          Map<String, dynamic>.from(stage),
        );
      }
      final classesByService = <String, List<Map<String, dynamic>>>{};
      for (final item in classRows) {
        final stageId = item['stage_id'] as String;
        final serviceId =
            stageRows.firstWhere(
                  (stage) => stage['id'] == stageId,
                )['service_id']
                as String;
        classesByService.putIfAbsent(serviceId, () => []).add({
          ...item,
          'stage_name': stageNames[stageId] ?? 'مرحلة',
        });
      }
      final existing = await client
          .from('servant_profiles')
          .select('id, service_id, role, stage_id, class_id')
          .eq('auth_user_id', authUserId);
      final existingRoles = <String, String>{
        for (final row in existing)
          row['service_id'] as String: row['role'] as String,
      };
      final existingStageIds = <String, String>{
        for (final row in existing)
          if (row['stage_id'] != null)
            row['service_id'] as String: row['stage_id'] as String,
      };
      final existingClassIds = <String, String>{
        for (final row in existing)
          if (row['class_id'] != null)
            row['service_id'] as String: row['class_id'] as String,
      };
      if (!mounted) return;
      final result = await showDialog<_EnrollmentChoice>(
        context: context,
        builder: (_) => _EnrollmentDialog(
          services: services,
          existingRoles: existingRoles,
          existingStageIds: existingStageIds,
          existingClassIds: existingClassIds,
          stagesByService: stagesByService,
          classesByService: classesByService,
        ),
      );
      if (result == null || !mounted) return;

      final existingIdsByService = <String, String>{
        for (final row in existing)
          row['service_id'] as String: row['id'] as String,
      };

      final removedServiceIds = existingRoles.keys
          .where((serviceId) => !result.roles.containsKey(serviceId))
          .toList();

      final updatedServiceIds = existingRoles.keys
          .where((serviceId) => result.roles.containsKey(serviceId))
          .toList();

      final newAssignments = result.roles.entries
          .where((entry) => !existingRoles.containsKey(entry.key))
          .map(
            (entry) => {
              'service_id': entry.key,
              'role': entry.value,
              'stage_id': result.stageIds[entry.key],
              'class_id': result.classIds[entry.key],
            },
          )
          .toList();

      // 1. Delete profiles for services that were unselected/removed
      for (final serviceId in removedServiceIds) {
        final profileId = existingIdsByService[serviceId];
        if (profileId != null) {
          await client.from('servant_profiles').delete().eq('id', profileId);
        }
      }

      // 2. Directly update roles and stage/class for existing service assignments.
      // This avoids touching user-owned profile fields (name, phone, birth_date, work_study),
      // which prevents the "fields cannot be changed by this user" authorization error.
      for (final serviceId in updatedServiceIds) {
        final profileId = existingIdsByService[serviceId];
        final newRole = result.roles[serviceId]!;
        final newStageId = result.stageIds[serviceId];
        final newClassId = result.classIds[serviceId];
        if (profileId != null) {
          await client
              .from('servant_profiles')
              .update({
                'role': newRole,
                'stage_id': newStageId,
                'class_id': newClassId,
                'account_status': 'active',
              })
              .eq('id', profileId);
        }
      }

      // 3. For any newly selected services, enroll them
      if (newAssignments.isNotEmpty) {
        await client.rpc<int>(
          'enroll_servant_to_services',
          params: {
            'p_auth_user_id': authUserId,
            'p_assignments': newAssignments,
          },
        );
      }

      // 4. Update the servant registration request status
      if (result.roles.isEmpty) {
        await client
            .from('servant_registration_requests')
            .update({
              'status': 'pending',
              'reviewed_at': null,
              'reviewed_by': null,
            })
            .eq('auth_user_id', authUserId);
      } else {
        await client
            .from('servant_registration_requests')
            .update({
              'status': 'enrolled',
              'reviewed_at': DateTime.now().toUtc().toIso8601String(),
              'reviewed_by': client.auth.currentUser!.id,
            })
            .eq('auth_user_id', authUserId);
      }

      if (!mounted) return;
      _reload();
      final totalServices = result.roles.length;
      final message = totalServices == 0
          ? 'تم إلغاء ربط الخادم بجميع الخدمات.'
          : 'تم تحديث خدمات الخادم ($totalServices خدمة).';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر ربط الحساب بالخدمة: ${_enrollmentError(error)}'),
        ),
      );
    }
  }

  String _enrollmentError(Object error) {
    final value = error.toString();
    if (value.contains('servant_active_stage_leader_unique')) {
      return 'يوجد أمين مرحلة نشط بالفعل في المرحلة المختارة.';
    }
    if (value.contains('servant_active_class_leader_unique')) {
      return 'يوجد أمين فصل نشط بالفعل في الفصل المختار.';
    }
    if (value.contains('servant_profiles_service_phone_unique') ||
        value.contains('23505')) {
      return 'رقم الهاتف مستخدم بالفعل في إحدى الخدمات. راجع بيانات الخادم أو سجله.';
    }
    if (value.contains('cannot be changed by this user')) {
      return 'بيانات الخادم الشخصية مملوكة له ولا يمكن تعديلها بواسطة هذا المستخدم.';
    }
    return value;
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض طلب التسجيل؟'),
        content: Text(
          'سيظل حساب ${request['full_name']} دون صلاحية دخول للخدمات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('servant_registration_requests')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'reviewed_by': client.auth.currentUser!.id,
          })
          .eq('auth_user_id', request['auth_user_id']);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تحديث الطلب: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('طلبات تسجيل الخدام'),
      leading: IconButton(
        tooltip: 'لوحة مسؤول النظام',
        onPressed: () => context.go('/admin'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _requests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعذر تحميل حسابات الخدام المسجلة.'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }
        final requests = snapshot.data ?? const [];
        if (requests.isEmpty) {
          return const Center(
            child: Text('لا توجد حسابات خدام مسجلة حتى الآن.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final request = requests[index];
            final status = request['status']?.toString() ?? 'pending';
            final pending = status == 'pending';
            final profileComplete =
                (request['full_name'] as String? ?? '').trim().isNotEmpty &&
                request['full_name'] != 'خادم جديد' &&
                (request['phone'] as String? ?? '').trim().isNotEmpty &&
                request['birth_date'] != null &&
                (request['work_study'] as String? ?? '').trim().isNotEmpty;
            return Card(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['full_name']?.toString() ?? 'خادم',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            [
                              if ((request['email'] as String? ?? '')
                                  .isNotEmpty)
                                request['email'],
                              if ((request['phone'] as String? ?? '')
                                  .isNotEmpty)
                                request['phone'],
                            ].join(' • '),
                          ),
                          if (!profileComplete)
                            Text(
                              'بانتظار استكمال بيانات الملف بواسطة الخادم',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          FutureBuilder<Map<String, List<String>>>(
                            future: _assignments,
                            builder: (context, assignments) {
                              final enrolledServices =
                                  assignments.data?[request['auth_user_id']] ??
                                  const <String>[];
                              return Text(
                                enrolledServices.isEmpty
                                    ? 'غير مرتبط بأي خدمة'
                                    : 'الخدمات: ${enrolledServices.join('، ')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Chip(label: Text(_statusLabel(status))),
                        ],
                      ),
                    ),
                    if (pending || status == 'enrolled')
                      FilledButton.tonalIcon(
                        key: Key('enroll_servant_${request['auth_user_id']}'),
                        onPressed: profileComplete
                            ? () => _enroll(request)
                            : null,
                        icon: const Icon(Icons.add_business_rounded),
                        label: Text(
                          status == 'enrolled'
                              ? 'تعديل أو إضافة خدمات'
                              : 'ربط بخدمة',
                        ),
                      ),
                    if (pending)
                      IconButton(
                        tooltip: 'رفض الطلب',
                        onPressed: () => _reject(request),
                        icon: const Icon(Icons.person_off_outlined),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );

  String _statusLabel(String status) => switch (status) {
    'pending' => 'بانتظار المراجعة',
    'enrolled' => 'تم ربطه بخدمة',
    'rejected' => 'مرفوض',
    _ => status,
  };
}

class _EnrollmentChoice {
  const _EnrollmentChoice(this.roles, this.stageIds, this.classIds);
  final Map<String, String> roles;
  final Map<String, String> stageIds;
  final Map<String, String> classIds;
}

class _EnrollmentDialog extends StatefulWidget {
  const _EnrollmentDialog({
    required this.services,
    required this.existingRoles,
    required this.existingStageIds,
    required this.existingClassIds,
    required this.stagesByService,
    required this.classesByService,
  });
  final List<Map<String, dynamic>> services;
  final Map<String, String> existingRoles;
  final Map<String, String> existingStageIds;
  final Map<String, String> existingClassIds;
  final Map<String, List<Map<String, dynamic>>> stagesByService;
  final Map<String, List<Map<String, dynamic>>> classesByService;

  @override
  State<_EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<_EnrollmentDialog> {
  late final Map<String, String> _roles;
  late final Map<String, String> _stageIds;
  late final Map<String, String> _classIds;

  bool get _canSubmit {
    if (_roles.isEmpty && widget.existingRoles.isEmpty) return false;
    for (final entry in _roles.entries) {
      if (entry.value == 'stage_leader') {
        final stages = widget.stagesByService[entry.key] ?? const [];
        if (!stages.any((stage) => stage['id'] == _stageIds[entry.key])) {
          return false;
        }
      }
      if (entry.value == 'class_leader' || entry.value == 'class_servant') {
        final classes = widget.classesByService[entry.key] ?? const [];
        if (!classes.any((item) => item['id'] == _classIds[entry.key])) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _roles = Map<String, String>.from(widget.existingRoles);
    _stageIds = Map<String, String>.from(widget.existingStageIds);
    _classIds = Map<String, String>.from(widget.existingClassIds);
    if (_roles.isEmpty && widget.services.isNotEmpty) {
      _roles[widget.services.first['id'].toString()] = 'class_servant';
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ربط الخادم بالخدمات'),
    content: SizedBox(
      width: 520,
      height: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('اختر خدمة أو أكثر وحدد دور الخادم في كل خدمة.'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final service in widget.services)
                  _serviceRoleTile(service),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: !_canSubmit
            ? null
            : () => Navigator.pop(
                context,
                _EnrollmentChoice(
                  Map.of(_roles),
                  Map.of(_stageIds),
                  Map.of(_classIds),
                ),
              ),
        child: const Text('تأكيد'),
      ),
    ],
  );

  Widget _serviceRoleTile(Map<String, dynamic> service) {
    final id = service['id'].toString();
    final role = _roles[id];
    final isExisting = widget.existingRoles.containsKey(id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 8),
        child: Column(
          children: [
            CheckboxListTile(
              value: role != null,
              contentPadding: EdgeInsets.zero,
              title: Text(service['name']?.toString() ?? 'خدمة'),
              subtitle: isExisting
                  ? const Text(
                      'مرتبط بها حاليًا (قم بإلغاء التحديد لإزالة الخادم من الخدمة)',
                    )
                  : null,
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _roles[id] = widget.existingRoles[id] ?? 'class_servant';
                  if (widget.existingStageIds.containsKey(id)) {
                    _stageIds[id] = widget.existingStageIds[id]!;
                  }
                  if (widget.existingClassIds.containsKey(id)) {
                    _classIds[id] = widget.existingClassIds[id]!;
                  }
                } else {
                  _roles.remove(id);
                  _stageIds.remove(id);
                  _classIds.remove(id);
                }
              }),
            ),
            if (role != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 40),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'الدور'),
                      items: const [
                        DropdownMenuItem(
                          value: 'overall_leader',
                          child: Text('أمين الخدمة'),
                        ),
                        DropdownMenuItem(
                          value: 'overall_helper',
                          child: Text('مساعد مسؤول الخدمة'),
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
                          _roles[id] = value;
                          _stageIds.remove(id);
                          _classIds.remove(id);
                        });
                      },
                    ),
                    if (role == 'stage_leader') _stageSelector(id),
                    if (role == 'class_leader' || role == 'class_servant')
                      _classSelector(id),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stageSelector(String serviceId) {
    final stages = widget.stagesByService[serviceId] ?? const [];
    final selected = stages.any((stage) => stage['id'] == _stageIds[serviceId])
        ? _stageIds[serviceId]
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('enroll_stage_$serviceId'),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'المرحلة المطلوبة *'),
      items: stages
          .map(
            (stage) => DropdownMenuItem<String>(
              value: stage['id'] as String,
              child: Text(stage['name']?.toString() ?? 'مرحلة'),
            ),
          )
          .toList(),
      onChanged: stages.isEmpty
          ? null
          : (value) => setState(() {
              if (value == null) {
                _stageIds.remove(serviceId);
              } else {
                _stageIds[serviceId] = value;
              }
            }),
      disabledHint: const Text('أضف مرحلة للخدمة أولًا'),
    );
  }

  Widget _classSelector(String serviceId) {
    final classes = widget.classesByService[serviceId] ?? const [];
    final selected = classes.any((item) => item['id'] == _classIds[serviceId])
        ? _classIds[serviceId]
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('enroll_class_$serviceId'),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'الفصل المطلوب *'),
      items: classes
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['id'] as String,
              child: Text(
                '${item['stage_name'] ?? 'مرحلة'} • ${item['name'] ?? 'فصل'}',
              ),
            ),
          )
          .toList(),
      onChanged: classes.isEmpty
          ? null
          : (value) => setState(() {
              if (value == null) {
                _classIds.remove(serviceId);
              } else {
                _classIds[serviceId] = value;
              }
            }),
      disabledHint: const Text('أضف فصلًا للخدمة أولًا'),
    );
  }
}
