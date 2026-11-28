import 'package:flutter/material.dart';

/// Shared viewport breakpoints for app and feature layouts.
abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double desktop = 1100;
}

extension AppResponsiveContext on BuildContext {
  double get viewportWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => viewportWidth < AppBreakpoints.mobile;
  bool get isTablet =>
      viewportWidth >= AppBreakpoints.mobile &&
      viewportWidth < AppBreakpoints.desktop;
  bool get isDesktop => viewportWidth >= AppBreakpoints.desktop;

  EdgeInsetsDirectional get adaptivePagePadding {
    final horizontal = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    return EdgeInsetsDirectional.fromSTEB(horizontal, 16, horizontal, 32);
  }
}

/// Centers content, constrains its readable width and applies adaptive padding.
class MaxWidthContainer extends StatelessWidget {
  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding ?? context.adaptivePagePadding,
            child: child,
          ),
        ),
      );
}
