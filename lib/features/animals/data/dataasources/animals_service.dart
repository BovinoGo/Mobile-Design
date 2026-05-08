import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';

class AnimalsService {
  Future<List<AnimalDto>> fetchAnimals() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.get(Uri.parse(Endpoints.bovines), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AnimalDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar bovinos');
  }

  Future<AnimalDto> fetchAnimalById(String id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.get(Uri.parse(Endpoints.bovineById(id)), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      return AnimalDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al cargar el bovino');
  }

  Future<AnimalDto> registerBovine(Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.post(
      Uri.parse(Endpoints.bovines),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.created ||
        response.statusCode == HttpStatus.ok) {
      return AnimalDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al registrar el bovino');
  }

  Future<void> updateBovine(String id, Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.put(
      Uri.parse(Endpoints.bovineById(id)),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.noContent) {
      return;
    }
    _throwError(response, 'Error al actualizar el bovino');
  }

  Future<void> deactivateBovine(String id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.delete(Uri.parse(Endpoints.bovineById(id)), headers: headers);
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.noContent) {
      return;
    }
    _throwError(response, 'Error al desactivar el bovino');
  }

  Future<VitalSignsResultDto> simulateVitalSigns(
      String bovineId, String userId, Map<String, dynamic> vitalData) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final body = {
      'bovineId': bovineId,
      'userId': userId,
      ...vitalData,
    };
    final response = await http.post(
      Uri.parse(Endpoints.bovineVitalSigns(bovineId)),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.ok) {
      return VitalSignsResultDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al simular signos vitales');
  }

  Future<List<VitalSignsResultDto>> fetchVitalSignsHistory(String bovineId) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.get(
        Uri.parse(Endpoints.bovineVitalSignsHistory(bovineId)),
        headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => VitalSignsResultDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar historial de signos vitales');
  }

  Future<List<CriticalAlertDto>> fetchAlerts() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.get(Uri.parse(Endpoints.bovineAlerts), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CriticalAlertDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar alertas');
  }

  Future<List<CriticalAlertDto>> fetchUnreadAlerts() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.get(Uri.parse(Endpoints.bovineAlertsUnread), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CriticalAlertDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar alertas no leídas');
  }

  Future<void> markAlertRead(String alertId) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.patch(
        Uri.parse(Endpoints.bovineAlertRead(alertId)),
        headers: headers);
    if (response.statusCode == HttpStatus.ok) return;
    _throwError(response, 'Error al marcar alerta como leída');
  }

  // Legacy stub — VacApp does not have stables; returns empty list.
  Future<List<AnimalDto>> fetchAnimalByStableId(int stableId) async => [];

  // Upload photo to Cloudinary, returns public URL
  Future<String?> uploadPhoto(File imageFile) async {
    const cloudName = 'dgcgdxn0u';
    const uploadPreset = 'vacapp_unsigned';
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path,
          filename: path.basename(imageFile.path)));
    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await http.Response.fromStream(response).then((r) => r.body));
      return data['secure_url'] as String?;
    }
    return null;
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
