import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class VaccineTypeDto {
  final int id;
  final String name;
  final String type;
  final String frequency;
  final String ageRecommended;

  VaccineTypeDto({
    required this.id,
    required this.name,
    required this.type,
    required this.frequency,
    required this.ageRecommended,
  });

  factory VaccineTypeDto.fromJson(Map<String, dynamic> json) {
    return VaccineTypeDto(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      frequency: json['frequency'] ?? '',
      ageRecommended: json['ageRecommended'] ?? '',
    );
  }

  // Verificar si la vacuna es solo para hembras
  bool get isOnlyForFemales {
    return ageRecommended.toLowerCase().contains('hembra') ||
           ageRecommended.toLowerCase().contains('obligatorio en hembras') ||
           name.toLowerCase().contains('reproduct') ||
           name.toLowerCase().contains('maternidad') ||
           name.toLowerCase().contains('parto');
  }

  // Verificar si la vacuna es después del parto
  bool get isPostPartum {
    return ageRecommended.toLowerCase().contains('después del parto') ||
           ageRecommended.toLowerCase().contains('post parto') ||
           ageRecommended.toLowerCase().contains('postparto') ||
           name.toLowerCase().contains('post parto') ||
           name.toLowerCase().contains('postparto');
  }

  // Obtener restricción de género
  String? getGenderRestriction() {
    if (isOnlyForFemales) {
      return 'Solo para hembras';
    }
    return null;
  }
}

class VaccineTypesService {
  static const String _baseUrl = 'https://6863277c88359a373e9407d1.mockapi.io/Vaccines';

  Future<List<VaccineTypeDto>> fetchVaccineTypes() async {
    try {
      debugPrint('[DEBUG] Fetching vaccine types from API...');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[DEBUG] API Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final vaccineTypes = jsonData.map((json) => VaccineTypeDto.fromJson(json)).toList();
        
        debugPrint('[DEBUG] Successfully loaded ${vaccineTypes.length} vaccine types');
        return vaccineTypes;
      } else {
        debugPrint('[DEBUG] Failed to load vaccine types: ${response.statusCode}');
        throw Exception('Failed to load vaccine types: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DEBUG] Error fetching vaccine types: $e');
      throw Exception('Error fetching vaccine types: $e');
    }
  }

  // Obtener solo los nombres únicos para el dropdown
  Future<List<String>> getVaccineNames() async {
    final vaccineTypes = await fetchVaccineTypes();
    return vaccineTypes.map((v) => v.name).toSet().toList()..sort();
  }

  // Obtener solo los tipos únicos para el dropdown
  Future<List<String>> getVaccineTypeNames() async {
    final vaccineTypes = await fetchVaccineTypes();
    return vaccineTypes.map((v) => v.type).toSet().toList()..sort();
  }

  // Obtener información específica de una vacuna por nombre
  Future<VaccineTypeDto?> getVaccineByName(String name) async {
    final vaccineTypes = await fetchVaccineTypes();
    try {
      return vaccineTypes.firstWhere((v) => v.name == name);
    } catch (e) {
      return null;
    }
  }

  // Validar si un animal cumple con la edad mínima para una vacuna
  bool validateMinimumAge(String ageRecommended, DateTime animalBirthDate) {
    try {
      // Parsear la edad recomendada (ej: "2-3 meses", "6 meses", "1 año")
      final now = DateTime.now();
      final animalAgeInMonths = _calculateAgeInMonths(animalBirthDate, now);
      final minimumAgeInMonths = _parseAgeRecommended(ageRecommended);
      
      debugPrint('[DEBUG] Animal age: $animalAgeInMonths months, Required: $minimumAgeInMonths months');
      return animalAgeInMonths >= minimumAgeInMonths;
    } catch (e) {
      debugPrint('[DEBUG] Error validating age: $e');
      return true; // En caso de error, permitir la vacunación
    }
  }

  int _calculateAgeInMonths(DateTime birthDate, DateTime currentDate) {
    int months = (currentDate.year - birthDate.year) * 12;
    months += currentDate.month - birthDate.month;
    
    if (currentDate.day < birthDate.day) {
      months--;
    }
    
    return months;
  }

  int _parseAgeRecommended(String ageRecommended) {
    final text = ageRecommended.toLowerCase();
    
    // Buscar patrones como "2-3 meses", "6 meses", "1 año"
    final regexMonths = RegExp(r'(\d+)(?:-\d+)?\s*mes');
    final regexYears = RegExp(r'(\d+)(?:-\d+)?\s*año');
    
    final monthsMatch = regexMonths.firstMatch(text);
    if (monthsMatch != null) {
      return int.parse(monthsMatch.group(1)!);
    }
    
    final yearsMatch = regexYears.firstMatch(text);
    if (yearsMatch != null) {
      return int.parse(yearsMatch.group(1)!) * 12;
    }
    
    // Si no se puede parsear, asumir 0 meses (sin restricción)
    return 0;
  }

  String getAgeValidationMessage(String ageRecommended) {
    return 'Edad mínima recomendada: $ageRecommended';
  }
}
