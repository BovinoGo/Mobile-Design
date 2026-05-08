import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:flutter/foundation.dart';

class UserApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtener información del perfil del usuario
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      debugPrint('🔍 [USER_API] Obteniendo información del usuario...');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Endpoints.baseUrl}/user/get-info'),
        headers: headers,
      );

      debugPrint('📊 [USER_API] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [USER_API] Información obtenida exitosamente');
        return data;
      } else {
        debugPrint('❌ [USER_API] Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al obtener información del usuario: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [USER_API] Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar perfil del usuario
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      debugPrint('🔄 [USER_API] Actualizando perfil del usuario...');
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Endpoints.baseUrl}/user/update-profile'),
        headers: headers,
        body: json.encode(profileData),
      );

      debugPrint('📊 [USER_API] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [USER_API] Perfil actualizado exitosamente');
        return data;
      } else {
        debugPrint('❌ [USER_API] Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al actualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [USER_API] Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar cuenta del usuario (PELIGROSO)
  static Future<bool> deleteAccount() async {
    try {
      debugPrint('🚨 [USER_API] ELIMINANDO CUENTA DEL USUARIO...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Endpoints.baseUrl}/user/delete-account'),
        headers: headers,
      );

      debugPrint('📊 [USER_API] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ [USER_API] Cuenta eliminada exitosamente');
        // Limpiar sesión local
        await TokenService.instance.clearUserSession();
        return true;
      } else {
        debugPrint('❌ [USER_API] Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al eliminar cuenta: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [USER_API] Error: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}
