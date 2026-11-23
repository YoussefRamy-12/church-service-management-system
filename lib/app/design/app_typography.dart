import 'package:flutter/material.dart';

/// Arabic-first type scale: Cairo headings and IBM Plex Sans Arabic body text.
abstract final class AppTypography {
  static const String headingFamily = 'Cairo';
  static const String bodyFamily = 'IBM Plex Sans Arabic';

  static TextTheme textTheme(Brightness brightness) {
    final ink = brightness == Brightness.dark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF17243A);
    final muted = brightness == Brightness.dark
        ? const Color(0xFFC0CAD8)
        : const Color(0xFF46515F);

    TextStyle heading(double size, FontWeight weight, double height) => TextStyle(
          fontFamily: headingFamily,
          fontFamilyFallback: const [bodyFamily, 'Arial'],
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: ink,
        );
    TextStyle body(double size, FontWeight weight, double height, Color color) =>
        TextStyle(
          fontFamily: bodyFamily,
          fontFamilyFallback: const [headingFamily, 'Arial'],
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color,
        );

    return TextTheme(
      displayLarge: heading(32, FontWeight.w800, 1.20),
      displayMedium: heading(28, FontWeight.w700, 1.22),
      displaySmall: heading(26, FontWeight.w700, 1.25),
      headlineLarge: heading(26, FontWeight.w700, 1.25),
      headlineMedium: heading(24, FontWeight.w700, 1.28),
      headlineSmall: heading(22, FontWeight.w700, 1.30),
      titleLarge: heading(20, FontWeight.w700, 1.35),
      titleMedium: body(16, FontWeight.w600, 1.40, ink),
      titleSmall: body(14, FontWeight.w600, 1.40, ink),
      bodyLarge: body(16, FontWeight.w400, 1.50, ink),
      bodyMedium: body(14, FontWeight.w400, 1.50, ink),
      bodySmall: body(13, FontWeight.w400, 1.45, muted),
      labelLarge: body(14, FontWeight.w600, 1.35, ink),
      labelMedium: body(12, FontWeight.w600, 1.35, muted),
      labelSmall: body(12, FontWeight.w500, 1.40, muted),
    );
  }
}
