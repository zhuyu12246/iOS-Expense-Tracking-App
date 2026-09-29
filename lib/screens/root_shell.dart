import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Hosts the three top level tabs and the custom bottom bar.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;

    if (!provider.isReady) {
      return Scaffold(
        backgroundColor: palette.pageBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[palette.brand, palette.brandDeep],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '轻记账',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: palette.brand,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        backgroundColor: palette.pageBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.error_outline_rounded, size: 44, color: palette.expense),
                const SizedBox(height: 16),
                Text(
                  '数据加载失败',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => provider.init(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<(IconData, String)> _items = <(IconData, String)>[
    (Icons.receipt_long_rounded, '明细'),
    (Icons.pie_chart_rounded, '统计'),
    (Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    key: ValueKey<String>('tab-$i'),
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _items[i].$1,
                          size: 24,
                          color: index == i ? palette.brand : palette.faint,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: index == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: index == i ? palette.brand : palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
