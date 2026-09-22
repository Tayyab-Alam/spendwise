class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 30);

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // User endpoints
  static const String usersMe = '/users/me';

  // Category endpoints
  static const String categories = '/categories';
  static String category(int id) => '/categories/$id';

  // Transaction endpoints
  static const String transactions = '/transactions';
  static String transaction(int id) => '/transactions/$id';

  // Budget endpoints
  static const String budgets = '/budgets';
  static String budget(int id) => '/budgets/$id';
  static String budgetStatus(int id) => '/budgets/$id/status';

  // Analytics endpoints
  static const String analyticsSummary = '/analytics/summary';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsMonthly = '/analytics/monthly';
  static const String analyticsBalance = '/analytics/balance';
}
