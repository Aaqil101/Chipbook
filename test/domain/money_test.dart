import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/entry_validation.dart';
import 'package:chipbook/domain/money.dart';

void main() {
  group('Money.format', () {
    test('formats USD minor units with two decimals and grouping', () {
      expect(Money.format(2500), 'USD 25.00');
      expect(Money.format(5), 'USD 0.05');
      expect(Money.format(0), 'USD 0.00');
      expect(Money.format(-1234), '-USD 12.34');
      expect(Money.format(123456), 'USD 1,234.56');
    });

    test('formats JPY without decimals', () {
      expect(Money.format(2500, currency: 'JPY'), 'JPY 2,500');
      expect(Money.format(-2500, currency: 'JPY'), '-JPY 2,500');
    });

    test('formats KWD with three decimals', () {
      expect(Money.format(2500, currency: 'KWD'), 'KWD 2.500');
      expect(Money.format(5, currency: 'KWD'), 'KWD 0.005');
    });

    test('falls back to two decimals for unknown codes', () {
      expect(Money.format(2500, currency: 'ZZZ'), 'ZZZ 25.00');
    });
  });

  group('Money.tryParseToMinor', () {
    test('parses whole and fractional USD amounts', () {
      expect(Money.tryParseToMinor('25'), 2500);
      expect(Money.tryParseToMinor('25.00'), 2500);
      expect(Money.tryParseToMinor('0.50'), 50);
      expect(Money.tryParseToMinor(' 1.5 '), 150);
    });

    test('parses JPY whole units only', () {
      expect(Money.tryParseToMinor('2500', currency: 'JPY'), 2500);
      expect(Money.tryParseToMinor('2500.0', currency: 'JPY'), isNull);
    });

    test('parses KWD with up to three decimals', () {
      expect(Money.tryParseToMinor('2.5', currency: 'KWD'), 2500);
      expect(Money.tryParseToMinor('2.500', currency: 'KWD'), 2500);
      expect(Money.tryParseToMinor('2.5000', currency: 'KWD'), isNull);
    });

    test('rejects negatives and malformed input', () {
      expect(Money.tryParseToMinor('-5'), isNull);
      expect(Money.tryParseToMinor(''), isNull);
      expect(Money.tryParseToMinor('1.234'), isNull);
      expect(Money.tryParseToMinor('1,000'), isNull);
      expect(Money.tryParseToMinor('abc'), isNull);
      expect(Money.tryParseToMinor('1.'), isNull);
      expect(Money.tryParseToMinor('.50'), isNull);
    });

    test('parses zero, which validation rejects separately', () {
      expect(Money.tryParseToMinor('0'), 0);
      expect(
        EntryValidation.amountError('0'),
        'Amount must be greater than zero',
      );
    });
  });

  group('EntryValidation', () {
    test('rejects empty and non-positive amounts', () {
      expect(EntryValidation.amountError(''), 'Enter an amount');
      expect(
        EntryValidation.amountError('0.00'),
        'Amount must be greater than zero',
      );
      expect(EntryValidation.amountError('-1'), 'Enter a valid amount for USD');
      expect(
        EntryValidation.amountError('12.345'),
        'Enter a valid amount for USD',
      );
    });

    test('accepts positive USD amounts', () {
      expect(EntryValidation.amountError('0.01'), isNull);
      expect(EntryValidation.amountError('25.00'), isNull);
    });

    test('validates against the selected currency', () {
      expect(EntryValidation.amountError('1000', currency: 'JPY'), isNull);
      expect(
        EntryValidation.amountError('1000.0', currency: 'JPY'),
        'Enter a valid amount for JPY',
      );
      expect(EntryValidation.amountError('1.234', currency: 'KWD'), isNull);
      expect(
        EntryValidation.amountError('1.2345', currency: 'KWD'),
        'Enter a valid amount for KWD',
      );
    });

    test('requires a non-blank contributor name', () {
      expect(EntryValidation.contributorError(''), 'Name is required');
      expect(EntryValidation.contributorError('   '), 'Name is required');
      expect(EntryValidation.contributorError('Ada'), isNull);
    });
  });
}
