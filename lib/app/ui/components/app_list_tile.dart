import 'package:flutter/material.dart';

/// RTL-aware list row with a comfortable minimum height and optional actions.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.minHeight = 56,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) => ListTile(
        minTileHeight: minHeight < 56 ? 56 : minHeight,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
}
