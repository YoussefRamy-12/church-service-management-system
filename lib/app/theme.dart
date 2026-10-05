import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF5B6F8A);

  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: seed,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    fontFamily: 'Arial',
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}
