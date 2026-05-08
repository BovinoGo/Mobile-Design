import 'package:vacapp/features/animals/domain/entitites/Animal.dart';

class AnimalDto {
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

  AnimalDto({
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

  factory AnimalDto.fromJson(Map<String, dynamic> json) {
    return AnimalDto(
      id: (json['id'] ?? '').toString(),
      earTagCode: json['earTagCode'] ?? '',
      name: json['name'],
      breed: json['breed'] ?? '',
      sex: json['sex']?.toString() ?? '',
      ageInMonths: json['ageInMonths'] ?? 0,
      healthStatus: json['healthStatus']?.toString() ?? 'Sano',
      lifeStatus: json['lifeStatus']?.toString() ?? 'Activo',
      ranchId: (json['ranchId'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      isActive: json['isActive'] ?? true,
      currentWeightKg: (json['currentWeightKg'] ?? 0).toDouble(),
      category: json['category']?.toString(),
      productivePurpose: json['productivePurpose']?.toString(),
      photoUrl: json['photoUrl'],
      vitalSignsStatus: json['vitalSignsStatus']?.toString(),
      bodyTemperatureCelsius: json['bodyTemperatureCelsius'] != null
          ? (json['bodyTemperatureCelsius'] as num).toDouble()
          : null,
      heartRateBpm: json['heartRateBpm'],
      respiratoryRateRpm: json['respiratoryRateRpm'],
    );
  }

  Map<String, dynamic> toJson() => {
        'earTagCode': earTagCode,
        if (name != null) 'name': name,
        'breed': breed,
        'sex': sex,
        'ranchId': ranchId,
        'ownerId': ownerId,
        'currentWeightKg': currentWeightKg,
        if (category != null) 'category': category,
        if (productivePurpose != null) 'productivePurpose': productivePurpose,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  // ── Backward-compat getters for legacy feature files ──────────────────────
  // These map VacApp fields to the names the old stables/vaccines code expects.
  String get gender => sex;
  String get bovineImg => photoUrl ?? '';
  String get birthDate => '';
  String get location => '';
  int get stableId => 0;
  // ─────────────────────────────────────────────────────────────────────────

  Animal toDomain() => Animal(
        id: id,
        earTagCode: earTagCode,
        name: name,
        breed: breed,
        sex: sex,
        ageInMonths: ageInMonths,
        healthStatus: healthStatus,
        lifeStatus: lifeStatus,
        ranchId: ranchId,
        ownerId: ownerId,
        isActive: isActive,
        currentWeightKg: currentWeightKg,
        category: category,
        productivePurpose: productivePurpose,
        photoUrl: photoUrl,
        vitalSignsStatus: vitalSignsStatus,
        bodyTemperatureCelsius: bodyTemperatureCelsius,
        heartRateBpm: heartRateBpm,
        respiratoryRateRpm: respiratoryRateRpm,
      );
}

class VitalSignsResultDto {
  final String bovineId;
  final double temperature;
  final int heartRate;
  final int respiratoryRate;
  final String vitalSignsStatus;
  final String simulatedAt;

  VitalSignsResultDto({
    required this.bovineId,
    required this.temperature,
    required this.heartRate,
    required this.respiratoryRate,
    required this.vitalSignsStatus,
    required this.simulatedAt,
  });

  factory VitalSignsResultDto.fromJson(Map<String, dynamic> json) =>
      VitalSignsResultDto(
        bovineId: (json['bovineId'] ?? '').toString(),
        temperature: (json['temperature'] ?? 0).toDouble(),
        heartRate: json['heartRate'] ?? 0,
        respiratoryRate: json['respiratoryRate'] ?? 0,
        vitalSignsStatus: json['vitalSignsStatus']?.toString() ?? '',
        simulatedAt: json['simulatedAt']?.toString() ?? '',
      );
}

class CriticalAlertDto {
  final String id;
  final String bovineId;
  final String ownerId;
  final String message;
  final bool isRead;
  final String createdAt;

  CriticalAlertDto({
    required this.id,
    required this.bovineId,
    required this.ownerId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory CriticalAlertDto.fromJson(Map<String, dynamic> json) =>
      CriticalAlertDto(
        id: (json['id'] ?? '').toString(),
        bovineId: (json['bovineId'] ?? '').toString(),
        ownerId: (json['ownerId'] ?? '').toString(),
        message: json['message']?.toString() ?? '',
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt']?.toString() ?? '',
      );
}
