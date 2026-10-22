import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import 'service_providers.dart';

class StructureSettingsPage extends ConsumerStatefulWidget {
  const StructureSettingsPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<StructureSettingsPage> createState() =>
      _StructureSettingsPageState();
}

class _StructureSettingsPageState extends ConsumerState<StructureSettingsPage> {
  bool saving = false;

  Future<String?> _askName(
    String title,
    String label, {
    String initialValue = '',
  }) => showDialog<String>(
    context: context,
    builder: (_) =>
        _NameDialog(title: title, label: label, initialValue: initialValue),
  );

  Future<void> _addStage() async {
    final name = await _askName('إضافة مرحلة', 'اسم المرحلة');
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      await ref.read(supabaseClientProvider).from('stages').insert({
        'id': const Uuid().v4(),
        'service_id': widget.serviceId,
        'name': name,
      });
      await ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة المرحلة.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذرت إضافة المرحلة: $error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _addClass(String stageId) async {
    final name = await _askName('إضافة فصل', 'اسم الفصل');
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      await ref.read(supabaseClientProvider).from('classes').insert({
        'id': const Uuid().v4(),
        'stage_id': stageId,
        'name': name,
      });
      await ref.read(serviceRepositoryProvider).refreshClasses(stageId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة الفصل.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذرت إضافة الفصل: $error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<bool> _confirmDelete(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _editStage(String id, String currentName) async {
    final name = await _askName(
      'تعديل المرحلة',
      'اسم المرحلة',
      initialValue: currentName,
    );
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .from('stages')
          .update({'name': name})
          .eq('id', id);
      await ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تعديل المرحلة.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تعديل المرحلة: $error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteStage(String id, String name) async {
    if (!await _confirmDelete(
      'حذف المرحلة؟',
      'سيؤدي حذف "$name" إلى حذف المرحلة من الخدمة. لا يمكن التراجع عن ذلك.',
    )) {
      return;
    }
    setState(() => saving = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .from('stages')
          .delete()
          .eq('id', id);
      await ref.read(serviceRepositoryProvider).deleteStage(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف المرحلة.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر حذف المرحلة. قد تحتوي على فصول أو بيانات مرتبطة. $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editClass(String id, String stageId, String currentName) async {
    final name = await _askName(
      'تعديل الفصل',
      'اسم الفصل',
      initialValue: currentName,
    );
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .from('classes')
          .update({'name': name})
          .eq('id', id);
      await ref.read(serviceRepositoryProvider).refreshClasses(stageId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تعديل الفصل.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تعديل الفصل: $error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteClass(String id, String name, String stageId) async {
    if (!await _confirmDelete(
      'حذف الفصل؟',
      'سيؤدي حذف "$name" إلى إزالته من المرحلة.',
    )) {
      return;
    }
    setState(() => saving = true);
    try {
      await ref
          .read(supabaseClientProvider)
          .from('classes')
          .delete()
          .eq('id', id);
      await ref.read(serviceRepositoryProvider).deleteClass(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الفصل.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر حذف الفصل. قد يحتوي على تلاميذ أو سجلات مرتبطة. $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final isAdmin = ref.watch(isSuperAdminProvider);
    final profile = ref.watch(currentServantProfileProvider);
    final canManage =
        isAdmin ||
        (profile.hasValue &&
            (profile.value?.role == 'overall_leader' ||
                profile.value?.role == 'overall_helper'));
    if (!canManage) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'لا تملك صلاحية إدارة المراحل والفصول',
          message: 'تحتاج إلى صلاحية مسؤول الخدمة.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('المراحل والفصول'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => repository.refreshStages(widget.serviceId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('structure_add_stage'),
        onPressed: saving ? null : _addStage,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مرحلة'),
      ),
      body: StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر تحميل المراحل',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingView(message: 'جاري تحميل المراحل...');
          }
          final stages = snapshot.data!;
          if (stages.isEmpty) {
            return const EmptyState(
              icon: Icons.layers_outlined,
              title: 'ابدأ بإضافة مرحلة',
              message: 'بعدها أضف الفصول التابعة لها.',
              action: null,
            );
          }
          return AppContent(
            maxWidth: 950,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                const Text(
                  'أضف المراحل والفصول التي ستُستخدم في تسجيل التلاميذ والحضور.',
                ),
                const SizedBox(height: 16),
                for (final stage in stages)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      key: Key('structure_stage_${stage.id}'),
                      leading: const Icon(Icons.layers_outlined),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stage.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'تعديل المرحلة',
                            onPressed: saving
                                ? null
                                : () => _editStage(stage.id, stage.name),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف المرحلة',
                            onPressed: saving
                                ? null
                                : () => _deleteStage(stage.id, stage.name),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      onExpansionChanged: (expanded) {
                        if (expanded) repository.refreshClasses(stage.id);
                      },
                      children: [
                        StreamBuilder(
                          stream: repository.watchClasses(stage.id),
                          builder: (context, classes) {
                            if (classes.hasError) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('تعذر تحميل الفصول.'),
                              );
                            }
                            if (!classes.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (classes.data!.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('لا توجد فصول في هذه المرحلة بعد.'),
                              );
                            }
                            return Column(
                              children: [
                                for (final item in classes.data!)
                                  ListTile(
                                    key: Key('structure_class_${item.id}'),
                                    leading: const Icon(Icons.groups_outlined),
                                    title: Text(item.name),
                                    trailing: Wrap(
                                      children: [
                                        IconButton(
                                          tooltip: 'تعديل الفصل',
                                          onPressed: saving
                                              ? null
                                              : () => _editClass(
                                                  item.id,
                                                  stage.id,
                                                  item.name,
                                                ),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف الفصل',
                                          onPressed: saving
                                              ? null
                                              : () => _deleteClass(
                                                  item.id,
                                                  item.name,
                                                  stage.id,
                                                ),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: saving
                                ? null
                                : () => _addClass(stage.id),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة فصل'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.label,
    this.initialValue = '',
  });
  final String title;
  final String label;
  final String initialValue;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'أدخل الاسم' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('حفظ'),
      ),
    ],
  );
}
