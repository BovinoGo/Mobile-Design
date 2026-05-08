import 'dart:async';
import 'connectivity_service.dart';
import 'offline_data_service.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineDataService _offlineService = OfflineDataService();
  final NotificationService _notificationService = NotificationService();

  late StreamSubscription<bool> _connectivitySubscription;
  bool _isSyncing = false;
  bool _hasUnsyncedData = false;

  /// Stream controller para notificar estado de sincronización
  final StreamController<SyncStatus> _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStream => _syncController.stream;

  /// Inicializar el servicio de sincronización
  Future<void> initialize() async {
    await _connectivityService.initialize();
    
    // Verificar si hay datos no sincronizados
    await _checkUnsyncedData();
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected && _hasUnsyncedData && !_isSyncing) {
        _syncDataWhenConnected();
      }
    });
  }

  /// Verificar si hay datos no sincronizados
  Future<void> _checkUnsyncedData() async {
    final unsyncedData = await _offlineService.getUnsyncedData();
    _hasUnsyncedData = unsyncedData.values.any((list) => list.isNotEmpty);
    
    if (_hasUnsyncedData) {
      _syncController.add(SyncStatus.pending);
    }
  }

  /// Sincronizar datos cuando se conecta
  Future<void> _syncDataWhenConnected() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncController.add(SyncStatus.syncing);
    
    try {
      await _performSync();
      _hasUnsyncedData = false;
      _syncController.add(SyncStatus.completed);
      
      // Mostrar notificación de sincronización exitosa
      await _notificationService.showConnectionRestoredNotification();
      
    } catch (e) {
      debugPrint('Error during sync: $e');
      _syncController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Realizar sincronización completa
  Future<void> _performSync() async {
    final unsyncedData = await _offlineService.getUnsyncedData();
    
    // Sincronizar establos primero (pueden ser referenciados por animales)
    await _syncStables(unsyncedData['stables'] ?? []);
    
    // Sincronizar animales
    await _syncAnimals(unsyncedData['animals'] ?? []);
    
    // Sincronizar vacunas
    await _syncVaccines(unsyncedData['vaccines'] ?? []);
    
    // Sincronizar campañas
    await _syncCampaigns(unsyncedData['campaigns'] ?? []);
    
    // Sincronizar staff
    await _syncStaff(unsyncedData['staff'] ?? []);
    
    // Limpiar caché expirado
    await _offlineService.clearExpiredCache();
  }

  /// Sincronizar establos
  Future<void> _syncStables(List<Map<String, dynamic>> stables) async {
    for (final stable in stables) {
      try {
        // Aquí harías la llamada a tu API
        // final response = await ApiService.createStable(stable);
        // await _offlineService.markAsSynced('stables', stable['id'], response['id']);
        
        // Por ahora, solo simulamos la sincronización
        await Future.delayed(const Duration(milliseconds: 100));
        await _offlineService.markAsSynced('stables', stable['id'], stable['id'] + 1000);
      } catch (e) {
        debugPrint('Error syncing stable ${stable['id']}: $e');
      }
    }
  }

  /// Sincronizar animales
  Future<void> _syncAnimals(List<Map<String, dynamic>> animals) async {
    for (final animal in animals) {
      try {
        // Aquí harías la llamada a tu API
        // final response = await ApiService.createAnimal(animal);
        // await _offlineService.markAsSynced('animals', animal['id'], response['id']);
        
        // Por ahora, solo simulamos la sincronización
        await Future.delayed(const Duration(milliseconds: 100));
        await _offlineService.markAsSynced('animals', animal['id'], animal['id'] + 1000);
      } catch (e) {
        debugPrint('Error syncing animal ${animal['id']}: $e');
      }
    }
  }

  /// Sincronizar vacunas
  Future<void> _syncVaccines(List<Map<String, dynamic>> vaccines) async {
    for (final vaccine in vaccines) {
      try {
        // Aquí harías la llamada a tu API
        // final response = await ApiService.createVaccine(vaccine);
        // await _offlineService.markAsSynced('vaccines', vaccine['id'], response['id']);
        
        // Por ahora, solo simulamos la sincronización
        await Future.delayed(const Duration(milliseconds: 100));
        await _offlineService.markAsSynced('vaccines', vaccine['id'], vaccine['id'] + 1000);
      } catch (e) {
        debugPrint('Error syncing vaccine ${vaccine['id']}: $e');
      }
    }
  }

  /// Sincronizar campañas
  Future<void> _syncCampaigns(List<Map<String, dynamic>> campaigns) async {
    for (final campaign in campaigns) {
      try {
        // Aquí harías la llamada a tu API
        // final response = await ApiService.createCampaign(campaign);
        // await _offlineService.markAsSynced('campaigns', campaign['id'], response['id']);
        
        // Por ahora, solo simulamos la sincronización
        await Future.delayed(const Duration(milliseconds: 100));
        await _offlineService.markAsSynced('campaigns', campaign['id'], campaign['id'] + 1000);
      } catch (e) {
        debugPrint('Error syncing campaign ${campaign['id']}: $e');
      }
    }
  }

  /// Sincronizar staff
  Future<void> _syncStaff(List<Map<String, dynamic>> staff) async {
    for (final member in staff) {
      try {
        // Aquí harías la llamada a tu API
        // final response = await ApiService.createStaffMember(member);
        // await _offlineService.markAsSynced('staff', member['id'], response['id']);
        
        // Por ahora, solo simulamos la sincronización
        await Future.delayed(const Duration(milliseconds: 100));
        await _offlineService.markAsSynced('staff', member['id'], member['id'] + 1000);
      } catch (e) {
        debugPrint('Error syncing staff member ${member['id']}: $e');
      }
    }
  }

  /// Forzar sincronización manual
  Future<void> forcSync() async {
    if (!_connectivityService.isConnected) {
      throw Exception('No hay conexión a internet');
    }
    
    await _syncDataWhenConnected();
  }

  /// Guardar datos para uso offline
  Future<void> saveForOffline(String dataType, Map<String, dynamic> data) async {
    switch (dataType) {
      case 'animal':
        await _offlineService.saveAnimalOffline(data);
        break;
      case 'vaccine':
        await _offlineService.saveVaccineOffline(data);
        break;
      case 'stable':
        await _offlineService.saveStableOffline(data);
        break;
      case 'campaign':
        await _offlineService.saveCampaignOffline(data);
        break;
    }
    
    _hasUnsyncedData = true;
    _syncController.add(SyncStatus.pending);
  }

  /// Obtener datos para modo offline
  Future<Map<String, dynamic>> getOfflineData() async {
    return {
      'animals': await _offlineService.getAnimalsOffline(),
      'vaccines': await _offlineService.getVaccinesOffline(),
      'stables': await _offlineService.getStablesOffline(),
      'campaigns': await _offlineService.getCampaignsOffline(),
      'stats': await _offlineService.getOfflineStats(),
    };
  }

  /// Verificar si hay datos guardados offline
  Future<bool> hasOfflineData() async {
    final stats = await _offlineService.getOfflineStats();
    return stats.values.any((count) => count > 0);
  }

  /// Obtener estado de sincronización
  SyncStatus get currentSyncStatus {
    if (_isSyncing) return SyncStatus.syncing;
    if (_hasUnsyncedData) return SyncStatus.pending;
    return SyncStatus.completed;
  }

  /// Limpiar todos los datos offline
  Future<void> clearOfflineData() async {
    await _offlineService.clearAllOfflineData();
    _hasUnsyncedData = false;
    _syncController.add(SyncStatus.completed);
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _syncController.close();
  }
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  error,
}
