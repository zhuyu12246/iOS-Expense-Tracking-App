import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/app_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Grouped monthly bars comparing spending and income.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points, this.height = 190});

  final List<TrendPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final maxValue = points.fold<int>(
      0,
      (max, point) =>
          [max, point.expense, point.income].reduce((a, b) => a > b ? a : b),
    );
    final maxY = maxValue <= 0 ? 100.0 : maxValue / 100 * 1.2;
    final interval = maxY / 4;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _LegendDot(color: palette.expense, label: '支出'),
            const SizedBox(width: 16),
            _LegendDot(color: palette.income, label: '收入'),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: palette.border,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${points[index].month.month}月',
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: <BarChartGroupData>[
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: points[i].expense / 100,
                        color: palette.expense,
                        width: 9,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      BarChartRodData(
                        toY: points[i].income / 100,
                        color: palette.income,
                        width: 9,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _TrendSummary(
                label: '${points.length}个月合计支出',
                value: formatMoney(
                  points.fold<int>(0, (sum, point) => sum + point.expense),
                ),
                color: onSurface,
              ),
            ),
            Container(width: 1, height: 24, color: palette.border),
            Expanded(
              child: _TrendSummary(
                label: '${points.length}个月合计收入',
                value: formatMoney(
                  points.fold<int>(0, (sum, point) => sum + point.income),
                ),
                color: onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.palette.muted),
        ),
      ],
    );
  }
}

class _TrendSummary extends StatelessWidget {
  const _TrendSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.palette.muted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
