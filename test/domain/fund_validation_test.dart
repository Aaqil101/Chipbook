import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/fund_validation.dart';

void main() {
  group('FundValidation', () {
    test('accepts a non-empty name', () {
      expect(FundValidation.nameError('Trip fund'), isNull);
    });

    test('rejects empty and overlong names', () {
      expect(FundValidation.nameError(''), 'Enter a fund name');
      expect(FundValidation.nameError('   '), 'Enter a fund name');
      expect(
        FundValidation.nameError('x'.padRight(81, 'x')),
        'Use 80 characters or fewer',
      );
    });

    test('accepts three-letter currency codes in any case', () {
      expect(FundValidation.currencyError('USD'), isNull);
      expect(FundValidation.currencyError('usd'), isNull);
    });

    test('rejects unknown or malformed currency codes', () {
      expect(FundValidation.currencyError('US'), isNotNull);
      expect(FundValidation.currencyError('USDD'), isNotNull);
      expect(FundValidation.currencyError('ZZZ'), isNotNull);
      expect(FundValidation.currencyError(r'12$'), isNotNull);
      expect(FundValidation.currencyError(''), isNotNull);
    });

    test('accepts an empty target as no goal', () {
      expect(FundValidation.targetError('', currency: 'USD'), isNull);
      expect(FundValidation.targetError('   ', currency: 'USD'), isNull);
    });

    test('accepts a positive target in the fund currency', () {
      expect(FundValidation.targetError('500', currency: 'USD'), isNull);
      expect(FundValidation.targetError('12.50', currency: 'USD'), isNull);
      expect(FundValidation.targetError('2500', currency: 'JPY'), isNull);
      expect(FundValidation.targetError('2.500', currency: 'KWD'), isNull);
    });

    test('rejects zero targets', () {
      expect(
        FundValidation.targetError('0', currency: 'USD'),
        'Enter an amount above zero',
      );
      expect(
        FundValidation.targetError('0.00', currency: 'USD'),
        'Enter an amount above zero',
      );
    });

    test('rejects malformed or over-precise targets', () {
      expect(
        FundValidation.targetError('-5', currency: 'USD'),
        'Enter a valid amount',
      );
      expect(
        FundValidation.targetError('abc', currency: 'USD'),
        'Enter a valid amount',
      );
      expect(
        FundValidation.targetError('1.234', currency: 'USD'),
        'Enter a valid amount',
      );
      expect(
        FundValidation.targetError('25.5', currency: 'JPY'),
        'Enter a valid amount',
      );
    });
  });
}
