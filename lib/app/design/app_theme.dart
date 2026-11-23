import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Builds the canonical Warm Navy Material 3 themes.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? AppDesignColors.darkCanvas : AppDesignColors.lightCanvas;
    final surface = isDark ? AppDesignColors.darkSurface : AppDesignColors.lightSurface;
    final subtleSurface = isDark
        ? AppDesignColors.darkSurfaceSubtle
        : AppDesignColors.lightSurfaceSubtle;
    final ink = isDark ? AppDesignColors.darkInk : AppDesignColors.lightInk;
    final mutedInk = isDark ? AppDesignColors.darkMutedInk : AppDesignColors.lightMutedInk;
    final border = isDark ? AppDesignColors.darkBorder : AppDesignColors.lightBorder;
    final focus = isDark ? const Color(0xFF93C5FD) : AppDesignColors.primaryContainer;
    final error = isDark ? AppDesignColors.darkError : AppDesignColors.lightError;
    final gold = isDark ? AppDesignColors.darkGold : AppDesignColors.lightGold;
    final semanticColors = AppColors.forBrightness(brightness);
    final actionForeground = isDark ? ink : AppDesignColors.primary;
    final selectedNavigationColor = isDark ? ink : AppDesignColors.primary;

    final scheme = isDark
        ? ColorScheme.dark(
            primary: AppDesignColors.primary,
            onPrimary: AppDesignColors.onPrimary,
            primaryContainer: AppDesignColors.primaryContainer,
            onPrimaryContainer: AppDesignColors.onPrimary,
            secondary: gold,
            onSecondary: const Color(0xFF0D1B2A),
            secondaryContainer: const Color(0xFF4B3A13),
            onSecondaryContainer: const Color(0xFFF8E7A8),
            tertiary: const Color(0xFF5EEAD4),
            onTertiary: AppDesignColors.darkCanvas,
            error: error,
            onError: const Color(0xFF450A0A),
            errorContainer: const Color(0xFF7F1D1D),
            onErrorContainer: const Color(0xFFFEE2E2),
            surface: surface,
            onSurface: ink,
            surfaceContainerLowest: canvas,
            surfaceContainerLow: surface,
            surfaceContainer: subtleSurface,
            surfaceContainerHigh: const Color(0xFF26344B),
            surfaceContainerHighest: const Color(0xFF334155),
            onSurfaceVariant: mutedInk,
            outline: const Color(0xFF94A3B8),
            outlineVariant: border,
            shadow: const Color(0x3D000000),
            scrim: const Color(0x99000000),
            inverseSurface: AppDesignColors.darkInk,
            onInverseSurface: AppDesignColors.darkCanvas,
            inversePrimary: AppDesignColors.primary,
            surfaceTint: AppDesignColors.primary,
          )
        : ColorScheme.light(
            primary: AppDesignColors.primary,
            onPrimary: AppDesignColors.onPrimary,
            primaryContainer: AppDesignColors.primaryContainer,
            onPrimaryContainer: AppDesignColors.onPrimary,
            secondary: gold,
            onSecondary: const Color(0xFF0D1B2A),
            secondaryContainer: const Color(0xFFF4E5C1),
            onSecondaryContainer: const Color(0xFF0D1B2A),
            tertiary: const Color(0xFF0F766E),
            onTertiary: Colors.white,
            error: error,
            onError: Colors.white,
            errorContainer: const Color(0xFFFEE2E2),
            onErrorContainer: const Color(0xFF7F1D1D),
            surface: surface,
            onSurface: ink,
            surfaceContainerLowest: surface,
            surfaceContainerLow: subtleSurface,
            surfaceContainer: subtleSurface,
            surfaceContainerHigh: const Color(0xFFE8E3DA),
            surfaceContainerHighest: border,
            onSurfaceVariant: mutedInk,
            outline: mutedInk,
            outlineVariant: border,
            shadow: const Color(0x140F172A),
            scrim: const Color(0x660F172A),
            inverseSurface: const Color(0xFF1E293B),
            onInverseSurface: const Color(0xFFF8FAFC),
            inversePrimary: const Color(0xFFC7D2FE),
            surfaceTint: AppDesignColors.primary,
          );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    final borderSide = BorderSide(color: scheme.outlineVariant);
    final focusSide = BorderSide(color: focus, width: 2);
    final errorSide = BorderSide(color: error, width: 1.5);
    final textTheme = AppTypography.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: scheme.outlineVariant,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: subtleSurface,
          disabledForegroundColor: mutedInk,
          elevation: 0,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          foregroundColor: actionForeground,
          side: borderSide,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: actionForeground,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: focusSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: errorSide,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedInk),
        labelStyle: textTheme.labelLarge?.copyWith(color: mutedInk),
        helperStyle: textTheme.bodySmall?.copyWith(color: mutedInk),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: borderSide,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: subtleSurface,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: textTheme.labelMedium!,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: borderSide,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: mutedInk,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => textTheme.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected) ? selectedNavigationColor : mutedInk,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : mutedInk,
          size: 22,
        )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        minWidth: 80,
        groupAlignment: -1,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: mutedInk),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: selectedNavigationColor),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: mutedInk),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: borderSide,
        ),
        titleTextStyle: textTheme.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bottomSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
        elevation: 2,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(subtleSurface),
        dividerThickness: 1,
        headingTextStyle: textTheme.labelLarge,
        dataTextStyle: textTheme.bodyMedium,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? scheme.primary : null),
        side: borderSide,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? scheme.onPrimary : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? scheme.primaryContainer : null),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: subtleSurface,
      ),
      focusColor: focus.withValues(alpha: 0.12),
      hoverColor: subtleSurface,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        textStyle: textTheme.labelSmall?.copyWith(color: scheme.onInverseSurface),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          foregroundColor: ink,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
    );
  }
}
