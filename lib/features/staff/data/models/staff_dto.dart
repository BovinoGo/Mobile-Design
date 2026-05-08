import 'package:vacapp/features/staff/domain/staff.dart';
import 'package:flutter/foundation.dart';

class StaffDto {
  final int id;
  final String name;
  final int employeeStatus;
  final int campaignId;

  StaffDto({
    required this.id,
    required this.name,
    required this.employeeStatus,
    required this.campaignId,
  });

  factory StaffDto.fromJson(Map<String, dynamic> json) {
    try {
      return StaffDto(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name: json['name']?.toString() ?? '',
        employeeStatus: json['employeeStatus'] is int
            ? json['employeeStatus']
            : int.parse(json['employeeStatus'].toString()),
        campaignId: json['campaignId'] is int
            ? json['campaignId']
            : int.parse(json['campaignId'].toString()),
      );
    } catch (e) {
      debugPrint('❌ Error parsing StaffDto: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeStatus': employeeStatus,
      'campaignId': campaignId,
    };
  }

  Staff toDomain() {
    return Staff(
      id: id,
      name: name,
      employeeStatus: employeeStatus,
      campaignId: campaignId,
    );
  }

  static StaffDto fromDomain(Staff staff) {
    return StaffDto(
      id: staff.id,
      name: staff.name,
      employeeStatus: staff.employeeStatus,
      campaignId: staff.campaignId,
    );
  }

  // Métodos helper para employeeStatus
  String get employeeStatusString {
    switch (employeeStatus) {
      case 1:
        return 'Disponible';
      case 2:
        return 'En Campaña';
      case 3:
        return 'Vacaciones';
      default:
        return 'Desconocido';
    }
  }

  static int employeeStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return 1;
      case 'en campaña':
      case 'en_campaña':
      case 'campaña':
        return 2;
      case 'vacaciones':
        return 3;
      default:
        return 1; // Por defecto disponible
    }
  }

  static List<String> get availableStatuses => [
    'Disponible',
    'En Campaña',
    'Vacaciones',
  ];

}