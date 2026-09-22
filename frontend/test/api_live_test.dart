import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/services/analytics_service.dart';
import 'package:spendwise/services/api_client.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/services/budget_service.dart';
import 'package:spendwise/services/category_service.dart';
import 'package:spendwise/services/transaction_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});

  test('Live End-to-End Foundation Verification against http://localhost:8000', () async {
    final apiClient = ApiClient();
    final authService = AuthService(apiClient: apiClient);
    final categoryService = CategoryService(apiClient: apiClient);
    final transactionService = TransactionService(apiClient: apiClient);
    final budgetService = BudgetService(apiClient: apiClient);
    final analyticsService = AnalyticsService(apiClient: apiClient);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'foundation_$timestamp@example.com';

    // 1. Auth: Register & Login
    final user = await authService.register(
      name: 'Full E2E Tester',
      email: testEmail,
      password: 'password12345',
    );
    expect(user.id, greaterThan(0));

    final token = await authService.login(
      email: testEmail,
      password: 'password12345',
    );
    expect(token, isNotEmpty);

    final me = await authService.getCurrentUser();
    expect(me.id, user.id);

    // 2. Categories: List seeded default categories
    final categories = await categoryService.getCategories();
    expect(categories.length, greaterThanOrEqualTo(13)); // 13 seeded default categories
    final expenseCat = categories.firstWhere((c) => c.isExpense);

    // 3. Transactions: Create & List
    final tx = await transactionService.createTransaction(
      type: expenseCat.type,
      amount: 1500.0,
      categoryId: expenseCat.id,
      date: '2026-09-21',
      note: 'Foundation phase live test expense',
    );
    expect(tx.id, greaterThan(0));
    expect(tx.amount, 1500.0);

    final txList = await transactionService.getTransactions();
    expect(txList.any((t) => t.id == tx.id), isTrue);

    // 4. Budgets: Create & Check Status
    final budget = await budgetService.createBudget(
      categoryId: expenseCat.id,
      month: '2026-09',
      limitAmount: 5000.0,
    );
    expect(budget.id, greaterThan(0));
    expect(budget.limitAmount, 5000.0);

    final status = await budgetService.getBudgetStatus(budget.id);
    expect(status.id, budget.id);
    expect(status.spent, 1500.0);
    expect(status.remaining, 3500.0);
    expect(status.percentage, 30.0);
    expect(status.isSafe, isTrue);

    // 5. Analytics: Summary and Balance
    final summary = await analyticsService.getSummary('2026-09');
    expect(summary.month, '2026-09');
    expect(summary.totalExpense, 1500.0);

    final balance = await analyticsService.getBalance();
    expect(balance.totalExpense, 1500.0);
  });
}
