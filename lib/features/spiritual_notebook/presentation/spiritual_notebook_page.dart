import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../data/spiritual_notebook_repository.dart';
import '../domain/weekly_period.dart';

part 'parts/notebook_page_state.dart';
part 'parts/notebook_page_layout.dart';
part 'widgets/notebook_controls.dart';
part 'widgets/student_list.dart';
part 'widgets/student_list_filters.dart';
part 'pages/student_notebook_page.dart';
part 'widgets/leaderboard.dart';
part 'widgets/leaderboard_sections.dart';
part 'widgets/notebook_settings.dart';

final spiritualNotebookRepositoryProvider = Provider(
  (ref) => SpiritualNotebookRepository(Supabase.instance.client),
);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Color _avatarColor(String name) {
  const palette = <Color>[
    Color(0xFF00236F),
    Color(0xFF0D9488),
    Color(0xFFB45309),
    AppDesignColors.lightMutedInk,
    Color(0xFF0369A1),
    Color(0xFF7C3AED),
    Color(0xFF059669),
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
