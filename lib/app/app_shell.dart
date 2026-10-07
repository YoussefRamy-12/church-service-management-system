import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/sync_status_widget.dart';
import '../features/auth/presentation/auth_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.serviceId, required this.child});
  final String serviceId;
  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('الرئيسية', Icons.dashboard_rounded, 'dashboard'),
    _NavItem('التلاميذ', Icons.school_rounded, 'students'),
    _NavItem('الحضور', Icons.fact_check_rounded, 'attendance'),
    _NavItem('المتابعة', Icons.volunteer_activism_rounded, 'follow-up'),
    _NavItem('التقارير', Icons.bar_chart_rounded, 'reports'),
    _NavItem('الخدام', Icons.groups_rounded, 'servants'),
    _NavItem('التصدير', Icons.file_download_rounded, 'export'),
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
    final compact = MediaQuery.sizeOf(context).width < 1000;
    final canManage = _canSeeManagement(profile?.role);

    final visibleItems = _items.where((item) {
      if (item.segment == 'settings') {
        return profile?.role == 'overall_leader' || profile?.role == 'overall_helper';
      }
      if (item.segment == 'servants' || item.segment == 'export' || item.segment == 'reports') {
        return canManage;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Row(
        children: [
          if (!compact) _DesktopSidebar(
            serviceId: serviceId,
            location: location,
            profileName: profile?.name,
            profileRole: profile?.role,
            items: visibleItems,
            onNavigate: (segment) => _go(context, segment),
            onLogout: () => context.go('/login'),
          ),
          Expanded(
            child: Column(
              children: [
                if (compact)
                  _MobileHeader(
                    profileName: profile?.name,
                    onMenu: () => _showNavigation(context, visibleItems),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigation(BuildContext context, List<_NavItem> items) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('التنقل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              for (final item in items)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _go(context, item.segment);
                  },
                ),
              const Divider(height: 24),
              ListTile(
                key: const Key('nav_logout'),
                leading: const Icon(Icons.logout_rounded),
                title: const Text('تسجيل الخروج'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.serviceId,
    required this.location,
    required this.profileName,
    required this.profileRole,
    required this.items,
    required this.onNavigate,
    required this.onLogout,
  });
  final String serviceId;
  final String location;
  final String? profileName;
  final String? profileRole;
  final List<_NavItem> items;
  final void Function(String) onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SizedBox(
        width: 272,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.church_rounded, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('خدمة تلاميذ المسيح', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('إدارة الخدمة', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 12, bottom: 8),
                      child: Text('القائمة الرئيسية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    for (final item in items)
                      _NavTile(
                        item: item,
                        selected: location.endsWith('/${item.segment}'),
                        onTap: () => onNavigate(item.segment),
                      ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 12, bottom: 8),
                      child: Text('حالة النظام', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SyncStatusWidget(key: Key('sync_status')),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        (profileName?.trim().isNotEmpty ?? false) ? profileName!.trim().substring(0, 1) : 'خ',
                        style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profileName ?? 'حساب الخدمة', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_roleLabel(profileRole), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('nav_logout'),
                      tooltip: 'تسجيل الخروج',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String? role) => switch (role) {
        'overall_leader' => 'مسؤول الخدمة',
        'overall_helper' => 'مساعد مسؤول الخدمة',
        'leader' => 'أمين مرحلة',
        'helper' => 'خادم',
        _ => 'مستخدم',
      };
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.profileName, required this.onMenu});
  final String? profileName;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              IconButton(
                key: const Key('nav_menu'),
                tooltip: 'القائمة',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('خدمة تلاميذ المسيح', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              if (profileName != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: CircleAvatar(
                    radius: 18,
                    child: Text(profileName!.trim().substring(0, 1)),
                  ),
                ),
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 8),
                child: SyncStatusWidget(key: Key('sync_status_mobile')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        key: Key('nav_${item.segment}'),
        selected: selected,
        selectedTileColor: scheme.primaryContainer,
        selectedColor: scheme.onPrimaryContainer,
        leading: Icon(item.icon),
        title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
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
