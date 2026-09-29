import 'types.dart';

/// A bookkeeping category such as 餐饮 or 工资.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
    this.sortOrder = 0,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final TxType type;
  final int sortOrder;
  final bool isSystem;

  Category copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    TxType? type,
    int? sortOrder,
    bool? isSystem,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': iconKey,
        'color': colorValue,
        'type': type.id,
        'sort_order': sortOrder,
        'is_system': isSystem ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id']! as String,
        name: map['name']! as String,
        iconKey: map['icon']! as String,
        colorValue: (map['color'] as num).toInt(),
        type: TxType.fromId(map['type'] as String?),
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        isSystem: ((map['is_system'] as num?)?.toInt() ?? 0) == 1,
      );
}
