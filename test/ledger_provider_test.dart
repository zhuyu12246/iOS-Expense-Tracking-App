import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/data/memory_ledger_store.dart';
import 'package:ledger_app/models/account.dart';
import 'package:ledger_app/models/category.dart';
import 'package:ledger_app/models/types.dart';
import 'package:ledger_app/providers/ledger_provider.dart';

void main() {
  late LedgerProvider provider;

  setUp(() async {
    provider = LedgerProvider(
      store: MemoryLedgerStore(),
      clock: () => DateTime(2026, 9, 29, 12),
    );
    await provider.init();
  });

  /// Wallets are user data now, so every test creates the one it needs.
  Future<Account> addAccount({String name = '现金', int balance = 0}) async {
    final account = Account(
      id: 'acc_test_$name',
      name: name,
      iconKey: 'cash',
      colorValue: 0xFF5B6BF5,
      kind: AccountKind.cash,
      initialBalance: balance,
    );
    await provider.saveAccount(account);
    return account;
  }

  test('首次启动只写入默认分类，不预置账户和余额', () {
    expect(provider.isReady, isTrue);
    expect(provider.error, isNull);
    expect(provider.categories, isNotEmpty);
    expect(provider.expenseCategories, isNotEmpty);
    expect(provider.incomeCategories, isNotEmpty);
    expect(provider.accounts, isEmpty);
    expect(provider.transactions, isEmpty);
    expect(provider.totalAssets, 0);
    expect(provider.monthExpense, 0);
  });

  test('账户列表允许清空，可以删除最后一个账户', () async {
    final account = await addAccount();
    expect(provider.accounts.length, 1);

    final result = await provider.deleteAccount(account.id);
    expect(result.ok, isTrue);
    expect(provider.accounts, isEmpty);
  });

  test('新增记录会更新当月收支与账户余额', () async {
    final account = await addAccount(balance: 100000);
    final before = provider.accountBalance(account.id);

    await provider.addRecord(
      type: TxType.expense,
      amount: 2500,
      categoryId: provider.expenseCategories.first.id,
      accountId: account.id,
      date: DateTime(2026, 9, 10),
    );

    expect(provider.monthExpense, 2500);
    expect(provider.monthCount, 1);
    expect(provider.accountBalance(account.id), before - 2500);

    await provider.addRecord(
      type: TxType.income,
      amount: 10000,
      categoryId: provider.incomeCategories.first.id,
      accountId: account.id,
      date: DateTime(2026, 9, 11),
    );

    expect(provider.monthIncome, 10000);
    expect(provider.monthBalance, 7500);
    expect(provider.accountBalance(account.id), before + 7500);
    expect(provider.allTimeIncome, 10000);
    expect(provider.allTimeExpense, 2500);
  });

  test('切换月份只统计当月记录', () async {
    final account = await addAccount();
    final category = provider.expenseCategories.first.id;

    await provider.addRecord(
      type: TxType.expense,
      amount: 3000,
      categoryId: category,
      accountId: account.id,
      date: DateTime(2026, 9, 10),
    );
    await provider.addRecord(
      type: TxType.expense,
      amount: 8000,
      categoryId: category,
      accountId: account.id,
      date: DateTime(2026, 8, 10),
    );

    expect(provider.monthExpense, 3000);

    provider.shiftMonth(-1);
    expect(provider.selectedMonth, DateTime(2026, 8));
    expect(provider.monthExpense, 8000);

    provider.goToCurrentMonth();
    expect(provider.selectedMonth, DateTime(2026, 9));
    expect(provider.isCurrentMonth, isTrue);
  });

  test('分类统计按金额排序并计算占比', () async {
    final account = await addAccount();
    final food = provider.expenseCategories.first;
    final transport = provider.expenseCategories[1];

    await provider.addRecord(
      type: TxType.expense,
      amount: 4000,
      categoryId: food.id,
      accountId: account.id,
      date: DateTime(2026, 9, 3),
    );
    await provider.addRecord(
      type: TxType.expense,
      amount: 2000,
      categoryId: transport.id,
      accountId: account.id,
      date: DateTime(2026, 9, 4),
    );

    final stats = provider.statsFor(TxType.expense);
    expect(stats.length, 2);
    expect(stats.first.category.id, food.id);
    expect(stats.first.total, 4000);
    expect(stats.first.ratio, closeTo(2 / 3, 0.0001));
    expect(stats.last.ratio, closeTo(1 / 3, 0.0001));
  });

  test('按天分组的顺序与当日合计正确', () async {
    final account = await addAccount();
    final category = provider.expenseCategories.first.id;

    await provider.addRecord(
      type: TxType.expense,
      amount: 1000,
      categoryId: category,
      accountId: account.id,
      date: DateTime(2026, 9, 5, 9),
    );
    await provider.addRecord(
      type: TxType.expense,
      amount: 500,
      categoryId: category,
      accountId: account.id,
      date: DateTime(2026, 9, 5, 19),
    );
    await provider.addRecord(
      type: TxType.income,
      amount: 700,
      categoryId: provider.incomeCategories.first.id,
      accountId: account.id,
      date: DateTime(2026, 9, 8),
    );

    final sections = provider.daySections;
    expect(sections.length, 2);
    expect(sections.first.date, DateTime(2026, 9, 8));
    expect(sections.first.income, 700);
    expect(sections.last.date, DateTime(2026, 9, 5));
    expect(sections.last.expense, 1500);
    expect(sections.last.items.length, 2);
    expect(sections.last.items.first.amount, 500);
  });

  test('有记录的分类和账户不能删除', () async {
    final account = await addAccount();
    final category = provider.expenseCategories.first;

    await provider.addRecord(
      type: TxType.expense,
      amount: 1000,
      categoryId: category.id,
      accountId: account.id,
      date: DateTime(2026, 9, 5),
    );

    final categoryResult = await provider.deleteCategory(category.id);
    expect(categoryResult.ok, isFalse);
    expect(provider.categories.any((item) => item.id == category.id), isTrue);

    final accountResult = await provider.deleteAccount(account.id);
    expect(accountResult.ok, isFalse);
  });

  test('新增分类追加到对应类型末尾', () async {
    final countBefore = provider.incomeCategories.length;
    await provider.saveCategory(
      const Category(
        id: 'cat_custom',
        name: '稿费',
        iconKey: 'parttime',
        colorValue: 0xFF5B6BF5,
        type: TxType.income,
      ),
    );
    expect(provider.incomeCategories.length, countBefore + 1);
    expect(
      provider.categoryById('cat_custom')?.sortOrder,
      countBefore,
    );
  });

  test('趋势返回连续 6 个月', () async {
    final account = await addAccount();
    await provider.addRecord(
      type: TxType.expense,
      amount: 1200,
      categoryId: provider.expenseCategories.first.id,
      accountId: account.id,
      date: DateTime(2026, 8, 2),
    );

    final points = provider.trend(months: 6);
    expect(points.length, 6);
    expect(points.first.month, DateTime(2026, 4));
    expect(points.last.month, DateTime(2026, 9));
    expect(points[4].expense, 1200);
    expect(points.last.expense, 0);
  });

  test('预算进度与清空记录', () async {
    final account = await addAccount();
    await provider.setMonthlyBudget(100000);
    expect(provider.monthlyBudget, 100000);
    expect(provider.budgetProgress, 0);

    await provider.addRecord(
      type: TxType.expense,
      amount: 25000,
      categoryId: provider.expenseCategories.first.id,
      accountId: account.id,
      date: DateTime(2026, 9, 5),
    );
    expect(provider.budgetProgress, closeTo(0.25, 0.0001));

    await provider.clearAllRecords();
    expect(provider.transactions, isEmpty);
    expect(provider.accounts, isNotEmpty);
    expect(provider.categories, isNotEmpty);
    expect(provider.monthlyBudget, 100000);
  });

  test('主题设置会被记住', () async {
    final store = MemoryLedgerStore();
    final first = LedgerProvider(
      store: store,
      clock: () => DateTime(2026, 9, 29),
    );
    await first.init();
    await first.setThemeMode(ThemeMode.dark);
    expect(first.themeMode, ThemeMode.dark);

    final reloaded = LedgerProvider(
      store: store,
      clock: () => DateTime(2026, 9, 29),
    );
    await reloaded.init();
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('载入示例数据会补齐账户并可以统计', () async {
    await provider.loadSampleData();
    expect(provider.accounts, isNotEmpty);
    expect(provider.transactions, isNotEmpty);
    expect(provider.monthExpense, greaterThan(0));
    expect(provider.statsFor(TxType.expense), isNotEmpty);
    expect(provider.daySections, isNotEmpty);
  });
}
