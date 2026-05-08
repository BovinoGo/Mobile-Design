import 'dart:io';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';

class AnimalRepository {
  final AnimalsService _service;

  AnimalRepository(this._service);

  Future<List<AnimalDto>> getAnimals() => _service.fetchAnimals();

  Future<AnimalDto> getAnimalById(String id) => _service.fetchAnimalById(id);

  Future<AnimalDto> createAnimal(Map<String, dynamic> body, {File? imageFile}) async {
    if (imageFile != null) {
      final photoUrl = await _service.uploadPhoto(imageFile);
      if (photoUrl != null) body['photoUrl'] = photoUrl;
    }
    return _service.registerBovine(body);
  }

  Future<void> updateAnimal(String id, Map<String, dynamic> body) =>
      _service.updateBovine(id, body);

  Future<void> deactivateAnimal(String id) => _service.deactivateBovine(id);

  Future<VitalSignsResultDto> simulateVitalSigns(
    String bovineId,
    String userId,
    Map<String, dynamic> data,
  ) =>
      _service.simulateVitalSigns(bovineId, userId, data);

  Future<List<VitalSignsResultDto>> getVitalSignsHistory(String bovineId) =>
      _service.fetchVitalSignsHistory(bovineId);

  Future<List<CriticalAlertDto>> getAlerts() => _service.fetchAlerts();

  Future<List<CriticalAlertDto>> getUnreadAlerts() => _service.fetchUnreadAlerts();

  Future<void> markAlertRead(String alertId) => _service.markAlertRead(alertId);
}
