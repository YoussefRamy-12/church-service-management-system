part of '../spiritual_notebook_page.dart';

extension _SpiritualNotebookPageLayout on _SpiritualNotebookPageState {
  Widget _buildTopHeader(
      BuildContext context, {
      required bool isDark,
      required bool isMobile,
      required WeeklyPeriod period,
      required bool isCurrentWeek,
    }

  Widget _buildMetricsSection({
      required bool isMobile,
      required int totalStudents,
      required int registeredCount,
      required int pendingCount,
      required int weekTotalPoints,
      required int completionPercentage,
    }

  Widget _buildTabBar({
      required bool isMobile,
      required int totalStudents,
      required bool canConfigure,
    }
}
