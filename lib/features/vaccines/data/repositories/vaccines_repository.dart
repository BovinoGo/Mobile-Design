import 'dart:io';

import 'package:vacapp/features/vaccines/data/datasources/vaccines_services.dart';
import 'package:vacapp/features/vaccines/data/models/vaccines_dto.dart';
import 'package:vacapp/core/services/connectivity_service.dart';
import 'package:vacapp/core/services/offline_data_service.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:flutter/foundation.dart';

class VaccinesRepository {
  final VaccinesService _vaccinesService;
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineDataService _offlineService = OfflineDataService();

  VaccinesRepository(this._vaccinesService);

  Future<List<VaccinesDto>> getVaccines() async {
    debugPrint('🔍 [DEBUG] Repositorio: Iniciando getVaccines...');
    try {
      // Si hay conexión, intentar obtener datos del servidor
      if (_connectivityService.isConnected) {
        final vaccines = await _vaccinesService.fetchVaccines();
        debugPrint('✅ [DEBUG] Repositorio: Vacunas obtenidas del servicio: ${vaccines.length}');
        
        // Guardar en el sistema offline
        for (final vaccine in vaccines) {
          await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccine));
        }
        
        // Marcar que hay datos offline disponibles
        if (vaccines.isNotEmpty) {
          await TokenService.instance.setHasOfflineData(true);
        }
        
        for (int i = 0; i < vaccines.length; i++) {
          debugPrint('🔍 [DEBUG] Repositorio: Vacuna $i: ${vaccines[i].name} (ID: ${vaccines[i].id})');
        }
        return vaccines;
      } else {
        // Sin conexión, usar datos offline
        final offlineData = await _offlineService.getVaccinesOffline();
        if (offlineData.isNotEmpty) {
          final vaccines = offlineData.map((data) => _mapFromOfflineFormat(data)).toList();
          debugPrint('✅ [DEBUG] Repositorio: Vacunas obtenidas offline: ${vaccines.length}');
          return vaccines;
        }
        
        debugPrint('⚠️ [DEBUG] Repositorio: No hay datos offline disponibles');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] Repositorio: Error en getVaccines: $e');
      
