import 'package:flutter/material.dart';

import '../models/types.dart';
import '../theme/app_theme.dart';

/// Segmented 支出 / 收入 switch.
class TxTypeSelector extends StatelessWidget {
  const TxTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.expanded = true,
  });

  final TxType value;
  final ValueChanged<TxType> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final children = <Widget>[
      for (final type in TxType.values)
        _Segment(
          label: type.label,
          selected: value == type,
          activeColor: type.isExpense ? palette.expense : palette.income,
          onTap: () => onChanged(type),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.chipBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: children
            .map(
              (child) => expanded
                  ? Expanded(child: child)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: child,
                    ),
            )
            .toList(),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
          ),
        ),
      ),
    );
  }
}
