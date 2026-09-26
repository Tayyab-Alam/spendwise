import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/budget.dart';
import '../models/budget_status.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService;

  List<Budget> _budgets = [];
  final Map<int, BudgetStatus> _statuses = {};
  bool _isLoading = false;
  String? _error;
  String? _currentMonth;

  BudgetProvider({BudgetService? budgetService})
      : _budgetService = budgetService ?? BudgetService();

  List<Budget> get budgets => List.unmodifiable(_budgets);
  Map<int, BudgetStatus> get statuses => Map.unmodifiable(_statuses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentMonth => _currentMonth;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load budgets for a specific month ('YYYY-MM').
  Future<void> loadBudgets([String? month]) async {
    _isLoading = true;
    _error = null;
    if (month != null) _currentMonth = month;
    notifyListeners();

    try {
      final list = await _budgetService.getBudgets(month: _currentMonth);
      _budgets = list;

      // Load status for each budget in parallel (silently)
      await Future.wait(
        list.map((b) => _fetchStatusSilently(b.id)),
      );

      _isLoading = false;
      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw ApiException(_error!);
    }
  }

  /// Load budget status for a single budget ID.
  Future<BudgetStatus> loadBudgetStatus(int id) async {
    try {
      final status = await _budgetService.getBudgetStatus(id);
      _statuses[id] = status;
      notifyListeners();
      return status;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw ApiException(_error!);
    }
  }

  Future<void> _fetchStatusSilently(int id) async {
    try {
      final status = await _budgetService.getBudgetStatus(id);
      _statuses[id] = status;
    } catch (_) {}
  }

  /// Create a new budget.
  Future<Budget> createBudget({
    required int categoryId,
    required String month,
    required double limitAmount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final budget = await _budgetService.createBudget(
        categoryId: categoryId,
        month: month,
        limitAmount: limitAmount,
      );
      _budgets = [..._budgets, budget];
      await _fetchStatusSilently(budget.id);

      _isLoading = false;
      notifyListeners();
      return budget;
    } on AppException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw ApiException(_error!);
    }
  }

  /// Update an existing budget limit.
  Future<Budget> updateBudget(int id, double limitAmount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _budgetService.updateBudget(id, limitAmount);
      _budgets = _budgets.map((b) => b.id == id ? updated : b).toList();
      await _fetchStatusSilently(id);

      _isLoading = false;
      notifyListeners();
      return updated;
    } on AppException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw ApiException(_error!);
    }
  }

  /// Delete a budget.
  Future<void> deleteBudget(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _budgetService.deleteBudget(id);
      _budgets = _budgets.where((b) => b.id != id).toList();
      _statuses.remove(id);

      _isLoading = false;
      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw ApiException(_error!);
    }
  }
}