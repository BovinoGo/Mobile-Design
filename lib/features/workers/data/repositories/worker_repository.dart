import 'package:vacapp/features/workers/data/datasources/worker_service.dart';
import 'package:vacapp/features/workers/data/models/worker_dto.dart';

class WorkerRepository {
  final WorkerService _service;

  WorkerRepository(this._service);

  Future<List<WorkerDto>> getByCompany(String companyId) =>
      _service.fetchByCompany(companyId);

  Future<WorkerDto> create(Map<String, dynamic> body) =>
      _service.create(body);

  Future<void> deactivate(String id) => _service.deactivate(id);
}
