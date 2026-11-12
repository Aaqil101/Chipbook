/// Lifecycle state of a ledger entry.
enum EntryStatus { pending, approved }

/// A single, immutable contribution record.
///
/// Entries are append-only: there is no edit or delete. A correction is a
/// new entry whose [reversesEntryId] points at the entry it reverses.
class Entry {
  const Entry({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.contributorName,
    required this.createdAt,
    required this.status,
    this.note = '',
    this.reversesEntryId,
  }) : assert(amountMinor > 0, 'amountMinor must be positive');

  /// Stable identifier used by reversal entries.
  final String id;

  /// Amount in the smallest currency unit (for example, cents).
  ///
  /// Always an integer; never a floating-point value.
  final int amountMinor;

  /// ISO 4217 currency code, for example `USD`.
  final String currency;

  /// Name of the person who contributed.
  final String contributorName;

  /// Optional free-form note; empty when omitted.
  final String note;

  final DateTime createdAt;

  final EntryStatus status;

  /// Id of the entry this entry reverses, or null for a normal entry.
  final String? reversesEntryId;

  /// Whether this entry corrects an earlier one.
  bool get isReversal => reversesEntryId != null;

  /// Whether this entry counts toward the running total.
  bool get isApproved => status == EntryStatus.approved;

  /// Contribution to the running total, negative for reversals.
  ///
  /// Callers must still ignore entries that are not approved.
  int get signedAmountMinor => isReversal ? -amountMinor : amountMinor;
}
