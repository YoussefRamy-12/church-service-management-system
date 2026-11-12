import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ui/app_ui.dart';
import '../../../../app/ui/role_labels.dart';
import '../../../auth/domain/entities/servant_profile.dart';
import '../../../servants/presentation/servant_providers.dart';
import '../../domain/entities/case_assignment.dart';
import '../follow_up_case_providers.dart';

class AssignServantsDialog extends ConsumerStatefulWidget {
  const AssignServantsDialog({
    super.key,
    required this.serviceId,
    required this.caseId,
    required this.classId,
    required this.assignedByProfileId,
    required this.currentAssignments,
  });

  final String serviceId;
  final String caseId;
  final String classId;
  final String assignedByProfileId;
  final List<CaseAssignment> currentAssignments;

  @override
  ConsumerState<AssignServantsDialog> createState() => _AssignServantsDialogState();
}

class _AssignServantsDialogState extends ConsumerState<AssignServantsDialog> {
  final Set<String> _selectedServantIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final a in widget.currentAssignments) {
      if (a.isActive) {
        _selectedServantIds.add(a.servantId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servantsStream =
        ref.watch(servantRepositoryProvider).watchForService(widget.serviceId);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.assignment_ind_rounded),
          SizedBox(width: 8),
          Text('تكليف خدام للمتابعة'),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 380,
        child: StreamBuilder<List<ServantProfile>>(
          stream: servantsStream,
          builder: (context, snapshot) {
            final allServants = snapshot.data ?? const [];
            // Filter active servants in this class or service
            final eligibleServants = allServants.where((s) {
              if (!s.isActive) return false;
              // Class servants must belong to this class, leaders can be assigned
              if (s.classId != null && s.classId != widget.classId) {
                // If servant is assigned specifically to another class, don't allow
                return false;
              }
              return true;
            }).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (eligibleServants.isEmpty) {
              return const Center(
                child: Text('لا يوجد خدام متاحين في هذا النطاق.'),
              );
            }

            return ListView.builder(
              itemCount: eligibleServants.length,
              itemBuilder: (context, index) {
                final servant = eligibleServants[index];
                final isSelected = _selectedServantIds.contains(servant.id);

                return CheckboxListTile(
                  value: isSelected,
                  title: Text(
                    servant.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    formatRoleLabel(servant.role),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedServantIds.add(servant.id);
                      } else {
                        _selectedServantIds.remove(servant.id);
                      }
                    });
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _saveAssignments,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ التكليفات'),
        ),
      ],
    );
  }

  Future<void> _saveAssignments() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(followUpCaseRepositoryProvider);

      final currentlyActive = widget.currentAssignments
          .where((a) => a.isActive)
          .map((a) => a.servantId)
          .toSet();

      // Newly added
      final toAdd = _selectedServantIds.difference(currentlyActive).toList();
      if (toAdd.isNotEmpty) {
        await repo.assignServants(
          caseId: widget.caseId,
          servantIds: toAdd,
          assignedBy: widget.assignedByProfileId,
        );
      }

      // Removed
      for (final a in widget.currentAssignments.where((a) => a.isActive)) {
        if (!_selectedServantIds.contains(a.servantId)) {
          await repo.removeAssignment(
            assignmentId: a.id,
            caseId: widget.caseId,
            removedBy: widget.assignedByProfileId,
          );
        }
      }

      invalidateFollowUpCaseData(
        ref,
        serviceId: widget.serviceId,
        caseId: widget.caseId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث تكليفات الخدام بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ التكليفات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

