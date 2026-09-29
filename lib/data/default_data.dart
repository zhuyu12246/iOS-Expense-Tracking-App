import 'dart:math';

import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import '../models/types.dart';
import '../theme/app_theme.dart';

int _argb(Color color) => color.toARGB32();

/// Categories shipped with the app. Users can rename, recolour, add and
/// remove their own on top of these.
final List<Category> kDefaultCategories = _buildDefaultCategories();

/// (id, name, iconKey, paletteIndex, type)
const List<(String, String, String, int, TxType)> _categoryDefs =
    <(String, String, String, int, TxType)>[
  ('food', '餐饮', 'restaurant', 0, TxType.expense),
  ('transport', '交通', 'bus', 5, TxType.expense),
  ('shopping', '购物', 'shopping', 6, TxType.expense),
  ('entertainment', '娱乐', 'game', 4, TxType.expense),
  ('housing', '居住', 'home', 3, TxType.expense),
  ('telecom', '通讯', 'wifi', 9, TxType.expense),
  ('medical', '医疗', 'medical', 11, TxType.expense),
  ('study', '学习', 'school', 1, TxType.expense),
  ('travel', '旅行', 'travel', 10, TxType.expense),
  ('clothes', '服饰', 'clothes', 2, TxType.expense),
  ('sports', '运动', 'fitness', 7, TxType.expense),
  ('social', '人情', 'gift', 8, TxType.expense),
  ('digital', '数码', 'devices', 5, TxType.expense),
  ('pets', '宠物', 'pets', 2, TxType.expense),
  ('other_expense', '其他', 'other', 8, TxType.expense),
  ('salary', '工资', 'salary', 2, TxType.income),
  ('bonus', '奖金', 'bonus', 3, TxType.income),
  ('parttime', '兼职', 'parttime', 0, TxType.income),
  ('invest', '理财', 'invest', 7, TxType.income),
  ('refund', '报销', 'refund', 5, TxType.income),
  ('redpacket', '红包', 'redpacket', 1, TxType.income),
  ('other_income', '其他', 'other', 8, TxType.income),
];

List<Category> _buildDefaultCategories() {
  return <Category>[
    for (var i = 0; i < _categoryDefs.length; i++)
      Category(
        id: 'cat_${_categoryDefs[i].$1}',
        name: _categoryDefs[i].$2,
        iconKey: _categoryDefs[i].$3,
        colorValue: _argb(
          kAccentPalette[_categoryDefs[i].$4 % kAccentPalette.length],
        ),
        type: _categoryDefs[i].$5,
        sortOrder: i,
        isSystem: true,
      ),
  ];
}

/// Wallet templates offered as one-tap presets when creating an account.
///
/// Nothing here is written to the database on first launch: a brand new
/// ledger has no wallets and no money until the user adds them.
final List<Account> kAccountPresets = _buildAccountPresets();

/// (id, name, iconKey, kind, paletteIndex)
const List<(String, String, String, AccountKind, int)> _accountPresetDefs =
    <(String, String, String, AccountKind, int)>[
  ('cash', '现金', 'cash', AccountKind.cash, 2),
  ('bank', '银行卡', 'bank', AccountKind.debitCard, 0),
  ('alipay', '支付宝', 'alipay', AccountKind.digital, 4),
  ('wechat', '微信', 'wechat', AccountKind.digital, 6),
  ('credit', '信用卡', 'creditcard', AccountKind.creditCard, 3),
];

List<Account> _buildAccountPresets() {
  return <Account>[
    for (var i = 0; i < _accountPresetDefs.length; i++)
      Account(
        id: 'acc_${_accountPresetDefs[i].$1}',
        name: _accountPresetDefs[i].$2,
        iconKey: _accountPresetDefs[i].$3,
        colorValue: _argb(
          kAccentPalette[_accountPresetDefs[i].$5 % kAccentPalette.length],
        ),
        kind: _accountPresetDefs[i].$4,
        sortOrder: i,
        isSystem: true,
      ),
  ];
}

