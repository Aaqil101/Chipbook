import 'package:intl/intl.dart';

import '../config.dart';
import 'currency.dart';

/// Formatting and parsing helpers for integer minor-unit amounts.
abstract final class Money {
  static final NumberFormat _groupedWhole = NumberFormat('#,##0', 'en_US');

  /// Formats [amountMinor] for display, for example `USD 25.00`.
  ///
  /// Fraction digits come from [CurrencyCatalog], so yen and dinars render
  /// with the right number of decimals.
  static String format(
    int amountMinor, {
    String currency = AppConfig.defaultCurrency,
  }) {
    final decimals = CurrencyCatalog.fractionDigitsFor(currency);
    final factor = _factor(decimals);
    final sign = amountMinor < 0 ? '-' : '';
    final absolute = amountMinor.abs();
    final whole = _groupedWhole.format(absolute ~/ factor);

    if (decimals == 0) {
      return '$sign$currency $whole';
    }

    final fraction = (absolute % factor).toString().padLeft(decimals, '0');
    return '$sign$currency $whole.$fraction';
  }

  /// Formats [amountMinor] as a decimal string without the currency code,
  /// suitable for pre-filling an amount field, for example `25.00`.
  static String toPlain(
    int amountMinor, {
    String currency = AppConfig.defaultCurrency,
  }) {
    final decimals = CurrencyCatalog.fractionDigitsFor(currency);
    final factor = _factor(decimals);
    final sign = amountMinor < 0 ? '-' : '';
    final absolute = amountMinor.abs();

    if (decimals == 0) {
      return '$sign${absolute ~/ factor}';
    }

    final fraction = (absolute % factor).toString().padLeft(decimals, '0');
    return '$sign${absolute ~/ factor}.$fraction';
  }

  /// Parses a decimal string such as `25.00` into integer minor units.
  ///
  /// Returns null for empty input, negatives, separators other than `.`,
  /// and fractions longer than the currency's fraction digits. Zero parses
  /// successfully; callers decide whether zero is acceptable.
  static int? tryParseToMinor(
    String input, {
    String currency = AppConfig.defaultCurrency,
  }) {
    final decimals = CurrencyCatalog.fractionDigitsFor(currency);
    final text = input.trim();
    if (text.isEmpty) {
      return null;
    }

    final parts = text.split('.');
    if (parts.length > 2) {
      return null;
    }

    final wholePart = parts[0];
    if (!_digits.hasMatch(wholePart)) {
      return null;
    }

    var fractionPart = '';
    if (parts.length == 2) {
      fractionPart = parts[1];
      if (fractionPart.isEmpty ||
          fractionPart.length > decimals ||
          !_digits.hasMatch(fractionPart)) {
        return null;
      }
    }

    final whole = int.tryParse(wholePart);
    if (whole == null) {
      return null;
    }

    final fraction = fractionPart.isEmpty
        ? 0
        : int.parse(fractionPart.padRight(decimals, '0'));

    return whole * _factor(decimals) + fraction;
  }

  static final RegExp _digits = RegExp(r'^\d+$');

  static int _factor(int decimals) {
    var factor = 1;
    for (var index = 0; index < decimals; index++) {
      factor *= 10;
    }
    return factor;
  }
}
