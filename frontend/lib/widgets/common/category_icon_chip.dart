import 'package:flutter/material.dart';

import '../../core/constants/category_colors.dart';
import '../../core/constants/category_icons.dart';

/// 40×40 rounded-square icon chip for a category.
///
/// Background is tinted at 15% opacity of the category color.
/// Icon is rendered at full category color.
class CategoryIconChip extends StatelessWidget {
  final String categoryName;
  final double size;
  final double iconSize;
  final double borderRadius;

  const CategoryIconChip({
    super.key,
    required this.categoryName,
    this.size = 40,
    this.iconSize = 20,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.forCategory(categoryName);
    final icon = CategoryIcons.forCategory(categoryName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}
