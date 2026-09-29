/// Localised, dependency-free formatting helpers for money and dates.
library;

const List<String> _weekdayNames = <String>[
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

const List<String> _weekdayShortNames = <String>[
  '周一',
  '周二',
  '周三',
  '周四',
  '周五',
  '周六',
  '周日',
];

/// Groups the integer part of [digits] with thousands separators.
String _group(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `123456` -> `1,234.56`
String formatAmount(int cents, {bool showPlusSign = false}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final yuan = abs ~/ 100;
  final fraction = abs % 100;
  final sign = negative ? '-' : (showPlusSign && cents > 0 ? '+' : '');
  return '$sign${_group(yuan.toString())}.${fraction.toString().padLeft(2, '0')}';
}

/// `123456` -> `¥1,234.56`
String formatMoney(int cents, {bool showPlusSign = false, String symbol = '¥'}) {
  final negative = cents < 0;
  final body = formatAmount(cents.abs(), showPlusSign: !negative && showPlusSign);
  return negative ? '-$symbol$body' : '$symbol$body';
}

/// Compact form used on chart axes: `12345678` -> `12.3万`
String formatCompact(int cents) {
  final yuan = cents / 100;
  final abs = yuan.abs();
  if (abs >= 100000000) {
    return '${(yuan / 100000000).toStringAsFixed(1)}亿';
  }
  if (abs >= 10000) return '${(yuan / 10000).toStringAsFixed(1)}万';
  return yuan.round().toString();
}

/// `2026-09` style key used for grouping and comparisons.
String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

/// `2026年9月`
String monthLabel(DateTime date) => '${date.year}年${date.month}月';

/// `9月29日`
String monthDayLabel(DateTime date) => '${date.month}月${date.day}日';

/// `2026年9月29日`
String fullDateLabel(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日';

/// `星期一`
String weekdayLabel(DateTime date) => _weekdayNames[date.weekday - 1];

/// `周一`
String weekdayShortLabel(DateTime date) => _weekdayShortNames[date.weekday - 1];

/// Friendly header used on ledger day groups: 今天 / 昨天 / 9月29日 星期一
String dayGroupLabel(DateTime date, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final target = DateTime(date.year, date.month, date.day);
  final base = DateTime(now.year, now.month, now.day);
  final diff = base.difference(target).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff == 2) return '前天';
  if (target.year == base.year) return monthDayLabel(target);
  return fullDateLabel(target);
}

/// `2026-09-29` for CSV export.
String isoDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `2026-09-29 18:04` for CSV export.
String isoDateTime(DateTime date) =>
    '${isoDate(date)} ${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

/// Number of days in the given month.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Parses the on-screen keypad buffer (`"12.5"`) into cents.
int parseAmountToCents(String input) {
  if (input.isEmpty) return 0;
  final parts = input.split('.');
  final yuanPart = parts.first.isEmpty ? '0' : parts.first;
  final yuan = int.tryParse(yuanPart) ?? 0;
  var fraction = parts.length > 1 ? parts[1] : '';
  if (fraction.length > 2) fraction = fraction.substring(0, 2);
  fraction = fraction.padRight(2, '0');
  return yuan * 100 + (int.tryParse(fraction) ?? 0);
}

/// Formats a [DateTime] into the keypad / editor display form.
String centsToInput(int cents) {
  if (cents == 0) return '';
  final yuan = cents ~/ 100;
  final fraction = cents % 100;
  if (fraction == 0) return yuan.toString();
  return '$yuan.${fraction.toString().padLeft(2, '0')}';
}
