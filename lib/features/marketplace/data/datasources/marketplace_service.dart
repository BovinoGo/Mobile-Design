import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/marketplace/data/models/publication_dto.dart';

class MarketplaceService {
  Future<List<PublicationDto>> fetchPublished() async {
    final response =
        await http.get(Uri.parse(Endpoints.publications));
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PublicationDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar publicaciones');
  }

  Future<List<PublicationDto>> fetchMine() async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response =
        await http.get(Uri.parse(Endpoints.publicationsMine), headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PublicationDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar mis publicaciones');
  }

  Future<PublicationDto> publish(Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.post(
      Uri.parse(Endpoints.publications),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.created ||
        response.statusCode == HttpStatus.ok) {
      return PublicationDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al publicar el bovino');
  }

  Future<PurchaseRequestDto> requestPurchase(
      String publicationId, Map<String, dynamic> body) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.post(
      Uri.parse(Endpoints.purchaseRequest(publicationId)),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return PurchaseRequestDto.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al solicitar compra');
  }

  Future<void> cancelPublication(String id) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.patch(
        Uri.parse(Endpoints.cancelPublication(id)), headers: headers);
    if (response.statusCode == HttpStatus.ok) return;
    _throwError(response, 'Error al cancelar la publicación');
  }

  Future<List<PurchaseRequestDto>> fetchPurchaseRequests(
      String publicationId) async {
    final headers = await TokenService.instance.getJsonAuthHeaders();
    final response = await http.get(
        Uri.parse(Endpoints.publicationPurchaseRequests(publicationId)),
        headers: headers);
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PurchaseRequestDto.fromJson(e)).toList();
    }
    _throwError(response, 'Error al cargar solicitudes');
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
