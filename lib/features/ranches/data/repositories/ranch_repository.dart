import 'package:vacapp/features/ranches/data/datasources/ranch_service.dart';
import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';

class RanchRepository {
  final RanchService _service;

  RanchRepository(this._service);

  Future<List<RanchDto>> getMine() => _service.fetchMine();
  Future<RanchDto> getById(String id) => _service.fetchById(id);
  Future<RanchDto> create(Map<String, dynamic> body) => _service.create(body);
  Future<RanchDto> update(String id, Map<String, dynamic> body) =>
      _service.update(id, body);
  Future<void> deactivate(String id) => _service.deactivate(id);
}
