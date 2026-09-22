double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

class AnalyticsSummary {
  final String month;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final int transactionCount;

  const AnalyticsSummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.transactionCount,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      month: json['month'] as String,
      totalIncome: _parseDouble(json['total_income']),
      totalExpense: _parseDouble(json['total_expense']),
      netBalance: _parseDouble(json['net_balance']),
      transactionCount: json['transaction_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net_balance': netBalance,
      'transaction_count': transactionCount,
    };
  }
}

class CategorySpending {
  final int categoryId;
  final String name;
  final String type; // 'income' | 'expense'
  final double total;
  final double percentage;

  const CategorySpending({
    required this.categoryId,
    required this.name,
    required this.type,
    required this.total,
    required this.percentage,
  });

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      total: _parseDouble(json['total']),
      percentage: _parseDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'type': type,
      'total': total,
      'percentage': percentage,
    };
  }
}

class CategoryBreakdown {
  final String month;
  final double totalSpent;
  final List<CategorySpending> categories;

  const CategoryBreakdown({
    required this.month,
    required this.totalSpent,
    required this.categories,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    final list = json['categories'] as List<dynamic>? ?? [];
    return CategoryBreakdown(
      month: json['month'] as String,
      totalSpent: _parseDouble(json['total_spent']),
      categories: list
          .map((item) => CategorySpending.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'total_spent': totalSpent,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}

class MonthlyTrendItem {
  final String month; // 'YYYY-MM'
  final double income;
  final double expense;

  const MonthlyTrendItem({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  factory MonthlyTrendItem.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendItem(
      month: json['month'] as String,
      income: _parseDouble(json['income']),
      expense: _parseDouble(json['expense']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'income': income,
      'expense': expense,
    };
  }
}

class MonthlyTrend {
  final int year;
  final List<MonthlyTrendItem> months;

  const MonthlyTrend({
    required this.year,
    required this.months,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    final list = json['months'] as List<dynamic>? ?? [];
    return MonthlyTrend(
      year: json['year'] as int,
      months: list
          .map((item) => MonthlyTrendItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'months': months.map((e) => e.toJson()).toList(),
    };
  }
}

class BalanceSummary {
  final double totalIncome;
  final double totalExpense;
  final double currentBalance;

  const BalanceSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalance,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    return BalanceSummary(
      totalIncome: _parseDouble(json['total_income']),
      totalExpense: _parseDouble(json['total_expense']),
      currentBalance: _parseDouble(json['current_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'current_balance': currentBalance,
    };
  }
}
