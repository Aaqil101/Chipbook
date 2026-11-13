/// Validation for creating a fund.
abstract final class FundValidation {
  static final RegExp _currencyCode = RegExp(r'^[A-Z]{3}$');

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
    final value = raw.trim().toUpperCase();
    if (!_currencyCode.hasMatch(value)) {
      return 'Use a 3-letter code like USD';
    }
    return null;
  }
}
