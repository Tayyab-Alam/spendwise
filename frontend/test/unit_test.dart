import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/analytics.dart';
import 'package:spendwise/models/budget_status.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/models/user.dart';
import 'package:spendwise/utils/formatters.dart';
import 'package:spendwise/utils/validators.dart';

void main() {
  group('Model Serialization & Decimal Parsing', () {
    test('User fromJson and toJson', () {
      final json = {
        'id': 1,
        'name': 'Tayyab Alam',
        'email': 'tayyab@example.com',
        'created_at': '2026-09-21T10:30:00.000Z',
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Tayyab Alam');
      expect(user.email, 'tayyab@example.com');
      expect(user.toJson()['email'], 'tayyab@example.com');
    });

    test('Category default and custom categorization', () {
      final defaultCat = Category.fromJson({
        'id': 1,
        'name': 'Food',
        'type': 'expense',
        'user_id': null,
        'is_active': true,
        'created_at': '2026-09-21T10:30:00.000Z',
      });
      expect(defaultCat.isDefault, isTrue);
      expect(defaultCat.isExpense, isTrue);
      expect(defaultCat.isIncome, isFalse);

      final customCat = Category.fromJson({
        'id': 10,
        'name': 'Freelance',
        'type': 'income',
        'user_id': 2,
        'is_active': true,
        'created_at': '2026-09-21T10:30:00.000Z',
      });
      expect(customCat.isDefault, isFalse);
      expect(customCat.isIncome, isTrue);
    });

    test('Transaction parses string amount to double', () {
      final json = {
        'id': 101,
        'user_id': 1,
        'type': 'expense',
        'amount': '500.50',
        'category_id': 1,
        'date': '2026-09-21',
        'note': 'Lunch',
        'created_at': '2026-09-21T12:00:00.000Z',
        'updated_at': '2026-09-21T12:00:00.000Z',
      };
      final tx = Transaction.fromJson(json);
      expect(tx.amount, 500.50);
      expect(tx.isExpense, isTrue);
      expect(tx.note, 'Lunch');
    });

    test('Budget and BudgetStatus calculations', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'category_id': 1,
        'month': '2026-09',
        'limit_amount': '7000.00',
        'created_at': '2026-09-01T00:00:00.000Z',
        'updated_at': '2026-09-01T00:00:00.000Z',
        'spent': '5800.00',
        'remaining': '1200.00',
        'percentage': 82.86,
        'status': 'approaching',
      };
      final status = BudgetStatus.fromJson(json);
      expect(status.limitAmount, 7000.00);
      expect(status.spent, 5800.00);
      expect(status.remaining, 1200.00);
      expect(status.percentage, 82.86);
      expect(status.isApproaching, isTrue);
      expect(status.isSafe, isFalse);
      expect(status.isExceeded, isFalse);
    });

    test('Analytics models parse numeric strings correctly', () {
      final summaryJson = {
        'month': '2026-09',
        'total_income': '60000.00',
        'total_expense': '28550.00',
        'net_balance': '31450.00',
        'transaction_count': 42,
      };
      final summary = AnalyticsSummary.fromJson(summaryJson);
      expect(summary.totalIncome, 60000.0);
      expect(summary.totalExpense, 28550.0);
      expect(summary.netBalance, 31450.0);
      expect(summary.transactionCount, 42);

      final breakdownJson = {
        'month': '2026-09',
        'total_spent': '28550.00',
        'categories': [
          {
            'category_id': 1,
            'name': 'Food',
            'type': 'expense',
            'total': '8200.00',
            'percentage': 28.71,
          }
        ],
      };
      final breakdown = CategoryBreakdown.fromJson(breakdownJson);
      expect(breakdown.totalSpent, 28550.0);
      expect(breakdown.categories.length, 1);
      expect(breakdown.categories.first.total, 8200.0);

      final balanceJson = {
        'total_income': '360000.00',
        'total_expense': '175000.00',
        'current_balance': '185000.00',
      };
      final balance = BalanceSummary.fromJson(balanceJson);
      expect(balance.currentBalance, 185000.0);
    });
  });

  group('Formatters', () {
    test('currency formatting standard and compact', () {
      expect(Formatters.currency(85000.0), 'PKR 85,000.00');
      expect(Formatters.currency(85000.0, compact: true), 'PKR 85k');
      expect(Formatters.currency(1500000.0, compact: true), 'PKR 1.5M');
      expect(Formatters.currency(2000000.0, compact: true), 'PKR 2M');
    });

    test('date and relative date formatting', () {
      final date = DateTime(2026, 9, 21);
      expect(Formatters.date(date), 'Sep 21, 2026');
      expect(Formatters.shortDate(date), 'Sep 21');

      final now = DateTime.now();
      expect(Formatters.relativeDate(now), 'Today');
      expect(
        Formatters.relativeDate(now.subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });

    test('monthLabel and percentage', () {
      expect(Formatters.monthLabel('2026-09'), 'September 2026');
      expect(Formatters.percentage(82.86), '82.86%');
    });
  });

  group('Validators', () {
    test('email validator', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('invalid-email'), 'Please enter a valid email address');
      expect(Validators.email('test@example.com'), isNull);
    });

    test('password validator', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password('1234567'), 'Password must be at least 8 characters');
      expect(Validators.password('12345678'), isNull);
    });

    test('amount validator', () {
      expect(Validators.amount(null), 'Amount is required');
      expect(Validators.amount('abc'), 'Please enter a valid numeric amount');
      expect(Validators.amount('0'), 'Amount must be greater than 0');
      expect(Validators.amount('-50'), 'Amount must be greater than 0');
      expect(Validators.amount('500.50'), isNull);
      expect(Validators.amount('1,500.00'), isNull);
    });

    test('name and required validators', () {
      expect(Validators.name(null), 'Name is required');
      expect(Validators.name('Tayyab Alam'), isNull);
      expect(Validators.required(null, 'Note'), 'Note is required');
      expect(Validators.required('Some note'), isNull);
    });
  });
}
