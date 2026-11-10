import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveThemeMode(AppThemeMode themeMode);
  Future<void> saveFontSize(AppFontSize fontSize);
  Future<void> saveLanguageCode(String languageCode);
}

