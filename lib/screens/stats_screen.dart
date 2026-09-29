import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_data.dart';
import '../models/types.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_avatar.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/charts/trend_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_switcher.dart';
import '../widgets/sheets.dart';
import '../widgets/surface_card.dart';
import '../widgets/tx_type_selector.dart';

/// Category breakdown and monthly trend.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TxType _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;
    final stats = provider.statsFor(_type);
    final total = _type.isExpense ? provider.monthExpense : provider.monthIncome;
    final trend = provider.trend(months: 6);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: palette.pageBackground,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 16,
            title: Text(
              '统计',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: <Widget>[
                MonthSwitcher(
                  month: provider.selectedMonth,
                  onPrevious: () => provider.shiftMonth(-1),
                  onNext: () => provider.shiftMonth(1),
                  onTapLabel: () async {
                    final picked = await showMonthPickerSheet(
                      context,
                      initial: provider.selectedMonth,
                    );
                    if (picked != null) provider.jumpToMonth(picked);
                  },
                ),
                const SizedBox(height: 10),
                TxTypeSelector(
                  value: _type,
                  onChanged: (value) => setState(() => _type = value),
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _MiniStat(
                            label: '本月${_type.label}',
                            value: formatMoney(total),
                            color: _type.isExpense
                                ? palette.expense
                                : palette.income,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: palette.border,
                          ),
                          _MiniStat(
                            label: '笔数',
                            value: '${provider.monthRecords.where((r) => r.type == _type).length} 笔',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: palette.border,
                          ),
                          _MiniStat(
                            label: '日均支出',
                            value: formatMoney(provider.averageDailyExpense),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Divider(height: 28, color: palette.border),
                      if (stats.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.donut_large_rounded,
                            title: '这个月还没有${_type.label}记录',
                            message: '记一笔之后就能看到分类占比了。',
                          ),
                        )
                      else
                        DonutChart(
                          stats: stats,
                          total: total,
                          centerLabel: '${monthLabel(provider.selectedMonth)}${_type.label}',
                        ),
                    ],
                  ),
                ),
                if (stats.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SectionHeader(
                          title: '分类排行',
                          subtitle: '共 ${stats.length} 个分类',
                        ),
                        for (var i = 0; i < stats.length; i++)
                          _RankRow(stat: stats[i], rank: i + 1),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionHeader(
                        title: '近 6 个月趋势',
                        subtitle: '按月对比收支变化',
                      ),
                      TrendChart(points: trend),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.palette.muted),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.stat, required this.rank});

  final CategoryStat stat;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Color(stat.category.colorValue);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? palette.brand : palette.faint,
              ),
            ),
          ),
          CategoryAvatar(
            iconKey: stat.category.iconKey,
            color: color,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        stat.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(stat.total),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stat.ratio,
                          minHeight: 6,
                          backgroundColor: palette.chipBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${(stat.ratio * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
