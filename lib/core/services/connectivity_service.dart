import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Stream controller para notificar cambios de conectividad
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Inicializar el servicio de conectividad
  Future<void> initialize() async {
    // Verificar estado inicial
    await _checkConnectivity();
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Verificar el estado actual de conectividad
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected = false;
      _connectivityController.add(false);
    }
  }

  /// Actualizar el estado de conexión
  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    bool connected = connectivityResult.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectivityController.add(connected);
      debugPrint('Connectivity changed: ${connected ? "Connected" : "Disconnected"}');
    }
  }

  /// Verificar manualmente la conectividad
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Limpiar recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
