import '../models/account.dart';
import '../models/app_data.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import 'ledger_store.dart';

/// In-memory [LedgerStore], used by tests and previews.
class MemoryLedgerStore implements LedgerStore {
  MemoryLedgerStore([AppData data = const AppData()]) {
    _categories.addAll(data.categories);
    _accounts.addAll(data.accounts);
    _transactions.addAll(data.transactions);
    _settings.addAll(data.settings);
  }

  final List<Category> _categories = <Category>[];
  final List<Account> _accounts = <Account>[];
  final List<TransactionRecord> _transactions = <TransactionRecord>[];
  final Map<String, String> _settings = <String, String>{};

  @override
  Future<AppData> load() async => AppData(
        categories: List<Category>.unmodifiable(_categories),
        accounts: List<Account>.unmodifiable(_accounts),
        transactions: List<TransactionRecord>.unmodifiable(_transactions),
        settings: Map<String, String>.unmodifiable(_settings),
      );

  @override
  Future<void> putCategory(Category category) async {
    _categories.removeWhere((item) => item.id == category.id);
    _categories.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> putAccount(Account account) async {
    _accounts.removeWhere((item) => item.id == account.id);
    _accounts.add(account);
  }

  @override
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> putTransaction(TransactionRecord record) async {
    _transactions.removeWhere((item) => item.id == record.id);
    _transactions.add(record);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> putSetting(String key, String value) async {
    _settings[key] = value;
  }

  @override
  Future<void> putAll(AppData data) async {
    _categories
      ..clear()
      ..addAll(data.categories);
    _accounts
      ..clear()
      ..addAll(data.accounts);
    _transactions
      ..clear()
      ..addAll(data.transactions);
    _settings
      ..clear()
      ..addAll(data.settings);
  }

  @override
  Future<void> wipe() async {
    _categories.clear();
    _accounts.clear();
    _transactions.clear();
    _settings.clear();
  }
}
