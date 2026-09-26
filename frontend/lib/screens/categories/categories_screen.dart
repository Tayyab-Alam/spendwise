import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../utils/snackbar.dart';
import '../../widgets/common/category_icon_chip.dart';
import '../../widgets/common/empty_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await context.read<CategoryProvider>().loadCategories();
    } catch (_) {}
  }

  Future<void> _openEditor([Category? category]) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
    if (result == null || !mounted) return;
    try {
      final provider = context.read<CategoryProvider>();
      if (category == null) {
        await provider.createCategory(name: result.name, type: result.type);
      } else {
        await provider.updateCategory(category.id, name: result.name);
      }
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete '${category.name}'?"),
        content:
            const Text('Transactions using this category will be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CategoryProvider>().deleteCategory(category.id);
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final expense = provider.expenseCategories;
    final income = provider.incomeCategories;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), actions: [
        IconButton(
            onPressed: _openEditor,
            tooltip: 'Add category',
            icon: const Icon(Symbols.add))
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.isLoading && provider.categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                _CategorySection(
                    title: 'Expense categories',
                    categories: expense,
                    textColor: textColor,
                    secondary: secondary,
                    onEdit: _openEditor,
                    onDelete: _delete),
                const SizedBox(height: AppSpacing.xxl),
                _CategorySection(
                    title: 'Income categories',
                    categories: income,
                    textColor: textColor,
                    secondary: secondary,
                    onEdit: _openEditor,
                    onDelete: _delete),
                if (provider.categories.isEmpty)
                  EmptyState(
                      icon: Symbols.category,
                      heading: "You're using default categories",
                      subtext:
                          'Add a custom category to personalize your tracking',
                      actionLabel: '+ Add custom category',
                      onAction: _openEditor),
              ]),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final Color textColor;
  final Color secondary;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;
  const _CategorySection(
      {required this.title,
      required this.categories,
      required this.textColor,
      required this.secondary,
      required this.onEdit,
      required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTypography.h3.copyWith(color: textColor)),
      const SizedBox(height: AppSpacing.sm),
      for (final category in categories)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CategoryIconChip(categoryName: category.name),
          title: Text(category.name,
              style: AppTypography.bodyMedium.copyWith(color: textColor)),
          subtitle: category.isDefault
              ? Text('Default',
                  style: AppTypography.caption.copyWith(color: secondary))
              : null,
          trailing: category.isDefault
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      onPressed: () => onEdit(category),
                      tooltip: 'Edit category',
                      icon: Icon(Symbols.edit, color: secondary)),
                  IconButton(
                      onPressed: () => onDelete(category),
                      tooltip: 'Delete category',
                      icon: Icon(Symbols.delete_outline,
                          color: AppColors.expense))
                ]),
        ),
    ]);
  }
}

class _CategoryFormResult {
  final String name;
  final String type;
  const _CategoryFormResult(this.name, this.type);
}

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  const _CategoryDialog({this.category});
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _controller;
  late String _type;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
    _type = widget.category?.type ?? 'expense';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: AppSpacing.lg),
        SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income'))
            ],
            selected: {
              _type
            },
            onSelectionChanged: widget.category == null
                ? (value) => setState(() => _type = value.first)
                : null),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty)
                Navigator.pop(context,
                    _CategoryFormResult(_controller.text.trim(), _type));
            },
            child: const Text('Save')),
      ],
    );
  }
}
