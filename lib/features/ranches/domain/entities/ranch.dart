class Ranch {
  final String id;
  final String name;
  final String country;
  final String region;
  final String productionType;
  final bool isActive;
  final String? description;
  final String? province;
  final String? district;
  final String? address;
  final double? totalAreaHectares;
  final int? capacityBovines;
  final String? contactPhone;
  final String? contactEmail;
  final String? sanitaryRegistrationCode;
  final String ownerId;

  const Ranch({
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
}
