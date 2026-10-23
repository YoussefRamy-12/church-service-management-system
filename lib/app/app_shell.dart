import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/sync_status_widget.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/domain/entities/session_identity.dart';
import 'theme.dart';
import 'ui/app_ui.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.serviceId, required this.child});
  final String serviceId;
  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('الرئيسية', Icons.dashboard_rounded, 'dashboard'),
    _NavItem('التلاميذ', Icons.school_rounded, 'students'),
    _NavItem('الحضور', Icons.how_to_reg_rounded, 'attendance'),
    _NavItem('المتابعة', Icons.phone_in_talk_rounded, 'follow-up'),
    _NavItem('التقارير', Icons.insights_rounded, 'reports'),
    _NavItem('تحضيري', Icons.menu_book_rounded, 'prep'),
    _NavItem('الخدام', Icons.supervised_user_circle_rounded, 'servants'),
    _NavItem('تصدير البيانات', Icons.file_download_rounded, 'export'),
    _NavItem('التخرج', Icons.school_outlined, 'graduation'),
    _NavItem('الإعدادات', Icons.settings_rounded, 'settings'),
  ];

  void _go(BuildContext context, String segment) =>
      context.go('/service/$serviceId/$segment');

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
    final isSuperAdmin =
        identityValue.hasValue && identityValue.value is SuperAdminIdentity;
    final canSwitchService =
        isSuperAdmin ||
        (identityValue.hasValue &&
            identityValue.value is MultiServiceServantIdentity);
    void switchService() => context.go(isSuperAdmin ? '/admin' : '/session');
    final compact = MediaQuery.sizeOf(context).width < 1100;
    final canManage = isSuperAdmin || _canSeeManagement(profile?.role);
    final displayName = profile?.name ?? (isSuperAdmin ? 'مسؤول النظام' : null);
    final pageTitle = _pageTitle(location);
    Future<void> logout() async {
      await signOutAndGoToLogin(ref, context);
    }

    final visibleItems = _items.where((item) {
      if (item.segment == 'settings') {
        return isSuperAdmin ||
            profile?.role == 'overall_leader' ||
            profile?.role == 'overall_helper';
      }
      if (item.segment == 'servants' ||
          item.segment == 'export' ||
          item.segment == 'graduation') {
        return canManage;
      }
      if (item.segment == 'reports') {
        return isSuperAdmin ||
            canManage ||
            profile?.role == 'stage_leader' ||
            profile?.role == 'class_leader';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AmbientBackground(
        child: Row(
          children: [
            if (!compact)
              _DesktopSidebar(
                serviceId: serviceId,
                location: location,
                profileName: displayName,
                profileRole: isSuperAdmin ? 'system_admin' : profile?.role,
                items: visibleItems,
                onNavigate: (segment) => _go(context, segment),
                canSwitchService: canSwitchService,
                switchServiceLabel: isSuperAdmin
                    ? 'اختيار خدمة أخرى'
                    : 'تغيير الخدمة',
                onSwitchService: switchService,
                onLogout: logout,
              ),
            Expanded(
              child: Column(
                children: [
                  _ShellTopBar(
                    compact: compact,
                    title: pageTitle,
                    profileName: displayName,
                    profileRole: isSuperAdmin ? 'system_admin' : profile?.role,
                    onMenu: () => _showNavigation(
                      context,
                      visibleItems,
                      logout,
                      canSwitchService,
                      isSuperAdmin ? 'اختيار خدمة أخرى' : 'تغيير الخدمة',
                      switchService,
                    ),
                    canSwitchService: canSwitchService,
                    switchServiceLabel: isSuperAdmin
                        ? 'اختيار خدمة أخرى'
                        : 'تغيير الخدمة',
                    onSwitchService: switchService,
                    onLogout: logout,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pageTitle(String path) {
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    final segment = segments.isEmpty ? null : segments.last;
    return switch (segment) {
      'dashboard' => 'الرئيسية',
      'students' => 'التلاميذ',
      'attendance' => 'الحضور',
      'follow-up' => 'المتابعة',
      'reports' => 'التقارير',
      'prep' => 'تحضيري',
      'servants' => 'الخدام',
      'export' => 'التصدير',
      'graduation' => 'التخرج',
      'settings' => 'الإعدادات',
      'structure' => 'المراحل والفصول',
      'system' => 'إعدادات النظام',
      _ => 'إدارة الخدمة',
    };
  }

  void _showNavigation(
    BuildContext context,
    List<_NavItem> items,
    VoidCallback onLogout,
    bool canSwitchService,
    String switchServiceLabel,
    VoidCallback onSwitchService,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: isDark
          ? const Color(0xF7131D33)
          : const Color(0xF7FFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'التنقل',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              if (canSwitchService)
                ListTile(
                  key: const Key('nav_switch_service'),
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: Text(switchServiceLabel),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSwitchService();
                  },
                ),
              for (final item in items)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _go(context, item.segment);
                  },
                ),
              const Divider(height: 24),
              ListTile(
                key: const Key('nav_logout'),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
  }
}

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.serviceId,
    required this.location,
    required this.profileName,
    required this.profileRole,
    required this.items,
    required this.onNavigate,
    required this.canSwitchService,
    required this.switchServiceLabel,
    required this.onSwitchService,
    required this.onLogout,
  });

  final String serviceId;
  final String location;
  final String? profileName;
  final String? profileRole;
  final List<_NavItem> items;
  final void Function(String) onNavigate;
  final bool canSwitchService;
  final String switchServiceLabel;
  final VoidCallback onSwitchService;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.82);
    final borderColor = isDark
        ? const Color(0x33818CF8)
        : const Color(0x1F4F46E5);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 290,
          decoration: BoxDecoration(
            color: sidebarBg,
            border: Border(left: BorderSide(color: borderColor, width: 1.2)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Brand Header with Glowing Icon Capsule
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.church_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'خدمة تلاميذ المسيح',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'إدارة الخدمة الذكية',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                // Nav Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 12,
                          bottom: 8,
                        ),
                        child: Text(
                          'القائمة الرئيسية',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subtextColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      for (final item in items)
                        _NavTile(
                          item: item,
                          selected: _isSelected(location, item.segment),
                          onTap: () => onNavigate(item.segment),
                        ),
                      if (canSwitchService)
                        _NavTile(
                          item: _NavItem(
                            switchServiceLabel,
                            Icons.swap_horiz_rounded,
                            'switch_service',
                          ),
                          selected: false,
                          onTap: onSwitchService,
                        ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 12,
                          bottom: 8,
                        ),
                        child: Text(
                          'حالة النظام',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subtextColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: SyncStatusWidget(key: Key('sync_status')),
                      ),
                    ],
                  ),
                ),
                // Frosted Servant Account Card
                Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.75)
                        : const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (profileName?.trim().isNotEmpty ?? false)
                              ? profileName!.trim().substring(0, 1)
                              : 'خ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileName ?? 'حساب الخدمة',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _roleLabel(profileRole),
                              style: TextStyle(
                                fontSize: 11,
                                color: subtextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('nav_logout'),
                        tooltip: 'تسجيل الخروج',
                        onPressed: onLogout,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String? role) => formatRoleLabel(role);

  bool _isSelected(String location, String segment) {
    final path = '/service/$serviceId/$segment';
    if (segment == 'dashboard') {
      return location == path ||
          location.startsWith('/service/$serviceId/stage/');
    }
    return location == path || location.startsWith('$path/');
  }
}

class _ShellTopBar extends ConsumerWidget {
  const _ShellTopBar({
    required this.compact,
    required this.title,
    required this.profileName,
    required this.profileRole,
    required this.onMenu,
    required this.onLogout,
    required this.canSwitchService,
    required this.switchServiceLabel,
    required this.onSwitchService,
  });

  final bool compact;
  final String title;
  final String? profileName;
  final String? profileRole;
  final VoidCallback onMenu;
  final VoidCallback onLogout;
  final bool canSwitchService;
  final String switchServiceLabel;
  final VoidCallback onSwitchService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topBarBg = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.85);
    final borderBottom = isDark
        ? const Color(0x33818CF8)
        : const Color(0x1A4F46E5);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: topBarBg,
            border: Border(bottom: BorderSide(color: borderBottom, width: 1.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (compact)
                IconButton(
                  key: const Key('nav_menu'),
                  tooltip: 'القائمة',
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded, size: 24),
                ),
              if (compact) const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خدمة تلاميذ المسيح',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 11 : 12,
                        height: 1.1,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 16 : 19,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('theme_toggle'),
                tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF4F46E5),
                ),
              ),
              if (canSwitchService)
                IconButton(
                  key: const Key('switch_service'),
                  tooltip: switchServiceLabel,
                  onPressed: onSwitchService,
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              PopupMenuButton<String>(
                key: const Key('user_menu'),
                tooltip: 'قائمة المستخدم',
                onSelected: (value) {
                  if (value == 'logout') onLogout();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName ?? 'حساب الخدمة',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _roleLabel(profileRole),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      title: Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (profileName?.trim().isNotEmpty ?? false)
                          ? profileName!.trim().substring(0, 1)
                          : 'خ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 4),
                child: SyncStatusWidget(key: Key('sync_status_mobile')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String? role) => formatRoleLabel(role);
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF4F46E5);
    final idleTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF1E293B);
    final hoveredTextColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  )
                : (_hovered
                      ? LinearGradient(
                          colors: [
                            primaryAccent.withValues(alpha: 0.12),
                            primaryAccent.withValues(alpha: 0.05),
                          ],
                        )
                      : null),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              key: Key('nav_${widget.item.segment}'),
              selected: widget.selected,
              selectedColor: Colors.white,
              selectedTileColor: Colors.transparent,
              leading: Icon(
                widget.item.icon,
                color: widget.selected
                    ? Colors.white
                    : (_hovered
                          ? primaryAccent
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B))),
                size: 22,
              ),
              title: Text(
                widget.item.label,
                style: TextStyle(
                  fontWeight: widget.selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: widget.selected
                      ? Colors.white
                      : (_hovered ? hoveredTextColor : idleTextColor),
                  fontSize: 14,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onTap: widget.onTap,
            ),
          ),
        ),
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
