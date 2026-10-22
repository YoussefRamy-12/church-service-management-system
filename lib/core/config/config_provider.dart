import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Centralized Riverpod provider for the synchronization feature flag.
///
/// Default value resolves to [AppConfig.offlineSyncEnabled], which is `false`
/// for online-only operation in the current release.
final offlineSyncEnabledProvider = Provider<bool>((ref) {
  return AppConfig.offlineSyncEnabled;
});
