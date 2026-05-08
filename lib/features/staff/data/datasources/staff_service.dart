import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/staff/data/models/staff_dto.dart';
import 'package:flutter/foundation.dart';

class StaffService {

  Future<StaffDto> createStaff(StaffDto staff) async {
    try {
      final headers = await TokenService.instance.getJsonAuthHeaders();
      final Uri uri = Uri.parse(Endpoints.staff);
      final body = jsonEncode(staff.toJson());
      
      debugPrint('🔄 Enviando POST a: $uri');
      debugPrint('📦 Headers: $headers');
      debugPrint('📦 Body: $body');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );
      
      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');
      
      if(response.statusCode != HttpStatus.created){
        String errorMessage = 'Error al crear el staff';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint('❌ Error parsing error response: $e');
          errorMessage = 'Error del servidor: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }

      if (response.body.isEmpty) {
        throw Exception('El servidor devolvió una respuesta vacía');
      }

      final createdStaff = StaffDto.fromJson(jsonDecode(response.body));
      debugPrint('✅ Staff created with ID: ${createdStaff.id}');
      return createdStaff;
    } catch (e) {
      debugPrint('❌ Error creating staff: $e');
      rethrow;
    }
  }

  Future<List<StaffDto>> fetchStaffs() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse(Endpoints.staff);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StaffDto.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar el staff');
    }
  }

  Future<StaffDto> fetchStaffById(int id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse('${Endpoints.staff}/$id');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      return StaffDto.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar el staff');
    }
  }

  Future<void> updateStaff(int id, StaffDto staff) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse('${Endpoints.staff}/$id');
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(staff.toJson()),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al actualizar el staff');
    }
  }

  Future<void> deleteStaff(int id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse('${Endpoints.staff}/$id');
    final response = await http.delete(uri, headers: headers);

    if (response.statusCode != HttpStatus.noContent) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al eliminar el staff');
    }
  }

  Future<List<StaffDto>> fetchStaffByCampaignId(int campaignId) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse('${Endpoints.staff}/search-by-campaign/$campaignId');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StaffDto.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar el staff por campaña');
    }
  }

  Future<List<StaffDto>> fetchStaffByEmployeeStatus(int employeeStatus) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse('${Endpoints.staff}/search-by-employee-status/$employeeStatus');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StaffDto.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar el staff por estado de empleado');
    }
  }

  Future<List<StaffDto>> fetchStaffByName(String name) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final Uri uri = Uri.parse('${Endpoints.staff}/search-by-name/$name');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StaffDto.fromJson(e)).toList();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al cargar el staff por nombre');
    }
  }
}