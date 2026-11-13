/// Lifecycle state of a ledger entry.
enum EntryStatus { pending, approved }

/// Whether an entry adds money to the fund or takes it out.
///
/// A [payout] is how an organizer records money leaving the fund, such as
/// paying a supplier at the end of a collection. It is still only a record:
/// Chipbook never moves the money itself.
enum EntryKind { contribution, payout }

/// A single ledger record.
///
/// Approved entries are append-only: there is no edit or delete for them. A
/// correction is a new entry whose [reversesEntryId] points at the entry it
/// reverses. A pending entry that was never approved may be deleted instead,
/// because it never counted toward a total.
class Entry {
  const Entry({
    required this.id,
    required this.fundId,
    required this.amountMinor,
    required this.currency,
    required this.contributorName,
    required this.createdAt,
    required this.status,
    this.note = '',
    this.reversesEntryId,
    this.kind = EntryKind.contribution,
  }) : assert(amountMinor > 0, 'amountMinor must be positive');

  /// Stable identifier used by reversal entries.
  final String id;

  /// Fund this entry belongs to.
  final String fundId;

  /// Amount in the smallest currency unit (for example, cents).
  ///
  /// Always an integer; never a floating-point value.
  final int amountMinor;

  /// ISO 4217 currency code, for example `USD`.
  final String currency;

  /// Name of the counterparty: the contributor, or the payee of a payout.
  final String contributorName;

  /// Optional free-form note; empty when omitted.
  final String note;

  final DateTime createdAt;

  final EntryStatus status;

  /// Id of the entry this entry reverses, or null for a normal entry.
  final String? reversesEntryId;

  /// Whether this entry adds money or pays it out.
  final EntryKind kind;

  /// Whether this entry corrects an earlier one.
  bool get isReversal => reversesEntryId != null;

  /// Whether this entry is money leaving the fund.
  bool get isPayout => kind == EntryKind.payout;

  /// Whether this entry counts toward the running total.
  bool get isApproved => status == EntryStatus.approved;

  /// Effect on the fund's balance.
  ///
  /// Contributions add, payouts subtract, and a reversal does the opposite of
  /// the entry it corrects. Callers must still ignore entries that are not
  /// approved.
  int get signedAmountMinor =>
      isReversal == isPayout ? amountMinor : -amountMinor;

  /// Returns a copy with a new [status], used only for approval.
  Entry copyWith({EntryStatus? status}) {
    return Entry(
      id: id,
      fundId: fundId,
      amountMinor: amountMinor,
      currency: currency,
      contributorName: contributorName,
      note: note,
      createdAt: createdAt,
      status: status ?? this.status,
      reversesEntryId: reversesEntryId,
      kind: kind,
    );
  }
}
