import 'budget.dart';
import 'category.dart';

class BudgetStatus extends Budget {
  final double spent;
  final double remaining;
  final double percentage;
  final String status; // 'safe' | 'approaching' | 'exceeded'

  const BudgetStatus({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.month,
    required super.limitAmount,
    super.category,
    required super.createdAt,
    required super.updatedAt,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    return BudgetStatus(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      month: json['month'] as String,
      limitAmount: _parseDouble(json['limit_amount']),
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      spent: _parseDouble(json['spent']),
      remaining: _parseDouble(json['remaining']),
      percentage: _parseDouble(json['percentage']),
      status: json['status'] as String? ?? 'safe',
    );
  }

  bool get isSafe => status == 'safe';
  bool get isApproaching => status == 'approaching';
  bool get isExceeded => status == 'exceeded';

  /// Converts this BudgetStatus back to a plain Budget.
  Budget toBudget() {
    return Budget(
      id: id,
      userId: userId,
      categoryId: categoryId,
      month: month,
      limitAmount: limitAmount,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}