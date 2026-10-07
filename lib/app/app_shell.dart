import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/sync/sync_status_widget.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.serviceId, required this.child});
  final String serviceId;
  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('الرئيسية', Icons.dashboard_outlined, 'dashboard'),
    _NavItem('التلاميذ', Icons.school_outlined, 'students'),
    _NavItem('الحضور', Icons.fact_check_outlined, 'attendance'),
    _NavItem('المتابعة', Icons.history_edu_outlined, 'follow-up'),
    _NavItem('التقارير', Icons.bar_chart_outlined, 'reports'),
    _NavItem('الخدام', Icons.people_alt_outlined, 'servants'),
    _NavItem('التصدير', Icons.download_outlined, 'export'),
    _NavItem('الإعدادات', Icons.settings_outlined, 'settings'),
  ];

  void _go(BuildContext context, String segment) =>
      context.go('/service/' + serviceId + '/' + segment);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final compact = MediaQuery.sizeOf(context).width < 900;
    return Scaffold(
      body: Row(children: [
        if (!compact)
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              width: 248,
              child: SafeArea(
                child: Column(children: [
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Row(children: [
                      Icon(Icons.church),
                      SizedBox(width: 10),
                      Expanded(child: Text('خدمة تلاميذ المسيح',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      children: [
                        for (final item in _items)
                          _NavTile(
                            item: item,
                            selected: location.endsWith('/' + item.segment),
                            onTap: () => _go(context, item.segment),
                          ),
                        const SizedBox(height: 12),
                        const SyncStatusWidget(key: Key('sync_status')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      key: const Key('nav_logout'),
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        Expanded(
          child: Column(children: [
            if (compact)
              SafeArea(
                bottom: false,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(children: [
                    IconButton(
                      key: const Key('nav_menu'),
                      onPressed: () => _showNavigation(context),
                      icon: const Icon(Icons.menu),
                    ),
                    const Expanded(
                      child: Text('خدمة تلاميذ المسيح',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 8),
                      child: SyncStatusWidget(key: Key('sync_status_mobile')),
                    ),
                  ]),
                ),
              ),
            Expanded(child: child),
          ]),
        ),
      ]),
    );
  }

  void _showNavigation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in _items)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  _go(context, item.segment);
                },
              ),
          ],
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          key: Key('nav_' + item.segment),
          selected: selected,
          leading: Icon(item.icon),
          title: Text(item.label),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      );
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.segment);
  final String label;
  final IconData icon;
  final String segment;
}