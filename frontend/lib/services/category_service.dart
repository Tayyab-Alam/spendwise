import '../config/api_config.dart';
import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient;

  CategoryService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// List all categories (default + user's custom), optionally filtered by type.
  Future<List<Category>> getCategories({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final response = await _apiClient.get(
      ApiConfig.categories,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final list = response.data as List<dynamic>;
    return list
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create a custom category for the authenticated user.
  Future<Category> createCategory({
    required String name,
    required String type, // 'income' | 'expense'
  }) async {
    final response = await _apiClient.post(
      ApiConfig.categories,
      data: {
        'name': name.trim(),
        'type': type,
      },
    );

    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update a custom category.
  Future<Category> updateCategory(
    int id, {
    String? name,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      data['name'] = name.trim();
    }
    if (isActive != null) {
      data['is_active'] = isActive;
    }

    final response = await _apiClient.put(
      ApiConfig.category(id),
      data: data,
    );

    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a custom category.
  Future<void> deleteCategory(int id) async {
    await _apiClient.delete(ApiConfig.category(id));
  }
}
