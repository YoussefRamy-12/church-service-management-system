import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/preferences_settings_repository.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

final sharedPreferencesProvider = Provider<Future<SharedPreferences>>((ref) {
  return SharedPreferences.getInstance();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefsFuture = ref.watch(sharedPreferencesProvider);
  return PreferencesSettingsRepository(prefsFuture);
});

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final loaded = await repo.loadSettings();
    state = loaded;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
  }

  Future<void> setFontSize(AppFontSize size) async {
    state = state.copyWith(fontSize: size);
    await ref.read(settingsRepositoryProvider).saveFontSize(size);
  }

  Future<void> setLanguageCode(String lang) async {
    state = state.copyWith(languageCode: lang);
    await ref.read(settingsRepositoryProvider).saveLanguageCode(lang);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

final appFontSizeProvider = Provider<AppFontSize>((ref) {
  return ref.watch(appSettingsProvider).fontSize;
});

final textScalerProvider = Provider<TextScaler>((ref) {
  final fontSize = ref.watch(appFontSizeProvider);
  return TextScaler.linear(fontSize.scaleFactor);
});

