import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/widgets/amount_input_formatter.dart';

void main() {
  String apply(AmountInputFormatter formatter, String oldText, String newText) {
    return formatter.formatEditUpdate(_value(oldText), _value(newText)).text;
  }

  group('AmountInputFormatter', () {
    test('accepts whole numbers', () {
      final formatter = AmountInputFormatter();

      expect(apply(formatter, '1', '12'), '12');
      expect(apply(formatter, '', '0'), '0');
    });

    test('accepts one decimal point with fractions', () {
      final formatter = AmountInputFormatter();

      expect(apply(formatter, '12', '12.'), '12.');
      expect(apply(formatter, '12.', '12.5'), '12.5');
      expect(apply(formatter, '12.5', '12.50'), '12.50');
    });

    test('rejects letters, signs, separators, and extra points', () {
      final formatter = AmountInputFormatter();

      expect(apply(formatter, '12', '12a'), '12');
      expect(apply(formatter, '12', '-12'), '12');
      expect(apply(formatter, '12', '1,000'), '12');
      expect(apply(formatter, '12.5', '12.5.6'), '12.5');
      expect(apply(formatter, '', '.5'), '');
      expect(apply(formatter, '', 'abc'), '');
    });

    test('caps fraction digits at the currency precision', () {
      final usd = AmountInputFormatter();
      expect(apply(usd, '12.34', '12.345'), '12.34');

      final kwd = AmountInputFormatter(decimalDigits: 3);
      expect(apply(kwd, '12.345', '12.3456'), '12.345');

      final jpy = AmountInputFormatter(decimalDigits: 0);
      expect(apply(jpy, '1200', '1200.'), '1200');
    });
  });
}

TextEditingValue _value(String text) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
