import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// `‹ 2026年9月 ›` control shared by the ledger and stats screens.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.onTapLabel,
    this.trailing,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTapLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
          tooltip: '上一月',
        ),
        Expanded(
          child: InkWell(
            onTap: onTapLabel,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    monthLabel(month),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: palette.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
          tooltip: '下一月',
        ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing!],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: palette.muted),
        ),
      ),
    );
  }
}
