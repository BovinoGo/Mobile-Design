import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vacapp/core/constants/endpoints.dart';
import 'package:vacapp/features/auth/data/models/user_dto.dart';

class AuthService {
  Future<UserDTO> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse(Endpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == HttpStatus.ok) {
      return UserDTO.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Login failed');
  }

  Future<UserDTO> registerCompany({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) =>
      _register(Endpoints.registerCompany, fullName, email, password, phone);

  Future<UserDTO> registerRancher({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) =>
      _register(Endpoints.registerRancher, fullName, email, password, phone);

  Future<UserDTO> registerBuyer({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) =>
      _register(Endpoints.registerBuyer, fullName, email, password, phone);

  Future<UserDTO> _register(
    String url,
    String fullName,
    String email,
    String password,
    String? phone,
  ) async {
    final body = {
      'fullName': fullName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return UserDTO.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Registration failed');
  }

  Never _throwError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? body['message'] ?? fallback);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(fallback);
    }
  }
}
