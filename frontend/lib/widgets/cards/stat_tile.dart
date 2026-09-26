import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../common/skeleton.dart';

/// Compact dual-tone stat tile.
///
/// Used in the Quick Stats row on the Home Dashboard.
/// No shadow, no gradient — clean elevated surface + thin border.
class StatTile extends StatelessWidget {
  final String label;
  final String amount;
  final Color amountColor;
  final bool isLoading;

  const StatTile({
    super.key,
    required this.label,
    required this.amount,
    required this.amountColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkeletonBox(height: 72, borderRadius: AppRadius.lg);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: AppTypography.amount.copyWith(color: amountColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
