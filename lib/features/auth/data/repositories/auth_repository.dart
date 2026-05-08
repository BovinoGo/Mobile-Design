import 'package:vacapp/features/auth/data/datasources/auth_service.dart';
import 'package:vacapp/features/auth/data/models/user_dto.dart';
import 'package:vacapp/features/auth/domain/entitites/user.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<User> login({required String email, required String password}) async {
    final dto = await _authService.login(email: email, password: password);
    return _dtoToUser(dto);
  }

  Future<User> registerCompany({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final dto = await _authService.registerCompany(
        fullName: fullName, email: email, password: password, phone: phone);
    return _dtoToUser(dto);
  }

  Future<User> registerRancher({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final dto = await _authService.registerRancher(
        fullName: fullName, email: email, password: password, phone: phone);
    return _dtoToUser(dto);
  }

  Future<User> registerBuyer({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final dto = await _authService.registerBuyer(
        fullName: fullName, email: email, password: password, phone: phone);
    return _dtoToUser(dto);
  }

  User _dtoToUser(UserDTO dto) => User(
        userId: dto.userId,
        fullName: dto.fullName,
        email: dto.email,
        token: dto.token,
        accountType: dto.accountType,
        role: dto.role,
      );
}
