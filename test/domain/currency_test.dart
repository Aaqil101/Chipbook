import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/currency.dart';

void main() {
  group('CurrencyCatalog', () {
    test('supplies ISO 4217 fraction digits', () {
      expect(CurrencyCatalog.fractionDigitsFor('USD'), 2);
      expect(CurrencyCatalog.fractionDigitsFor('JPY'), 0);
      expect(CurrencyCatalog.fractionDigitsFor('KWD'), 3);
      expect(CurrencyCatalog.fractionDigitsFor('BHD'), 3);
      expect(CurrencyCatalog.fractionDigitsFor('VND'), 0);
    });

    test('looks up codes case-insensitively', () {
      expect(CurrencyCatalog.byCode('usd')?.code, 'USD');
      expect(CurrencyCatalog.byCode(' JpY ')?.code, 'JPY');
      expect(CurrencyCatalog.byCode('ZZZ'), isNull);
    });

    test('unknown codes fall back to two decimals', () {
      expect(CurrencyCatalog.fractionDigitsFor('ZZZ'), 2);
    });

    test('codes are unique three-letter uppercase ISO codes', () {
      final codes = CurrencyCatalog.currencies.map((c) => c.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
      for (final code in codes) {
        expect(code, matches(RegExp(r'^[A-Z]{3}$')));
      }
    });

    test('catalog is sorted by code', () {
      final codes = CurrencyCatalog.currencies.map((c) => c.code).toList();
      final sorted = [...codes]..sort();
      expect(codes, sorted);
    });

    test('search matches codes and names case-insensitively', () {
      expect(CurrencyCatalog.search('yen').single.code, 'JPY');
      expect(CurrencyCatalog.search('yuan').single.code, 'CNY');
      expect(CurrencyCatalog.search(' jpy ').single.code, 'JPY');
      expect(CurrencyCatalog.search('uruguayan').single.code, 'UYU');
    });

    test('search with no match is empty and blank returns everything', () {
      expect(CurrencyCatalog.search('zzz'), isEmpty);
      expect(CurrencyCatalog.search('   '), CurrencyCatalog.currencies);
    });
  });
}
