import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';

class RanchService {
  Future<List<RanchDto>> fetchMine() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.get(Uri.parse(Endpoints.ranches), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => RanchDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar ranchos');
  }

  Future<RanchDto> fetchById(String id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.get(Uri.parse(Endpoints.ranchById(id)), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      return RanchDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al cargar el rancho');
  }

  Future<RanchDto> create(Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.post(
      Uri.parse(Endpoints.ranches),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.created ||
        response.statusCode == HttpStatus.ok) {
      return RanchDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al crear el rancho');
  }

  Future<RanchDto> update(String id, Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.put(
      Uri.parse(Endpoints.ranchById(id)),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.ok) {
      return RanchDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al actualizar el rancho');
  }

  Future<void> deactivate(String id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.delete(
        Uri.parse(Endpoints.ranchById(id)), headers: headers);
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.noContent) {
      return;
    }
    _throwError(response, 'Error al desactivar el rancho');
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
