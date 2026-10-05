import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!AppConfig.isConfigured) {
    throw StateError(
      'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
    );
  }

  return Supabase.instance.client;
});
