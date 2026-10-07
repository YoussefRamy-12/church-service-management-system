import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../students/domain/entities/student.dart';
import 'follow_up_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/sync/sync_engine_provider.dart';

class FollowUpPage extends ConsumerStatefulWidget {
  const FollowUpPage({super.key, required this.student});

  final Student student;

  @override
  ConsumerState<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends ConsumerState<FollowUpPage> {
  String status = 'contacted';
  String method = 'phone';
  bool another = false;
  bool saving = false;
  DateTime date = DateTime.now();
  DateTime next = DateTime.now().add(const Duration(days: 7));

  final reason = TextEditingController();
  final studentResponse = TextEditingController();
  final parentResponse = TextEditingController();
  final action = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    reason.dispose();
    studentResponse.dispose();
    parentResponse.dispose();
    action.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentServantProfileProvider);
    final servantId = profile.hasValue ? profile.value?.id : null;
    final history =
        ref.watch(followUpRepositoryProvider).watchForStudent(widget.student.id);
    final formatter = DateFormat('yyyy-MM-dd');

    return Scaffold(
      key: const Key('follow_up_page'),
      appBar: AppBar(
        title: Text('متابعة — ${widget.student.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'سجل المتابعة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          StreamBuilder(
            stream: history,
            builder: (context, snap) {
              final rows = snap.data ?? const [];
              if (rows.isEmpty) return const EmptyState(icon: Icons.history_toggle_off_rounded, title: 'لا توجد متابعات بعد', message: 'عند تسجيل أول متابعة ستظهر هنا.');

              return Column(
                children: rows
                    .map(
                      (r) => Card(
                        child: ListTile(
                          title: Text(
                            "${r.followUpDate} — ${r.contactStatus == 'contacted' ? 'تم التواصل' : 'لم يتم التواصل'}",
                          ),
                          subtitle: Text(
                            r.notes?.isNotEmpty == true
                                ? r.notes!
                                : (r.actionRequired ?? ''),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const Divider(height: 32),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'الحالة'),
            items: const [
              DropdownMenuItem(
                value: 'contacted',
                child: Text('تم التواصل'),
              ),
              DropdownMenuItem(
                value: 'not_contacted',
                child: Text('لم يتم التواصل'),
              ),
            ],
            onChanged: (value) => setState(() => status = value!),
          ),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'طريقة التواصل'),
            items: const [
              DropdownMenuItem(
                value: 'phone',
                child: Text('مكالمة'),
              ),
              DropdownMenuItem(
                value: 'whatsapp',
                child: Text('WhatsApp'),
              ),
              DropdownMenuItem(
                value: 'in_person',
                child: Text('مقابلة'),
              ),
            ],
            onChanged: (value) => setState(() => method = value!),
          ),
          ListTile(
            title: Text('تاريخ المتابعة: ${formatter.format(date)}'),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (selected != null && context.mounted) {
                  setState(() => date = selected);
                }
              },
            ),
          ),
          TextField(
            controller: reason,
            decoration: const InputDecoration(labelText: 'سبب الغياب'),
          ),
          TextField(
            controller: studentResponse,
            decoration: const InputDecoration(labelText: 'رد التلميذ'),
          ),
          TextField(
            controller: parentResponse,
            decoration: const InputDecoration(labelText: 'رد ولي الأمر'),
          ),
          TextField(
            controller: action,
            decoration: const InputDecoration(labelText: 'الإجراء المطلوب'),
          ),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
          ),
          SwitchListTile(
            title: const Text('متابعة أخرى مطلوبة'),
            value: another,
            onChanged: (value) => setState(() => another = value),
          ),
          if (another)
            ListTile(
              title: Text('المتابعة القادمة: ${formatter.format(next)}'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: next,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null && context.mounted) {
                    setState(() => next = selected);
                  }
                },
              ),
            ),
          FilledButton(
            key: const Key('follow_up_save'),
            onPressed: servantId == null || saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                    await ref.read(followUpRepositoryProvider).create(
                          studentId: widget.student.id,
                          createdBy: servantId,
                          followUpDate: formatter.format(date),
                          contactStatus: status,
                          contactMethod: method,
                          absenceReason: reason.text,
                          studentResponse: studentResponse.text,
                          parentResponse: parentResponse.text,
                          actionRequired: action.text,
                          notes: notes.text,
                          anotherFollowUpNeeded: another,
                          nextFollowUpDate:
                              another ? formatter.format(next) : null,
                        );
                    await ref.read(syncEngineProvider).syncNow();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المتابعة محليًا وسيتم مزامنتها.')));
                      if (mounted) setState(() => saving = false);
                    } catch (error) {
                      if (mounted) {
                        setState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ المتابعة: $error')));
                      }
                    }
                  },
            child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('حفظ المتابعة'),
          ),
        ],
      ),
    );
  }
}
