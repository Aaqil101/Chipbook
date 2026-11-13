import '../config.dart';
import 'money.dart';

/// User-facing validation rules for recording a contribution.
abstract final class EntryValidation {
  /// Returns an error message for [raw], or null when it is valid.
  static String? amountError(
    String raw, {
    String currency = AppConfig.defaultCurrency,
  }) {
    if (raw.trim().isEmpty) {
      return 'Enter an amount';
    }

    final amountMinor = Money.tryParseToMinor(raw, currency: currency);
    if (amountMinor == null) {
      return 'Enter a valid amount for $currency';
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

  /// A payout must name who was paid.
  static String? payeeError(String raw) {
    return raw.trim().isEmpty ? 'Enter who was paid' : null;
  }

  /// A payout must explain what it was for.
  static String? payoutReasonError(String raw) {
    return raw.trim().isEmpty ? 'Enter a reason for the payout' : null;
  }

  /// A reversal must explain why the original entry is being corrected.
  static String? reversalReasonError(String raw) {
    return raw.trim().isEmpty ? 'Enter a reason for the reversal' : null;
  }
}
