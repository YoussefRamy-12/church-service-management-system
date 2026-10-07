import 'package:flutter/material.dart';

class AppContent extends StatelessWidget {
  const AppContent({super.key, required this.child, this.maxWidth = 1100, this.padding});
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 16.0 : width < 1000 ? 24.0 : 32.0;
    return Center(child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding ?? EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32), child: child),
    ));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon; final String title; final String? message; final Widget? action;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
          child: Icon(icon, size: 30, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        if (message != null) ...[const SizedBox(height: 6), Text(message!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant))],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    ));
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.icon, required this.title, this.message, this.tone = StatusTone.neutral});
  final IconData icon; final String title; final String? message; final StatusTone tone;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      StatusTone.success => scheme.primary,
      StatusTone.warning => scheme.tertiary,
      StatusTone.error => scheme.error,
      StatusTone.neutral => scheme.onSurfaceVariant,
    };
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
      color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .18))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (message != null) ...[const SizedBox(height: 2), Text(message!)],
        ])),
      ]));
  }
}
enum StatusTone { neutral, success, warning, error }

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(), if (message != null) ...[const SizedBox(height: 12), Text(message!, textAlign: TextAlign.center)],
  ])));
}
