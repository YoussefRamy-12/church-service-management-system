import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this._prefsFuture);

  final Future<SharedPreferences> _prefsFuture;

  static const _keyThemeMode = 'app_settings_theme_mode';
  static const _keyFontSize = 'app_settings_font_size';
  static const _keyLanguageCode = 'app_settings_language_code';

  @override
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await _prefsFuture;
      final themeStr = prefs.getString(_keyThemeMode);
      final fontStr = prefs.getString(_keyFontSize);
      final langStr = prefs.getString(_keyLanguageCode) ?? 'ar';

      return AppSettings(
        themeMode: AppThemeMode.fromString(themeStr),
        fontSize: AppFontSize.fromString(fontStr),
        languageCode: langStr,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(_keyThemeMode, themeMode.name);
    } catch (_) {}
  }

  @override
  Future<void> saveFontSize(AppFontSize fontSize) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(_keyFontSize, fontSize.name);
    } catch (_) {}
  }

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(_keyLanguageCode, languageCode);
    } catch (_) {}
  }
}

