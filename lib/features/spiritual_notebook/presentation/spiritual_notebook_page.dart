import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../data/spiritual_notebook_repository.dart';
import '../domain/weekly_period.dart';

part 'parts/notebook_data.dart';
part 'parts/notebook_page_state.dart';
part 'parts/notebook_page_layout.dart';
part 'widgets/notebook_controls.dart';
part 'widgets/student_list.dart';
part 'widgets/student_list_filters.dart';
part 'pages/student_notebook_page.dart';
part 'pages/student_notebook_activity_section.dart';
part 'pages/student_notebook_bonus_section.dart';
part 'pages/student_notebook_footer_section.dart';
part 'pages/student_notebook_actions.dart';
part 'widgets/leaderboard.dart';
part 'widgets/leaderboard_sections.dart';
part 'widgets/leaderboard_controls.dart';
part 'widgets/notebook_settings.dart';
part 'widgets/notebook_settings_actions.dart';

final spiritualNotebookRepositoryProvider = Provider(
  (ref) => SpiritualNotebookRepository(Supabase.instance.client),
);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

({Color bg, Color fg}) _avatarColors(BuildContext context, String name) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final colors = AppColors.of(context);
  final isDark = theme.brightness == Brightness.dark;
  if (isDark) {
    final palette = <({Color bg, Color fg})>[
      (bg: scheme.primaryContainer, fg: scheme.onPrimaryContainer),
      (bg: colors.synced.background, fg: colors.synced.foreground),
      (bg: colors.warning.background, fg: colors.warning.foreground),
      (bg: colors.excused.background, fg: colors.excused.foreground),
      (bg: colors.present.background, fg: colors.present.foreground),
    ];
    if (name.isEmpty) return palette.first;
    final code = name.codeUnits.fold<int>(0, (v, u) => v + u);
    return palette[code % palette.length];
  }
  final palette = <Color>[
    scheme.primary,
    colors.synced.foreground,
    colors.warning.foreground,
    scheme.onSurfaceVariant,
    colors.excused.foreground,
    colors.present.foreground,
  ];
  final c = name.isEmpty
      ? palette.first
      : palette[name.codeUnits.fold<int>(0, (v, u) => v + u) % palette.length];
  return (bg: c.withValues(alpha: 0.12), fg: c);
}

class SpiritualNotebookPage extends ConsumerStatefulWidget {
  const SpiritualNotebookPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<SpiritualNotebookPage> createState() =>
      _SpiritualNotebookPageState();
}
