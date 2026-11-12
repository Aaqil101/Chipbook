import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/entry_validation.dart';
import 'package:chipbook/domain/money.dart';

void main() {
  group('Money.format', () {
    test('formats minor units with two decimals', () {
      expect(Money.format(2500), 'USD 25.00');
      expect(Money.format(5), 'USD 0.05');
      expect(Money.format(0), 'USD 0.00');
      expect(Money.format(-1234), '-USD 12.34');
    });

    test('supports other currencies and zero decimals', () {
      expect(Money.format(2500, currency: 'EUR'), 'EUR 25.00');
      expect(Money.format(2500, currency: 'JPY', decimals: 0), 'JPY 2500');
    });
  });

  group('Money.tryParseToMinor', () {
    test('parses whole and fractional amounts', () {
      expect(Money.tryParseToMinor('25'), 2500);
      expect(Money.tryParseToMinor('25.00'), 2500);
      expect(Money.tryParseToMinor('0.50'), 50);
      expect(Money.tryParseToMinor(' 1.5 '), 150);
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
      expect(EntryValidation.amountError('-1'), 'Enter an amount like 25.00');
      expect(
        EntryValidation.amountError('12.345'),
        'Enter an amount like 25.00',
      );
    });

    test('accepts positive amounts', () {
      expect(EntryValidation.amountError('0.01'), isNull);
      expect(EntryValidation.amountError('25.00'), isNull);
    });

    test('requires a non-blank contributor name', () {
      expect(EntryValidation.contributorError(''), 'Name is required');
      expect(EntryValidation.contributorError('   '), 'Name is required');
      expect(EntryValidation.contributorError('Ada'), isNull);
    });
  });
}
