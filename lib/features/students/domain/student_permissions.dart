import 'package:flutter/material.dart';

import '../../auth/domain/entities/servant_profile.dart';
import '../domain/entities/student.dart';

/// Evaluates whether the current servant profile or super admin can manage the
/// given service membership. Students without a cached membership ID are read-only
/// until the membership-backed directory has refreshed.
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
  if (student.membershipId == null) return false;
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

/// Confirms archival of a student's membership in the current service.
/// The global identity and historical records are retained.
Future<bool?> showDeleteStudentConfirmationDialog({
  required BuildContext context,
  required String studentName,
  bool isOffline = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(
        'أرشفة عضوية التلميذ؟',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'هل أنت متأكد من أرشفة عضوية "$studentName" في هذه الخدمة؟\n\n'
        '${isOffline ? "سيتم إيقاف العضوية محليًا ومزامنة الأرشفة عند توفر الاتصال." : "سيتم إيقاف العضوية مع الاحتفاظ ببيانات التلميذ وسجلاته التاريخية."}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('confirm_archive_student_membership_button'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('تأكيد الأرشفة'),
        ),
      ],
    ),
  );
}
