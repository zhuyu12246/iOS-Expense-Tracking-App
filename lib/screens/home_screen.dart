import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/app_data.dart';
import '../models/transaction_record.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_switcher.dart';
import '../widgets/sheets.dart';
import '../widgets/summary_card.dart';
import '../widgets/surface_card.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_editor_screen.dart';

/// The ledger: month summary plus every record grouped by day.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;
    final sections = provider.daySections;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        backgroundColor: palette.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: SlidableAutoCloseBehavior(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: palette.pageBackground,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              title: Text(
                '明细',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  tooltip: '选择月份',
                  onPressed: () => _pickMonth(context, provider),
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Column(
                  children: <Widget>[
                    MonthSwitcher(
                      month: provider.selectedMonth,
                      onPrevious: () => provider.shiftMonth(-1),
                      onNext: () => provider.shiftMonth(1),
                      onTapLabel: () => _pickMonth(context, provider),
                    ),
                    const SizedBox(height: 8),
                    SummaryCard(
                      month: provider.selectedMonth,
                      expense: provider.monthExpense,
                      income: provider.monthIncome,
                      budget: provider.monthlyBudget,
                      onBudgetTap: () => _editBudget(context, provider),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: provider.hasRecords
                    ? EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: '${monthLabel(provider.selectedMonth)}还没有记录',
                        message: '换个日期看看，或者记下这个月的第一笔。',
                        action: FilledButton.icon(
                          onPressed: () => _openEditor(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('记一笔'),
                        ),
                      )
                    : EmptyState(
                        title: '开始你的第一笔记录',
                        message: '记录每一笔收支，月底就能清楚看到钱花在了哪里。',
                        action: Column(
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () => _openEditor(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('记一笔'),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () async {
                                await provider.loadSampleData();
                                if (context.mounted) {
                                  showToast(context, '已载入示例数据');
                                }
                              },
                              child: const Text('先载入示例数据看看'),
                            ),
                          ],
                        ),
                      ),
              )
            else
              SliverList.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) => _DayGroup(
                  section: sections[index],
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  static Future<void> _openEditor(
    BuildContext context, {
    TransactionRecord? record,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditorScreen(record: record),
      ),
    );
  }

  static Future<void> _pickMonth(
    BuildContext context,
    LedgerProvider provider,
  ) async {
    final picked = await showMonthPickerSheet(
      context,
      initial: provider.selectedMonth,
    );
    if (picked != null) provider.jumpToMonth(picked);
  }

  static Future<void> _editBudget(
    BuildContext context,
    LedgerProvider provider,
  ) async {
    final result = await showAmountInputDialog(
      context,
      title: '设置月预算',
      message: '填 0 可以关闭预算提醒',
      initialCents: provider.monthlyBudget,
    );
    if (result == null) return;
    await provider.setMonthlyBudget(result);
    if (context.mounted) {
      showToast(
        context,
        result == 0 ? '已关闭预算' : '月预算已设为 ${formatMoney(result)}',
      );
    }
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.section});

  final DaySection section;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SurfaceCard(
        clip: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            DaySectionHeader(section: section),
            for (var i = 0; i < section.items.length; i++) ...<Widget>[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  color: palette.border,
                ),
              _RecordRow(record: section.items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;

    return Slidable(
      key: ValueKey<String>(record.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.48,
        children: <Widget>[
          SlidableAction(
            onPressed: (_) =>
                HomeScreen._openEditor(context, record: record),
            backgroundColor: palette.brand,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, provider, record),
            backgroundColor: palette.expense,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: '删除',
          ),
        ],
      ),
      child: TransactionTile(
        record: record,
        category: provider.categoryById(record.categoryId),
        account: provider.accountById(record.accountId),
        onTap: () => HomeScreen._openEditor(context, record: record),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LedgerProvider provider,
    TransactionRecord record,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除这笔记录？',
      message: '${provider.categoryById(record.categoryId)?.name ?? '未分类'} '
          '${formatMoney(record.amount)}，删除后无法恢复。',
    );
    if (!confirmed) return;
    await provider.deleteRecord(record.id);
    if (context.mounted) showToast(context, '已删除');
  }
}
