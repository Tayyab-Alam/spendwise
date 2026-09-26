import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/analytics.dart';
import '../../utils/formatters.dart';
import '../common/skeleton.dart';

/// Hero balance card — the flagship widget on the Home Dashboard.
///
/// Shows available balance, monthly income, and monthly expenses.
/// Includes count-up animation on first load, gradient background,
/// subtle indigo corner tint, and a radial glow in the top-left corner.
class BalanceCard extends StatefulWidget {
  final BalanceSummary? balance;
  final AnalyticsSummary? summary;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.summary,
    required this.isLoading,
    this.error,
    this.onRetry,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _balanceAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  /// Track the last value that was successfully shown.
  /// Initialize to null so first real load animates from 0 → value.
  double? _lastShownBalance;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final initial = widget.balance?.currentBalance ?? 0;
    _lastShownBalance = widget.balance != null ? initial : null;

    _balanceAnim = Tween<double>(begin: 0, end: initial).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // First-frame animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.balance != null) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newBalance = widget.balance?.currentBalance;

    // Only animate when we have a REAL new value AND it's different
    // from what we've already shown. Skip null values entirely.
    if (newBalance == null) return;

    if (_lastShownBalance == null) {
      // First real value arrived after being empty → animate from 0
      _balanceAnim = Tween<double>(begin: 0, end: newBalance).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _lastShownBalance = newBalance;
      _controller.forward(from: 0);
    } else if (newBalance != _lastShownBalance) {
      // Value changed → animate from previous to new
      final previous = _lastShownBalance!;
      _balanceAnim = Tween<double>(begin: previous, end: newBalance).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _lastShownBalance = newBalance;
      _controller.forward(from: 0);
    }
    // else: same value, do nothing — no flicker
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatBalanceCompact(double amount) {
    final absVal = amount.abs();
    final formatted = absVal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return amount < 0 ? '-PKR $formatted' : 'PKR $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show skeleton ONLY on the very first load, before any real value.
    if (widget.balance == null &&
        widget.error == null &&
        _lastShownBalance == null) {
      return const SkeletonBox(
        width: double.infinity,
        height: 180,
        borderRadius: 24,
      );
    }

    if (widget.error != null && _lastShownBalance == null) {
      return _ErrorCard(error: widget.error!, onRetry: widget.onRetry);
    }

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: _CardBody(
          isDark: isDark,
          balanceAnim: _balanceAnim,
          summary: widget.summary,
          formatBalance: _formatBalanceCompact,
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final bool isDark;
  final Animation<double> balanceAnim;
  final AnalyticsSummary? summary;
  final String Function(double) formatBalance;

  const _CardBody({
    required this.isDark,
    required this.balanceAnim,
    required this.summary,
    required this.formatBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.7)
              : AppColors.lightBorder,
          width: 0.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.darkElevated,
                  AppColors.darkSurface,
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.03),
                  AppColors.lightElevated,
                  AppColors.lightSurface,
                ],
          stops: const [0.0, 0.35, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Radial glow — top-left
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: AppTypography.overline.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedBuilder(
                animation: balanceAnim,
                builder: (_, __) {
                  return Text(
                    formatBalance(balanceAnim.value),
                    style: AppTypography.amountHero.copyWith(
                      color:
                          isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _IncomeExpenseChip(
                    isIncome: true,
                    amount: summary?.totalIncome ?? 0,
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  _IncomeExpenseChip(
                    isIncome: false,
                    amount: summary?.totalExpense ?? 0,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseChip extends StatelessWidget {
  final bool isIncome;
  final double amount;

  const _IncomeExpenseChip({
    required this.isIncome,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isIncome
        ? (isDark ? AppColors.income : AppColors.lightIncome)
        : (isDark ? AppColors.expense : AppColors.lightExpense);
    final label = isIncome ? 'Income' : 'Expenses';
    final icon = isIncome ? Symbols.arrow_downward : Symbols.arrow_upward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 12, color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Column(
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
            Text(
              Formatters.currency(amount, compact: true),
              style: AppTypography.amountLarge.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _ErrorCard({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? AppColors.expense : AppColors.lightExpense)
              .withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.error_outline,
            color: isDark ? AppColors.expense : AppColors.lightExpense,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Could not load balance',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.caption,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}