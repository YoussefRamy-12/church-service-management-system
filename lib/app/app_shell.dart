import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sync/sync_engine_provider.dart';
import '../core/sync/sync_queue_repository.dart';
import '../features/auth/domain/entities/session_identity.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/follow_up/presentation/follow_up_case_providers.dart';
import 'design/app_radii.dart';
import 'design/app_spacing.dart';
import 'ui/app_ui.dart';
import 'ui/components/app_section_header.dart';
import 'ui/components/sync_badge.dart';
import 'ui/responsive.dart';

/// Responsive application navigation for service-scoped routes.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.serviceId, required this.child});

  final String serviceId;
  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('الرئيسية', Icons.dashboard_rounded, 'dashboard'),
    _NavItem('التلاميذ', Icons.school_rounded, 'students'),
    _NavItem(
      'النوتة الروحية',
      Icons.auto_stories_rounded,
      'spiritual-notebook',
    ),
    _NavItem('الحضور', Icons.how_to_reg_rounded, 'attendance'),
    _NavItem('المتابعة', Icons.phone_in_talk_rounded, 'follow-up'),
    _NavItem('التقارير', Icons.insights_rounded, 'reports'),
    _NavItem('تحضيري', Icons.menu_book_rounded, 'prep'),
    _NavItem('الخدام', Icons.supervised_user_circle_rounded, 'servants'),
    _NavItem('تصدير البيانات', Icons.file_download_rounded, 'export'),
    _NavItem('التخرج', Icons.school_outlined, 'graduation'),
    _NavItem('إعدادات الخدمة', Icons.settings_rounded, 'settings'),
    _NavItem('حسابي', Icons.account_circle_rounded, 'my-settings'),
  ];

  static const _primarySegments = <String>[
    'dashboard',
    'attendance',
    'students',
    'follow-up',
  ];

  static const _primaryLabels = <String, String>{
    'dashboard': 'الرئيسية',
    'attendance': 'الحضور',
    'students': 'التلاميذ',
    'follow-up': 'المتابعة',
  };

  bool _canSeeManagement(String? role) =>
      role == 'overall_leader' ||
      role == 'overall_helper' ||
      role == 'leader' ||
      role == 'helper';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final profileValue = ref.watch(currentServantProfileProvider);
    final profile = profileValue.hasValue ? profileValue.value : null;
    final identityValue = ref.watch(currentSessionIdentityProvider);
    final identity = identityValue.hasValue ? identityValue.value : null;
    final isSuperAdmin = identity is SuperAdminIdentity;
    final canSwitchService =
        isSuperAdmin || identity is MultiServiceServantIdentity;
    final canManage = isSuperAdmin || _canSeeManagement(profile?.role);
    final displayName = profile?.name ?? (isSuperAdmin ? 'مسؤول النظام' : null);
    final pageTitle = _pageTitle(location);
    final visibleItems = _visibleItems(
      profile?.role,
      isSuperAdmin: isSuperAdmin,
      canManage: canManage,
    );
    final primaryItems = _primaryItems(visibleItems);
    final selectedSegment = _selectedSegment(location);
    final isMoreSelected = !_primarySegments.contains(selectedSegment);
    final selectedIndex = primaryItems.indexWhere(
      (item) => item.segment == selectedSegment,
    );
    final navigationIndex = selectedIndex >= 0
        ? selectedIndex
        : primaryItems.length;
    final isFullScreenFlow = _isFullScreenFlow(location);
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    void go(String segment) => context.go('/service/$serviceId/$segment');
    void switchService() => context.go(isSuperAdmin ? '/admin' : '/session');
    Future<void> logout() async {
      await signOutAndGoToLogin(ref, context);
    }

    void openMore() => _showMoreSheet(
      context,
      visibleItems: visibleItems,
      canSwitchService: canSwitchService,
      switchServiceLabel: isSuperAdmin ? 'اختيار خدمة أخرى' : 'تغيير الخدمة',
      onNavigate: go,
      onSwitchService: switchService,
      onLogout: logout,
    );

    final content = Column(
      children: [
        SafeArea(
          bottom: false,
          child: _ShellTopBar(
            title: pageTitle,
            showSyncBadge: !isDesktop,
            onSyncTap: () => context.go('/sync'),
          ),
        ),
        Expanded(child: child),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Row(
        children: [
          if (isDesktop)
            _DesktopSidebar(
              location: location,
              profileName: displayName,
              profileRole: isSuperAdmin ? 'system_admin' : profile?.role,
              items: visibleItems,
              canSwitchService: canSwitchService,
              switchServiceLabel: isSuperAdmin
                  ? 'اختيار خدمة أخرى'
                  : 'تغيير الخدمة',
              onNavigate: go,
              onSwitchService: switchService,
              onLogout: logout,
              onSyncTap: () => context.go('/sync'),
            ),
          if (isTablet)
            SafeArea(
              child: _TabletNavigationRail(
                items: primaryItems,
                selectedIndex: navigationIndex,
                isMoreSelected: isMoreSelected,
                onNavigate: (segment) =>
                    segment == 'more' ? openMore() : go(segment),
              ),
            ),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar:
          isMobile &&
              !isFullScreenFlow &&
              MediaQuery.viewInsetsOf(context).bottom == 0
          ? SafeArea(
              top: false,
              child: _MobileNavigationBar(
                items: primaryItems,
                selectedIndex: navigationIndex,
                isMoreSelected: isMoreSelected,
                onNavigate: (segment) =>
                    segment == 'more' ? openMore() : go(segment),
                followUpCount: _followUpCount(ref, serviceId),
              ),
            )
          : null,
    );
  }

  List<_NavItem> _visibleItems(
    String? role, {
    required bool isSuperAdmin,
    required bool canManage,
  }) {
    // Keep the existing authorization/visibility rules unchanged.
    return _items.where((item) {
      if (item.segment == 'settings') {
        return isSuperAdmin ||
            role == 'overall_leader' ||
            role == 'overall_helper';
      }
      if (item.segment == 'my-settings') return true;
      if (item.segment == 'servants' ||
          item.segment == 'export' ||
          item.segment == 'graduation') {
        return canManage;
      }
      if (item.segment == 'reports') {
        return isSuperAdmin ||
            canManage ||
            role == 'stage_leader' ||
            role == 'class_leader';
      }
      return true;
    }).toList();
  }

  List<_NavItem> _primaryItems(List<_NavItem> visibleItems) {
    final bySegment = {for (final item in visibleItems) item.segment: item};
    return [
      for (final segment in _primarySegments)
        if (bySegment.containsKey(segment)) bySegment[segment]!,
    ];
  }

  String _selectedSegment(String path) {
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (segments.length < 3 || segments[0] != 'service') return 'more';
    final section = segments[2];
    return switch (section) {
      'dashboard' || 'stage' => 'dashboard',
      'attendance' => 'attendance',
      'students' => 'students',
      'follow-up' => 'follow-up',
      _ => 'more',
    };
  }

  bool _isFullScreenFlow(String path) {
    // QR scan, add-student and import screens are pushed on the root Navigator,
    // so they cover this shell without changing its GoRouter location. The
    // only GoRouter full-screen flow in app.dart is attendance/session (plus
    // the legacy top-level attendance route).
    return path.startsWith('/service/$serviceId/attendance/session/') ||
        RegExp(r'^/attendance/[^/]+/[^/]+$').hasMatch(path);
  }

  String _pageTitle(String path) {
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (path.contains('/attendance/session/')) return 'تسجيل الحضور';
    if (path.endsWith('/settings/structure')) return 'المراحل والفصول';
    if (path.endsWith('/settings/system')) return 'إعدادات النظام';
    if (path.endsWith('/settings/meetings')) return 'مواعيد الاجتماعات';
    if (path.contains('/spiritual-notebook/student/')) return 'النوتة الروحية';
    final section = segments.length > 2 ? segments[2] : null;
    return switch (section) {
      'dashboard' => 'الرئيسية',
      'stage' => 'المرحلة والفصل',
      'students' => 'التلاميذ',
      'spiritual-notebook' => 'النوتة الروحية',
      'attendance' => 'الحضور',
      'follow-up' => 'المتابعة',
      'reports' => 'التقارير',
      'prep' => 'تحضيري',
      'servants' => 'الخدام',
      'export' => 'التصدير',
      'graduation' => 'التخرج',
      'settings' => 'إعدادات الخدمة',
      'my-settings' => 'حسابي',
      _ => 'إدارة الخدمة',
    };
  }

  int? _followUpCount(WidgetRef ref, String serviceId) {
    final provider = followUpStudentItemsProvider(serviceId);
    // Do not kick off the expensive aggregate query just to paint a badge.
    // Reuse the result only when the existing Follow-up screen/provider has
    // already initialized it in this ProviderContainer.
    if (!ref.exists(provider)) return null;
    final data = ref.read(provider).asData?.value;
    if (data == null) return null;
    return data.where((item) => item.needsFollowUp).length;
  }

  void _showMoreSheet(
    BuildContext context, {
    required List<_NavItem> visibleItems,
    required bool canSwitchService,
    required String switchServiceLabel,
    required ValueChanged<String> onNavigate,
    required VoidCallback onSwitchService,
    required VoidCallback onLogout,
  }) {
    final visible = {for (final item in visibleItems) item.segment: item};
    final serviceItems = [
      visible['prep'],
      visible['spiritual-notebook'],
      visible['reports'],
    ].whereType<_NavItem>().toList();
    final managementItems = [
      visible['servants'],
      visible['export'],
      visible['graduation'],
      visible['settings'],
    ].whereType<_NavItem>().toList();
    final accountItems = [
      visible['my-settings'],
    ].whereType<_NavItem>().toList();
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.bottomSheet),
        ),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + media.viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('المزيد', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _MoreSection(
                    title: 'الخدمة',
                    items: serviceItems,
                    onNavigate: onNavigate,
                  ),
                  _MoreSection(
                    title: 'الإدارة',
                    items: managementItems,
                    onNavigate: onNavigate,
                  ),
                  const Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: AppSpacing.md,
                      bottom: AppSpacing.xs,
                    ),
                    child: AppSectionHeader(title: 'الحساب'),
                  ),
                  for (final item in accountItems)
                    ListTile(
                      key: Key('nav_more_${item.segment}'),
                      minVerticalPadding: AppSpacing.sm,
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onNavigate(item.segment);
                      },
                    ),
                  if (canSwitchService)
                    ListTile(
                      key: const Key('nav_switch_service'),
                      minVerticalPadding: AppSpacing.sm,
                      leading: const Icon(Icons.swap_horiz_rounded),
                      title: Text(switchServiceLabel),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSwitchService();
                      },
                    ),
                  const Divider(height: AppSpacing.md),
                  ListTile(
                    key: const Key('nav_logout'),
                    minVerticalPadding: AppSpacing.sm,
                    leading: Icon(Icons.logout_rounded, color: scheme.error),
                    title: Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileNavigationBar extends StatelessWidget {
  const _MobileNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.isMoreSelected,
    required this.onNavigate,
    required this.followUpCount,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final bool isMoreSelected;
  final ValueChanged<String> onNavigate;
  final int? followUpCount;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      for (final item in items)
        NavigationDestination(
          key: Key('nav_tab_${item.segment}'),
          icon: _DestinationIcon(
            icon: item.icon,
            badgeCount: item.segment == 'follow-up' ? followUpCount : null,
          ),
          selectedIcon: _DestinationIcon(
            icon: item.icon,
            badgeCount: item.segment == 'follow-up' ? followUpCount : null,
          ),
          label: AppShell._primaryLabels[item.segment] ?? item.label,
        ),
      const NavigationDestination(
        key: Key('nav_tab_more'),
        icon: Icon(Icons.more_horiz_rounded),
        selectedIcon: Icon(Icons.more_horiz_rounded),
        label: 'المزيد',
      ),
    ];

    return NavigationBar(
      key: const Key('app_shell_bottom_navigation'),
      selectedIndex: isMoreSelected ? items.length : selectedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      onDestinationSelected: (index) {
        if (index == items.length) {
          onNavigate('more');
        } else {
          onNavigate(items[index].segment);
        }
      },
      destinations: destinations,
    );
  }
}

