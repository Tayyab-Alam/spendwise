import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/cards/transaction_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _pageSize = 50;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<Transaction> _items = [];
  String? _selectedType;
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _items = [];
      _offset = 0;
      _hasMore = true;
      _lastError = null;
    });
    await _loadPage(reset: true);
  }

  Future<void> _loadPage({required bool reset}) async {
    if (_isLoadingMore || (!reset && !_hasMore)) return;
    setState(() => _isLoadingMore = true);
    try {
      final provider = context.read<TransactionProvider>();
      await provider.loadTransactions(
        type: _selectedType,
        search: _searchController.text,
        skip: reset ? 0 : _offset,
        limit: _pageSize,
        sortBy: 'date',
        sortOrder: 'desc',
      );
      if (!mounted) return;
      final page = provider.transactions;
      setState(() {
        if (reset) {
          _items = page;
          _offset = page.length;
        } else {
          _items = [..._items, ...page];
          _offset += page.length;
        }
        _hasMore = page.length == _pageSize;
        _lastError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _lastError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadPage(reset: false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _reload);
    setState(() {});
  }

  void _selectType(String? type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _reload();
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (created == true) _reload();
  }

  Map<String, List<Transaction>> _groupByDate() {
    final groups = <String, List<Transaction>>{};
    for (final item in _items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      final key = date.toIso8601String();
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final initialLoading =
        provider.isLoading && _items.isEmpty && _lastError == null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Activity',
                              style:
                                  AppTypography.h2.copyWith(color: textColor))),
                      IconButton(
                        onPressed: () => _showFilterInfo(context),
                        tooltip: 'Filters',
                        icon: Icon(Symbols.tune, color: secondary),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                sliver: SliverToBoxAdapter(child: _buildSearch(secondary)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
                sliver: SliverToBoxAdapter(child: _buildFilters()),
              ),
              if (initialLoading)
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  sliver: SliverList.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child:
                          SkeletonBox(height: 72, borderRadius: AppRadius.md),
                    ),
                  ),
                )
              else if (_lastError != null && _items.isEmpty)
                SliverFillRemaining(
                    hasScrollBody: false, child: _ErrorState(onRetry: _reload))
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Symbols.receipt_long,
                    heading: 'No transactions yet',
                    subtext: 'Start tracking your spending',
                    actionLabel: '+ Add Transaction',
                    onAction: _openAdd,
                  ),
                )
              else
                _buildTransactionSlivers(secondary),
              if (_isLoadingMore && _items.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        heroTag: 'transactions_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add transaction',
        child: const Icon(Symbols.add_rounded),
      ),
    );
  }

  Widget _buildSearch(Color secondary) {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: AppTypography.body.copyWith(color: AppColors.darkText),
      decoration: InputDecoration(
        hintText: 'Search by note...',
        hintStyle: AppTypography.body.copyWith(color: secondary),
        prefixIcon: Icon(Symbols.search, color: secondary),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _reload();
                },
                icon: Icon(Symbols.close, color: secondary),
              ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
              label: 'All',
              selected: _selectedType == null,
              onTap: () => _selectType(null)),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
              label: 'Income',
              selected: _selectedType == 'income',
              onTap: () => _selectType('income')),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
              label: 'Expense',
              selected: _selectedType == 'expense',
              onTap: () => _selectType('expense')),
        ],
      ),
    );
  }

  Widget _buildTransactionSlivers(Color secondary) {
    final groups = _groupByDate();
    final children = <Widget>[];
    for (final entry in groups.entries) {
      final date = DateTime.parse(entry.key);
      children.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: Text(_dateLabel(date),
                style: AppTypography.bodyMedium.copyWith(color: secondary)),
          ),
        ),
      );
      children.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          sliver: SliverList.builder(
            itemCount: entry.value.length,
            itemBuilder: (_, index) {
              final transaction = entry.value[index];
              return InkWell(
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(
                        transactionId: transaction.id,
                        initialTransaction: transaction,
                      ),
                    ),
                  );
                  if (changed == true) _reload();
                },
                child: TransactionTile(
                  transaction: transaction,
                  showDivider: index != entry.value.length - 1,
                ),
              );
            },
          ),
        ),
      );
    }
    return SliverMainAxisGroup(slivers: children);
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return Formatters.date(date);
  }

  void _showFilterInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Use the chips to filter income or expenses')),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: selected
            ? Colors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
      ),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Symbols.refresh),
        label: const Text('Retry'),
      ),
    );
  }
}
