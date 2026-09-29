import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_avatar.dart';
import '../widgets/sheets.dart';
import '../widgets/surface_card.dart';
import 'account_editor_screen.dart';
import 'categories_screen.dart';

/// Assets, wallets, preferences and data tools.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;

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
              '我的',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.list(
              children: <Widget>[
                _AssetCard(provider: provider),
                const SizedBox(height: 20),
                const SectionHeader(title: '账户'),
                SurfaceCard(
                  clip: true,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      if (provider.accounts.isEmpty)
                        const _NoAccountHint()
                      else
                        for (var i = 0; i < provider.accounts.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 62,
                              color: palette.border,
                            ),
                          _AccountRow(
                            account: provider.accounts[i],
                            balance: provider.accountBalance(
                              provider.accounts[i].id,
                            ),
                            onTap: () => Navigator.of(context).push<Account>(
                              MaterialPageRoute<Account>(
                                builder: (_) => AccountEditorScreen(
                                  account: provider.accounts[i],
                                ),
                              ),
                            ),
                          ),
                        ],
                      Divider(height: 1, indent: 62, color: palette.border),
                      _SettingRow(
                        icon: Icons.add_rounded,
                        iconColor: palette.brand,
                        title: '添加账户',
                        onTap: () => Navigator.of(context).push<Account>(
                          MaterialPageRoute<Account>(
                            builder: (_) => const AccountEditorScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: '记账设置'),
                SurfaceCard(
                  clip: true,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      _SettingRow(
                        icon: Icons.savings_rounded,
                        iconColor: const Color(0xFFF7A325),
                        title: '月预算',
                        value: provider.monthlyBudget > 0
                            ? formatMoney(provider.monthlyBudget)
                            : '未设置',
                        onTap: () => _editBudget(context, provider),
                      ),
                      Divider(height: 1, indent: 62, color: palette.border),
                      _SettingRow(
                        icon: Icons.category_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: '分类管理',
                        value: '${provider.categories.length} 个',
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: '外观'),
                SurfaceCard(
                  child: _ThemeSelector(
                    value: provider.themeMode,
                    onChanged: provider.setThemeMode,
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: '数据'),
                SurfaceCard(
                  clip: true,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      _SettingRow(
                        icon: Icons.ios_share_rounded,
                        iconColor: const Color(0xFF18B98A),
                        title: '导出 CSV',
                        value: '${provider.transactions.length} 条记录',
                        onTap: () => _export(context, provider),
                      ),
                      Divider(height: 1, indent: 62, color: palette.border),
                      _SettingRow(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: '载入示例数据',
                        onTap: () => _loadSamples(context, provider),
                      ),
                      Divider(height: 1, indent: 62, color: palette.border),
                      _SettingRow(
                        icon: Icons.delete_sweep_rounded,
                        iconColor: palette.expense,
                        title: '清空所有记录',
                        destructive: true,
                        onTap: () => _clearRecords(context, provider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: '关于'),
                SurfaceCard(
                  clip: true,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      _SettingRow(
                        icon: Icons.info_outline_rounded,
                        iconColor: palette.brand,
                        title: '轻记账',
                        value: 'v$_version',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: '轻记账',
                          applicationVersion: 'v$_version',
                          applicationIcon: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  palette.brand,
                                  palette.brandDeep,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                            ),
                          ),
                          children: const <Widget>[
                            Text(
                              '一个用 Flutter 写的本地记账 App：所有数据都保存在设备上，'
                              '支持多账户、分类统计、预算和 CSV 导出。',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    '数据仅保存在本机 · 轻记账 v$_version',
                    style: TextStyle(fontSize: 11, color: palette.faint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  static Future<void> _export(
    BuildContext context,
    LedgerProvider provider,
  ) async {
    if (provider.transactions.isEmpty) {
      showToast(context, '还没有记录可以导出');
      return;
    }
    try {
      final path = await provider.exportCsv();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('导出成功'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('CSV 已保存到 App 文档目录：'),
              const SizedBox(height: 10),
              SelectableText(
                path,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: path));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) showToast(context, '路径已复制');
              },
              child: const Text('复制路径'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('好'),
            ),
          ],
        ),
      );
    } catch (exception) {
      if (context.mounted) showToast(context, '导出失败：$exception');
    }
  }

  static Future<void> _loadSamples(
    BuildContext context,
    LedgerProvider provider,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '载入示例数据？',
      message: '会覆盖当前所有记录，账户和分类保持不变。',
      confirmText: '载入',
      destructive: false,
    );
    if (!confirmed) return;
    await provider.loadSampleData();
    if (context.mounted) showToast(context, '示例数据已载入');
  }

  static Future<void> _clearRecords(
    BuildContext context,
    LedgerProvider provider,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '清空所有记录？',
      message: '所有收支记录都会被删除，此操作无法撤销。',
      confirmText: '清空',
    );
    if (!confirmed) return;
    await provider.clearAllRecords();
    if (context.mounted) showToast(context, '已清空所有记录');
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.provider});

  final LedgerProvider provider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final income = provider.allTimeIncome;
    final expense = provider.allTimeExpense;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.brand, palette.brandDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.brand.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '总资产',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(provider.totalAssets),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _AssetMetric(label: '累计收入', value: formatMoney(income)),
              ),
              Container(
                width: 1,
                height: 26,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _AssetMetric(label: '累计支出', value: formatMoney(expense)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetMetric extends StatelessWidget {
  const _AssetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Shown in the wallet section before the user has created anything.
class _NoAccountHint extends StatelessWidget {
  const _NoAccountHint();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 19,
              color: palette.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '还没有账户',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '添加一个现金或银行卡账户，就能开始记账了',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.onTap,
  });

  final Account account;
  final int balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: <Widget>[
              CategoryAvatar(
                iconKey: account.iconKey,
                color: Color(account.colorValue),
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.kind.label,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(balance),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: balance < 0
                      ? palette.expense
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: destructive
                        ? palette.expense
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const List<(ThemeMode, String, IconData)> _options =
      <(ThemeMode, String, IconData)>[
    (ThemeMode.system, '跟随系统', Icons.brightness_auto_rounded),
    (ThemeMode.light, '浅色', Icons.light_mode_rounded),
    (ThemeMode.dark, '深色', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        for (var i = 0; i < _options.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(_options[i].$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: value == _options[i].$1
                      ? palette.brand.withValues(alpha: 0.12)
                      : palette.chipBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: value == _options[i].$1
                        ? palette.brand
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      _options[i].$3,
                      size: 20,
                      color: value == _options[i].$1
                          ? palette.brand
                          : palette.muted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _options[i].$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: value == _options[i].$1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: value == _options[i].$1
                            ? palette.brand
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
