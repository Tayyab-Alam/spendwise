import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Maps category names to their Material Symbols icon.
/// Used across the app for category icon chips.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _map = {
    'Food': Symbols.restaurant,
    'Transport': Symbols.directions_car,
    'Bills': Symbols.receipt_long,
    'Shopping': Symbols.shopping_bag,
    'Entertainment': Symbols.movie,
    'Health': Symbols.medical_services,
    'Education': Symbols.school,
    'Other Expense': Symbols.more_horiz,
    'Salary': Symbols.payments,
    'Freelance': Symbols.work_outline,
    'Business': Symbols.business_center,
    'Investment': Symbols.trending_up,
    'Other Income': Symbols.add_circle_outline,
  };

  static const IconData _default = Symbols.category;

  /// Returns the icon for the given category name, or the default icon.
  static IconData forCategory(String name) {
    return _map[name] ?? _default;
  }
}
