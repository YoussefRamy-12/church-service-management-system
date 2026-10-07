import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF4F6F52);
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  const radius = 14.0;
  return ThemeData(
    useMaterial3: true, colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF7F8F7),
    visualDensity: VisualDensity.standard, materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(backgroundColor: const Color(0xFFF7F8F7), foregroundColor: scheme.onSurface,
      elevation: 0, centerTitle: false, scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 21, fontWeight: FontWeight.w800)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: scheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: scheme.error, width: 2))),
    cardTheme: const CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)))),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 10, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(0, 44))),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide.none),
  );
}
