class PublicationDto {
  final String id;
  final String bovineId;
  final String? ranchId;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final String salePurpose;
  final String publicationStatus;
  final bool negotiablePrice;
  final String contactPreference;
  final bool includesTransport;
  final bool requiresSanitaryDocumentation;
  final String? publishedAt;
  final String? healthSummary;
  final bool? vaccinationHistoryAvailable;
  final String? sellerId;

  PublicationDto({
    required this.id,
    required this.bovineId,
    this.ranchId,
    required this.title,
    this.description,
    required this.price,
    required this.currency,
    required this.salePurpose,
    required this.publicationStatus,
    required this.negotiablePrice,
    required this.contactPreference,
    required this.includesTransport,
    required this.requiresSanitaryDocumentation,
    this.publishedAt,
    this.healthSummary,
    this.vaccinationHistoryAvailable,
    this.sellerId,
  });

  factory PublicationDto.fromJson(Map<String, dynamic> json) => PublicationDto(
        id: (json['id'] ?? '').toString(),
        bovineId: (json['bovineId'] ?? '').toString(),
        ranchId: json['ranchId']?.toString(),
        title: json['title'] ?? '',
        description: json['description'],
        price: (json['price'] ?? 0).toDouble(),
        currency: json['currency']?.toString() ?? 'USD',
        salePurpose: json['salePurpose']?.toString() ?? '',
        publicationStatus: json['publicationStatus']?.toString() ?? '',
        negotiablePrice: json['negotiablePrice'] ?? false,
        contactPreference: json['contactPreference']?.toString() ?? '',
        includesTransport: json['includesTransport'] ?? false,
        requiresSanitaryDocumentation:
            json['requiresSanitaryDocumentation'] ?? false,
        publishedAt: json['publishedAt']?.toString(),
        healthSummary: json['healthSummary'],
        vaccinationHistoryAvailable: json['vaccinationHistoryAvailable'],
        sellerId: json['sellerId']?.toString(),
      );
}

class PurchaseRequestDto {
  final String id;
  final String publicationId;
  final String buyerId;
  final String requestStatus;
  final String createdAt;
  final String? message;

  PurchaseRequestDto({
    required this.id,
    required this.publicationId,
    required this.buyerId,
    required this.requestStatus,
    required this.createdAt,
    this.message,
  });

  factory PurchaseRequestDto.fromJson(Map<String, dynamic> json) =>
      PurchaseRequestDto(
        id: (json['id'] ?? '').toString(),
        publicationId: (json['publicationId'] ?? '').toString(),
        buyerId: (json['buyerId'] ?? '').toString(),
        requestStatus: json['requestStatus']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        message: json['message'],
      );
}
