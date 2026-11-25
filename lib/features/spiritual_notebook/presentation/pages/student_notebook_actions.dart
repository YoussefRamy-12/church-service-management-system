// ignore_for_file: invalid_use_of_protected_member

part of '../spiritual_notebook_page.dart';

extension _SpiritualNotebookStudentActions on _SpiritualNotebookStudentPageState {
  void _openStudentAt(int index) {
    if (index < 0 || index >= widget.studentIds.length) return;
    context.go(
      '/service/${widget.serviceId}/spiritual-notebook/student/${widget.studentIds[index]}',
      extra: {
        'studentIds': widget.studentIds,
        'studentIndex': index,
      },
    );
  }


  Future<_StudentFormData> _load() async {
      final repo = ref.read(spiritualNotebookRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.students(widget.serviceId),
        repo.activities(widget.serviceId),
        repo.submissions(widget.serviceId),
        repo.settings(widget.serviceId),
      ]);
      final students = results[0] as List<Map<String, dynamic>>;
      final student = students
          .where((row) => row['membership_id'] == widget.membershipId)
          .firstOrNull;
      if (student == null) {
        throw StateError('Active student membership is not available in this service.');
      }

      final period = WeeklyPeriod.containing(DateTime.now());
      final existing = (results[2] as List<Map<String, dynamic>>)
          .where(
            (row) =>
                row['student_id'] == widget.membershipId &&
                row['period_start'] == _date(period.start),
          )
          .firstOrNull;
      return _StudentFormData(
        student,
        results[1] as List<Map<String, dynamic>>,
        existing,
        results[3] as Map<String, dynamic>?,
      );
    }

  Future<void> _submitRecord({bool goToNext = false}) async {
      final d = (await data);
      if (!mounted) return;
      final period = WeeklyPeriod.containing(DateTime.now());
      final role = ref.read(currentServantProfileProvider).value?.role;
      final bonusAllowed = (d.settings?['bonus_roles'] as List<dynamic>? ?? [])
          .contains(role);
      final maxBonus = (d.settings?['max_bonus_points'] as int?) ?? 0;
      final b = int.tryParse(bonus.text) ?? 0;
      final studentName = d.student['name'] as String? ?? 'التلميذ';
      final selectedPoints = d.activities
          .where((a) => selected.contains(a['id']))
          .fold<int>(0, (sum, a) => sum + (a['points'] as int));
      final grandTotal = selectedPoints + (bonusAllowed ? b : 0);

      if (selected.isEmpty && (d.settings?['allow_zero_submissions'] != true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر نشاطاً واحداً على الأقل للتلميذ')),
        );
        return;
      }

      if (b < 0 || b > maxBonus || (b > 0 && reason.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تحقق من قيمة النقاط الإضافية وسبب إضافتها'),
          ),
        );
        return;
      }

      final selectedActivities = d.activities
          .where((activity) => selected.contains(activity['id']))
          .toList();
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              20,
              8,
              20,
              20 + MediaQuery.viewInsetsOf(c).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'مراجعة النوتة قبل الحفظ',
                  style: Theme.of(c).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$studentName • ${period.label}',
                  style: Theme.of(c).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                if (selectedActivities.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(c).size.height * 0.30,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectedActivities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final activity = selectedActivities[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(activity['name'] as String),
                          trailing: Text(
                            '+${activity['points']} ن',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Text('سيتم حفظ النوتة دون أنشطة هذا الأسبوع.'),
                if (bonusAllowed && b > 0) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Text('النقاط التشجيعية')),
                      Text('+$b ن'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'السبب: ${reason.text.trim()}',
                    style: Theme.of(c).textTheme.bodySmall,
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'إجمالي النقاط',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '$grandTotal نقطة',
                      style: Theme.of(c).textTheme.titleLarge?.copyWith(
                        color: Theme.of(c).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('مراجعة التعديلات'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () => Navigator.pop(c, true),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('حفظ النوتة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'تنبيه: لا يمكن تعديل السجل بعد الحفظ.',
                  textAlign: TextAlign.center,
                  style: Theme.of(c).textTheme.bodySmall?.copyWith(
                    color: Theme.of(c).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true) return;
      setState(() => saving = true);

      try {
        await ref
            .read(spiritualNotebookRepositoryProvider)
            .submit(
              membershipId: widget.membershipId,
              period: period,
              activityIds: selected.toList(),
              bonusPoints: bonusAllowed ? b : 0,
              bonusReason: reason.text.trim(),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ النوتة الروحية للتلميذ بنجاح'),
              backgroundColor: appSuccess,
            ),
          );
          if (goToNext && widget.studentIndex < widget.studentIds.length - 1) {
            _openStudentAt(widget.studentIndex + 1);
          } else {
            setState(() {
              data = _load();
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حفظ النوتة. حاول مرة أخرى.'), backgroundColor: appError),
          );
        }
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
  }
