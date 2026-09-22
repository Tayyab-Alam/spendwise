import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService({
    ApiClient? apiClient,
    StorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? StorageService();

  ApiClient get apiClient => _apiClient;
  StorageService get storageService => _storageService;

  /// Register a new user account.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.register,
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  /// Login and store the JWT access token.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String;

    await _storageService.saveToken(token);
    return token;
  }

  /// Fetch currently authenticated user profile and cache it.
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get(ApiConfig.usersMe);
    final user = User.fromJson(response.data as Map<String, dynamic>);
    await _storageService.saveUser(user);
    return user;
  }

  /// Update current user profile.
  Future<User> updateProfile({
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final response = await _apiClient.put(
      ApiConfig.usersMe,
      data: body,
    );

    final updated = User.fromJson(response.data as Map<String, dynamic>);
    await _storageService.saveUser(updated);
    return updated;
  }

  /// Log out by clearing stored credentials and cached data.
  Future<void> logout() async {
    await _storageService.clearAll();
  }
}
