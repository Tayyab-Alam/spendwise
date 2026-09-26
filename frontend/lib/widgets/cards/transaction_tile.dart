import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';
import '../common/category_icon_chip.dart';

/// Flat transaction row — NOT a card wrapper, just a row.
///
/// Shows category icon chip, category name, note/date, and amount.
/// A 1px divider is rendered below via the [showDivider] flag.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final amountColor = transaction.isIncome
      ? (isDark ? AppColors.income : AppColors.lightIncome)
      : (isDark ? AppColors.expense : AppColors.lightExpense);
    final amountPrefix = transaction.isIncome ? '+ ' : '- ';

    final categoryName = transaction.category?.name ?? 'Other';
    final dateLabel = Formatters.relativeDate(transaction.date);
    final timeLabel = _formatTime(transaction.date);
    final subtitle =
        transaction.note?.isNotEmpty == true
            ? transaction.note!
            : '$dateLabel · $timeLabel';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategoryIconChip(categoryName: categoryName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$amountPrefix${Formatters.currency(transaction.amount)}',
                style: AppTypography.amount.copyWith(color: amountColor),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: dividerColor,
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }
}
