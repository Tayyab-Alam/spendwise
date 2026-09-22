import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Format an amount as Pakistani Rupee currency.
  /// Example: "PKR 85,000.00" or "PKR 85k" (compact).
  static String currency(double amount, {bool compact = false}) {
    if (compact) {
      final isNegative = amount < 0;
      final abs = amount.abs();
      String formatted;
      if (abs >= 1000000) {
        final val = (abs / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        formatted = '${val}M';
      } else if (abs >= 1000) {
        final val = (abs / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        formatted = '${val}k';
      } else {
        formatted = abs.toStringAsFixed(0);
      }
      return isNegative ? '-PKR $formatted' : 'PKR $formatted';
    }

    final formatter = NumberFormat.currency(
      symbol: 'PKR ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format as full readable date.
  /// Example: "Sep 21, 2026"
  static String date(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format as short date without year.
  /// Example: "Sep 21"
  static String shortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format as relative date label.
  /// Example: "Today", "Yesterday", or "Sep 15"
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  /// Format YYYY-MM string to full month label.
  /// Example: "2026-09" → "September 2026"
  static String monthLabel(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final dt = DateTime(year, m);
        return DateFormat('MMMM yyyy').format(dt);
      }
    } catch (_) {}
    return month;
  }

  /// Format percentage to two decimal places.
  /// Example: 82.86 → "82.86%"
  static String percentage(double value) {
    return '${value.toStringAsFixed(2)}%';
  }
}
