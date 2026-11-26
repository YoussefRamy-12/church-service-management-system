import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../app/design/app_colors.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/analytics_models.dart';
import '../domain/service_report.dart';
import 'pages/student_analytics_detail_page.dart';
import 'report_providers.dart';
import 'widgets/actionable_insights_card.dart';
import 'widgets/attendance_trend_chart.dart';
import 'widgets/class_comparison_table.dart';
import 'widgets/early_regular_distribution_chart.dart';
import 'widgets/follow_up_analytics_view.dart';
import 'widgets/repeated_absences_table.dart';
import 'widgets/report_export_dialog.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_kpi_card.dart';
import 'widgets/servant_workload_table.dart';
import 'widgets/student_analytics_view.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> stages = [];
  List<dynamic> classes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(_loadMetadata);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    try {
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final s = await serviceRepo.getStages(widget.serviceId);
      final cList = <dynamic>[];
      for (final stage in s) {
        cList.addAll(await serviceRepo.getClasses(stage.id));
      }
      if (mounted) {
        setState(() {
          stages = s;
          classes = cList;
        });
      }
    } catch (_) {}
  }

  void _openExportDialog(ServiceReport report) {
    final filter = ref.read(reportFilterProvider);
    showDialog<void>(
      context: context,
      builder: (_) => ReportExportDialog(report: report, filter: filter),
    );
  }

  void _onStudentTap(RepeatedAbsenceRecord record) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StudentAnalyticsDetailPage(student: record),
      ),
    );
  }

  void _onInsightTap(ActionableInsight insight) {
    if (insight.targetTab == 'attendance') {
      _tabController.animateTo(0);
    } else if (insight.targetTab == 'follow_up') {
      _tabController.animateTo(1);
    } else if (insight.targetTab == 'students') {
      _tabController.animateTo(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reportAsync = ref.watch(reportsAnalyticsProvider(widget.serviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => MediaQuery.sizeOf(context).width >= 768
                ? OutlinedButton.icon(
                    onPressed: () => _openExportDialog(report),
                    icon: const Icon(Icons.file_download_rounded, size: 18),
                    label: const Text('تصدير Excel / PDF'),
                  )
                : IconButton(
                    tooltip: 'تصدير التقرير',
                    onPressed: () => _openExportDialog(report),
                    icon: const Icon(Icons.file_download_outlined),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: () => ref.invalidate(reportsAnalyticsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppContent(
        maxWidth: 1200,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Filter Bar
            ReportFilterBar(
              serviceId: widget.serviceId,
              stages: stages,
              classes: classes,
            ),

            // 4 Primary Navigation Tabs
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.2,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(6),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.how_to_reg_rounded, size: 18),
                    text: 'الحضور',
                  ),
                  Tab(
                    icon: Icon(Icons.mark_chat_read_rounded, size: 18),
                    text: 'المتابعة',
                  ),
                  Tab(
                    icon: Icon(Icons.groups_rounded, size: 18),
                    text: 'التلاميذ',
                  ),
                  Tab(
                    icon: Icon(Icons.diversity_3_rounded, size: 18),
                    text: 'الخدام',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Report Data Content
            reportAsync.when(
              loading: () => LayoutBuilder(
                builder: (context, constraints) {
                  final scheme = Theme.of(context).colorScheme;
                  final columns = constraints.maxWidth >= 900 ? 4 : 2;
                  final cardWidth =
                      (constraints.maxWidth - 12 * (columns - 1)) / columns;
                  return Column(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var index = 0; index < 4; index++)
                            Container(
                              width: cardWidth,
                              height: 132,
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Container(
                                    width: cardWidth * 0.62,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  Container(
                                    width: cardWidth * 0.42,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 190,
                              height: 14,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (final height in [
                                  72.0,
                                  118.0,
                                  88.0,
                                  146.0,
                                  104.0,
                                ])
                                  Container(
                                    width: 24,
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              error: (error, stack) {
                debugPrint('Failed to load report analytics: $error');
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.of(context).absent.foreground,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'تعذر تحميل بيانات التقرير. تحقق من الاتصال ثم أعد المحاولة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              ref.invalidate(reportsAnalyticsProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              data: (report) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Actionable Insights Banner (if any)
                    if (report.actionableInsights.isNotEmpty) ...[
                      ActionableInsightsCard(
                        insights: report.actionableInsights,
                        onInsightTap: _onInsightTap,
                      ),
                    ],

                    // Tab View Bodies
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        switch (_tabController.index) {
                          case 0:
                            return _buildAttendanceTab(report, isDark);
                          case 1:
                            return _buildFollowUpTab(report, isDark);
                          case 2:
                            return _buildStudentsTab(report, isDark);
                          case 3:
                            return _buildServantsTab(report, isDark);
                          default:
                            return _buildAttendanceTab(report, isDark);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 1. Attendance & Absence Tab
  Widget _buildAttendanceTab(ServiceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 900;
            final isTablet = width >= 600 && width < 900;

            final cards = [
              ReportKpiCard(
                title: 'معدل الحضور العام',
                value: '${report.attendancePercentage.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.of(context).present.foreground,
                changePercentage: report.attendanceChange,
                subtitle:
                    'حضر ${report.present} من أصل ${report.expectedAttendance} متوقع',
              ),
              ReportKpiCard(
                title: 'حضور مبكر',
                value: '${report.earlyRate.toStringAsFixed(1)}%',
                icon: Icons.timer_rounded,
                color: Theme.of(context).colorScheme.primary,
                subtitle: '${report.early + report.before} تلميذ حضروا مبكراً',
              ),
              ReportKpiCard(
                title: 'إجمالي الغياب',
                value: '${report.absencePercentage.toStringAsFixed(1)}%',
                icon: Icons.person_off_rounded,
                color: AppColors.of(context).absent.foreground,
                subtitle: '${report.absentCount} حالة غياب فردية مسجلة',
              ),
              ReportKpiCard(
                title: 'الغياب المتكرر',
                value: '${report.repeatedAbsences.length}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.of(context).pending.foreground,
                subtitle: 'تلاميذ تغيبوا عن اجتماعين متتاليين أو أكثر',
              ),
            ];

            if (isDesktop) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            } else if (isTablet) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 14),
                      Expanded(child: cards[1]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: cards[2]),
                      const SizedBox(width: 14),
                      Expanded(child: cards[3]),
                    ],
                  ),
                ],
              );
            } else {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: (width - 12) / 2, child: card),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),

        // Visualizations: Attendance Trend & Arrival Distribution
        AttendanceTrendChart(meetingHistory: report.meetingHistory),
        const SizedBox(height: 20),
        EarlyRegularDistributionChart(
          expectedAttendance: report.expectedAttendance,
          beforeCount: report.before,
          earlyCount: report.early,
          normalCount: report.normal,
          absentCount: report.absentCount,
        ),
        const SizedBox(height: 24),

        // Repeated Absences Table
        RepeatedAbsencesTable(
          repeatedAbsences: report.repeatedAbsences,
          onStudentTap: _onStudentTap,
        ),
        const SizedBox(height: 24),

        // Class Comparison Table (if multiple classes in scope)
        if (report.classComparisons.isNotEmpty) ...[
          ClassComparisonTable(
            classComparisons: report.classComparisons,
            onClassTap: (c) {
              ref.read(reportFilterProvider.notifier).setClass(c.classId);
            },
          ),
        ],
      ],
    );
  }

  // 2. Pastoral Follow-Up Tab
  Widget _buildFollowUpTab(ServiceReport report, bool isDark) {
    final completionRate = report.followUpAnalytics?.completionRate ?? 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 900;

            final cards = [
              ReportKpiCard(
                title: 'إجمالي حالات الافتقاد',
                value:
                    '${report.followUpAnalytics?.totalCases ?? report.followUps}',
                icon: Icons.mark_chat_read_rounded,
                color: AppColors.of(context).warning.foreground,
                subtitle: 'حالات المتابعة المقيدة في نطاق الفترة',
              ),
              ReportKpiCard(
                title: 'حالات معلقة',
                value: '${report.followUpAnalytics?.openCases ?? 0}',
                icon: Icons.pending_actions_rounded,
                color: AppColors.of(context).absent.foreground,
                subtitle: 'حالات بانتظار التواصل والحسم',
              ),
              ReportKpiCard(
                title: 'نسبة الإنجاز',
                value: '${completionRate.toStringAsFixed(1)}%',
                icon: Icons.task_alt_rounded,
                color: AppColors.of(context).present.foreground,
                subtitle: 'الحالات المحسومة والمغلقة بنجاح',
              ),
              ReportKpiCard(
                title: 'الأنشطة الافتقادية',
                value:
                    '${report.followUpAnalytics?.totalActivities ?? report.followUps}',
                icon: Icons.volunteer_activism_rounded,
                color: Theme.of(context).colorScheme.primary,
                subtitle: 'مكالمات، زيارات، وجلسات منفذة',
              ),
            ];

            if (isDesktop) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            } else {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: (width - 12) / 2, child: card),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        FollowUpAnalyticsView(
          analytics: report.followUpAnalytics,
          legacyFollowUpsCount: report.followUps,
        ),
        const SizedBox(height: 24),
        // Repeated Absences requiring follow-up
        RepeatedAbsencesTable(
          repeatedAbsences: report.repeatedAbsences,
          onStudentTap: _onStudentTap,
        ),
      ],
    );
  }

  // 3. Students & Growth Tab
  Widget _buildStudentsTab(ServiceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 900;

            final cards = [
              ReportKpiCard(
                title: 'إجمالي المخدومين',
                value: '${report.students}',
                icon: Icons.school_rounded,
                color: Theme.of(context).colorScheme.primary,
                subtitle: 'التلاميذ المشمولون في نطاق التقرير',
              ),
              ReportKpiCard(
                title: 'تلاميذ معتمدون',
                value:
                    '${report.studentAnalytics?.activeStudents ?? report.students}',
                icon: Icons.verified_user_rounded,
                color: AppColors.of(context).present.foreground,
                subtitle: 'مقيدون بصورة نشطة في الفصول',
              ),
              ReportKpiCard(
                title: 'قيد الاعتماد',
                value: '${report.studentAnalytics?.pendingStudents ?? 0}',
                icon: Icons.hourglass_top_rounded,
                color: AppColors.of(context).warning.foreground,
                subtitle: 'بانتظار موافقة أمين الخدمة',
              ),
              ReportKpiCard(
                title: 'التزام كامل (٩٠٪+)',
                value:
                    '${report.studentAnalytics?.attendanceTiers["90-100%"] ?? 0}',
                icon: Icons.star_rounded,
                color: AppColors.of(context).present.foreground,
                subtitle: 'تلاميذ لم يتخلفوا عن أي اجتماع',
              ),
            ];

            if (isDesktop) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            } else {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: (width - 12) / 2, child: card),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        StudentAnalyticsView(
          analytics: report.studentAnalytics,
          totalStudents: report.students,
        ),
        const SizedBox(height: 24),
        RepeatedAbsencesTable(
          repeatedAbsences: report.repeatedAbsences,
          onStudentTap: _onStudentTap,
        ),
      ],
    );
  }

  // 4. Servants & Workload Tab
  Widget _buildServantsTab(ServiceReport report, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 900;

            final cards = [
              ReportKpiCard(
                title: 'إجمالي الخدام',
                value: '${report.servantWorkloads.length}',
                icon: Icons.diversity_3_rounded,
                color: Theme.of(context).colorScheme.primary,
                subtitle: 'خدام الخدمة والمراحل والفصول',
              ),
              ReportKpiCard(
                title: 'إجمالي الحالات الموزعة',
                value:
                    '${report.servantWorkloads.fold<int>(0, (sum, s) => sum + s.assignedCasesCount)}',
                icon: Icons.assignment_ind_rounded,
                color: AppColors.of(context).warning.foreground,
                subtitle: 'أعباء الافتقاد المسندة للخدام',
              ),
              ReportKpiCard(
                title: 'الأنشطة الافتقادية المنفذة',
                value:
                    '${report.servantWorkloads.fold<int>(0, (sum, s) => sum + s.completedActivitiesCount)}',
                icon: Icons.volunteer_activism_rounded,
                color: AppColors.of(context).present.foreground,
                subtitle: 'مكالمات وزيارات موثقة خلال الفترة',
              ),
            ];

            if (isDesktop) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            } else {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: (width - 12) / 2, child: card),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        ServantWorkloadTable(servantWorkloads: report.servantWorkloads),
      ],
    );
  }
}
