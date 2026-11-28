import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_initializer.dart';

Future<void> main() async {
  MarionetteBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const ProviderScope(child: ChurchServiceApp()));
}
