import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/user.dart';
import '../routes/app_router.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    final handleUnauthorized = () async {
      await logout();
      _error = 'Session expired. Please log in again.';
      notifyListeners();
      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
      }
    };
    _authService.apiClient.onUnauthorized = handleUnauthorized;
    ApiClient.onUnauthorizedGlobal = handleUnauthorized;
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated && _user != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Attempt auto-login using persisted token on application startup.
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasToken = await _authService.storageService.hasToken();
      if (!hasToken) {
        _isLoading = false;
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }

      // First attempt to load cached user for instant state restoration
      final cachedUser = await _authService.storageService.getUser();
      if (cachedUser != null) {
        _user = cachedUser;
        _isAuthenticated = true;
        notifyListeners();
      }

      // Verify token with backend
      final user = await _authService.getCurrentUser();
      _user = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      // Invalidate on auth/token error
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user account.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      // Auto-login: acquire JWT token and establish session
      await _authService.login(email: email, password: password);
      _user = newUser;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return newUser;
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

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      final user = await _authService.getCurrentUser();
      _user = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      throw ApiException(_error!);
    }
  }

  /// Log out and reset session state.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Update the current user's profile.
  Future<User> updateProfile({
    String? name,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _authService.updateProfile(
        name: name,
        email: email,
      );
      _user = updated;
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
}
