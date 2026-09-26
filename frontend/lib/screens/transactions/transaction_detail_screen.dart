import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/transaction_service.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';
import '../../widgets/common/category_icon_chip.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;
  final Transaction? initialTransaction;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.initialTransaction,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _service = TransactionService();
  Transaction? _transaction;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _date;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _transaction = widget.initialTransaction;
    _hydrateFields();
    _loadTransaction();
  }

  void _hydrateFields() {
    final item = _transaction;
    if (item == null) return;
    _amountController.text = item.amount.toStringAsFixed(2);
    _noteController.text = item.note ?? '';
    _date = item.date;
    _categoryId = item.categoryId;
  }

  Future<void> _loadTransaction() async {
    try {
      final item =
          _transaction ?? await _service.getTransaction(widget.transactionId);
      if (!mounted) return;
      setState(() {
        _transaction = item;
        _loading = false;
      });
      _hydrateFields();
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackbar.error(context, error.toString());
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.expense
                  : AppColors.lightExpense,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context
          .read<TransactionProvider>()
          .deleteTransaction(widget.transactionId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    }
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0 || _transaction == null) {
      AppSnackbar.error(context, 'Enter a valid amount');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated =
          await context.read<TransactionProvider>().updateTransaction(
                widget.transactionId,
                amount: amount,
                categoryId: _categoryId,
                date: _date?.toIso8601String().split('T').first,
                note: _noteController.text,
              );
      if (!mounted) return;
      setState(() {
        _transaction = updated;
        _editing = false;
      });
      _hydrateFields();
      AppSnackbar.success(context, 'Transaction updated');
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _transaction;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          if (item != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') setState(() => _editing = true);
                if (value == 'delete') _delete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? Center(
                  child: Text('Transaction not found',
                      style: AppTypography.body.copyWith(color: secondary)))
              : _editing
                  ? _buildEditForm(item, textColor, secondary)
                  : _buildDetails(item, textColor, secondary),
    );
  }

  Widget _buildDetails(Transaction item, Color textColor, Color secondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item.isIncome
      ? (isDark ? AppColors.income : AppColors.lightIncome)
      : (isDark ? AppColors.expense : AppColors.lightExpense);
    final categoryName = item.category?.name ?? 'Other';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
            child: Text(
                '${item.isIncome ? '+' : '-'}${Formatters.currency(item.amount)}',
                style: AppTypography.amountHero.copyWith(color: color))),
        const SizedBox(height: AppSpacing.xl),
        Center(
            child: Column(children: [
          CategoryIconChip(categoryName: categoryName, size: 56, iconSize: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(categoryName,
              style: AppTypography.bodyMedium.copyWith(color: textColor))
        ])),
        const SizedBox(height: AppSpacing.lg),
        Center(
            child: Text(Formatters.date(item.date),
                style: AppTypography.bodyLarge.copyWith(color: textColor))),
        if (item.note?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(item.note!,
                style: AppTypography.body.copyWith(color: textColor)),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Text('Created at ${Formatters.date(item.createdAt)}',
            style: AppTypography.caption.copyWith(color: secondary)),
        const SizedBox(height: AppSpacing.xs),
        Text('Updated at ${Formatters.date(item.updatedAt)}',
            style: AppTypography.caption.copyWith(color: secondary)),
      ],
    );
  }

  Widget _buildEditForm(Transaction item, Color textColor, Color secondary) {
    final categories = context
        .watch<CategoryProvider>()
        .categories
        .where((category) => category.type == item.type)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text('Amount', style: AppTypography.caption.copyWith(color: secondary)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.amountHero.copyWith(color: textColor),
            decoration: const InputDecoration(prefixText: 'PKR ')),
        const SizedBox(height: AppSpacing.xxl),
        Text('Category',
            style: AppTypography.caption.copyWith(color: secondary)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<int>(
          initialValue: _categoryId,
          items: categories
              .map((category) => DropdownMenuItem(
                  value: category.id, child: Text(category.name)))
              .toList(),
          onChanged: (value) => setState(() => _categoryId = value),
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
            controller: _noteController,
            maxLength: 255,
            style: AppTypography.body.copyWith(color: textColor),
            decoration: const InputDecoration(labelText: 'Note (optional)')),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
            height: 50,
            child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save changes'))),
      ],
    );
  }
}
