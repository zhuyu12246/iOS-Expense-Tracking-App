import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/app_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Category breakdown ring with the month total in the middle.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.stats,
    required this.total,
    required this.centerLabel,
    this.size = 180,
  });

  final List<CategoryStat> stats;
  final int total;
  final String centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (stats.isEmpty || total <= 0) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(fontSize: 14, color: palette.muted),
          ),
        ),
      );
    }

    // Keep the ring readable: show the top 6 slices and merge the rest.
    const maxSlices = 6;
    final visible = stats.take(maxSlices).toList();
    final restTotal = stats
        .skip(maxSlices)
        .fold<int>(0, (sum, stat) => sum + stat.total);

    final sections = <PieChartSectionData>[
      for (final stat in visible)
        PieChartSectionData(
          value: stat.total.toDouble(),
          color: Color(stat.category.colorValue),
          radius: 20,
          showTitle: false,
        ),
      if (restTotal > 0)
        PieChartSectionData(
          value: restTotal.toDouble(),
          color: palette.faint,
          radius: 20,
          showTitle: false,
        ),
    ];

    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 3,
              centerSpaceRadius: size * 0.29,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                centerLabel,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
              const SizedBox(height: 4),
              Text(
                '¥${formatAmount(total)}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
