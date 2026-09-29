import 'types.dart';

/// A single income / expense entry.
///
/// [amount] is always a positive value stored in cents to avoid the rounding
/// problems that come with floating point money.
class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.date,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final TxType type;
  final int amount;
  final String categoryId;
  final String accountId;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  bool get isExpense => type.isExpense;

  /// Signed amount: negative for expenses, positive for income.
  int get signedAmount => isExpense ? -amount : amount;

  TransactionRecord copyWith({
    TxType? type,
    int? amount,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? date,
  }) {
    return TransactionRecord(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.id,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'note': note,
        'date': date.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory TransactionRecord.fromMap(Map<String, Object?> map) =>
      TransactionRecord(
        id: map['id']! as String,
        type: TxType.fromId(map['type'] as String?),
        amount: (map['amount'] as num).toInt(),
        categoryId: map['category_id']! as String,
        accountId: map['account_id']! as String,
        note: (map['note'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(
          (map['date'] as num).toInt(),
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as num?)?.toInt() ??
              (map['date'] as num).toInt(),
        ),
      );
}
