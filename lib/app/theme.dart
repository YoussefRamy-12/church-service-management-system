import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Diakonia Stewardship palette from UI/DESIGN.md.
const appCanvas = Color(0xFFF8F9FF);
const appSurface = Color(0xFFFFFFFF);
const appSurfaceGlass = Color(0xD8FFFFFF);
const appPrimary = Color(0xFF00236F);
const appPrimaryContainer = Color(0xFF1E3A8A);
const appSecondary = Color(0xFF904D00);
const appSecondaryContainer = Color(0xFFF4C27A);
const appTertiary = Color(0xFF059669);
const appAccentCyan = Color(0xFF06B6D4);
const appAccentViolet = Color(0xFF818CF8);
const appSoftBlue = Color(0xFFEFF4FF);
const appMistBlue = Color(0xFFDCE9FF);
const appInk = Color(0xFF0D1C2E);
const appMutedInk = Color(0xFF444651);
const appBorder = Color(0xFFC5C5D3);
const appGlassBorder = Color(0x1F00236F);
const appSuccess = Color(0xFF059669);
const appWarning = Color(0xFF904D00);
const appError = Color(0xFFDC2626);

ThemeData buildAppTheme() {
  const radius = 12.0;
  const controlRadius = 8.0;
  const scheme = ColorScheme.light(
    primary: appPrimary,
    onPrimary: Colors.white,
    primaryContainer: appPrimaryContainer,
    onPrimaryContainer: Colors.white,
    secondary: appSecondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFE8C2),
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
    surfaceContainer: Color(0xFFF1F4FA),
    surfaceContainerHigh: appMistBlue,
    surfaceContainerHighest: Color(0xFFE6EAF2),
    onSurfaceVariant: appMutedInk,
    outline: appMutedInk,
    outlineVariant: appBorder,
    shadow: Color(0x140F172A),
    scrim: Color(0x660F172A),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFFC7D2FE),
    surfaceTint: appPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: appCanvas,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerColor: const Color(0xFFE2E8F0),
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
      fillColor: appSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: Color(0xFFC5C5D3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: appPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: appError, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: appError, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      labelStyle: const TextStyle(
        color: appMutedInk,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: appSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        backgroundColor: appPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: appPrimary,
        side: const BorderSide(color: Color(0xFFC5C5D3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
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
        foregroundColor: appPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: const Color(0x1F0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: appInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      showDragHandle: true,
      dragHandleColor: Color(0xFFCBD5E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0F172A),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: appPrimaryContainer,
      linearTrackColor: appMistBlue,
    ),
    focusColor: appPrimaryContainer.withValues(alpha: 0.12),
    hoverColor: appSoftBlue,
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: appPrimaryContainer,
        selectedForegroundColor: Colors.white,
        foregroundColor: appInk,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
      ),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  const radius = 12.0;
  const controlRadius = 8.0;
  const darkCanvas = Color(0xFF0B1120); // Deep Obsidian Canvas
  const darkSurface = Color(0xFF131D33); // Elevated Midnight Slate
  const darkSurfaceContainer = Color(0xFF1E293B);
  const darkInk = Color(0xFFF8FAFC);
  const darkMutedInk = Color(0xFF94A3B8);
  const darkBorder = Color(0xFF1E293B);
  const darkSubtleBorder = Color(0xFF334155);

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
    dividerColor: darkBorder,
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
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: darkSubtleBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: appAccentViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      labelStyle: const TextStyle(
        color: darkMutedInk,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: appAccentViolet,
        side: const BorderSide(color: darkSubtleBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: darkSubtleBorder, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: darkInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      showDragHandle: true,
      dragHandleColor: Color(0xFF475569),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
      side: const BorderSide(color: darkSubtleBorder, width: 1),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: darkSubtleBorder, width: 1),
      ),
      elevation: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: appAccentViolet,
      linearTrackColor: Color(0xFF1E293B),
    ),
    focusColor: const Color(0xFF4F46E5).withValues(alpha: 0.20),
    hoverColor: const Color(0xFF1E293B),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
      ),
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: const Color(0xFF4F46E5),
        selectedForegroundColor: Colors.white,
        foregroundColor: darkInk,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFamilyFallback: ['Cairo', 'IBM Plex Sans', 'Arial'],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
      ),
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