class _TabletNavigationRail extends StatelessWidget {
  const _TabletNavigationRail({
    required this.items,
    required this.selectedIndex,
    required this.isMoreSelected,
    required this.onNavigate,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final bool isMoreSelected;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      key: const Key('app_shell_navigation_rail'),
      labelType: NavigationRailLabelType.all,
      selectedIndex: isMoreSelected ? items.length : selectedIndex,
      onDestinationSelected: (index) {
        if (index == items.length) {
          onNavigate('more');
        } else {
          onNavigate(items[index].segment);
        }
      },
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon, key: Key('nav_tab_${item.segment}')),
            selectedIcon: Icon(item.icon),
            label: Text(AppShell._primaryLabels[item.segment] ?? item.label),
          ),
        const NavigationRailDestination(
          icon: Icon(Icons.more_horiz_rounded, key: Key('nav_tab_more')),
          selectedIcon: Icon(Icons.more_horiz_rounded),
          label: Text('المزيد'),
        ),
      ],
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({required this.icon, this.badgeCount});

  final IconData icon;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (badgeCount == null || badgeCount == 0) return iconWidget;
    return Badge(
      label: Text(badgeCount! > 99 ? '99+' : '$badgeCount'),
      child: iconWidget,
    );
  }
}

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({
    required this.title,
    required this.showSyncBadge,
    required this.onSyncTap,
  });

  final String title;
  final bool showSyncBadge;
  final VoidCallback onSyncTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (showSyncBadge) ...[
            const SizedBox(width: AppSpacing.sm),
            _ShellSyncBadge(onTap: onSyncTap),
          ],
        ],
      ),
    );
  }
}

