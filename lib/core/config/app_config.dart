class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Controls whether offline synchronization, local queueing, and background
  /// sync workers are active.
  ///
  /// Effective default is `false` (online-only mode) until the synchronization
  /// engine can be repaired and validated.
  ///
  /// To re-enable offline sync, build with:
  /// `--dart-define=OFFLINE_SYNC_ENABLED=true`
  /// or override [offlineSyncEnabledProvider] in test environments.
  static const bool offlineSyncEnabled = bool.fromEnvironment(
    'OFFLINE_SYNC_ENABLED',
    defaultValue: false,
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
