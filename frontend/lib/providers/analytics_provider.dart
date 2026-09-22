import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService;

  AnalyticsSummary? _summary;
  CategoryBreakdown? _breakdown;
  MonthlyTrend? _trend;
  BalanceSummary? _balance;
  bool _isLoading = false;
  String? _error;

  AnalyticsProvider({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService ?? AnalyticsService();

  AnalyticsSummary? get summary => _summary;
  CategoryBreakdown? get breakdown => _breakdown;
  MonthlyTrend? get trend => _trend;
  BalanceSummary? get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load monthly summary (income, expense, net balance, transaction count).
  Future<void> loadSummary(String month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _analyticsService.getSummary(month);
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

  /// Load category-wise spending breakdown for a month.
  Future<void> loadBreakdown(String month, {String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _breakdown = await _analyticsService.getCategoryBreakdown(month, type: type);
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

  /// Load 12-month trend for a given year.
  Future<void> loadTrend(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trend = await _analyticsService.getMonthlyTrend(year);
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

  /// Load all-time user balance.
  Future<void> loadBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _balance = await _analyticsService.getBalance();
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

  /// Load all analytics data in parallel for a given month and year.
  Future<void> loadAll(String month, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _analyticsService.getSummary(month),
        _analyticsService.getCategoryBreakdown(month),
        _analyticsService.getMonthlyTrend(year),
        _analyticsService.getBalance(),
      ]);

      _summary = results[0] as AnalyticsSummary;
      _breakdown = results[1] as CategoryBreakdown;
      _trend = results[2] as MonthlyTrend;
      _balance = results[3] as BalanceSummary;

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
