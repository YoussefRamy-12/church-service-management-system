import 'package:flutter/material.dart';

/// Priority of a follow-up case with Arabic labels and distinct visual colors.
enum CasePriority {
  low('low', 'منخفضة', Color(0xFF64748B), Icons.low_priority_rounded),
  medium('medium', 'متوسطة', Color(0xFF0284C7), Icons.remove_rounded),
  high('high', 'عالية', Color(0xFFD97706), Icons.priority_high_rounded),
  urgent('urgent', 'عاجلة', Color(0xFFDC2626), Icons.warning_amber_rounded);

  const CasePriority(this.value, this.arabicLabel, this.color, this.icon);

  final String value;
  final String arabicLabel;
  final Color color;
  final IconData icon;

  static CasePriority fromString(String? value) {
    return CasePriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => CasePriority.medium,
    );
  }
}

