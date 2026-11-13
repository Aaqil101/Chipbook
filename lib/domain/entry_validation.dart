import 'money.dart';

/// User-facing validation rules for recording a contribution.
abstract final class EntryValidation {
  /// Returns an error message for [raw], or null when it is valid.
  static String? amountError(String raw) {
    if (raw.trim().isEmpty) {
      return 'Enter an amount';
    }

    final amountMinor = Money.tryParseToMinor(raw);
    if (amountMinor == null) {
      return 'Enter an amount like 25.00';
    }
    if (amountMinor <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  /// Returns an error message for [raw], or null when it is valid.
  static String? contributorError(String raw) {
    return raw.trim().isEmpty ? 'Name is required' : null;
  }

  /// A reversal must explain why the original entry is being corrected.
  static String? reversalReasonError(String raw) {
    return raw.trim().isEmpty ? 'Enter a reason for the reversal' : null;
  }
}
