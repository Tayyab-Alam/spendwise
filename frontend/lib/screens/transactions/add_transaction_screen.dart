import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/common/category_icon_chip.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';
  DateTime _date = DateTime.now();
  Category? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CategoryProvider>();
      if (provider.categories.isEmpty) {
        try {
          await provider.loadCategories();
        } catch (_) {}
      }
      if (mounted) _selectFirstCategory();
    });
  }

  void _selectFirstCategory() {
    final categories = _categoriesForType;
    if (_category == null ||
        !categories.any((item) => item.id == _category!.id)) {
      setState(() => _category = categories.isEmpty ? null : categories.first);
    }
  }

  List<Category> get _categoriesForType {
    final categories = context.read<CategoryProvider>().categories;
    return categories
        .where((item) => item.type == _type && item.isActive)
        .toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      AppSnackbar.error(context, 'Choose a category');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<TransactionProvider>().createTransaction(
            type: _type,
            amount:
                double.parse(_amountController.text.trim().replaceAll(',', '')),
            categoryId: _category!.id,
            date: _date.toIso8601String().split('T').first,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppSnackbar.success(context, 'Transaction saved');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final categories = _categoriesForType;

    return Scaffold(
      appBar: AppBar(title: const Text('Add transaction')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text('Amount',
                  style: AppTypography.caption.copyWith(color: secondary)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
                style: AppTypography.amountHero.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText),
                decoration: const InputDecoration(prefixText: 'PKR '),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Type',
                  style: AppTypography.caption.copyWith(color: secondary)),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Symbols.arrow_upward)),
                  ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Symbols.arrow_downward)),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _category = null;
                  });
                  _selectFirstCategory();
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Category',
                  style: AppTypography.caption.copyWith(color: secondary)),
              const SizedBox(height: AppSpacing.sm),
              if (categories.isEmpty)
                Text('No categories available',
                    style: AppTypography.body.copyWith(color: secondary))
              else
                SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, index) {
                      final category = categories[index];
                      final selected = category.id == _category?.id;
                      return GestureDetector(
                        onTap: () => setState(() => _category = category),
                        child: Container(
                          width: 76,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.16)
                                : (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CategoryIconChip(
                                  categoryName: category.name,
                                  size: 32,
                                  iconSize: 17),
                              const SizedBox(height: AppSpacing.xs),
                              Text(category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                      color: isDark
                                          ? AppColors.darkText
                                          : AppColors.lightText)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Date',
                  style: AppTypography.caption.copyWith(color: secondary)),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Symbols.calendar_today, color: secondary),
                title: Text(Formatters.date(_date),
                    style: AppTypography.body.copyWith(
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText)),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                  controller: _noteController,
                  label: 'Note (optional)',
                  hint: 'What was this for?'),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                  label: 'Save transaction',
                  onPressed: _save,
                  isLoading: _saving,
                  icon: Symbols.check),
            ],
          ),
        ),
      ),
    );
  }
}
