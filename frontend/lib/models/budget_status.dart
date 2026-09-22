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

  bool get isSafe => status == 'safe';
  bool get isApproaching => status == 'approaching';
  bool get isExceeded => status == 'exceeded';

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    return BudgetStatus(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      month: json['month'] as String,
      limitAmount: _parseAmount(json['limit_amount']),
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      spent: _parseAmount(json['spent']),
      remaining: _parseAmount(json['remaining']),
      percentage: _parsePercentage(json['percentage']),
      status: json['status'] as String? ?? 'safe',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'spent': spent,
      'remaining': remaining,
      'percentage': percentage,
      'status': status,
    });
    return map;
  }

  static double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static double _parsePercentage(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  BudgetStatus copyWithStatus({
    int? id,
    int? userId,
    int? categoryId,
    String? month,
    double? limitAmount,
    Category? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? spent,
    double? remaining,
    double? percentage,
    String? status,
  }) {
    return BudgetStatus(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      limitAmount: limitAmount ?? this.limitAmount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
    );
  }
}
