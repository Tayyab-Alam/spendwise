import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../core/constants/category_colors.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_provider.dart';
import '../../services/analytics_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _service = AnalyticsService();
  late int _year;
  double? _previousExpense;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _month =>
      '${_year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final provider = context.read<AnalyticsProvider>();
    final current = DateTime.now();
    final previousDate = DateTime(current.year, current.month - 1);
    final previousMonth =
        '${previousDate.year}-${previousDate.month.toString().padLeft(2, '0')}';
    try {
      await Future.wait([
        provider.loadBreakdown(_month, type: 'expense'),
        provider.loadSummary(_month),
        provider.loadTrend(_year),
        _loadPrevious(previousMonth),
      ]);
    } catch (_) {}
  }

  Future<void> _loadPrevious(String month) async {
    try {
      _previousExpense = (await _service.getSummary(month)).totalExpense;
    } catch (_) {
      _previousExpense = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final breakdown = provider.breakdown;
    final loading = provider.isLoading && breakdown == null;

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
              Row(children: [
                Expanded(
                    child: Text('Insights',
                        style: AppTypography.h2.copyWith(color: textColor))),
                DropdownButton<int>(
                    value: _year,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (var year = DateTime.now().year - 2;
                          year <= DateTime.now().year;
                          year++)
                        DropdownMenuItem(value: year, child: Text('$year'))
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _year = value);
                        _load();
                      }
                    }),
              ]),
              const SizedBox(height: AppSpacing.xl),
              Text('This month',
                  style: AppTypography.h3.copyWith(color: textColor)),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                const SkeletonBox(height: 290, borderRadius: AppRadius.lg)
              else if (provider.error != null && breakdown == null)
                _Retry(onRetry: _load)
              else if (breakdown == null || breakdown.categories.isEmpty)
                EmptyState(
                    icon: Symbols.pie_chart,
                    heading: 'No spending data yet',
                    subtext: 'Add transactions to see your spending breakdown')
              else ...[
                _PieCard(
                    breakdown: breakdown,
                    textColor: textColor,
                    secondary: secondary),
                const SizedBox(height: AppSpacing.xxl),
              ],
              Text('Monthly trend',
                  style: AppTypography.h3.copyWith(color: textColor)),
              const SizedBox(height: AppSpacing.md),
              if (provider.trend == null && loading)
                const SkeletonBox(height: 280, borderRadius: AppRadius.lg)
              else if (provider.trend == null)
                _Retry(onRetry: _load)
              else
                _TrendCard(
                    trend: provider.trend!,
                    textColor: textColor,
                    secondary: secondary),
              if (_previousExpense != null && provider.summary != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                _buildInsight(
                    provider.summary!.totalExpense, textColor, secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsight(double current, Color textColor, Color secondary) {
    if (_previousExpense == null || _previousExpense == 0)
      return const SizedBox.shrink();
    final change = ((current - _previousExpense!) / _previousExpense!) * 100;
    final increased = change >= 0;
    final color = increased ? AppColors.expense : AppColors.income;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(children: [
        Icon(increased ? Symbols.trending_up : Symbols.trending_down,
            color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: Text(
                'Your spending ${increased ? 'increased' : 'decreased'} ${change.abs().toStringAsFixed(1)}% compared with last month.',
                style: AppTypography.body.copyWith(color: secondary)))
      ]),
    );
  }
}

class _PieCard extends StatelessWidget {
  final CategoryBreakdown breakdown;
  final Color textColor;
  final Color secondary;
  const _PieCard(
      {required this.breakdown,
      required this.textColor,
      required this.secondary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(children: [
        SizedBox(
            height: 210,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                  centerSpaceRadius: 58,
                  sectionsSpace: 2,
                  sections: [
                    for (final item in breakdown.categories)
                      PieChartSectionData(
                          value: item.total,
                          color: CategoryColors.forCategory(item.name),
                          radius: 42,
                          showTitle: false)
                  ])),
              Column(children: [
                Text(Formatters.currency(breakdown.totalSpent, compact: true),
                    style:
                        AppTypography.amountLarge.copyWith(color: textColor)),
                Text('spent',
                    style: AppTypography.caption.copyWith(color: secondary))
              ])
            ])),
        const SizedBox(height: AppSpacing.md),
        for (final item in breakdown.categories)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: CategoryColors.forCategory(item.name),
                        shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(item.name,
                        style: AppTypography.body.copyWith(color: textColor))),
                Text('${item.percentage.toStringAsFixed(1)}%',
                    style: AppTypography.caption.copyWith(color: secondary)),
                const SizedBox(width: AppSpacing.md),
                Text(Formatters.currency(item.total, compact: true),
                    style: AppTypography.amount.copyWith(color: textColor))
              ])),
      ]),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final MonthlyTrend trend;
  final Color textColor;
  final Color secondary;
  const _TrendCard(
      {required this.trend, required this.textColor, required this.secondary});
  @override
  Widget build(BuildContext context) {
    final maxValue = trend.months.fold<double>(
        0,
        (max, item) =>
            [max, item.income, item.expense].reduce((a, b) => a > b ? a : b));
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                      Formatters.currency(value, compact: true),
                      style:
                          AppTypography.caption.copyWith(color: secondary)))),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= trend.months.length)
                      return const SizedBox.shrink();
                    return Text(trend.months[index].month.substring(5),
                        style:
                            AppTypography.caption.copyWith(color: secondary));
                  })),
        ),
        lineBarsData: [
          _line(trend.months, true, AppColors.income),
          _line(trend.months, false, AppColors.expense),
        ],
      )),
    );
  }

  LineChartBarData _line(
          List<MonthlyTrendItem> months, bool income, Color color) =>
      LineChartBarData(
          spots: [
            for (var index = 0; index < months.length; index++)
              FlSpot(index.toDouble(),
                  income ? months[index].income : months[index].expense)
          ],
          isCurved: true,
          color: color,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false));
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
      child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Symbols.refresh),
          label: const Text('Retry')));
}
