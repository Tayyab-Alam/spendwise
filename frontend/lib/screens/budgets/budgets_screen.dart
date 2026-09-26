import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/budget_status.dart';
import '../../providers/budget_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import 'add_budget_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _monthValue =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    try {
      await context.read<BudgetProvider>().loadBudgets(_monthValue);
    } catch (_) {}
  }

  Future<void> _changeMonth(int offset) async {
    final next = DateTime(_month.year, _month.month + offset);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    if (next.isBefore(current)) return;
    setState(() => _month = next);
    await _load();
  }

  Future<void> _addBudget() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddBudgetScreen(month: _monthValue)),
    );
    if (created == true) _load();
  }

  Future<void> _editBudget(BudgetStatus status) async {
    debugPrint('=== _editBudget called with id: ${status.id} ===');
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddBudgetScreen(
          month: _monthValue,
          existing: status.toBudget(),
        ),
      ),
    );
    if (updated == true) _load();
  }

  Future<void> _deleteBudget(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<BudgetProvider>().deleteBudget(id);
      await _load();
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    final statuses = provider.statuses.values
        .where((status) => status.month == _monthValue)
        .toList();
    final spent = statuses.fold<double>(0, (sum, item) => sum + item.spent);
    final limit =
        statuses.fold<double>(0, (sum, item) => sum + item.limitAmount);
    final progress = limit == 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 100),
            children: [
              // ---- Header ----
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Budgets',
                      style: AppTypography.h2.copyWith(color: textColor),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Symbols.chevron_left),
                  ),
                  Text(
                    Formatters.monthLabel(_monthValue),
                    style: AppTypography.caption.copyWith(color: secondary),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Symbols.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Body ----
              if (provider.isLoading && provider.budgets.isEmpty)
                const SkeletonBox(height: 150, borderRadius: AppRadius.lg)
              else if (provider.error != null && provider.budgets.isEmpty)
                _Retry(onRetry: _load)
              else if (provider.budgets.isEmpty)
                EmptyState(
                  icon: Symbols.savings,
                  heading: 'No budgets yet',
                  subtext: 'Set a monthly limit to control your spending',
                  actionLabel: '+ Add Budget',
                  onAction: _addBudget,
                )
              else ...[
                _SummaryCard(
                  spent: spent,
                  limit: limit,
                  progress: progress,
                  textColor: textColor,
                  secondary: secondary,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final budget in provider.budgets) ...[
                  _BudgetTile(
                    status: provider.statuses[budget.id],
                    fallbackName: budget.category?.name ?? 'Category',
                    textColor: textColor,
                    secondary: secondary,
                    isDark: isDark,
                    onEdit: () {
                      final status = provider.statuses[budget.id];
                      if (status != null) _editBudget(status);
                    },
                    onDelete: () => _deleteBudget(budget.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudget,
        heroTag: 'budgets_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add budget',
        child: const Icon(Symbols.add_rounded),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  final double spent;
  final double limit;
  final double progress;
  final Color textColor;
  final Color secondary;
  final bool isDark;

  const _SummaryCard({
    required this.spent,
    required this.limit,
    required this.progress,
    required this.textColor,
    required this.secondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly budgets',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${Formatters.currency(spent, compact: true)} of ${Formatters.currency(limit, compact: true)} spent',
            style: AppTypography.body.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: borderColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BUDGET TILE (with FIXED overflow + edit icon)
// ============================================================

class _BudgetTile extends StatelessWidget {
  final BudgetStatus? status;
  final String fallbackName;
  final Color textColor;
  final Color secondary;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetTile({
    required this.status,
    required this.fallbackName,
    required this.textColor,
    required this.secondary,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const SkeletonBox(height: 105, borderRadius: AppRadius.md);
    }
    final item = status!;
    final color = item.isExceeded
        ? AppColors.expense
        : item.isApproaching
            ? AppColors.warning
            : AppColors.income;
    final name = item.category?.name ?? fallbackName;
    final statusText = item.isExceeded
        ? '${Formatters.currency(item.remaining.abs(), compact: true)} over budget'
        : '${Formatters.currency(item.remaining, compact: true)} remaining';
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Row 1: Icon + Name + Amount + Actions ----
              Row(
                children: [
                  Icon(Symbols.category, color: color, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${Formatters.currency(item.spent, compact: true)} / ${Formatters.currency(item.limitAmount, compact: true)}',
                    style: AppTypography.caption.copyWith(color: secondary),
                  ),
                  // Edit icon
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit budget',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Symbols.edit, color: secondary, size: 20),
                  ),
                  // Delete icon
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete budget',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Symbols.delete_outline,
                        color: secondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // ---- Row 2: Progress bar ----
              LinearProgressIndicator(
                value: (item.percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: borderColor,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ---- Row 3: Status text ----
              Text(
                statusText,
                style: AppTypography.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RETRY
// ============================================================

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;

  const _Retry({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Symbols.refresh),
          label: const Text('Retry'),
        ),
      );
}