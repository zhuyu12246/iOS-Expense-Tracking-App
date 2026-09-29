import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/utils/formatters.dart';

void main() {
  group('金额格式化', () {
    test('千分位与两位小数', () {
      expect(formatAmount(0), '0.00');
      expect(formatAmount(5), '0.05');
      expect(formatAmount(123456), '1,234.56');
      expect(formatAmount(100000000), '1,000,000.00');
    });

    test('正负号', () {
      expect(formatAmount(-500), '-5.00');
      expect(formatMoney(-500), '-¥5.00');
      expect(formatMoney(5000), '¥50.00');
      expect(formatMoney(5000, showPlusSign: true), '¥+50.00');
    });

    test('紧凑格式用于图表', () {
      expect(formatCompact(150000000), '150.0万');
      expect(formatCompact(99900), '999');
      expect(formatCompact(1234567890), '1234.6万');
    });
  });

  group('键盘输入解析', () {
    test('解析为分', () {
      expect(parseAmountToCents(''), 0);
      expect(parseAmountToCents('12'), 1200);
      expect(parseAmountToCents('12.5'), 1250);
      expect(parseAmountToCents('12.34'), 1234);
      expect(parseAmountToCents('0.09'), 9);
    });

    test('回填输入框', () {
      expect(centsToInput(0), '');
      expect(centsToInput(1200), '12');
      expect(centsToInput(1250), '12.50');
    });
  });

  group('日期文案', () {
    test('月份与星期', () {
      final date = DateTime(2026, 9, 29);
      expect(monthLabel(date), '2026年9月');
      expect(monthKey(date), '2026-09');
      expect(weekdayLabel(date), '星期二');
      expect(weekdayShortLabel(date), '周二');
      expect(isoDate(date), '2026-09-29');
    });

    test('今天昨天前天', () {
      final today = DateTime(2026, 9, 29);
      expect(dayGroupLabel(DateTime(2026, 9, 29), today: today), '今天');
      expect(dayGroupLabel(DateTime(2026, 9, 28), today: today), '昨天');
      expect(dayGroupLabel(DateTime(2026, 9, 27), today: today), '前天');
      expect(dayGroupLabel(DateTime(2026, 9, 20), today: today), '9月20日');
      expect(
        dayGroupLabel(DateTime(2025, 12, 31), today: today),
        '2025年12月31日',
      );
    });
  });
}
