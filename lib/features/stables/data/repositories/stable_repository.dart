import 'package:vacapp/features/stables/data/datasources/stables_service.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:vacapp/core/services/connectivity_service.dart';
import 'package:vacapp/core/services/offline_data_service.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:flutter/foundation.dart';

class StableRepository {
  final StablesService _stablesService;
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineDataService _offlineService = OfflineDataService();

  StableRepository(this._stablesService);

  Future<List<StableDto>> getStables() async {
    try {
      // Si hay conexión, intentar obtener datos del servidor
      if (_connectivityService.isConnected) {
        final stables = await _stablesService.fetchStables();
        
        // Guardar en el sistema offline
        for (final stable in stables) {
          await _offlineService.saveStableOffline(_mapToOfflineFormat(stable));
        }
        
        // Marcar que hay datos offline disponibles
        if (stables.isNotEmpty) {
          await TokenService.instance.setHasOfflineData(true);
        }
        
        return stables;
      } else {
        // Sin conexión, usar datos offline
        final offlineData = await _offlineService.getStablesOffline();
        if (offlineData.isNotEmpty) {
          return offlineData.map((data) => _mapFromOfflineFormat(data)).toList();
        }
        
        return [];
      }
    } catch (e) {
      debugPrint('Error in getStables: $e');
      
      // En caso de error, intentar usar datos offline
      try {
        final offlineData = await _offlineService.getStablesOffline();
        if (offlineData.isNotEmpty) {
          return offlineData.map((data) => _mapFromOfflineFormat(data)).toList();
        }
        
        return [];
      } catch (offlineError) {
        debugPrint('Error accessing offline stables: $offlineError');
        return [];
      }
    }
  }
  
  // Crear un establo
  Future<StableDto> createStable(StableDto stable) async {
    try {
      if (_connectivityService.isConnected) {
        final createdStable = await _stablesService.createStable(stable);
        await getStables(); // Actualizar caché
        return createdStable;
      } else {
        // Sin conexión, guardar offline
        await _offlineService.saveStableOffline(_mapToOfflineFormat(stable));
        await TokenService.instance.setHasOfflineData(true);
        debugPrint('Establo guardado offline para sincronización posterior');
        return stable; // Devolver el establo original con ID temporal
      }
    } catch (e) {
      // En caso de error, guardar offline
      await _offlineService.saveStableOffline(_mapToOfflineFormat(stable));
      await TokenService.instance.setHasOfflineData(true);
      debugPrint('Error creating stable, saved offline: $e');
      rethrow;
    }
  }

  // Actualizar un establo
  Future<void> updateStable(int id, StableDto stable) async {
    try {
      if (_connectivityService.isConnected) {
        await _stablesService.updateStable(id, stable);
        await getStables();
      } else {
        // Sin conexión, guardar cambios offline
        final stableWithId = StableDto(id: id, name: stable.name, limit: stable.limit);
        await _offlineService.saveStableOffline(_mapToOfflineFormat(stableWithId));
        await TokenService.instance.setHasOfflineData(true);
        debugPrint('Stable update guardado offline para sincronización posterior');
      }
    } catch (e) {
      // En caso de error, guardar offline
      final stableWithId = StableDto(id: id, name: stable.name, limit: stable.limit);
      await _offlineService.saveStableOffline(_mapToOfflineFormat(stableWithId));
      await TokenService.instance.setHasOfflineData(true);
      debugPrint('Error updating stable, saved offline: $e');
      rethrow;
    }
  }

  // Eliminar un establo
  Future<void> deleteStable(int id) async {
    try {
      if (_connectivityService.isConnected) {
        await _stablesService.deleteStable(id);
        await getStables();
      } else {
        debugPrint('Stable deletion will be synced when connection is restored');
        throw Exception('No se puede eliminar sin conexión. Intenta cuando tengas internet.');
      }
    } catch (e) {
      debugPrint('Error deleting stable: $e');
      rethrow;
    }
  }

  // Obtener un establo por ID
  Future<StableDto> getStableById(int id) async {
    try {
      if (_connectivityService.isConnected) {
        return await _stablesService.fetchStableById(id);
      } else {
        // Buscar en datos offline
        final offlineStables = await _offlineService.getStablesOffline();
        final stable = offlineStables.firstWhere(
          (data) => data['id'] == id || data['server_id'] == id,
          orElse: () => throw Exception('Establo no encontrado offline'),
        );
        return _mapFromOfflineFormat(stable);
      }
    } catch (e) {
      debugPrint('Error getting stable by ID: $e');
      rethrow;
    }
  }

  /// Verificar si hay datos offline disponibles
  Future<bool> hasOfflineData() async {
    try {
      final offlineStables = await _offlineService.getStablesOffline();
      return offlineStables.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mapear StableDto al formato del OfflineDataService
  Map<String, dynamic> _mapToOfflineFormat(StableDto stable) {
    return {
      'server_id': stable.id,
      'name': stable.name,
      'location': '', // StableDto no tiene location, usar valor por defecto
      'capacity': stable.limit,
      'description': '', // StableDto no tiene description, usar valor por defecto
    };
  }

  /// Mapear del formato offline a StableDto
  StableDto _mapFromOfflineFormat(Map<String, dynamic> data) {
    return StableDto(
      id: data['server_id'] ?? data['id'] ?? 0,
      name: data['name'] ?? '',
      limit: data['capacity'] ?? data['limit'] ?? 0,
    );
  }
}