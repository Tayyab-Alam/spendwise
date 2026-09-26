import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../core/constants/category_colors.dart';
import '../../utils/formatters.dart';
import '../common/category_icon_chip.dart';

/// A single category row with icon, name, amount, and a progress bar.
///
/// Used in the "Spending this month" section of the Home Dashboard.
class CategoryProgressRow extends StatelessWidget {
  final String categoryName;
  final double amount;
  final double percentage;

  const CategoryProgressRow({
    super.key,
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = CategoryColors.forCategory(categoryName);
    final progressBg = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Clamp to [0,1]
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CategoryIconChip(categoryName: categoryName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + amount row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                      ),
                    ),
                    Text(
                      Formatters.currency(amount),
                      style: AppTypography.amount.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: progressBg,
                    valueColor: AlwaysStoppedAnimation<Color>(catColor),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Percentage label
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.caption.copyWith(
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
