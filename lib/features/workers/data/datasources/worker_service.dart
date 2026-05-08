import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/workers/data/models/worker_dto.dart';

class WorkerService {
  Future<List<WorkerDto>> fetchByCompany(String companyId) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final uri = Uri.parse('${Endpoints.workers}?companyId=$companyId');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WorkerDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar trabajadores');
  }

  Future<WorkerDto> create(Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.post(
      Uri.parse(Endpoints.workers),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return WorkerDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al crear el trabajador');
  }

  Future<void> deactivate(String id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.delete(Uri.parse(Endpoints.workerById(id)), headers: headers);
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.noContent) {
      return;
    }
    _throwError(response, 'Error al desactivar el trabajador');
  }

  Never _throwError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? body['message'] ?? body['title'] ?? fallback);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(fallback);
    }
  }
}