      // En caso de error, intentar usar datos offline
      try {
        final offlineData = await _offlineService.getVaccinesOffline();
        if (offlineData.isNotEmpty) {
          final vaccines = offlineData.map((data) => _mapFromOfflineFormat(data)).toList();
          debugPrint('✅ [DEBUG] Repositorio: Vacunas obtenidas offline (fallback): ${vaccines.length}');
          return vaccines;
        }
        
        return [];
      } catch (offlineError) {
        debugPrint('❌ [DEBUG] Repositorio: Error accessing offline vaccines: $offlineError');
        return [];
      }
    }
  }

  // Crear una vacuna
  Future<void> createVaccine(VaccinesDto vaccine, File imageFile) async {
    try {
      if (_connectivityService.isConnected) {
        await _vaccinesService.createVaccine(vaccine, imageFile);
        await getVaccines();
      } else {
        // Sin conexión, guardar offline
        await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccine));
        await TokenService.instance.setHasOfflineData(true);
        debugPrint('Vacuna guardada offline para sincronización posterior');
      }
    } catch (e) {
      // En caso de error, guardar offline
      await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccine));
      await TokenService.instance.setHasOfflineData(true);
      debugPrint('Error creating vaccine, saved offline: $e');
      rethrow;
    }
  }

  // Crear una vacuna con URL de imagen predeterminada
  Future<void> createVaccineWithUrl(VaccinesDto vaccine) async {
    try {
      if (_connectivityService.isConnected) {
        await _vaccinesService.createVaccineWithUrl(vaccine);
        await getVaccines();
      } else {
        // Sin conexión, guardar offline
        await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccine));
        await TokenService.instance.setHasOfflineData(true);
        debugPrint('Vacuna guardada offline para sincronización posterior');
      }
    } catch (e) {
      // En caso de error, guardar offline
      await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccine));
      await TokenService.instance.setHasOfflineData(true);
      debugPrint('Error creating vaccine, saved offline: $e');
      rethrow;
    }
  }

  // Actualizar una vacuna
  Future<void> updateVaccine(int id, Map<String, dynamic> data, File? imageFile) async {
    try {
      if (_connectivityService.isConnected) {
        await VaccinesService().updateVaccine(id, data, imageFile);
      } else {
        // Sin conexión, guardar cambios offline
        data['id'] = id;
        final vaccineDto = VaccinesDto.fromJson(data);
        await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccineDto));
        await TokenService.instance.setHasOfflineData(true);
        debugPrint('Vaccine update guardado offline para sincronización posterior');
      }
    } catch (e) {
      // En caso de error, guardar offline
      data['id'] = id;
      final vaccineDto = VaccinesDto.fromJson(data);
      await _offlineService.saveVaccineOffline(_mapToOfflineFormat(vaccineDto));
      await TokenService.instance.setHasOfflineData(true);
      debugPrint('Error updating vaccine, saved offline: $e');
      rethrow;
    }
  }

  // Eliminar una vacuna
  Future<void> deleteVaccine(int id) async {
    try {
      if (_connectivityService.isConnected) {
        await _vaccinesService.deleteVaccine(id);
        await getVaccines();
      } else {
        debugPrint('Vaccine deletion will be synced when connection is restored');
        throw Exception('No se puede eliminar sin conexión. Intenta cuando tengas internet.');
      }
    } catch (e) {
      debugPrint('Error deleting vaccine: $e');
      rethrow;
    }
  }

  // Obtener una vacuna por ID
  Future<VaccinesDto> getVaccineById(int id) async {
    try {
      if (_connectivityService.isConnected) {
        return await _vaccinesService.fetchVaccineById(id);
      } else {
        // Buscar en datos offline
        final offlineVaccines = await _offlineService.getVaccinesOffline();
        final vaccine = offlineVaccines.firstWhere(
          (data) => data['id'] == id || data['server_id'] == id,
          orElse: () => throw Exception('Vacuna no encontrada offline'),
        );
        return _mapFromOfflineFormat(vaccine);
      }
    } catch (e) {
      debugPrint('Error getting vaccine by ID: $e');
      rethrow;
    }
  }

  // Obtener vacunas por bovinoId
  Future<List<VaccinesDto>> getVaccinesByBovineId(int bovineId) async {
    try {
      if (_connectivityService.isConnected) {
        return await _vaccinesService.fetchVaccinesByBovineId(bovineId);
      } else {
        // Filtrar datos offline por bovineId
        final offlineVaccines = await _offlineService.getVaccinesOffline(animalId: bovineId);
        return offlineVaccines.map((data) => _mapFromOfflineFormat(data)).toList();
      }
    } catch (e) {
      debugPrint('Error getting vaccines by bovine ID: $e');
      
      // Fallback: buscar en todos los datos offline
      try {
        final allOfflineVaccines = await _offlineService.getVaccinesOffline();
        final filteredVaccines = allOfflineVaccines.where(
          (data) => data['animal_id'] == bovineId || data['bovineId'] == bovineId,
        ).toList();
        
        return filteredVaccines.map((data) => _mapFromOfflineFormat(data)).toList();
      } catch (offlineError) {
        debugPrint('Error accessing offline vaccines: $offlineError');
        return [];
      }
    }
  }

  /// Verificar si hay datos offline disponibles
  Future<bool> hasOfflineData() async {
    try {
      final offlineVaccines = await _offlineService.getVaccinesOffline();
      return offlineVaccines.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mapear VaccinesDto al formato del OfflineDataService
  Map<String, dynamic> _mapToOfflineFormat(VaccinesDto vaccine) {
    return {
      'server_id': vaccine.id,
      'animal_id': vaccine.bovineId,
      'vaccine_name': vaccine.name,
      'application_date': vaccine.vaccineDate,
      'next_dose_date': '', // VaccinesDto no tiene esta información
      'notes': vaccine.vaccineType,
    };
  }

  /// Mapear del formato offline a VaccinesDto
  VaccinesDto _mapFromOfflineFormat(Map<String, dynamic> data) {
    return VaccinesDto(
      id: data['server_id'] ?? data['id'] ?? 0,
      name: data['vaccine_name'] ?? data['name'] ?? '',
      vaccineType: data['notes'] ?? data['vaccineType'] ?? '',
      vaccineDate: data['application_date'] ?? data['vaccineDate'] ?? '',
      vaccineImg: '', // Los datos offline no incluyen imagen por defecto
      bovineId: data['animal_id'] ?? data['bovineId'] ?? 0,
    );
  }
}