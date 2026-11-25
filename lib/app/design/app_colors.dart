import 'package:flutter/material.dart';

/// Canonical Warm Navy palette. Feature code should consume ColorScheme/AppColors.
abstract final class AppDesignColors {
  static const lightCanvas = Color(0xFFFAF8F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSubtle = Color(0xFFF1EEE7);
  static const lightInk = Color(0xFF17243A);
  static const lightMutedInk = Color(0xFF46515F);
  static const lightBorder = Color(0xFFD6D0C5);
  static const lightBorderSubtle = Color(0xFFE8E3DA);
  static const primary = Color(0xFF00236F);
  static const darkPrimary = Color(0xFF2563EB);
  static const primaryContainer = Color(0xFF1E3A8A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const lightGold = Color(0xFFB8860B);
  static const darkGold = Color(0xFFC9A227);
  static const lightError = Color(0xFFB91C1C);
  static const darkError = Color(0xFFF87171);
  static const darkCanvas = Color(0xFF0B1120);
  static const darkSurface = Color(0xFF131D33);
  static const darkSurfaceSubtle = Color(0xFF1E293B);
  static const darkInk = Color(0xFFF8FAFC);
  static const darkMutedInk = Color(0xFFC0CAD8);
  static const darkBorder = Color(0xFF64748B);
  static const darkBorderSubtle = Color(0xFF26344B);
}

@immutable
class AppSemanticColors {
  const AppSemanticColors({required this.foreground, required this.background});

  final Color foreground;
  final Color background;

  AppSemanticColors copyWith({Color? foreground, Color? background}) =>
      AppSemanticColors(
        foreground: foreground ?? this.foreground,
        background: background ?? this.background,
      );

  AppSemanticColors lerp(AppSemanticColors other, double t) =>
      AppSemanticColors(
        foreground: Color.lerp(foreground, other.foreground, t)!,
        background: Color.lerp(background, other.background, t)!,
      );
}

/// Semantic foreground/background pairs. All are designed for AA normal text.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.present,
    required this.absent,
    required this.notMarked,
    required this.lateArrival,
    required this.excused,
    required this.pending,
    required this.synced,
    required this.conflict,
    required this.warning,
    required this.accent,
  });

  final AppSemanticColors present;
  final AppSemanticColors absent;
  final AppSemanticColors notMarked;
  final AppSemanticColors lateArrival;
  final AppSemanticColors excused;
  final AppSemanticColors pending;
  final AppSemanticColors synced;
  final AppSemanticColors conflict;
  final AppSemanticColors warning;
  final AppSemanticColors accent;

  static const light = AppColors(
    present: AppSemanticColors(foreground: Color(0xFF166534), background: Color(0xFFDCFCE7)),
    absent: AppSemanticColors(foreground: Color(0xFFB91C1C), background: Color(0xFFFEE2E2)),
    notMarked: AppSemanticColors(foreground: Color(0xFF46515F), background: Color(0xFFF1EEE7)),
    lateArrival: AppSemanticColors(foreground: Color(0xFF92400E), background: Color(0xFFFEF3C7)),
    excused: AppSemanticColors(foreground: Color(0xFF1D4ED8), background: Color(0xFFDBEAFE)),
    pending: AppSemanticColors(foreground: Color(0xFF854D0E), background: Color(0xFFFEF3C7)),
    synced: AppSemanticColors(foreground: Color(0xFF0F766E), background: Color(0xFFCCFBF1)),
    conflict: AppSemanticColors(foreground: Color(0xFFB91C1C), background: Color(0xFFFFE4E6)),
    warning: AppSemanticColors(foreground: Color(0xFF854D0E), background: Color(0xFFFEF3C7)),
    accent: AppSemanticColors(foreground: Color(0xFF0D1B2A), background: Color(0xFFB8860B)),
  );

  static const dark = AppColors(
    present: AppSemanticColors(foreground: Color(0xFF4ADE80), background: Color(0xFF163A2A)),
    absent: AppSemanticColors(foreground: Color(0xFFF87171), background: Color(0xFF451B22)),
    notMarked: AppSemanticColors(foreground: Color(0xFFC0CAD8), background: Color(0xFF1E293B)),
    lateArrival: AppSemanticColors(foreground: Color(0xFFFBBF24), background: Color(0xFF45320E)),
    excused: AppSemanticColors(foreground: Color(0xFF60A5FA), background: Color(0xFF172F52)),
    pending: AppSemanticColors(foreground: Color(0xFFFCD34D), background: Color(0xFF45320E)),
    synced: AppSemanticColors(foreground: Color(0xFF5EEAD4), background: Color(0xFF123C3A)),
    conflict: AppSemanticColors(foreground: Color(0xFFFB7185), background: Color(0xFF4A1D2A)),
    warning: AppSemanticColors(foreground: Color(0xFFFCD34D), background: Color(0xFF45320E)),
    accent: AppSemanticColors(foreground: Color(0xFFC9A227), background: Color(0xFF263044)),
  );

  static AppColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ?? forBrightness(theme.brightness);
  }

  List<AppSemanticColors> get semanticColors => [
        present, absent, notMarked, lateArrival, excused, pending, synced, conflict, warning, accent,
      ];

  /// WCAG 2.x contrast ratio for opaque sRGB colors.
  static double contrastRatio(Color foreground, Color background) {
    final first = foreground.computeLuminance();
    final second = background.computeLuminance();
    final lighter = first > second ? first : second;
    final darker = first > second ? second : first;
    return (lighter + 0.05) / (darker + 0.05);
  }

  @override
  AppColors copyWith({
    AppSemanticColors? present,
    AppSemanticColors? absent,
    AppSemanticColors? notMarked,
    AppSemanticColors? lateArrival,
    AppSemanticColors? excused,
    AppSemanticColors? pending,
    AppSemanticColors? synced,
    AppSemanticColors? conflict,
    AppSemanticColors? warning,
    AppSemanticColors? accent,
  }) => AppColors(
        present: present ?? this.present,
        absent: absent ?? this.absent,
        notMarked: notMarked ?? this.notMarked,
        lateArrival: lateArrival ?? this.lateArrival,
        excused: excused ?? this.excused,
        pending: pending ?? this.pending,
        synced: synced ?? this.synced,
        conflict: conflict ?? this.conflict,
        warning: warning ?? this.warning,
        accent: accent ?? this.accent,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      present: present.lerp(other.present, t),
      absent: absent.lerp(other.absent, t),
      notMarked: notMarked.lerp(other.notMarked, t),
      lateArrival: lateArrival.lerp(other.lateArrival, t),
      excused: excused.lerp(other.excused, t),
      pending: pending.lerp(other.pending, t),
      synced: synced.lerp(other.synced, t),
      conflict: conflict.lerp(other.conflict, t),
      warning: warning.lerp(other.warning, t),
      accent: accent.lerp(other.accent, t),
    );
  }
}
