import 'package:flutter/material.dart';

/// Type of follow-up activity recorded in a case.
enum ActivityType {
  call('call', 'اتصال هاتفي', Icons.phone_in_talk_rounded, Color(0xFF2563EB)),
  visit('visit', 'افتِقاد منزلي', Icons.home_rounded, Color(0xFF059669)),
  message('message', 'رسالة نصية / واتساب', Icons.chat_rounded, Color(0xFF0D9488)),
  inPerson('in_person', 'لقاء في الكنيسة', Icons.church_rounded, Color(0xFF7C3AED)),
  statusChange('status_change', 'تغيير حالة المتابعة', Icons.sync_alt_rounded, Color(0xFFD97706)),
  assignmentChange('assignment_change', 'تحديث الخدام المكلفين', Icons.group_add_rounded, Color(0xFF4F46E5)),
  note('note', 'ملاحظة', Icons.sticky_note_2_rounded, Color(0xFF64748B));

  const ActivityType(this.value, this.arabicLabel, this.icon, this.color);

  final String value;
  final String arabicLabel;
  final IconData icon;
  final Color color;

  static ActivityType fromString(String? value) {
    return ActivityType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => ActivityType.note,
    );
  }
}