/// Wallets that old builds created automatically, together with balances the
/// user never entered (`id` -> `initial_balance` in cents).
///
/// The provider deletes an untouched set once, so an upgrade does not leave
/// phantom money behind. Fresh installs never create these at all.
const Map<String, int> kLegacySeedAccounts = <String, int>{
  'acc_cash': 50000,
  'acc_bank': 1860000,
  'acc_alipay': 320000,
  'acc_wechat': 156000,
  'acc_credit': 0,
};

/// Builds a few months of believable records so the app is not empty on first
/// launch when the user taps 「载入示例数据」.
List<TransactionRecord> buildSampleTransactions({
  required List<String> accountIds,
  DateTime? today,
  int months = 3,
}) {
  if (accountIds.isEmpty) return <TransactionRecord>[];

  final random = Random(20260929);
  final now = today ?? DateTime.now();
  final records = <TransactionRecord>[];

  final expenseSeeds = <(String, int, List<String>)>[
    ('cat_food', 1500, ['午餐', '晚餐 · 小炒', '下午茶', '外卖', '和朋友吃饭']),
    ('cat_transport', 800, ['地铁', '打车回家', '公交', '加油']),
    ('cat_shopping', 9900, ['日用品', '超市采购', '厨房用品']),
    ('cat_entertainment', 4500, ['电影票', '剧本杀', '游戏充值']),
    ('cat_housing', 260000, ['房租', '物业费']),
    ('cat_telecom', 9900, ['手机话费', '宽带续费']),
    ('cat_clothes', 25900, ['换季衣物', '鞋子']),
    ('cat_social', 20000, ['朋友生日红包', '同事婚礼']),
    ('cat_digital', 39900, ['蓝牙耳机', '充电器']),
    ('cat_study', 6800, ['专业书籍', '在线课程']),
  ];

  final incomeSeeds = <(String, int, List<String>)>[
    ('cat_salary', 1850000, ['月度工资']),
    ('cat_bonus', 500000, ['季度奖金']),
    ('cat_parttime', 120000, ['周末兼职']),
    ('cat_invest', 86000, ['基金分红']),
    ('cat_redpacket', 20000, ['家人红包']),
  ];

  for (var offset = months - 1; offset >= 0; offset--) {
    final monthAnchor = DateTime(now.year, now.month - offset, 1);
    final lastDay = DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final maxDay = offset == 0 ? now.day : lastDay;

    final recordCount = 14 + random.nextInt(10);
    for (var i = 0; i < recordCount; i++) {
      final seed = expenseSeeds[random.nextInt(expenseSeeds.length)];
      final day = 1 + random.nextInt(maxDay);
      final date = DateTime(
        monthAnchor.year,
        monthAnchor.month,
        day,
        7 + random.nextInt(15),
        random.nextInt(60),
      );
      final variation = 0.6 + random.nextDouble() * 1.1;
      records.add(
        TransactionRecord(
          id: 'seed_${monthAnchor.year}_${monthAnchor.month}_$i',
          type: TxType.expense,
          amount: max(100, (seed.$2 * variation).round()),
          categoryId: seed.$1,
          accountId: accountIds[random.nextInt(accountIds.length)],
          note: seed.$3[random.nextInt(seed.$3.length)],
          date: date,
          createdAt: date,
        ),
      );
    }

    for (final seed in incomeSeeds) {
      if (seed.$1 == 'cat_salary' || random.nextDouble() > 0.55) {
        final day = seed.$1 == 'cat_salary'
            ? (offset == 0 && now.day < 10 ? 1 : 10)
            : 1 + random.nextInt(maxDay);
        final date = DateTime(
          monthAnchor.year,
          monthAnchor.month,
          day,
          9,
          30,
        );
        records.add(
          TransactionRecord(
            id: 'seed_in_${monthAnchor.year}_${monthAnchor.month}_${seed.$1}',
            type: TxType.income,
            amount: seed.$2,
            categoryId: seed.$1,
            accountId: accountIds[random.nextInt(accountIds.length)],
            note: seed.$3.first,
            date: date,
            createdAt: date,
          ),
        );
      }
    }
  }

  records.sort((a, b) => b.date.compareTo(a.date));
  return records;
}
