import '../config.dart';

/// Formatting helpers for integer minor-unit amounts.
abstract final class Money {
  /// Formats [amountMinor] for display, for example `USD 25.00`.
  ///
  /// Phase 1 assumes a two-decimal currency.
  static String format(
    int amountMinor, {
    String currency = AppConfig.defaultCurrency,
    int decimals = 2,
  }) {
    final factor = _factor(decimals);
    final sign = amountMinor < 0 ? '-' : '';
    final absolute = amountMinor.abs();
    final whole = absolute ~/ factor;

    if (decimals == 0) {
      return '$sign$currency $whole';
    }

    final fraction = (absolute % factor).toString().padLeft(decimals, '0');
    return '$sign$currency $whole.$fraction';
  }

  static int _factor(int decimals) {
    var factor = 1;
    for (var index = 0; index < decimals; index++) {
      factor *= 10;
    }
    return factor;
  }
}
