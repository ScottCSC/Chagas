import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Expone estado de conectividad para banner "Sin conexión" y para evitar
/// refresh token / requests cuando no hay internet.
class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final Connectivity _connectivity = Connectivity();

  /// Estado actual (cache del último resultado conocido).
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Stream de cambios de conectividad (true = online, false = offline).
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map(_resultToBool)
      .distinct()
      .asyncMap((_) async {
    _isOnline = await checkConnectivity();
    return _isOnline;
  });

  static bool _resultToBool(List<ConnectivityResult> result) {
    if (result.isEmpty) return true;
    if (result.length == 1 && result.single == ConnectivityResult.none) return false;
    return result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);
  }

  /// Comprueba ahora si hay conexión (útil antes de refresh token o requests).
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _resultToBool(result);
      return _isOnline;
    } catch (_) {
      _isOnline = false;
      return false;
    }
  }

  /// Inicializar: actualiza _isOnline con el estado actual.
  Future<void> init() async {
    _isOnline = await checkConnectivity();
  }
}
