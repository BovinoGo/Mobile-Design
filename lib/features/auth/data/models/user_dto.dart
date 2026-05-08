class UserDTO {
  final String token;
  final String userId;
  final String fullName;
  final String email;
  final String accountType;
  final String role;

  UserDTO({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.accountType,
    required this.role,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      token: json['token'] ?? '',
      userId: (json['userId'] ?? '').toString(),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      accountType: json['accountType'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
