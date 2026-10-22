import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
export 'role_labels.dart';

/// Full-canvas Ambient Background that renders soft, luminous 2026 gradient orbs.
/// Frosted glass surfaces placed over this glow with rich translucent color.
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
    return Stack(
      children: [
        // Base canvas
        Positioned.fill(
          child: Container(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        // Ambient soft gradient orbs
        Positioned(
          top: -120,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.16 * intensity),
                    const Color(0xFF818CF8).withValues(alpha: 0.06 * intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: IgnorePointer(
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: 0.12 * intensity),
                    const Color(0xFF38BDF8).withValues(alpha: 0.04 * intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: 120,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.07 * intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Child content
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Frosted Glass Container with backdrop blur, crystalline gradient border, and shadow.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF131D33) : Colors.white;
    final effectiveColor = (color ?? defaultBg).withValues(alpha: opacity);
    final effectiveBorder =
        border ??
        Border.all(
          color: isDark
              ? const Color(0x33818CF8)
              : Colors.white.withValues(alpha: 0.65),
          width: 1.2,
        );

    Widget content = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    final defaultShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : const Color(0xFF0F172A).withValues(alpha: 0.06);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: defaultShadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: content,
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

/// Interactive 2026 Glass Card with subtle hover lift and micro-animation.
class GlassCard extends StatefulWidget {
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
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF131D33) : Colors.white;
    final scale = _pressed
        ? 0.985
        : (_hovered && widget.hoverElevation ? 1.012 : 1.0);

    return MouseRegion(
      onEnter: (_) {
        if (isInteractive || widget.hoverElevation) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (isInteractive || widget.hoverElevation) {
          setState(() => _hovered = false);
        }
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? (isDark
                            ? const Color(0xFF818CF8).withValues(alpha: 0.16)
                            : const Color(0xFF4F46E5).withValues(alpha: 0.12))
                      : (isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : const Color(0xFF0F172A).withValues(alpha: 0.05)),
                  blurRadius: _hovered ? 26 : 18,
                  offset: Offset(0, _hovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blur,
                  sigmaY: widget.blur,
                ),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (widget.color ?? defaultBg).withValues(
                      alpha: _hovered
                          ? (widget.opacity + 0.06).clamp(0.0, 1.0)
                          : widget.opacity,
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: _hovered
                          ? (isDark
                                ? const Color(0xFF818CF8).withValues(alpha: 0.6)
                                : const Color(
                                    0xFF4F46E5,
                                  ).withValues(alpha: 0.45))
                          : (isDark
                                ? const Color(0x33818CF8)
                                : Colors.white.withValues(alpha: 0.70)),
                      width: _hovered ? 1.4 : 1.2,
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
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

/// Modern Glass Pill Badge with a glowing status dot
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassContainer(
          borderRadius: 24,
          opacity: 0.82,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.15),
                      scheme.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(icon, size: 34, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.55,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
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
