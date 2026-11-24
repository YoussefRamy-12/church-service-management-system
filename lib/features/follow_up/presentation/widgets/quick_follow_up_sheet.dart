import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/session_identity.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/activity_type.dart';
import '../../domain/entities/follow_up_student_item.dart';
import '../follow_up_case_providers.dart';
import '../pages/create_follow_up_case_page.dart';

class QuickFollowUpSheet extends ConsumerStatefulWidget {
  const QuickFollowUpSheet({
    super.key,
    required this.serviceId,
    required this.item,
  });

  final String serviceId;
  final FollowUpStudentItem item;

  @override
  ConsumerState<QuickFollowUpSheet> createState() => _QuickFollowUpSheetState();
}

class _QuickFollowUpSheetState extends ConsumerState<QuickFollowUpSheet> {
  final _descriptionController = TextEditingController();
  ActivityType _activityType = ActivityType.call;
  String? _selectedCaseId;
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.item.student;
    final casesAsync = ref.watch(
      studentCasesProvider((
        serviceId: widget.serviceId,
        studentId: student.id,
      )),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: casesAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعذر تحميل حالات المتابعة المرتبطة بالتلميذ.'),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.invalidate(
                  studentCasesProvider((
                    serviceId: widget.serviceId,
                    studentId: student.id,
                  )),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
          data: (cases) {
            final activeCases = cases.where((item) => item.isActive).toList();
            if (activeCases.isEmpty) {
              return _buildNoActiveCase(context, student);
            }
            final selectedId = _selectedCaseId ??
                (activeCases.length == 1 ? activeCases.first.id : null);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_calendar_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تسجيل متابعة — ${student.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (activeCases.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    decoration: const InputDecoration(
                      labelText: 'حالة المتابعة',
                    ),
                    items: [
                      for (final caseItem in activeCases)
                        DropdownMenuItem(
                          value: caseItem.id,
                          child: Text(
                            caseItem.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCaseId = value),
                  ),
                  const SizedBox(height: 12),
                ] else
                  Text(
                    activeCases.first.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                Text('نوع المتابعة', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in const [
                      ActivityType.call,
                      ActivityType.visit,
                      ActivityType.message,
                      ActivityType.inPerson,
                      ActivityType.note,
                    ])
                      ChoiceChip(
                        avatar: Icon(type.icon, size: 16),
                        label: Text(type.arabicLabel),
                        selected: _activityType == type,
                        onSelected: (_) =>
                            setState(() => _activityType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملخص المتابعة',
                    hintText: 'النتيجة أو الخطوة القادمة...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving || selectedId == null
                      ? null
                      : () => _saveActivity(selectedId),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ المتابعة'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoActiveCase(BuildContext context, Student student) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'لا توجد حالة متابعة مفتوحة لهذا التلميذ.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('افتح حالة متابعة أولاً حتى يمكن ربط النشاط بسجل التلميذ.'),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            navigator.push(
              MaterialPageRoute(
                builder: (_) => CreateFollowUpCasePage(
                  serviceId: widget.serviceId,
                  preselectedStudent: student,
                  classId: student.currentClassId ?? '',
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('فتح حالة متابعة'),
        ),
      ],
    );
  }

  Future<void> _saveActivity(String caseId) async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب ملخص المتابعة أولاً.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await ref.read(currentServantProfileProvider.future);
      final identity = await ref.read(currentSessionIdentityProvider.future);
      final actorId = profile?.id ??
          (identity is SuperAdminIdentity ? identity.profile.id : null);
      if (actorId == null) {
        throw Exception('لم يتم التعرف على حساب الخادم المسجل');
      }

      await ref.read(followUpCaseRepositoryProvider).recordActivity(
            caseId: caseId,
            activityType: _activityType,
            description: description,
            createdBy: actorId,
            activityDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          );
      invalidateFollowUpCaseData(
        ref,
        serviceId: widget.serviceId,
        studentId: widget.item.student.id,
        caseId: caseId,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تسجيل المتابعة بنجاح.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل المتابعة: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
