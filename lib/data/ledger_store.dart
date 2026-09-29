import '../models/account.dart';
import '../models/app_data.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';

/// Persistence boundary for the ledger.
///
/// The production implementation is backed by SQLite; tests use an in-memory
/// implementation, which keeps the domain logic testable without a device.
abstract class LedgerStore {
  Future<AppData> load();

  Future<void> putCategory(Category category);
  Future<void> deleteCategory(String id);

  Future<void> putAccount(Account account);
  Future<void> deleteAccount(String id);

  Future<void> putTransaction(TransactionRecord record);
  Future<void> deleteTransaction(String id);

  Future<void> putSetting(String key, String value);

  Future<void> putAll(AppData data);

  Future<void> wipe();
}

/// Repository failures surface as this exception so the UI can show a message
/// instead of a raw plugin error.
class LedgerStoreException implements Exception {
  const LedgerStoreException(this.message);

  final String message;

  @override
  String toString() => 'LedgerStoreException: $message';
}
