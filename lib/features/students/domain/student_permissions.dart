import 'package:flutter/material.dart';

import '../../auth/domain/entities/servant_profile.dart';
import '../domain/entities/student.dart';

/// Evaluates whether the current servant profile or super admin has permission
/// to edit or delete the given [student].
///
/// This matches the scope of Supabase RLS policies `students_update` and `students_delete`:
/// - System administrators can edit and delete any student.
/// - Overall leaders and overall helpers have service-wide access to all students in their service.
/// - Class leaders and class servants can edit and delete students assigned to their class
///   (matching either `currentClassId` or `proposedClassId`).
/// - Other active servants within the service without a restricted class assignment retain
///   service-wide access.
bool canEditOrDeleteStudent({
  required Student student,
  required ServantProfile? profile,
  required bool isSuperAdmin,
}) {
  if (isSuperAdmin) return true;
  if (profile == null || !profile.isActive) return false;
  if (profile.serviceId != student.serviceId) return false;

  // Overall leaders / overall helpers have service-wide authority
  if (profile.role == 'overall_leader' || profile.role == 'overall_helper') {
    return true;
  }

  // Class-scoped leaders and servants are restricted to their assigned class
  if (profile.classId != null && profile.classId!.isNotEmpty) {
    return student.currentClassId == profile.classId ||
        student.proposedClassId == profile.classId;
  }

  return true;
}

/// Displays a standard permanent confirmation dialog before deleting [studentName].
///
/// Clearly identifies the student and explicitly warns that deletion is irreversible.
Future<bool?> showDeleteStudentConfirmationDialog({
  required BuildContext context,
  required String studentName,
  bool isOffline = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(
        'حذف التلميذ؟',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'هل أنت متأكد من حذف التلميذ "$studentName"؟\n\n'
        '${isOffline ? "سيتم حذف التلميذ محليًا ومزامنة الحذف عند توفر الاتصال." : "هذا الإجراء نهائي وسيتم حذف التلميذ من قاعدة البيانات بشكل دائم ولا يمكن التراجع عنه."}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('confirm_delete_student_button'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('تأكيد الحذف'),
        ),
      ],
    ),
  );
}
