class Category {
  final int id;
  final String name;
  final String type; // 'income' | 'expense'
  final int? userId;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isDefault => userId == null;
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      userId: json['user_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'user_id': userId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    int? userId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
