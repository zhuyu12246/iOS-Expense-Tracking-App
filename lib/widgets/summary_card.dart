import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// The gradient hero card at the top of the ledger screen.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.month,
    required this.expense,
    required this.income,
    required this.budget,
    this.onBudgetTap,
  });

  final DateTime month;
  final int expense;
  final int income;
  final int budget;
  final VoidCallback? onBudgetTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final balance = income - expense;
    final hasBudget = budget > 0;
    final progress = hasBudget ? (expense / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - expense;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.brand, palette.brandDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.brand.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -36,
            top: -48,
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '${monthLabel(month)}支出',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (onBudgetTap != null)
                      InkWell(
                        onTap: onBudgetTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                hasBudget ? '预算' : '设预算',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      const Text(
                        '¥',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatAmount(expense),
                        style: const TextStyle(
                          fontSize: 36,
                          height: 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _Metric(
                      label: '收入',
                      value: formatMoney(income),
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    _Metric(
                      label: '结余',
                      value: formatMoney(balance),
                    ),
                  ],
                ),
                if (hasBudget) ...<Widget>[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remaining < 0
                            ? const Color(0xFFFFC7CB)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    remaining >= 0
                        ? '本月预算还剩 ${formatMoney(remaining)}'
                        : '已超出预算 ${formatMoney(-remaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
