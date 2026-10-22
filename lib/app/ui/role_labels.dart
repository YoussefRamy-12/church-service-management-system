/// Formats a servant/admin role into a human-readable Arabic label.
String formatRoleLabel(String? role) => switch (role) {
  'system_admin' => 'مسؤول النظام',
  'overall_leader' => 'مسؤول الخدمة',
  'overall_helper' => 'مساعد مسؤول الخدمة',
  'leader' || 'stage_leader' => 'أمين مرحلة',
  'helper' || 'class_servant' => 'خادم',
  'class_leader' => 'أمين الفصل',
  _ => role ?? 'مستخدم',
};
