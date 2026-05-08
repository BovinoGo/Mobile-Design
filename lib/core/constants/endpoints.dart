class Endpoints {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:5067/api/v1',
  );

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String registerCompany = '$baseUrl/auth/register/company';
  static const String registerRancher = '$baseUrl/auth/register/rancher';
  static const String registerBuyer = '$baseUrl/auth/register/buyer';

  // Bovines
  static const String bovines = '$baseUrl/bovines';
  static String bovineById(String id) => '$bovines/$id';
  static String bovineVitalSigns(String id) => '$bovines/$id/vital-signs';
  static String bovineVitalSignsHistory(String id) => '$bovines/$id/vital-signs/history';
  static const String bovineAlerts = '$bovines/alerts';
  static const String bovineAlertsUnread = '$bovines/alerts/unread';
  static String bovineAlertRead(String alertId) => '$bovines/alerts/$alertId/read';
  static String bovinesByRanch(String ranchId) => '$bovines/by-ranch/$ranchId';

  // Ranches
  static const String ranches = '$baseUrl/ranches';
  static String ranchById(String id) => '$ranches/$id';

  // Marketplace
  static const String publications = '$baseUrl/marketplace/publications';
  static const String publicationsMine = '$baseUrl/marketplace/publications/mine';
  static String publicationById(String id) => '$baseUrl/marketplace/publications/$id';
  static String purchaseRequest(String id) =>
      '$baseUrl/marketplace/publications/$id/purchase-request';
  static String confirmSale(String id) =>
      '$baseUrl/marketplace/publications/$id/confirm-sale';
  static String cancelPublication(String id) =>
      '$baseUrl/marketplace/publications/$id/cancel';
  static String publicationPurchaseRequests(String id) =>
      '$baseUrl/marketplace/publications/$id/purchase-requests';
  static String sanitaryDocuments(String id) =>
      '$baseUrl/marketplace/publications/$id/sanitary-documents';
  static String rejectPurchaseRequest(String id) =>
      '$baseUrl/marketplace/purchase-requests/$id/reject';

  // Workers
  static const String workers = '$baseUrl/workers';
  static String workerById(String id) => '$workers/$id';

  // Admin
  static const String adminUsers = '$baseUrl/admin/users';
  static String deactivateUser(String id) => '$baseUrl/admin/users/$id/deactivate';
  static String verifyUser(String id) => '$baseUrl/admin/users/$id/verify';
  static const String adminPublications = '$baseUrl/admin/publications';
  static String adminCancelPublication(String id) =>
      '$baseUrl/admin/publications/$id/cancel';
  static const String auditLogs = '$baseUrl/admin/audit-logs';
  static const String salesTraceability = '$baseUrl/admin/sales';
  static const String adminAlerts = '$baseUrl/admin/alerts';

  // Catalogs (public)
  static const String catalogProductionTypes =
      '$baseUrl/admin/catalogs/production-types';
  static const String catalogBovineCategories =
      '$baseUrl/admin/catalogs/bovine-categories';
  static const String catalogHealthStatuses =
      '$baseUrl/admin/catalogs/health-statuses';
  static const String catalogSalePurposes =
      '$baseUrl/admin/catalogs/sale-purposes';
  static const String catalogAccountTypes =
      '$baseUrl/admin/catalogs/account-types';

  // ── Legacy MuuSmart constants (compile-compat only — not navigable in UI) ──
  static const String animal   = '$baseUrl/bovines';
  static const String stable   = '$baseUrl/stables';
  static const String vaccine  = '$baseUrl/vaccines';
  static const String campaign = '$baseUrl/campaigns';
  static const String staff    = '$baseUrl/staff';
  static const String report   = '$baseUrl/admin';
  // ──────────────────────────────────────────────────────────────────────────
}
