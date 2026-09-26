import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/formatters.dart';
import '../../widgets/cards/balance_card.dart';
import '../../widgets/cards/category_progress_row.dart';
import '../../widgets/cards/stat_tile.dart';
import '../../widgets/cards/transaction_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/skeleton.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _refreshTimer;
  DateTime? _lastLoadedAt;
  bool _isLoadingData = false;
  bool _hasLoadedOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedOnce) return;
    if (_lastLoadedAt == null) return;
    if (DateTime.now().difference(_lastLoadedAt!) <
        const Duration(seconds: 60)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isLoadingData) return;
    _isLoadingData = true;

    final analytics = context.read<AnalyticsProvider>();
    final transactions = context.read<TransactionProvider>();

    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      await Future.wait([
        _ignoreFailure(analytics.loadBalance()),
        _ignoreFailure(analytics.loadSummary(currentMonth)),
        _ignoreFailure(analytics.loadBreakdown(currentMonth, type: 'expense')),
        _ignoreFailure(
          transactions.loadTransactions(
            limit: 5,
            sortBy: 'date',
            sortOrder: 'desc',
          ),
        ),
      ]);
      _lastLoadedAt = DateTime.now();
      _hasLoadedOnce = true;
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _ignoreFailure(Future<void> request) async {
    try {
      await request;
    } catch (_) {}
  }

  void _openAddTransaction() {
    Navigator.of(context).pushNamed(AppRouter.addTransaction);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Hello';
  }

  Widget _animated(Widget child, double start,
      {Offset offset = const Offset(0, 0.04)}) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final analytics = context.watch<AnalyticsProvider>();
    final transactions = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final firstName = auth.user?.name.trim().split(RegExp(r'\s+')).first;
    final hasName = firstName?.isNotEmpty == true;

    // Use provider balance directly. The provider keeps the last value
    // during refetch, so no flicker.
    final displayBalance = analytics.balance;
    final balanceIsLoading =
        displayBalance == null && analytics.error == null;
    final balanceError = displayBalance == null ? analytics.error : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              100,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasName ? '${_greeting()},' : 'Hello',
                          style: AppTypography.body.copyWith(color: secondary),
                        ),
                        if (hasName) ...[
                          Text(
                            firstName!,
                            style: AppTypography.h1.copyWith(
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          Formatters.monthLabel(month),
                          style:
                              AppTypography.caption.copyWith(color: secondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRouter.profile),
                    tooltip: 'Settings',
                    icon: Icon(Symbols.settings, color: secondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _animated(
                BalanceCard(
                  balance: displayBalance,
                  summary: analytics.summary,
                  isLoading: balanceIsLoading,
                  error: balanceError,
                  onRetry: _loadData,
                ),
                0,
              ),
              const SizedBox(height: AppSpacing.lg),
              _animated(
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Income',
                        amount: Formatters.currency(
                            analytics.summary?.totalIncome ?? 0,
                            compact: true),
                        amountColor:
                            isDark ? AppColors.income : AppColors.lightIncome,
                        isLoading:
                            analytics.isLoading && analytics.summary == null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        label: 'Expenses',
                        amount: Formatters.currency(
                            analytics.summary?.totalExpense ?? 0,
                            compact: true),
                        amountColor: isDark
                            ? AppColors.expense
                            : AppColors.lightExpense,
                        isLoading:
                            analytics.isLoading && analytics.summary == null,
                      ),
                    ),
                  ],
                ),
                0.12,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: 'Spending this month',
                actionLabel: 'See all',
                onAction: () => widget.onNavigate?.call(3),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSpending(analytics),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: 'Recent activity',
                actionLabel: 'View all',
                onAction: () => widget.onNavigate?.call(1),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildActivity(transactions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpending(AnalyticsProvider analytics) {
    if (analytics.isLoading && analytics.breakdown == null) {
      return const Column(
        children: [
          SkeletonBox(height: 68, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 68, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 68, borderRadius: AppRadius.md),
        ],
      );
    }
    if (analytics.error != null && analytics.breakdown == null) {
      return _RetryState(onRetry: _loadData);
    }

    final categories = analytics.breakdown?.categories.take(3).toList() ?? [];
    if (categories.isEmpty) {
      return EmptyState(
        icon: Symbols.pie_chart_outline,
        heading: 'No spending yet this month',
        subtext: 'Add your first transaction to see insights here',
        actionLabel: '+ Add Transaction',
        onAction: _openAddTransaction,
      );
    }

    return _animated(
      Column(
        children: [
          for (final category in categories)
            CategoryProgressRow(
              categoryName: category.name,
              amount: category.total,
              percentage: category.percentage,
            ),
        ],
      ),
      0.22,
    );
  }

  Widget _buildActivity(TransactionProvider transactions) {
    if (transactions.isLoading && transactions.transactions.isEmpty) {
      return const Column(
        children: [
          SkeletonBox(height: 68, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 68, borderRadius: AppRadius.md),
        ],
      );
    }
    if (transactions.error != null && transactions.transactions.isEmpty) {
      return _RetryState(onRetry: _loadData);
    }
    if (transactions.transactions.isEmpty) {
      return EmptyState(
        icon: Symbols.receipt_long,
        heading: 'No transactions yet',
        subtext:
            'Start tracking your spending by adding your first transaction',
        actionLabel: '+ Add Transaction',
        onAction: _openAddTransaction,
      );
    }

    return _animated(
      Column(
        children: [
          for (final transaction in transactions.transactions.take(5))
            TransactionTile(transaction: transaction),
        ],
      ),
      0.3,
    );
  }
}

class _RetryState extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Symbols.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}