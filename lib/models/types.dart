/// Shared enums and small value types used across the app.
library;

/// Whether a record moves money out of the wallet or into it.
enum TxType {
  expense('expense', '支出'),
  income('income', '收入');

  const TxType(this.id, this.label);

  final String id;
  final String label;

  bool get isExpense => this == TxType.expense;
  bool get isIncome => this == TxType.income;

  static TxType fromId(String? value) =>
      value == TxType.income.id ? TxType.income : TxType.expense;

  TxType get opposite => isExpense ? TxType.income : TxType.expense;
}

/// The kind of wallet an [Account] represents.
enum AccountKind {
  cash('cash', '现金'),
  debitCard('debit_card', '储蓄卡'),
  creditCard('credit_card', '信用卡'),
  digital('digital', '电子钱包'),
  other('other', '其他');

  const AccountKind(this.id, this.label);

  final String id;
  final String label;

  static AccountKind fromId(String? value) => AccountKind.values.firstWhere(
        (kind) => kind.id == value,
        orElse: () => AccountKind.other,
      );
}
