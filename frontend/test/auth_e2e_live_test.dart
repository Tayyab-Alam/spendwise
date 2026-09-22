import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/providers/auth_provider.dart';
import 'package:spendwise/services/api_client.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/services/storage_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});

  test('Live Auth Flow E2E: Register -> Auto-login -> Logout -> Login -> Auto-login check', () async {
    final storageService = StorageService();
    final apiClient = ApiClient(storageService: storageService);
    final authService = AuthService(apiClient: apiClient, storageService: storageService);
    final authProvider = AuthProvider(authService: authService);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'phase2_e2e_$timestamp@example.com';
    const testPassword = 'password12345';
    const testName = 'Phase2 Auth Tester';

    // 1. Initial State: Unauthenticated
    expect(authProvider.isAuthenticated, isFalse);
    expect(authProvider.user, isNull);

    // 2. Register with Auto-Login
    final registeredUser = await authProvider.register(
      name: testName,
      email: testEmail,
      password: testPassword,
    );

    expect(registeredUser.id, greaterThan(0));
    expect(registeredUser.email, testEmail);
    expect(registeredUser.name, testName);

    // Verify auto-login succeeded: session active & token in secure storage
    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.user?.id, registeredUser.id);
    final storedToken = await storageService.getToken();
    expect(storedToken, isNotNull);
    expect(storedToken!.isNotEmpty, isTrue);

    // 3. Logout
    await authProvider.logout();
    expect(authProvider.isAuthenticated, isFalse);
    expect(authProvider.user, isNull);
    final tokenAfterLogout = await storageService.getToken();
    expect(tokenAfterLogout, isNull);

    // 4. Login with same credentials
    await authProvider.login(
      email: testEmail,
      password: testPassword,
    );
    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.user?.email, testEmail);

    final tokenAfterLogin = await storageService.getToken();
    expect(tokenAfterLogin, isNotNull);

    // 5. Try Auto-Login (simulating app restart)
    final autoLoginSuccess = await authProvider.tryAutoLogin();
    expect(autoLoginSuccess, isTrue);
    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.user?.email, testEmail);

    // Clean up
    await authProvider.logout();
  });
}
