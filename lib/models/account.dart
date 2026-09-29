import 'types.dart';

/// A place money lives: 现金, 银行卡, 支付宝 ...
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.kind = AccountKind.other,
    this.initialBalance = 0,
    this.sortOrder = 0,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final AccountKind kind;

  /// Opening balance in cents. The live balance is derived from records.
  final int initialBalance;
  final int sortOrder;
  final bool isSystem;

  Account copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    AccountKind? kind,
    int? initialBalance,
    int? sortOrder,
    bool? isSystem,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
      initialBalance: initialBalance ?? this.initialBalance,
      sortOrder: sortOrder ?? this.sortOrder,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': iconKey,
        'color': colorValue,
        'kind': kind.id,
        'initial_balance': initialBalance,
        'sort_order': sortOrder,
        'is_system': isSystem ? 1 : 0,
      };

  factory Account.fromMap(Map<String, Object?> map) => Account(
        id: map['id']! as String,
        name: map['name']! as String,
        iconKey: map['icon']! as String,
        colorValue: (map['color'] as num).toInt(),
        kind: AccountKind.fromId(map['kind'] as String?),
        initialBalance: (map['initial_balance'] as num?)?.toInt() ?? 0,
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        isSystem: ((map['is_system'] as num?)?.toInt() ?? 0) == 1,
      );
}
