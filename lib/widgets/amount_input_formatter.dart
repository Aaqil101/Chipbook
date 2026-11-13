import 'package:flutter/services.dart';

/// Restricts an amount field to digits and at most one decimal point.
///
/// [decimalDigits] comes from the selected currency, so currencies without
/// minor units reject the separator and other currencies cap the fraction.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({this.decimalDigits = 2})
    : _pattern = RegExp(
        decimalDigits == 0 ? r'^\d+$' : '^\\d+(\\.\\d{0,$decimalDigits})?\$',
      );

  /// Number of digits allowed after the decimal separator.
  final int decimalDigits;

  final RegExp _pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
