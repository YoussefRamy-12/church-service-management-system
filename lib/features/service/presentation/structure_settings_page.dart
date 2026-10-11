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
  ConsumerState<StructureSettingsPage> createState() => _StructureSettingsPageState();
}

class _StructureSettingsPageState extends ConsumerState<StructureSettingsPage> {
  bool saving = false;

  Future<String?> _askName(String title, String label) => showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, label: label),
  );

  Future<void> _addStage() async {
    final name = await _askName('إضافة مرحلة', 'اسم المرحلة');
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      await ref.read(supabaseClientProvider).from('stages').insert({'id': const Uuid().v4(), 'service_id': widget.serviceId, 'name': name});
      await ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المرحلة.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذرت إضافة المرحلة: $error')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> _addClass(String stageId) async {
    final name = await _askName('إضافة فصل', 'اسم الفصل');
    if (name == null || !mounted) return;
    setState(() => saving = true);
    try {
      await ref.read(supabaseClientProvider).from('classes').insert({'id': const Uuid().v4(), 'stage_id': stageId, 'name': name});
      await ref.read(serviceRepositoryProvider).refreshClasses(stageId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الفصل.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذرت إضافة الفصل: $error')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final isAdmin = ref.watch(isSuperAdminProvider);
    final profile = ref.watch(currentServantProfileProvider);
    final canManage = isAdmin || (profile.hasValue && (profile.value?.role == 'overall_leader' || profile.value?.role == 'overall_helper'));
    if (!canManage) return const Scaffold(body: EmptyState(icon: Icons.lock_outline_rounded, title: 'لا تملك صلاحية إدارة المراحل والفصول', message: 'تحتاج إلى صلاحية مسؤول الخدمة.'));
    return Scaffold(
      appBar: AppBar(title: const Text('المراحل والفصول'), actions: [IconButton(tooltip: 'تحديث', onPressed: () => repository.refreshStages(widget.serviceId), icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(key: const Key('structure_add_stage'), onPressed: saving ? null : _addStage, icon: const Icon(Icons.add), label: const Text('إضافة مرحلة')),
      body: StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const EmptyState(icon: Icons.error_outline, title: 'تعذر تحميل المراحل');
          if (!snapshot.hasData) return const LoadingView(message: 'جاري تحميل المراحل...');
          final stages = snapshot.data!;
          if (stages.isEmpty) return const EmptyState(icon: Icons.layers_outlined, title: 'ابدأ بإضافة مرحلة', message: 'بعدها أضف الفصول التابعة لها.', action: null);
          return AppContent(maxWidth: 950, child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
            const Text('أضف المراحل والفصول التي ستُستخدم في تسجيل التلاميذ والحضور.'),
            const SizedBox(height: 16),
            for (final stage in stages) Card(margin: const EdgeInsets.only(bottom: 12), child: ExpansionTile(
              key: Key('structure_stage_${stage.id}'),
              leading: const Icon(Icons.layers_outlined),
              title: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              onExpansionChanged: (expanded) { if (expanded) repository.refreshClasses(stage.id); },
              children: [
                StreamBuilder(stream: repository.watchClasses(stage.id), builder: (context, classes) {
                  if (classes.hasError) return const Padding(padding: EdgeInsets.all(16), child: Text('تعذر تحميل الفصول.'));
                  if (!classes.hasData) return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
                  if (classes.data!.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد فصول في هذه المرحلة بعد.'));
                  return Column(children: [for (final item in classes.data!) ListTile(key: Key('structure_class_${item.id}'), leading: const Icon(Icons.groups_outlined), title: Text(item.name))]);
                }),
                Align(alignment: AlignmentDirectional.centerEnd, child: TextButton.icon(onPressed: saving ? null : () => _addClass(stage.id), icon: const Icon(Icons.add), label: const Text('إضافة فصل'))),
              ],
            )),
          ]));
        },
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label});
  final String title;
  final String label;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(key: _formKey, child: TextFormField(controller: _controller, autofocus: true, decoration: InputDecoration(labelText: widget.label), validator: (value) => value == null || value.trim().isEmpty ? 'أدخل الاسم' : null)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _controller.text.trim()); }, child: const Text('حفظ')),
    ],
  );
}
