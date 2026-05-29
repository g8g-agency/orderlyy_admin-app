class ApiConstants {
  static const String apiVersion = '/api/v1';

  // Auth Endpoints
  static const String login = '$apiVersion/auth/login';
  static const String logout = '$apiVersion/auth/logout';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String changePassword = '$apiVersion/auth/change-password';

  // Restaurant Context Endpoints
  static const String restaurantContext = '$apiVersion/context/bootstrap';
  static const String currentTenant = '$apiVersion/tenants/current';
  static const String selectOrganization = '$apiVersion/tenants/select';

  // Menu & Catalog Endpoints
  static const String categories = '$apiVersion/menu/categories';
  static const String menuItems = '$apiVersion/menu/items';
  static const String pricing = '$apiVersion/pricing';
  static const String taxes = '$apiVersion/tax/profiles';
  static const String modifiers = '$apiVersion/modifier/groups';

  // Operational Endpoints
  static const String tables = '$apiVersion/tables';
  static const String availability = '$apiVersion/availability';
  static const String orders = '$apiVersion/orders';
  static const String staff = '$apiVersion/staff';

  // Analytics & Settings
  static const String analytics = '$apiVersion/analytics';
  static const String settings = '$apiVersion/settings';

  // Runtime Observability
  static const String runtimeObservability =
      '$apiVersion/runtime/observability';
  static const String runtimeCertify = '$apiVersion/runtime/certify';
}
