import 'currency.dart';

/// Validation for creating a fund.
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
}
