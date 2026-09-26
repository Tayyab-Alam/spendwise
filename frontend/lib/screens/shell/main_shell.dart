import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../providers/analytics_provider.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/insights/insights_screen.dart';
import '../../screens/transactions/add_transaction_screen.dart';
import '../../screens/transactions/transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _selectTab),
    const TransactionsScreen(),
    const BudgetsScreen(),
    const InsightsScreen(),
  ];

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _openAddTransaction() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (created != true || !mounted) return;

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final analytics = context.read<AnalyticsProvider>();
    await Future.wait([
      analytics.loadBalance(),
      analytics.loadSummary(month),
      analytics.loadBreakdown(month, type: 'expense'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final border = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4D6C63FF),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openAddTransaction,
          heroTag: 'main_fab',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          tooltip: 'Add transaction',
          child: const Icon(Symbols.add_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        color: surface,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: border, width: 0.5)),
          ),
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                index: 0,
                selectedIndex: _currentIndex,
                outlinedIcon: Symbols.home,
                filledIcon: Symbols.home,
                onTap: _selectTab,
              ),
              _NavItem(
                label: 'Activity',
                index: 1,
                selectedIndex: _currentIndex,
                outlinedIcon: Symbols.receipt_long,
                filledIcon: Symbols.receipt_long,
                onTap: _selectTab,
              ),
              const SizedBox(width: 72),
              _NavItem(
                label: 'Budgets',
                index: 2,
                selectedIndex: _currentIndex,
                outlinedIcon: Symbols.savings,
                filledIcon: Symbols.savings,
                onTap: _selectTab,
              ),
              _NavItem(
                label: 'Insights',
                index: 3,
                selectedIndex: _currentIndex,
                outlinedIcon: Symbols.insights,
                filledIcon: Symbols.insights,
                onTap: _selectTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final IconData outlinedIcon;
  final IconData filledIcon;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.outlinedIcon,
    required this.filledIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? filledIcon : outlinedIcon,
                  key: ValueKey(selected),
                  color: selected ? AppColors.primary : secondary,
                  fill: selected ? 1 : 0,
                  size: 23,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? AppColors.primary : secondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}