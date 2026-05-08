import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _fullNameKey = 'full_name';
  static const String _accountTypeKey = 'account_type';
  static const String _roleKey = 'role';
  static const String _loginDateKey = 'login_date';
  static const String _lastSyncKey = 'last_sync';
  static const String _keepSessionKey = 'keep_session';
  static const String _hasOfflineDataKey = 'has_offline_data';
  
  static TokenService? _instance;
  
  TokenService._();
  
  static TokenService get instance {
    _instance ??= TokenService._();
    return _instance!;
  }

  /// Obtiene el token de autenticación almacenado
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? '';
  }

  /// Guarda el token de autenticación
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Guarda el username del usuario
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  /// Obtiene el username almacenado
  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? '';
  }

  /// Guarda el ID del usuario (UUID como String)
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// Obtiene el ID del usuario (UUID como String)
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Guarda el email del usuario
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  /// Obtiene el email del usuario
  Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  /// Guarda el nombre completo del usuario
  Future<void> saveFullName(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fullNameKey, fullName);
  }

  /// Obtiene el nombre completo del usuario
  Future<String> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullNameKey) ?? '';
  }

  /// Guarda el tipo de cuenta (LivestockCompany, IndependentRancher, etc.)
  Future<void> saveAccountType(String accountType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountTypeKey, accountType);
  }

  /// Obtiene el tipo de cuenta
  Future<String> getAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountTypeKey) ?? '';
  }

  /// Guarda el rol del usuario (CompanyAdmin, CompanyWorker, etc.)
  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  /// Obtiene el rol del usuario
  Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? '';
  }

  /// Guarda toda la sesión del usuario incluyendo fecha de login
  Future<void> saveUserSession(
    String token,
    String username, {
    String? userId,
    String? email,
    String? fullName,
    String? accountType,
    String? role,
    bool keepSession = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_loginDateKey, DateTime.now().toIso8601String());
    await prefs.setBool(_keepSessionKey, keepSession);

    if (userId != null) await prefs.setString(_userIdKey, userId);
    if (email != null) await prefs.setString(_emailKey, email);
    if (fullName != null) await prefs.setString(_fullNameKey, fullName);
    if (accountType != null) await prefs.setString(_accountTypeKey, accountType);
    if (role != null) await prefs.setString(_roleKey, role);
  }

  /// Obtiene la fecha del último login
  Future<DateTime?> getLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_loginDateKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Actualiza la fecha de la última sincronización
  Future<void> updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Obtiene la fecha de la última sincronización
  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastSyncKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Verifica si el usuario quiere mantener la sesión
  Future<bool> shouldKeepSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepSessionKey) ?? true;
  }

  /// Marca que hay datos offline disponibles
  Future<void> setHasOfflineData(bool hasData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasOfflineDataKey, hasData);
  }

  /// Verifica si hay datos offline disponibles
  Future<bool> hasOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasOfflineDataKey) ?? false;
  }

  /// Elimina toda la sesión del usuario
  Future<void> clearUserSession({bool keepOfflineData = false}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_accountTypeKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_loginDateKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_keepSessionKey);

    if (!keepOfflineData) {
      await prefs.remove(_hasOfflineDataKey);
    }
  }

  /// Verifica si existe un token válido
  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token.isEmpty) return false;
    
    // Verificar si debe mantener la sesión
    final keepSession = await shouldKeepSession();
    if (!keepSession) return false;
    
    // Verificar que no haya expirado (opcional: agregar validación de expiración)
    return true;
  }

  /// Verifica si hay una sesión activa o datos offline disponibles
  Future<bool> hasActiveSessionOrOfflineData() async {
    final hasToken = await hasValidToken();
    final hasOffline = await hasOfflineData();
    return hasToken || hasOffline;
  }

  /// Obtiene información completa del usuario logueado
  Future<Map<String, dynamic>> getUserInfo() async {
    return {
      'token': await getToken(),
      'username': await getUsername(),
      'email': await getEmail(),
      'userId': await getUserId(),
      'fullName': await getFullName(),
      'accountType': await getAccountType(),
      'role': await getRole(),
      'loginDate': await getLoginDate(),
      'lastSync': await getLastSync(),
      'keepSession': await shouldKeepSession(),
      'hasOfflineData': await hasOfflineData(),
    };
  }

  /// Obtiene los headers de autorización con el token
  Future<Map<String, String>> getAuthHeaders({Map<String, String>? additionalHeaders}) async {
    final token = await getToken();
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
    return headers;
  }

  /// Obtiene los headers de autorización con Content-Type application/json
  Future<Map<String, String>> getJsonAuthHeaders() async {
    return await getAuthHeaders(additionalHeaders: {
      'Content-Type': 'application/json',
    });
  }

  /// Verifica si la sesión está próxima a expirar (opcional)
  Future<bool> isSessionNearExpiry({Duration threshold = const Duration(days: 1)}) async {
    final loginDate = await getLoginDate();
    if (loginDate == null) return true;
    
    final now = DateTime.now();
    final timeSinceLogin = now.difference(loginDate);
    final sessionDuration = const Duration(days: 30); // Duración de sesión configurable
    
    return (sessionDuration - timeSinceLogin) <= threshold;
  }
}
