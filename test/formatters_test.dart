import 'package:flutter_test/flutter_test.dart';
import 'package:kasku/core/utils/formatters.dart';

void main() {
  group('CurrencyFormatter tests', () {
    test('formats positive amounts correctly', () {
      final formatted = CurrencyFormatter.format(1250000);
      expect(formatted, contains('1.250.000'));
      expect(formatted, contains('Rp'));
    });

    test('formatSigned displays correct signs', () {
      final positive = CurrencyFormatter.formatSigned(50000);
      expect(positive.startsWith('+'), isTrue);

      final negative = CurrencyFormatter.formatSigned(-50000);
      expect(negative.startsWith('-'), isTrue);
    });

    test('formatCompact displays compact amounts', () {
      final compact = CurrencyFormatter.formatCompact(1200000);
      expect(compact, isNotEmpty);
    });
  });

  group('DateFormatter tests', () {
    final testDate = DateTime(2026, 10, 22);

    test('formats day and month in Indonesian', () {
      expect(DateFormatter.dayMonth(testDate), '22 Okt');
    });

    test('formats full date in Indonesian', () {
      expect(DateFormatter.full(testDate), '22 Oktober 2026');
    });

    test('formats month and year in Indonesian', () {
      expect(DateFormatter.monthYear(testDate), 'Oktober 2026');
    });

    test('formats short date in Indonesian', () {
      expect(DateFormatter.short(testDate), '22 Okt 2026');
    });

    test('isSameDay detects matching days', () {
      final same = DateTime(2026, 10, 22, 14, 30);
      final different = DateTime(2026, 10, 23);

      expect(DateFormatter.isSameDay(testDate, same), isTrue);
      expect(DateFormatter.isSameDay(testDate, different), isFalse);
    });
  });
}
