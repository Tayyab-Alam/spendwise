import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/common/category_icon_chip.dart';
import '../../widgets/common/primary_button.dart';

class AddBudgetScreen extends StatefulWidget {
  /// The month the new budget is for. Ignored when [existing] is provided.
  final String month;

  /// When provided, the screen operates in EDIT mode:
  /// - Category is locked
  /// - Month is locked
  /// - Only the limit amount can be changed
  final Budget? existing;

  const AddBudgetScreen({
    super.key,
    required this.month,
    this.existing,
  });

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  Category? _category;
  String? _month;
  bool _saving = false;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      // Edit mode: lock month and category from existing budget
      _month = widget.existing!.month;
      _category = widget.existing!.category;
      _limitController.text = widget.existing!.limitAmount
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.00$'), '');
    } else {
      _month = widget.month;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<CategoryProvider>();
        if (provider.categories.isEmpty) {
          try {
            await provider.loadCategories(type: 'expense');
          } catch (_) {}
        }
        if (mounted && _expenseCategories.isNotEmpty) {
          setState(() => _category = _expenseCategories.first);
        }
      });
    }
  }

  List<Category> get _expenseCategories => context
      .read<CategoryProvider>()
      .categories
      .where((item) => item.isExpense && item.isActive)
      .toList();

  Future<void> _pickMonth() async {
    if (_isEditMode) return; // month is locked in edit mode
    final initial = DateTime.parse('${_month!}-01');
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime(now.year, now.month))
          ? DateTime(now.year, now.month)
          : initial,
      firstDate: DateTime(now.year, now.month),
      lastDate: DateTime(now.year + 2, 12),
    );
    if (picked != null) {
      setState(() =>
          _month = '${picked.year}-${picked.month.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) {
      if (_category == null) AppSnackbar.error(context, 'Choose a category');
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<BudgetProvider>();
    final limit =
        double.parse(_limitController.text.trim().replaceAll(',', ''));

    try {
      if (_isEditMode) {
        await provider.updateBudget(widget.existing!.id, limit);
      } else {
        await provider.createBudget(
          categoryId: _category!.id,
          month: _month!,
          limitAmount: limit,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final categories = _expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit budget' : 'New budget'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Category',
                style: AppTypography.caption.copyWith(color: secondary)),
            const SizedBox(height: AppSpacing.sm),

            // -------- CATEGORY PICKER --------
            if (_isEditMode)
              // Locked display in edit mode
              Row(
                children: [
                  CategoryIconChip(
                    categoryName: _category?.name ?? '',
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _category?.name ?? '',
                      style: AppTypography.bodyMedium.copyWith(color: textColor),
                    ),
                  ),
                  Icon(Symbols.lock, size: 16, color: secondary),
                ],
              )
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
                    final selected = _category?.id == category.id;
                    return GestureDetector(
                      onTap: () => setState(() => _category = category),
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.16)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CategoryIconChip(
                              categoryName: category.name,
                              size: 32,
                              iconSize: 17,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption
                                  .copyWith(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: AppSpacing.xxl),

            // -------- MONTH --------
            Text('Month',
                style: AppTypography.caption.copyWith(color: secondary)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Symbols.calendar_month, color: secondary),
              title: Text(
                Formatters.monthLabel(_month!),
                style: AppTypography.body.copyWith(color: textColor),
              ),
              trailing:
                  _isEditMode ? Icon(Symbols.lock, size: 16, color: secondary) : const Icon(Symbols.chevron_right),
              onTap: _isEditMode ? null : _pickMonth,
            ),

            const SizedBox(height: AppSpacing.lg),

            // -------- LIMIT --------
            Text('Limit amount',
                style: AppTypography.caption.copyWith(color: secondary)),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
              style: AppTypography.amountLarge.copyWith(color: textColor),
              decoration: const InputDecoration(prefixText: 'PKR '),
            ),

            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: _isEditMode ? 'Save changes' : 'Save budget',
              onPressed: _save,
              isLoading: _saving,
              icon: Symbols.check,
            ),
          ],
        ),
      ),
    );
  }
}