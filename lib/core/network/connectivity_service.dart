/// Abstract contract for checking network connectivity.
/// Decouples features and sync mechanisms from concrete plugins (DIP).
abstract interface class ConnectivityService {
  /// Checks whether network connection is currently available.
  Future<bool> get isOnline;

  /// Stream of online status changes (true if online, false if offline).
  Stream<bool> get onConnectivityChanged;
}
