import 'package:flutter/painting.dart';

/// Maps category names to their muted brand colors.
/// Used for category icon chip tints and progress bars.
class CategoryColors {
  CategoryColors._();

  static const Map<String, Color> _map = {
    'Food': Color(0xFF22C55E),          // green
    'Transport': Color(0xFF6C63FF),     // indigo
    'Bills': Color(0xFFF59E0B),         // amber
    'Shopping': Color(0xFFEC4899),      // pink
    'Entertainment': Color(0xFF8B5CF6), // purple
    'Health': Color(0xFFEF4444),        // red
    'Education': Color(0xFF06B6D4),     // cyan
    'Other Expense': Color(0xFF6B7280), // gray
    'Salary': Color(0xFF22C55E),        // green
    'Freelance': Color(0xFF6C63FF),     // indigo
    'Business': Color(0xFFF59E0B),      // amber
    'Investment': Color(0xFF10B981),    // emerald
    'Other Income': Color(0xFF8B5CF6),  // purple
  };

  static const Color _default = Color(0xFF6B7280); // gray

  /// Returns the color for the given category name, or the default color.
  static Color forCategory(String name) {
    return _map[name] ?? _default;
  }
}
