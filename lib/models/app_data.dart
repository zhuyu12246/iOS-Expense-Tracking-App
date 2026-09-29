import 'account.dart';
import 'category.dart';
import 'transaction_record.dart';

/// Everything the app needs to boot, loaded in one shot.
class AppData {
  const AppData({
    this.categories = const [],
    this.accounts = const [],
    this.transactions = const [],
    this.settings = const {},
  });

  final List<Category> categories;
  final List<Account> accounts;
  final List<TransactionRecord> transactions;
  final Map<String, String> settings;

  bool get isEmpty => categories.isEmpty && accounts.isEmpty;
}

/// A day of records, used by the ledger list.
class DaySection {
  const DaySection({
    required this.date,
    required this.items,
    required this.expense,
    required this.income,
  });

  final DateTime date;
  final List<TransactionRecord> items;
  final int expense;
  final int income;
}

/// Aggregated spending per category, used by the stats screen.
class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.total,
    required this.ratio,
    required this.count,
  });

  final Category category;
  final int total;
  final double ratio;
  final int count;
}

/// A month of aggregated totals, used by the trend chart.
class TrendPoint {
  const TrendPoint({
    required this.month,
    required this.expense,
    required this.income,
  });

  final DateTime month;
  final int expense;
  final int income;

  int get balance => income - expense;
}
