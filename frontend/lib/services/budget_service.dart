import '../config/api_config.dart';
import '../models/budget.dart';
import '../models/budget_status.dart';
import 'api_client.dart';

class BudgetService {
  final ApiClient _apiClient;

  BudgetService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// List budgets for current user, optionally filtered by month ('YYYY-MM').
  Future<List<Budget>> getBudgets({String? month}) async {
    final queryParams = <String, dynamic>{};
    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    }

    final response = await _apiClient.get(
      ApiConfig.budgets,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final list = response.data as List<dynamic>;
    return list
        .map((item) => Budget.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create a budget for an expense category in a given month.
  Future<Budget> createBudget({
    required int categoryId,
    required String month, // 'YYYY-MM'
    required double limitAmount,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.budgets,
      data: {
        'category_id': categoryId,
        'month': month,
        'limit_amount': limitAmount,
      },
    );

    return Budget.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetch a single budget by ID.
  Future<Budget> getBudget(int id) async {
    final response = await _apiClient.get(ApiConfig.budget(id));
    return Budget.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetch live status (spent, remaining, percentage, status) for a budget.
  Future<BudgetStatus> getBudgetStatus(int id) async {
    final response = await _apiClient.get(ApiConfig.budgetStatus(id));
    return BudgetStatus.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update the limit amount of an existing budget.
  Future<Budget> updateBudget(int id, double limitAmount) async {
  final response = await _apiClient.put(
    '/budgets/$id',
    data: {'limit_amount': limitAmount},
  );
  return Budget.fromJson(response.data);
}

  /// Delete a budget.
  Future<void> deleteBudget(int id) async {
    await _apiClient.delete(ApiConfig.budget(id));
  }
}
