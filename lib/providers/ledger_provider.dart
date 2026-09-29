import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/default_data.dart';
import '../data/ledger_store.dart';
import '../data/sqflite_ledger_store.dart';
import '../models/account.dart';
import '../models/app_data.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import '../models/types.dart';
import '../utils/formatters.dart';

/// Outcome of a delete request that may be refused (e.g. category in use).
class OperationResult {
  const OperationResult.success() : ok = true, message = null;
  const OperationResult.failure(this.message) : ok = false;

  final bool ok;
  final String? message;
}

/// Single source of truth for the ledger UI.
class LedgerProvider extends ChangeNotifier {
  LedgerProvider({LedgerStore? store, DateTime Function()? clock})
      : _store = store ?? SqfliteLedgerStore(),
        _clock = clock ?? DateTime.now {
    final now = _clock();
    _selectedMonth = DateTime(now.year, now.month);
  }

  static const String _themeKey = 'theme_mode';
  static const String _budgetKey = 'monthly_budget';
  static const _uuid = Uuid();

  final LedgerStore _store;
  final DateTime Function() _clock;

  bool _ready = false;
  String? _error;
  ThemeMode _themeMode = ThemeMode.system;
  int _monthlyBudget = 0;
  late DateTime _selectedMonth;

  List<Category> _categories = const <Category>[];
  List<Account> _accounts = const <Account>[];
  List<TransactionRecord> _transactions = const <TransactionRecord>[];

  // ---- Derived state, recomputed whenever data or month changes ----------
  List<TransactionRecord> _monthRecords = const <TransactionRecord>[];
  List<DaySection> _daySections = const <DaySection>[];
  int _monthExpense = 0;
  int _monthIncome = 0;
  Map<String, int> _accountTotals = const <String, int>{};

  bool get isReady => _ready;
  String? get error => _error;
  /// Injectable "now", so tests and previews can pin the current date.
  DateTime get now => _clock();
  DateTime get selectedMonth => _selectedMonth;
  ThemeMode get themeMode => _themeMode;
  int get monthlyBudget => _monthlyBudget;
  String get currencySymbol => '¥';

  List<Category> get categories => _categories;
  List<Account> get accounts => _accounts;
  List<TransactionRecord> get transactions => _transactions;

  List<Category> categoriesOf(TxType type) =>
      _categories.where((item) => item.type == type).toList();

