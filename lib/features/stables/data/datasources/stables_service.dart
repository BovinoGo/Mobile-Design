import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:flutter/foundation.dart';

class StablesService {
  
  Future<StableDto> createStable(StableDto stable) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();

    final Uri uri = Uri.parse(Endpoints.stable);
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(stable.toJson()),
    );

    if (response.statusCode != HttpStatus.created) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al crear el establo');
    }
    
    // Retornar el establo creado con su ID asignado por el backend
    final createdStable = StableDto.fromJson(jsonDecode(response.body));
    debugPrint('✅ Stable created with ID: ${createdStable.id}');
    return createdStable;
  }

  Future<List<StableDto>> fetchStables() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();

    final Uri uri = Uri.parse(Endpoints.stable);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StableDto.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar establos');
    }
  }

  Future<StableDto> fetchStableById(int id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();

    final Uri uri = Uri.parse('${Endpoints.stable}/$id');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      return StableDto.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar el establo');
    }
  }

  Future<void> updateStable(int id, StableDto stable) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();

    final Uri uri = Uri.parse('${Endpoints.stable}/$id');
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(stable.toJson()),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al actualizar el establo');
    }
    debugPrint('✅ Stable $id updated');
  }

  Future<void> deleteStable(int id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();

    final Uri uri = Uri.parse('${Endpoints.stable}/$id');
    final response = await http.delete(uri, headers: headers);

    if (response.statusCode != HttpStatus.noContent) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al eliminar el establo');
    }
    debugPrint('✅ Stable $id deleted');
  }

}