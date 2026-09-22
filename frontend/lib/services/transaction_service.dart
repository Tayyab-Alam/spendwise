import '../config/api_config.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class TransactionService {
  final ApiClient _apiClient;

  TransactionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch transactions with optional filters and pagination.
  Future<List<Transaction>> getTransactions({
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
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sort_order'] = sortOrder;
    if (skip != null) queryParams['skip'] = skip;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiClient.get(
      ApiConfig.transactions,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final list = response.data as List<dynamic>;
    return list
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single transaction by ID.
  Future<Transaction> getTransaction(int id) async {
    final response = await _apiClient.get(ApiConfig.transaction(id));
    return Transaction.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create a new transaction.
  Future<Transaction> createTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required String date, // 'YYYY-MM-DD'
    String? note,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.transactions,
      data: {
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'date': date,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    return Transaction.fromJson(response.data as Map<String, dynamic>);
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
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type;
    if (amount != null) data['amount'] = amount;
    if (categoryId != null) data['category_id'] = categoryId;
    if (date != null) data['date'] = date;
    if (note != null) data['note'] = note.trim();

    final response = await _apiClient.put(
      ApiConfig.transaction(id),
      data: data,
    );

    return Transaction.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a transaction by ID.
  Future<void> deleteTransaction(int id) async {
    await _apiClient.delete(ApiConfig.transaction(id));
  }
}
