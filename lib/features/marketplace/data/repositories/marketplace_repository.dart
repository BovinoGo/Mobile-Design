import 'package:vacapp/features/marketplace/data/datasources/marketplace_service.dart';
import 'package:vacapp/features/marketplace/data/models/publication_dto.dart';

class MarketplaceRepository {
  final MarketplaceService _service;

  MarketplaceRepository(this._service);

  Future<List<PublicationDto>> getPublished() => _service.fetchPublished();
  Future<List<PublicationDto>> getMine() => _service.fetchMine();
  Future<PublicationDto> publish(Map<String, dynamic> body) =>
      _service.publish(body);
  Future<PurchaseRequestDto> requestPurchase(
          String publicationId, Map<String, dynamic> body) =>
      _service.requestPurchase(publicationId, body);
  Future<void> cancel(String id) => _service.cancelPublication(id);
  Future<List<PurchaseRequestDto>> getPurchaseRequests(String publicationId) =>
      _service.fetchPurchaseRequests(publicationId);
}
