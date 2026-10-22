import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_service.dart';

/// Implementation of [ConnectivityService] wrapping `connectivity_plus`.
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none))
      .distinct();
}
