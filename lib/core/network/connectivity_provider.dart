import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'connectivity_service_impl.dart';

/// Riverpod provider for [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl();
});

/// Riverpod stream provider for live connectivity state.
final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
