import 'package:vacapp/features/marketplace/data/models/publication_dto.dart';

abstract class MarketplaceState {
  const MarketplaceState();
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class PublicationsLoaded extends MarketplaceState {
  final List<PublicationDto> publications;
  const PublicationsLoaded(this.publications);
}

class MarketplaceOperationSuccess extends MarketplaceState {
  final String message;
  const MarketplaceOperationSuccess(this.message);
}

class MarketplaceError extends MarketplaceState {
  final String message;
  const MarketplaceError(this.message);
}
