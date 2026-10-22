import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 2026 Trend Palette: Deep Royal Indigo, Electric Indigo, Sacred Amber, Luminous Emerald & Cyan
const appCanvas = Color(0xFFF5F7FC);
const appSurface = Color(0xFFFFFFFF);
const appSurfaceGlass = Color(0xD8FFFFFF);
const appPrimary = Color(0xFF312E81); // Deep Royal Indigo
const appPrimaryContainer = Color(0xFF4F46E5); // Electric Indigo 2026
const appSecondary = Color(0xFFD97706); // Sacred Amber Gold
const appSecondaryContainer = Color(0xFFF59E0B);
const appTertiary = Color(0xFF0D9488); // Cyan Teal
const appAccentCyan = Color(0xFF06B6D4);
const appAccentViolet = Color(0xFF818CF8);
const appSoftBlue = Color(0xFFEEF2FF);
const appMistBlue = Color(0xFFE0E7FF);
const appInk = Color(0xFF0F172A); // Obsidian Slate
const appMutedInk = Color(0xFF475569);
const appBorder = Color(0xFFE2E8F0);
const appGlassBorder = Color(0x334F46E5);
const appSuccess = Color(0xFF10B981);
const appWarning = Color(0xFFF59E0B);
const appError = Color(0xFFEF4444);

ThemeData buildAppTheme() {
  const radius = 16.0;
  const scheme = ColorScheme.light(
    primary: appPrimaryContainer,
    onPrimary: Colors.white,
    primaryContainer: appPrimary,
    onPrimaryContainer: Colors.white,
    secondary: appSecondary,
    onSecondary: Colors.white,
    secondaryContainer: appSecondaryContainer,
    onSecondaryContainer: Color(0xFF451A03),
    tertiary: appTertiary,
    onTertiary: Colors.white,
    error: appError,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: appCanvas,
    onSurface: appInk,
    surfaceContainerLowest: appSurface,
    surfaceContainerLow: appSoftBlue,
    surfaceContainer: Color(0xFFE6EEFF),
    surfaceContainerHigh: appMistBlue,
    surfaceContainerHighest: Color(0xFFD5E3FC),
    onSurfaceVariant: appMutedInk,
    outline: Color(0xFF94A3B8),
    outlineVariant: appBorder,
    shadow: Color(0x140F172A),
    scrim: Color(0x660F172A),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFFC7D2FE),
    surfaceTint: Color(0xFF4F46E5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: appCanvas,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerColor: const Color(0x144F46E5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: appInk,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: appInk,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      headlineLarge: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      headlineMedium: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      headlineSmall: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      titleLarge: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      titleMedium: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      titleSmall: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      bodyLarge: TextStyle(
        color: appInk,
        height: 1.6,
        fontWeight: FontWeight.w500,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      bodyMedium: TextStyle(
        color: appMutedInk,
        height: 1.55,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      bodySmall: TextStyle(
        color: appMutedInk,
        height: 1.45,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      labelSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xF2FFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: appBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: appBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: appPrimaryContainer, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: appError, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: appError, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      labelStyle: const TextStyle(
        color: appMutedInk,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: appSurface.withValues(alpha: 0.90),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x1F4F46E5), width: 1.2),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        backgroundColor: appPrimaryContainer,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: appPrimaryContainer.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: appPrimaryContainer,
        side: const BorderSide(color: Color(0x334F46E5), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: appPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xF7FFFFFF),
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: const Color(0x2E0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x33FFFFFF), width: 1.5),
      ),
      titleTextStyle: const TextStyle(
        color: appInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xF7FFFFFF),
      surfaceTintColor: Colors.transparent,
      elevation: 20,
      showDragHandle: true,
      dragHandleColor: Color(0xFFCBD5E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(appSoftBlue),
      dividerThickness: 1,
      headingTextStyle: TextStyle(
        color: appInk,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      dataTextStyle: TextStyle(
        color: appInk,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? appPrimaryContainer : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: appBorder, width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? appPrimaryContainer : null,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: appSoftBlue,
      selectedColor: appPrimaryContainer,
      secondarySelectedColor: appPrimaryContainer,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: Color(0x1F4F46E5), width: 1),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xF20F172A),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x26FFFFFF), width: 1),
      ),
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: appPrimaryContainer,
      linearTrackColor: appMistBlue,
    ),
  );
}

ThemeData buildAppDarkTheme() {
  const radius = 16.0;
  const darkCanvas = Color(0xFF0B1120); // Deep Obsidian Canvas
  const darkSurface = Color(0xFF131D33); // Elevated Midnight Slate
  const darkSurfaceContainer = Color(0xFF1A2642);
  const darkInk = Color(0xFFF8FAFC);
  const darkMutedInk = Color(0xFF94A3B8);
  const darkBorder = Color(0xFF1E293B);
  const darkGlassBorder = Color(0x33818CF8);

  const scheme = ColorScheme.dark(
    primary: appAccentViolet,
    onPrimary: Color(0xFF0F172A),
    primaryContainer: Color(0xFF4338CA),
    onPrimaryContainer: Colors.white,
    secondary: appSecondaryContainer,
    onSecondary: Color(0xFF451A03),
    secondaryContainer: Color(0xFF78350F),
    onSecondaryContainer: Color(0xFFFEF3C7),
    tertiary: appAccentCyan,
    onTertiary: Color(0xFF083344),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: darkCanvas,
    onSurface: darkInk,
    surfaceContainerLowest: Color(0xFF080D19),
    surfaceContainerLow: darkSurface,
    surfaceContainer: darkSurfaceContainer,
    surfaceContainerHigh: Color(0xFF223154),
    surfaceContainerHighest: Color(0xFF2B3D66),
    onSurfaceVariant: darkMutedInk,
    outline: Color(0xFF64748B),
    outlineVariant: darkBorder,
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    inverseSurface: Color(0xFFF8FAFC),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: appPrimary,
    surfaceTint: appAccentViolet,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: darkCanvas,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerColor: const Color(0x1F818CF8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkInk,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: darkInk,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      headlineLarge: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      headlineMedium: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      headlineSmall: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      titleLarge: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      titleMedium: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      titleSmall: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      bodyLarge: TextStyle(
        color: darkInk,
        height: 1.6,
        fontWeight: FontWeight.w500,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      bodyMedium: TextStyle(
        color: darkMutedInk,
        height: 1.55,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      bodySmall: TextStyle(
        color: darkMutedInk,
        height: 1.45,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      labelSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xCC131D33),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: appAccentViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      labelStyle: const TextStyle(
        color: darkMutedInk,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface.withValues(alpha: 0.88),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkGlassBorder, width: 1.2),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: appAccentViolet,
        side: const BorderSide(color: Color(0x55818CF8), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: appAccentViolet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xF2131D33),
      surfaceTintColor: Colors.transparent,
      elevation: 20,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x33818CF8), width: 1.5),
      ),
      titleTextStyle: const TextStyle(
        color: darkInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xF5131D33),
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      showDragHandle: true,
      dragHandleColor: Color(0xFF475569),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFF1E293B)),
      dividerThickness: 1,
      headingTextStyle: TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      dataTextStyle: TextStyle(
        color: darkInk,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF4F46E5)
            : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: Color(0xFF475569), width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF4F46E5)
            : null,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: const Color(0xFF4F46E5),
      secondarySelectedColor: const Color(0xFF4F46E5),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: Color(0x33818CF8), width: 1),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xF21E293B),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x33818CF8), width: 1),
      ),
      elevation: 10,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: appAccentViolet,
      linearTrackColor: Color(0xFF1E293B),
    ),
  );
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
