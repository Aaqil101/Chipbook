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
  });
}
