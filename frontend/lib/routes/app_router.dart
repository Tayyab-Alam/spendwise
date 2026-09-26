import 'package:flutter/material.dart';

import '../config/theme/typography.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/budgets/add_budget_screen.dart';
import '../screens/budgets/budgets_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';
import '../screens/transactions/transactions_screen.dart';

class AppRouter {
  AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String categories = '/categories';
  static const String budgets = '/budgets';
  static const String addBudget = '/budgets/add';
  static const String insights = '/insights';
  static const String profile = '/profile';

  /// Standard route generator for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? splash);

    // Dynamic route: /transactions/:id
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'transactions') {
      final idParam = uri.pathSegments[1];
      if (idParam != 'add' && int.tryParse(idParam) != null) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              TransactionDetailScreen(transactionId: int.parse(idParam)),
        );
      }
    }

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShell(),
        );

      case transactions:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TransactionsScreen(),
        );

      case addTransaction:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddTransactionScreen(),
        );

      case categories:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CategoriesScreen(),
        );

      case budgets:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BudgetsScreen(),
        );

      case addBudget:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AddBudgetScreen(month: _currentMonth()),
        );

      case insights:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const InsightsScreen(),
        );

      case profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _PlaceholderScreen(
            title: 'Not Found',
            subtitle: 'No route defined for ${settings.name}',
          ),
        );
    }
  }

  /// Named routes map for direct route bindings
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        home: (_) => const MainShell(),
        transactions: (_) => const TransactionsScreen(),
        addTransaction: (_) => const AddTransactionScreen(),
        categories: (_) => const CategoriesScreen(),
        budgets: (_) => const BudgetsScreen(),
        addBudget: (_) => AddBudgetScreen(month: _currentMonth()),
        insights: (_) => const InsightsScreen(),
        profile: (_) => const ProfileScreen(),
      };
}

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PlaceholderScreen({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.h3),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style:
                  AppTypography.h2.copyWith(color: theme.colorScheme.onSurface),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTypography.body.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
