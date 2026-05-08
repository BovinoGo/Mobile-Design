class Animal {
  final String id;
  final String earTagCode;
  final String? name;
  final String breed;
  final String sex;
  final int ageInMonths;
  final String healthStatus;
  final String lifeStatus;
  final String ranchId;
  final String ownerId;
  final bool isActive;
  final double currentWeightKg;
  final String? category;
  final String? productivePurpose;
  final String? photoUrl;
  final String? vitalSignsStatus;
  final double? bodyTemperatureCelsius;
  final int? heartRateBpm;
  final int? respiratoryRateRpm;

  const Animal({
    required this.id,
    required this.earTagCode,
    this.name,
    required this.breed,
    required this.sex,
    required this.ageInMonths,
    required this.healthStatus,
    required this.lifeStatus,
    required this.ranchId,
    required this.ownerId,
    required this.isActive,
    required this.currentWeightKg,
    this.category,
    this.productivePurpose,
    this.photoUrl,
    this.vitalSignsStatus,
    this.bodyTemperatureCelsius,
    this.heartRateBpm,
    this.respiratoryRateRpm,
  });

  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : earTagCode;

  bool get isCritical => vitalSignsStatus == 'Critico';
  bool get isHealthy => healthStatus == 'Sano';
}
