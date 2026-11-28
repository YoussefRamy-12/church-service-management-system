import 'package:flutter/material.dart';

class ServantRoleFilter extends StatelessWidget {
  const ServantRoleFilter({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final String selectedRole;
  final ValueChanged<String> onChanged;

  static const options = <(String, String)>[
    ('all', 'كل الأدوار'),
    ('overall_leader', 'أمين الخدمة'),
    ('overall_helper', 'أمين مساعد'),
    ('stage_leader', 'أمين المرحلة'),
    ('class_leader', 'أمين الفصل'),
    ('class_servant', 'خادم الفصل'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الدور', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.$2),
                selected: selectedRole == option.$1,
                onSelected: (_) => onChanged(option.$1),
              ),
          ],
        ),
      ],
    );
  }
}
