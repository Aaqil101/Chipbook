import 'currency.dart';
import 'money.dart';

/// Validation for creating or editing a fund.
abstract final class FundValidation {
  static String? nameError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'Enter a fund name';
    }
    if (value.length > 80) {
      return 'Use 80 characters or fewer';
    }
    return null;
  }

  static String? currencyError(String raw) {
    return CurrencyCatalog.byCode(raw) == null
        ? 'Choose a supported currency'
        : null;
  }

  /// Validates an optional target amount for a fund in [currency].
  ///
  /// An empty value means no target, so it is valid.
  static String? targetError(String raw, {required String currency}) {
    if (raw.trim().isEmpty) {
      return null;
    }

    final amountMinor = Money.tryParseToMinor(raw, currency: currency);
    if (amountMinor == null) {
      return 'Enter a valid amount';
    }
    if (amountMinor <= 0) {
      return 'Enter an amount above zero';
    }
    return null;
  }
}
