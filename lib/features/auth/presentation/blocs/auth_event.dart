abstract class AuthEvent {
  const AuthEvent();
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent({required this.email, required this.password});
}

class RegisterCompanyEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  const RegisterCompanyEvent({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });
}

class RegisterRancherEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  const RegisterRancherEvent({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });
}

class RegisterBuyerEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  const RegisterBuyerEvent({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });
}
