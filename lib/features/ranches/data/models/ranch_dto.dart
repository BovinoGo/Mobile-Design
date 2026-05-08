import 'package:vacapp/features/ranches/domain/entities/ranch.dart';

class RanchDto {
  final String id;
  final String name;
  final String country;
  final String region;
  final String productionType;
  final bool isActive;
  final String ownerId;
  final String? description;
  final String? province;
  final String? district;
  final String? address;
  final double? totalAreaHectares;
  final int? capacityBovines;
  final String? contactPhone;
  final String? contactEmail;
  final String? sanitaryRegistrationCode;

  RanchDto({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.productionType,
    required this.isActive,
    required this.ownerId,
    this.description,
    this.province,
    this.district,
    this.address,
    this.totalAreaHectares,
    this.capacityBovines,
    this.contactPhone,
    this.contactEmail,
    this.sanitaryRegistrationCode,
  });

  factory RanchDto.fromJson(Map<String, dynamic> json) => RanchDto(
        id: (json['id'] ?? '').toString(),
        name: json['name'] ?? '',
        country: json['country'] ?? '',
        region: json['region'] ?? '',
        productionType: json['productionType']?.toString() ?? '',
        isActive: json['isActive'] ?? true,
        ownerId: (json['ownerId'] ?? '').toString(),
        description: json['description'],
        province: json['province'],
        district: json['district'],
        address: json['address'],
        totalAreaHectares: json['totalAreaHectares'] != null
            ? (json['totalAreaHectares'] as num).toDouble()
            : null,
        capacityBovines: json['capacityBovines'],
        contactPhone: json['contactPhone'],
        contactEmail: json['contactEmail'],
        sanitaryRegistrationCode: json['sanitaryRegistrationCode'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'region': region,
        'productionType': productionType,
        'ownerId': ownerId,
        if (description != null) 'description': description,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
        if (address != null) 'address': address,
        if (totalAreaHectares != null) 'totalAreaHectares': totalAreaHectares,
        if (capacityBovines != null) 'capacityBovines': capacityBovines,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (sanitaryRegistrationCode != null)
          'sanitaryRegistrationCode': sanitaryRegistrationCode,
      };

  Ranch toDomain() => Ranch(
        id: id,
        name: name,
        country: country,
        region: region,
        productionType: productionType,
        isActive: isActive,
        ownerId: ownerId,
        description: description,
        province: province,
        district: district,
        address: address,
        totalAreaHectares: totalAreaHectares,
        capacityBovines: capacityBovines,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        sanitaryRegistrationCode: sanitaryRegistrationCode,
      );
}
