part of '../spiritual_notebook_page.dart';

extension _SpiritualNotebookStudentActions on _SpiritualNotebookStudentPageState {

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

  Future<void> _submitRecord() async {
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

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: appPrimary),
              SizedBox(width: 8),
              Text('تأكيد اعتماد النوتة الروحية'),
            ],
          ),
          content: Text(
            'هل تود اعتماد $grandTotal نقطة للتلميذ «$studentName» لهذا الأسبوع (${period.label})؟\n\nتنبيه: بعد الاعتماد لا يمكن تعديل السجل.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('مراجعة'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('تأكيد واعتماد'),
            ),
          ],
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
              content: Text('تم اعتماد النوتة الروحية للتلميذ بنجاح'),
              backgroundColor: appSuccess,
            ),
          );
          setState(() {
            data = _load();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر الحفظ: $e'), backgroundColor: appError),
          );
        }
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
  }
