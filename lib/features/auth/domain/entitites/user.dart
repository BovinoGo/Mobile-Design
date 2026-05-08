class User {
  final String userId;
  final String fullName;
  final String email;
  final String token;
  final String accountType;
  final String role;

  const User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.token,
    required this.accountType,
    required this.role,
  });

  bool get isCompany => accountType == 'LivestockCompany';
  bool get isRancher => accountType == 'IndependentRancher';
  bool get isBuyer => accountType == 'BuyerCustomer';
  bool get isPlatformAdmin => accountType == 'PlatformAccount';
  bool get isCompanyAdmin => role == 'CompanyAdmin';
  bool get isWorker => role == 'CompanyWorker';

  String get accountTypeDisplay {
    switch (accountType) {
      case 'LivestockCompany':
        return 'Empresa Ganadera';
      case 'IndependentRancher':
        return 'Ganadero Independiente';
      case 'BuyerCustomer':
        return 'Comprador';
      case 'PlatformAccount':
        return 'Administrador';
      default:
        return accountType;
    }
  }
}