  List<Category> get expenseCategories => categoriesOf(TxType.expense);
  List<Category> get incomeCategories => categoriesOf(TxType.income);

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final item in _categories) {
      if (item.id == id) return item;
    }
    return null;
  }

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final item in _accounts) {
      if (item.id == id) return item;
    }
    return null;
  }

  // ---- Ledger ------------------------------------------------------------

  List<TransactionRecord> get monthRecords => _monthRecords;
  List<DaySection> get daySections => _daySections;
  int get monthExpense => _monthExpense;
  int get monthIncome => _monthIncome;
  int get monthBalance => _monthIncome - _monthExpense;
  int get monthCount => _monthRecords.length;
  bool get hasRecords => _transactions.isNotEmpty;

  bool get isCurrentMonth {
    final now = _clock();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  int accountBalance(String accountId) {
    final account = accountById(accountId);
    if (account == null) return 0;
    return account.initialBalance + (_accountTotals[accountId] ?? 0);
  }

  /// Net worth across every wallet.
  int get totalAssets => _accounts.fold<int>(
        0,
        (sum, account) => sum + accountBalance(account.id),
      );

  int get allTimeIncome => _transactions
      .where((item) => item.type.isIncome)
      .fold<int>(0, (sum, item) => sum + item.amount);

  int get allTimeExpense => _transactions
      .where((item) => item.type.isExpense)
      .fold<int>(0, (sum, item) => sum + item.amount);

  double get budgetProgress {
    if (_monthlyBudget <= 0) return 0;
    return (_monthExpense / _monthlyBudget).clamp(0.0, 1.0);
  }

  /// Spending grouped by category for the selected month.
  List<CategoryStat> statsFor(TxType type) {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final record in _monthRecords) {
      if (record.type != type) continue;
      totals[record.categoryId] = (totals[record.categoryId] ?? 0) +
          record.amount;
      counts[record.categoryId] = (counts[record.categoryId] ?? 0) + 1;
    }
    final grand = totals.values.fold<int>(0, (sum, value) => sum + value);
    final stats = <CategoryStat>[];
    totals.forEach((categoryId, total) {
      final category = categoryById(categoryId);
      if (category == null) return;
      stats.add(
        CategoryStat(
          category: category,
          total: total,
          ratio: grand == 0 ? 0 : total / grand,
          count: counts[categoryId] ?? 0,
        ),
      );
    });
    stats.sort((a, b) => b.total.compareTo(a.total));
    return stats;
  }

  int get statsTotal => _monthRecords
      .where((item) => item.type.isExpense)
      .fold<int>(0, (sum, item) => sum + item.amount);

  /// Monthly totals for the [months] months ending at the selected month.
  List<TrendPoint> trend({int months = 6}) {
    final buckets = <String, (int, int)>{};
    for (final record in _transactions) {
      final key = monthKey(record.date);
      final current = buckets[key] ?? (0, 0);
      buckets[key] = record.type.isExpense
          ? (current.$1 + record.amount, current.$2)
          : (current.$1, current.$2 + record.amount);
    }
    final points = <TrendPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(_selectedMonth.year, _selectedMonth.month - i);
      final bucket = buckets[monthKey(month)] ?? (0, 0);
      points.add(
        TrendPoint(month: month, expense: bucket.$1, income: bucket.$2),
      );
    }
    return points;
  }

  /// Highest single-day spending in the selected month, used for the daily
  /// average comparison on the stats screen.
  int get averageDailyExpense {
    final days = daysInMonth(_selectedMonth.year, _selectedMonth.month);
    if (days == 0) return 0;
    return (_monthExpense / days).round();
  }

  // ---- Lifecycle ---------------------------------------------------------

  Future<void> init() async {
    try {
      var data = await _store.load();

      // A brand new install only gets categories. Wallets belong to the user:
      // no accounts, no records and no invented balances until they add them.
      if (data.categories.isEmpty) {
        data = AppData(
          categories: kDefaultCategories,
          accounts: data.accounts,
          transactions: data.transactions,
          settings: data.settings,
        );
        await _store.putAll(data);
      }

      data = await _dropLegacySeedAccounts(data);

      _applyData(data);
      _ready = true;
    } catch (exception) {
      _error = exception.toString();
      _ready = true;
    }
    notifyListeners();
  }

  /// An older build created five wallets with made-up balances on first
  /// launch. An upgrade silently removes that untouched set once, so nobody
  /// is left with money they never entered. Anything edited by the user — or
  /// any ledger that already has records — is left alone.
  Future<AppData> _dropLegacySeedAccounts(AppData data) async {
    if (data.transactions.isNotEmpty) return data;
    if (data.accounts.length != kLegacySeedAccounts.length) return data;

    final untouched = data.accounts.every(
      (account) => kLegacySeedAccounts[account.id] == account.initialBalance,
    );
    if (!untouched) return data;

    for (final account in data.accounts) {
      await _store.deleteAccount(account.id);
    }
    return AppData(
      categories: data.categories,
      accounts: const <Account>[],
      transactions: data.transactions,
      settings: data.settings,
    );
  }

  void _applyData(AppData data) {
    _categories = List<Category>.from(data.categories)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _accounts = List<Account>.from(data.accounts)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _transactions = List<TransactionRecord>.from(data.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    _monthlyBudget = int.tryParse(data.settings[_budgetKey] ?? '') ?? 0;
    _themeMode = switch (data.settings[_themeKey]) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _recompute();
  }

  void _recompute() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    _monthRecords = _transactions
        .where((item) => item.date.year == year && item.date.month == month)
        .toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    var expense = 0;
    var income = 0;
    final byDay = <DateTime, List<TransactionRecord>>{};
    for (final record in _monthRecords) {
      if (record.type.isExpense) {
        expense += record.amount;
      } else {
        income += record.amount;
      }
      final key = DateTime(record.date.year, record.date.month, record.date.day);
      byDay.putIfAbsent(key, () => <TransactionRecord>[]).add(record);
    }
    _monthExpense = expense;
    _monthIncome = income;

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    _daySections = <DaySection>[
      for (final day in days)
        DaySection(
          date: day,
          items: byDay[day]!,
          expense: byDay[day]!
              .where((item) => item.type.isExpense)
              .fold<int>(0, (sum, item) => sum + item.amount),
          income: byDay[day]!
              .where((item) => item.type.isIncome)
              .fold<int>(0, (sum, item) => sum + item.amount),
        ),
    ];

    final totals = <String, int>{};
    for (final record in _transactions) {
      totals[record.accountId] =
          (totals[record.accountId] ?? 0) + record.signedAmount;
    }
    _accountTotals = totals;
  }

  // ---- Navigation --------------------------------------------------------

  void shiftMonth(int delta) {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    _recompute();
    notifyListeners();
  }

  void jumpToMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    _recompute();
    notifyListeners();
  }

  void goToCurrentMonth() {
    final now = _clock();
    jumpToMonth(DateTime(now.year, now.month));
  }

  // ---- Mutations ---------------------------------------------------------

  Future<void> addRecord({
    required TxType type,
    required int amount,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String note = '',
  }) async {
    final now = _clock();
    final record = TransactionRecord(
      id: _uuid.v4(),
      type: type,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      note: note.trim(),
      date: date,
      createdAt: now,
    );
    await _store.putTransaction(record);
    _transactions = <TransactionRecord>[record, ..._transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    _recompute();
    notifyListeners();
  }

  Future<void> updateRecord(TransactionRecord record) async {
    await _store.putTransaction(record);
    _transactions = _transactions
        .map((item) => item.id == record.id ? record : item)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _recompute();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _store.deleteTransaction(id);
    _transactions = _transactions.where((item) => item.id != id).toList();
    _recompute();
    notifyListeners();
  }

  int recordCountForCategory(String categoryId) =>
      _transactions.where((item) => item.categoryId == categoryId).length;

  int recordCountForAccount(String accountId) =>
      _transactions.where((item) => item.accountId == accountId).length;

  Future<OperationResult> deleteCategory(String id) async {
    final used = recordCountForCategory(id);
    if (used > 0) {
      return OperationResult.failure('该分类下还有 $used 笔记录，无法删除');
    }
    await _store.deleteCategory(id);
    _categories = _categories.where((item) => item.id != id).toList();
    _recompute();
    notifyListeners();
    return const OperationResult.success();
  }

  Future<void> saveCategory(Category category) async {
    final exists = _categories.any((item) => item.id == category.id);
    final next = exists
        ? category
        : category.copyWith(
            sortOrder: _categories
                    .where((item) => item.type == category.type)
                    .length,
          );
    await _store.putCategory(next);
    final merged = <Category>[
      for (final item in _categories)
        if (item.id != next.id) item,
      next,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _categories = merged;
    _recompute();
    notifyListeners();
  }

  Future<OperationResult> deleteAccount(String id) async {
    final used = recordCountForAccount(id);
    if (used > 0) {
      return OperationResult.failure('该账户下还有 $used 笔记录，无法删除');
    }
    await _store.deleteAccount(id);
    _accounts = _accounts.where((item) => item.id != id).toList();
    _recompute();
    notifyListeners();
    return const OperationResult.success();
  }

  Future<void> saveAccount(Account account) async {
    final exists = _accounts.any((item) => item.id == account.id);
    final next = exists
        ? account
        : account.copyWith(sortOrder: _accounts.length);
    await _store.putAccount(next);
    final merged = <Account>[
      for (final item in _accounts)
        if (item.id != next.id) item,
      next,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _accounts = merged;
    _recompute();
    notifyListeners();
  }

  Future<void> setMonthlyBudget(int cents) async {
    _monthlyBudget = cents;
    await _store.putSetting(_budgetKey, cents.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _store.putSetting(_themeKey, mode.name);
    notifyListeners();
  }

  String newId(String prefix) => '${prefix}_${_uuid.v4()}';

  /// Seeds a few months of demo records. Handy for exploring the app.
  Future<void> loadSampleData() async {
    // Demo records need wallets to belong to, so create the presets first.
    var accounts = _accounts;
    if (accounts.isEmpty) {
      accounts = List<Account>.from(kAccountPresets);
      for (final account in accounts) {
        await _store.putAccount(account);
      }
    }

    final samples = buildSampleTransactions(
      accountIds: accounts.map((account) => account.id).toList(),
      today: _clock(),
      months: 3,
    );

    await _store.putAll(
      AppData(
        categories: _categories,
        accounts: accounts,
        transactions: samples,
        settings: _settingsSnapshot(),
      ),
    );
    _accounts = accounts;
    _transactions = List<TransactionRecord>.from(samples)
      ..sort((a, b) => b.date.compareTo(a.date));
    _recompute();
    notifyListeners();
  }

  Future<void> clearAllRecords() async {
    await _store.putAll(
      AppData(
        categories: _categories,
        accounts: _accounts,
        transactions: const <TransactionRecord>[],
        settings: _settingsSnapshot(),
      ),
    );
    _transactions = const <TransactionRecord>[];
    _recompute();
    notifyListeners();
  }

  Map<String, String> _settingsSnapshot() => <String, String>{
        _themeKey: _themeMode.name,
        _budgetKey: _monthlyBudget.toString(),
      };

  /// Writes every record to a CSV file and returns its path.
  Future<String> exportCsv() async {
    final buffer = StringBuffer()..writeln('日期,类型,分类,账户,金额,备注');
    for (final record in _transactions) {
      final category = categoryById(record.categoryId)?.name ?? '未分类';
      final account = accountById(record.accountId)?.name ?? '未知账户';
      final note = record.note.replaceAll('"', '""');
      buffer.writeln(
        '${isoDateTime(record.date)},${record.type.label},'
        '${_csv(category)},${_csv(account)},'
        '${formatAmount(record.signedAmount)},${_csv(note)}',
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    final stamp = isoDate(_clock()).replaceAll('-', '');
    final file = File(p.join(directory.path, '轻记账_$stamp.csv'));
    await file.writeAsString('\uFEFF$buffer');
    return file.path;
  }

  String _csv(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
