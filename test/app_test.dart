import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/app.dart';
import 'package:ledger_app/data/memory_ledger_store.dart';
import 'package:ledger_app/providers/ledger_provider.dart';
import 'package:ledger_app/screens/account_editor_screen.dart';
import 'package:ledger_app/screens/settings_screen.dart';
import 'package:ledger_app/screens/stats_screen.dart';
import 'package:ledger_app/screens/transaction_editor_screen.dart';
import 'package:ledger_app/widgets/amount_keypad.dart';
import 'package:ledger_app/widgets/charts/donut_chart.dart';
import 'package:provider/provider.dart';

const ValueKey<String> _statsTab = ValueKey<String>('tab-1');
const ValueKey<String> _profileTab = ValueKey<String>('tab-2');

Future<LedgerProvider> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final provider = LedgerProvider(
    store: MemoryLedgerStore(),
    clock: () => DateTime(2026, 9, 29, 12),
  );
  await provider.init();

  await tester.pumpWidget(
    ChangeNotifierProvider<LedgerProvider>.value(
      value: provider,
      child: const LedgerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

/// The editor shows a blinking caret, so it never reaches a settled state.
Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await _pumpRoute(tester);
}

void main() {
  testWidgets('新装 App 没有任何账户，记一笔时引导创建', (tester) async {
    final provider = await _pumpApp(tester);

    expect(find.text('明细'), findsWidgets);
    expect(find.text('开始你的第一笔记录'), findsOneWidget);
    expect(provider.accounts, isEmpty);

    await _openEditor(tester);
    expect(find.byType(TransactionEditorScreen), findsOneWidget);
    expect(find.text('餐饮'), findsWidgets);

    // 没有账户时，点账户胶囊直接进入创建账户页
    final accountChip = find.descendant(
      of: find.byType(TransactionEditorScreen),
      matching: find.text('添加账户'),
    );
    expect(accountChip, findsOneWidget);
    await tester.tap(accountChip);
    await tester.pumpAndSettle();
    expect(find.byType(AccountEditorScreen), findsOneWidget);

    await tester.tap(find.text('支付宝'));
    await tester.pump();

    final saveAccount = find.widgetWithText(FilledButton, '保存');
    await tester.dragUntilVisible(
      saveAccount,
      find.descendant(
        of: find.byType(AccountEditorScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(saveAccount);
    // 回到记账页，那里有常驻闪烁光标，只能按帧推进
    await _pumpRoute(tester);

    expect(provider.accounts.length, 1);
    expect(provider.totalAssets, 0);
    expect(find.byType(TransactionEditorScreen), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();

    final saveButton = find.descendant(
      of: find.byType(AmountKeypad),
      matching: find.text('记一笔'),
    );
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(provider.transactions.length, 1);
    expect(provider.monthExpense, 12300);
    expect(find.byType(TransactionEditorScreen), findsNothing);
    expect(find.text('-123.00'), findsOneWidget);
  });

  testWidgets('金额为空时不能保存', (tester) async {
    final provider = await _pumpApp(tester);

    await _openEditor(tester);

    final saveButton = find.descendant(
      of: find.byType(AmountKeypad),
      matching: find.text('记一笔'),
    );
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(provider.transactions, isEmpty);
    expect(find.byType(TransactionEditorScreen), findsOneWidget);
  });

  testWidgets('切换月份后明细随之变化', (tester) async {
    final provider = await _pumpApp(tester);
    await provider.loadSampleData();
    await tester.pumpAndSettle();

    final september = provider.monthExpense;
    expect(september, greaterThan(0));

    await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
    await tester.pumpAndSettle();

    expect(provider.selectedMonth.month, 8);
    expect(provider.monthExpense, isNot(september));
  });

  testWidgets('统计页展示分类占比与趋势', (tester) async {
    final provider = await _pumpApp(tester);
    await provider.loadSampleData();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_statsTab));
    await tester.pumpAndSettle();

    expect(find.byType(DonutChart), findsOneWidget);
    expect(find.text('分类排行'), findsOneWidget);

    final scrollView = find.descendant(
      of: find.byType(StatsScreen),
      matching: find.byType(CustomScrollView),
    );
    await tester.drag(scrollView, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('近 6 个月趋势'), findsOneWidget);
  });

  testWidgets('我的页展示总资产、账户与数据设置', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(_profileTab));
    await tester.pumpAndSettle();

    expect(find.text('总资产'), findsOneWidget);
    expect(find.text('月预算'), findsOneWidget);
    expect(find.text('分类管理'), findsOneWidget);

    final scrollView = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(CustomScrollView),
    );
    await tester.drag(scrollView, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('导出 CSV'), findsOneWidget);
    expect(find.text('清空所有记录'), findsOneWidget);
  });

  testWidgets('可以进入分类管理并新建分类', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(_profileTab));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('分类管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分类管理'));
    await tester.pumpAndSettle();

    expect(find.text('新建分类'), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);

    await tester.tap(find.text('新建分类'));
    await tester.pumpAndSettle();
    expect(find.text('编辑分类'), findsNothing);
    expect(find.text('名称'), findsOneWidget);
  });

  testWidgets('可以切换深色主题', (tester) async {
    final provider = await _pumpApp(tester);

    await tester.tap(find.byKey(_profileTab));
    await tester.pumpAndSettle();

    final scrollView = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(CustomScrollView),
    );
    await tester.drag(scrollView, const Offset(0, -400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    expect(provider.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
  });
}
