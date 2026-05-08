abstract class MarketplaceEvent {
  const MarketplaceEvent();
}

class LoadPublicationsEvent extends MarketplaceEvent {}

class LoadMyPublicationsEvent extends MarketplaceEvent {}

class PublishBovineEvent extends MarketplaceEvent {
  final Map<String, dynamic> body;
  const PublishBovineEvent(this.body);
}

class RequestPurchaseEvent extends MarketplaceEvent {
  final String publicationId;
  final String buyerId;
  final String? message;
  const RequestPurchaseEvent(
      {required this.publicationId, required this.buyerId, this.message});
}

class CancelPublicationEvent extends MarketplaceEvent {
  final String id;
  const CancelPublicationEvent(this.id);
}
