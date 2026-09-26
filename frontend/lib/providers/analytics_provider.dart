import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService;

  BalanceSummary? _balance;
  AnalyticsSummary? _summary;
  CategoryBreakdown? _breakdown;
  MonthlyTrend? _trend;
  bool _isLoading = false;
  String? _error;

  AnalyticsProvider({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService ?? AnalyticsService();

  BalanceSummary? get balance => _balance;
  AnalyticsSummary? get summary => _summary;
  CategoryBreakdown? get breakdown => _breakdown;
  MonthlyTrend? get trend => _trend;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load balance.
  /// NOTE: We do NOT clear _balance at the start of the fetch.
  /// This prevents the UI from flickering to 0 or loading during refetch.
  Future<void> loadBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _analyticsService.getBalance();
      _balance = result;   // ← Only set when we have new data
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

  /// Load summary for a month.
  Future<void> loadSummary(String month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _analyticsService.getSummary(month);
      _summary = result;
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

  /// Load category breakdown for a month.
  Future<void> loadBreakdown(String month, {String type = 'expense'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _analyticsService.getCategoryBreakdown(
        month,
        type: type,
      );
      _breakdown = result;
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

  /// Load monthly trend for a year.
  Future<void> loadTrend(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _analyticsService.getMonthlyTrend(year);
      _trend = result;
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