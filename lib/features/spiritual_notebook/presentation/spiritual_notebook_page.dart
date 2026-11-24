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

Color _avatarColor(String name) {
  const palette = <Color>[
    AppDesignColors.primary,
    AppColors.light.synced.foreground,
    AppColors.light.warning.foreground,
    AppDesignColors.lightMutedInk,
    AppColors.light.excused.foreground,
    AppColors.light.excused.foreground,
    AppColors.light.present.foreground,
  ];
  if (name.isEmpty) return palette.first;
  final code = name.codeUnits.fold<int>(0, (v, u) => v + u);
  return palette[code % palette.length];
}

class SpiritualNotebookPage extends ConsumerStatefulWidget {
  const SpiritualNotebookPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<SpiritualNotebookPage> createState() =>
      _SpiritualNotebookPageState();
}
