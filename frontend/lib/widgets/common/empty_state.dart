import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';

/// Full-section empty state widget.
///
/// Shows a large icon, heading, optional subtext, and an optional action button.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String? subtext;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.heading,
    this.subtext,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: secondaryColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            heading,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          if (subtext != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtext!,
              style: AppTypography.caption.copyWith(color: secondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
