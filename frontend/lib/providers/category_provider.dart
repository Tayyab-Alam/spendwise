import 'package:flutter/foundation.dart' hide Category;

import '../core/errors/app_exception.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider({CategoryService? categoryService})
      : _categoryService = categoryService ?? CategoryService();

  List<Category> get categories => List.unmodifiable(_categories);
  List<Category> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();
  List<Category> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load categories from backend.
  Future<void> loadCategories({String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _categoryService.getCategories(type: type);
      _categories = fetched;
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

  /// Create a new category and add it to the state.
  Future<Category> createCategory({
    required String name,
    required String type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final category = await _categoryService.createCategory(
        name: name,
        type: type,
      );
      _categories = [..._categories, category];
      _isLoading = false;
      notifyListeners();
      return category;
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

  /// Update an existing category.
  Future<Category> updateCategory(
    int id, {
    String? name,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _categoryService.updateCategory(
        id,
        name: name,
        isActive: isActive,
      );
      _categories = _categories.map((c) => c.id == id ? updated : c).toList();
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

  /// Delete a custom category by ID.
  Future<void> deleteCategory(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _categoryService.deleteCategory(id);
      _categories = _categories.where((c) => c.id != id).toList();
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
