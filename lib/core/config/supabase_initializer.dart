import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

Future<void> initializeSupabase() async {
  if (!AppConfig.isConfigured) {
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
}
