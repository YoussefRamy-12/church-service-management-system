import 'package:flutter/material.dart';
import '../theme.dart';
export 'role_labels.dart';

/// Applies the shared, quiet canvas behind the application shell.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

/// Solid surface container. Legacy visual parameters remain accepted so existing
/// call sites keep working while rendering stays crisp and predictable.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 16,
    this.opacity = 0.75,
    this.color,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.boxShadow,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Solid High-Contrast Card for dense rosters, forms, and tables
class SolidCard extends StatelessWidget {
  const SolidCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.color,
    this.border,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevation = 0,
  });

  final Widget child;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        color ?? (isDark ? const Color(0xFF131D33) : Colors.white);
    final borderColor =
        border ??
        Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : const Color(0x0F0F172A),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 1.5),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Shared solid card with an optional accessible tap target.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 16,
    this.opacity = 0.80,
    this.color,
    this.padding,
    this.margin,
    this.onTap,
    this.hoverElevation = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hoverElevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      ),
    );
  }
}

/// Smooth Pressable wrapper with micro-scale feedback
class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Modern Pill Badge with a crisp solid status dot (Impeccable craft)
class GlassBadge extends StatelessWidget {
  const GlassBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600
        ? 16.0
        : width < 1000
        ? 24.0
        : 32.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ?? EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32),
          child: child,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 280 || constraints.maxWidth < 420;

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 24),
              child: GlassContainer(
                borderRadius: 16,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 28,
                  vertical: isCompact ? 14 : 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isCompact ? 44 : 64,
                      height: isCompact ? 44 : 64,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: isCompact ? 22 : 30,
                        color: scheme.primary,
                      ),
                    ),
                    SizedBox(height: isCompact ? 10 : 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: (isCompact
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact ? 15 : 18,
                      ),
                    ),
                    if (message != null) ...[
                      SizedBox(height: isCompact ? 4 : 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                            fontSize: isCompact ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                    if (action != null) ...[
                      SizedBox(height: isCompact ? 12 : 20),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = StatusTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? message;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      StatusTone.success => appSuccess,
      StatusTone.warning => appWarning,
      StatusTone.error => scheme.error,
      StatusTone.neutral => scheme.primary,
    };
    return GlassContainer(
      borderRadius: 16,
      opacity: 0.85,
      color: color.withValues(alpha: 0.06),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { neutral, success, warning, error }

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message ?? 'جاري تحميل البيانات',
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          if (message != null) ...[
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
          ],
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              3,
              (index) => GlassContainer(
                width: 190,
                height: 94,
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SkeletonLine(width: 72 + index * 14, height: 12),
                    _SkeletonLine(width: 46 + index * 18, height: 22),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 3 ? 0 : 18),
                  child: Row(
                    children: [
                      const _SkeletonLine(width: 44, height: 44, round: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonLine(width: 120 + index * 12, height: 14),
                            const SizedBox(height: 8),
                            const _SkeletonLine(width: 190, height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatefulWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    this.round = false,
  });

  final double width;
  final double height;
  final bool round;

  @override
  State<_SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<_SkeletonLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.45 + _controller.value * 0.35;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF818CF8).withValues(alpha: opacity * 0.25),
            borderRadius: BorderRadius.circular(widget.round ? 99 : 8),
          ),
        );
      },
    );
  }
}

/// UI/UX Pro Max + Impeccable - Responsive Metric Grid
/// Adapts dynamically to viewport width:
/// - < 520px: 1 column (generous width, high readability, no clipped text)
/// - 520px - 850px: 2 columns
/// - >= 850px: up to 3 or 4 columns (or as many items provided)
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.children,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns;
        if (width < 520) {
          columns = 1;
        } else if (width < 850) {
          columns = 2;
        } else if (width < 1200) {
          columns = children.length >= 4 ? 4 : (children.length >= 3 ? 3 : 2);
        } else {
          columns = children.length >= 4 ? 4 : children.length;
        }

        if (columns == 1) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                SizedBox(width: double.infinity, child: children[i]),
              ],
            ],
          );
        }

        final itemWidth = (width - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

/// UI/UX Pro Max + Impeccable - Responsive Header Row with Action
/// Displays title + optional badge on the start, and action button on the end.
/// On small screens (< 540px), wraps or stacks vertically to prevent overflow.
class ResponsiveHeaderRow extends StatelessWidget {
  const ResponsiveHeaderRow({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 540;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  badge!,
                ],
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );

        if (action == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: titleSection,
          );
        }

        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleSection,
                const SizedBox(height: 12),
                action!,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 16),
              action!,
            ],
          ),
        );
      },
    );
  }
}

/// UI/UX Pro Max - High-impact responsive Metric Card
class ModernMetricCard extends StatelessWidget {
  const ModernMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = SolidCard(
      borderRadius: 14,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: Border.all(
        color: isDark
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.15),
        width: 1.0,
      ),
      color: isDark
          ? color.withValues(alpha: 0.08)
          : color.withValues(alpha: 0.04),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : appMutedInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : appInk,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? const Color(0xFF64748B) : appMutedInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}

/// UI/UX Pro Max - Accessible Search Field with clear action
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.onClear,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                tooltip: 'مسح البحث',
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  controller!.clear();
                  onChanged('');
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}

/// UI/UX Pro Max - Section Header with optional action
class ModernSectionHeader extends StatelessWidget {
  const ModernSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
