import '../config/api_config.dart';
import '../models/analytics.dart';
import 'api_client.dart';

class AnalyticsService {
  final ApiClient _apiClient;

  AnalyticsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get summary of income, expense, and balance for a specific month ('YYYY-MM').
  Future<AnalyticsSummary> getSummary(String month) async {
    final response = await _apiClient.get(
      ApiConfig.analyticsSummary,
      queryParameters: {'month': month},
    );

    return AnalyticsSummary.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get category-wise spending breakdown for a month ('YYYY-MM').
  Future<CategoryBreakdown> getCategoryBreakdown(
    String month, {
    String? type, // 'expense' or 'income'
  }) async {
    final queryParams = <String, dynamic>{'month': month};
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final response = await _apiClient.get(
      ApiConfig.analyticsCategories,
      queryParameters: queryParams,
    );

    return CategoryBreakdown.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get 12-month income/expense trend for a given year.
  Future<MonthlyTrend> getMonthlyTrend(int year) async {
    final response = await _apiClient.get(
      ApiConfig.analyticsMonthly,
      queryParameters: {'year': year},
    );

    return MonthlyTrend.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get all-time user balance.
  Future<BalanceSummary> getBalance() async {
    final response = await _apiClient.get(ApiConfig.analyticsBalance);
    return BalanceSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
