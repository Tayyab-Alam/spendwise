import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Filter state
  String? _filterType;
  int? _filterCategoryId;
  String? _filterDateFrom;
  String? _filterDateTo;
  String? _filterSearch;
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  int _skip = 0;
  final int _limit = 50;

  TransactionProvider({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService();

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter getters
  String? get filterType => _filterType;
  int? get filterCategoryId => _filterCategoryId;
  String? get filterDateFrom => _filterDateFrom;
  String? get filterDateTo => _filterDateTo;
  String? get filterSearch => _filterSearch;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  int get skip => _skip;
  int get limit => _limit;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load transactions using current or custom filters.
  Future<void> loadTransactions({
    String? type,
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? skip,
    int? limit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _transactionService.getTransactions(
        type: type ?? _filterType,
        categoryId: categoryId ?? _filterCategoryId,
        dateFrom: dateFrom ?? _filterDateFrom,
        dateTo: dateTo ?? _filterDateTo,
        search: search ?? _filterSearch,
        sortBy: sortBy ?? _sortBy,
        sortOrder: sortOrder ?? _sortOrder,
        skip: skip ?? _skip,
        limit: limit ?? _limit,
      );

      _transactions = items;
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

  /// Apply new filter values and reload.
  Future<void> applyFilters({
    String? type,
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    _filterType = type;
    _filterCategoryId = categoryId;
    _filterDateFrom = dateFrom;
    _filterDateTo = dateTo;
    _filterSearch = search;
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;
    _skip = 0;

    await loadTransactions();
  }

  /// Reset all filters to default and reload.
  Future<void> clearFilters() async {
    _filterType = null;
    _filterCategoryId = null;
    _filterDateFrom = null;
    _filterDateTo = null;
    _filterSearch = null;
    _sortBy = 'date';
    _sortOrder = 'desc';
    _skip = 0;

    await loadTransactions();
  }

  /// Create a transaction and prepend it to the list.
  Future<Transaction> createTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required String date,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final item = await _transactionService.createTransaction(
        type: type,
        amount: amount,
        categoryId: categoryId,
        date: date,
        note: note,
      );
      _transactions = [item, ..._transactions];
      _isLoading = false;
      notifyListeners();
      return item;
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

  /// Update an existing transaction.
  Future<Transaction> updateTransaction(
    int id, {
    String? type,
    double? amount,
    int? categoryId,
    String? date,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _transactionService.updateTransaction(
        id,
        type: type,
        amount: amount,
        categoryId: categoryId,
        date: date,
        note: note,
      );
      _transactions = _transactions.map((t) => t.id == id ? updated : t).toList();
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

  /// Delete a transaction by ID.
  Future<void> deleteTransaction(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _transactionService.deleteTransaction(id);
      _transactions = _transactions.where((t) => t.id != id).toList();
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