class _ShellSyncBadge extends ConsumerStatefulWidget {
  const _ShellSyncBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  ConsumerState<_ShellSyncBadge> createState() => _ShellSyncBadgeState();
}

class _ShellSyncBadgeState extends ConsumerState<_ShellSyncBadge> {
  Stream<int>? _pendingStream;
  Stream<int>? _conflictStream;
  SyncQueueRepository? _lastQueue;

  void _updateStreams(SyncQueueRepository queue) {
    if (_lastQueue != queue) {
      _lastQueue = queue;
      _pendingStream = queue.watchCountByStatus('pending');
      _conflictStream = queue.watchCountByStatus('conflict');
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(syncQueueRepositoryProvider);
    _updateStreams(queue);
    return StreamBuilder<int>(
      stream: _pendingStream,
      builder: (context, pendingSnapshot) {
        return StreamBuilder<int>(
          stream: _conflictStream,
          builder: (context, conflictSnapshot) {
            final pending = pendingSnapshot.data ?? 0;
            final conflicts = conflictSnapshot.data ?? 0;
            final state = conflicts > 0
                ? SyncState.conflict
                : pending > 0
                ? SyncState.pending
                : SyncState.synced;
            return SyncBadge(state: state, count: pending, onTap: widget.onTap);
          },
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.location,
    required this.profileName,
    required this.profileRole,
    required this.items,
    required this.canSwitchService,
    required this.switchServiceLabel,
    required this.onNavigate,
    required this.onSwitchService,
    required this.onLogout,
    required this.onSyncTap,
  });

  final String location;
  final String? profileName;
  final String? profileRole;
  final List<_NavItem> items;
  final bool canSwitchService;
  final String switchServiceLabel;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSwitchService;
  final VoidCallback onLogout;
  final VoidCallback onSyncTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('app_shell_desktop_sidebar'),
      width: 288,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Icon(
                      Icons.church_rounded,
                      color: scheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خدمة تلاميذ المسيح',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'إدارة الخدمة الذكية',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'القائمة الرئيسية',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final item in items)
                    _DesktopNavTile(
                      item: item,
                      selected: _isSelected(location, item.segment),
                      onTap: () => onNavigate(item.segment),
                    ),
                  if (canSwitchService)
                    _DesktopNavTile(
                      item: _NavItem(
                        switchServiceLabel,
                        Icons.swap_horiz_rounded,
                        'switch_service',
                      ),
                      selected: false,
                      onTap: onSwitchService,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'حالة النظام',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _ShellSyncBadge(onTap: onSyncTap),
            ),
            _SidebarAccount(
              profileName: profileName,
              profileRole: profileRole,
              onLogout: onLogout,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(String path, String segment) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final current = parts.length > 2 ? parts[2] : '';
    if (segment == 'dashboard') {
      return current == 'dashboard' || current == 'stage';
    }
    return current == segment;
  }
}

class _SidebarAccount extends StatelessWidget {
  const _SidebarAccount({
    required this.profileName,
    required this.profileRole,
    required this.onLogout,
  });

  final String? profileName;
  final String? profileRole;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              (profileName?.trim().isNotEmpty ?? false)
                  ? profileName!.trim().substring(0, 1)
                  : 'خ',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName ?? 'حساب الخدمة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  formatRoleLabel(profileRole),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('nav_logout'),
            tooltip: 'تسجيل الخروج',
            onPressed: onLogout,
            icon: Icon(Icons.logout_rounded, color: scheme.error),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavTile extends StatelessWidget {
  const _DesktopNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          key: Key('nav_${item.segment}'),
          minVerticalPadding: AppSpacing.sm,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          selected: selected,
          selectedTileColor: scheme.primaryContainer,
          selectedColor: scheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          leading: Icon(item.icon),
          title: Text(item.label),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.title,
    required this.items,
    required this.onNavigate,
  });

  final String title;
  final List<_NavItem> items;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: AppSectionHeader(title: title),
          ),
          for (final item in items)
            ListTile(
              key: Key('nav_more_${item.segment}'),
              minVerticalPadding: AppSpacing.sm,
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                Navigator.pop(context);
                onNavigate(item.segment);
              },
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.segment);

  final String label;
  final IconData icon;
  final String segment;
}
