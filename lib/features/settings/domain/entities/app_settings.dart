import 'package:flutter/material.dart';

/// Available theme modes for the application.
enum AppThemeMode {
  system('تلقائي (حسب النظام)', ThemeMode.system, Icons.brightness_auto_rounded),
  light('فاتح', ThemeMode.light, Icons.light_mode_rounded),
  dark('داكن', ThemeMode.dark, Icons.dark_mode_rounded);

  const AppThemeMode(this.label, this.mode, this.icon);

  final String label;
  final ThemeMode mode;
  final IconData icon;

  static AppThemeMode fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}

/// Available text scaling options for Arabic typography.
enum AppFontSize {
  small(0.85, 'صغير (85%)'),
  normal(1.0, 'طبيعي - افتراضي (100%)'),
  large(1.15, 'كبير (115%)'),
  extraLarge(1.30, 'كبير جداً (130%)');

  const AppFontSize(this.scaleFactor, this.label);

  final double scaleFactor;
  final String label;

  static AppFontSize fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'small' => AppFontSize.small,
      'large' => AppFontSize.large,
      'extralarge' || 'extra_large' => AppFontSize.extraLarge,
      _ => AppFontSize.normal,
    };
  }
}

/// Consolidated application settings model.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.fontSize = AppFontSize.normal,
    this.languageCode = 'ar',
  });

  final AppThemeMode themeMode;
  final AppFontSize fontSize;
  final String languageCode;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppFontSize? fontSize,
    String? languageCode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          fontSize == other.fontSize &&
          languageCode == other.languageCode;

  @override
  int get hashCode => Object.hash(themeMode, fontSize, languageCode);
}

