import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/app_data.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'category_avatar.dart';

/// One ledger row: icon, category, note, wallet and amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.record,
    required this.category,
    required this.account,
    this.onTap,
  });

  final TransactionRecord record;
  final Category? category;
  final Account? account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = category == null
        ? palette.muted
        : Color(category!.colorValue);
    final time =
        '${record.date.hour.toString().padLeft(2, '0')}:'
        '${record.date.minute.toString().padLeft(2, '0')}';
    final subtitle = <String>[
      if (record.note.isNotEmpty) record.note,
      if (account != null) account!.name,
      time,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              CategoryAvatar(
                iconKey: category?.iconKey ?? 'other',
                color: color,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      category?.name ?? '未分类',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                record.type.isExpense
                    ? '-${formatAmount(record.amount)}'
                    : '+${formatAmount(record.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: record.type.isExpense
                      ? Theme.of(context).colorScheme.onSurface
                      : palette.income,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header row that introduces each day group.
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({super.key, required this.section});

  final DaySection section;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final date = section.date;
    final expense = section.expense;
    final income = section.income;
    final summary = <String>[
      if (income > 0) '收入 ${formatAmount(income)}',
      if (expense > 0) '支出 ${formatAmount(expense)}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: <Widget>[
          Text(
            dayGroupLabel(date),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            weekdayShortLabel(date),
            style: TextStyle(fontSize: 12, color: palette.faint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}
