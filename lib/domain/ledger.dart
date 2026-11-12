import '../models/entry.dart';

/// Aggregated view of a set of ledger entries.
///
/// Phase 1 assumes a single currency per ledger; [currency] is the display
/// currency supplied by the caller.
class LedgerSummary {
  LedgerSummary._({
    required this.totalMinor,
    required this.currency,
    required this.approved,
    required this.pending,
  });

  /// Builds a summary from [entries].
  ///
  /// Only approved entries count toward [totalMinor]. An approved reversal
  /// subtracts from the total only when the entry it reverses is also
  /// approved, so reversing a pending entry has no effect.
  factory LedgerSummary.from(
    Iterable<Entry> entries, {
    required String currency,
  }) {
    final approved = <Entry>[];
    final pending = <Entry>[];

    for (final entry in entries) {
      if (entry.isApproved) {
        approved.add(entry);
      } else {
        pending.add(entry);
      }
    }

    final approvedIds = approved.map((entry) => entry.id).toSet();

    var totalMinor = 0;
    for (final entry in approved) {
      final countsTowardTotal =
          !entry.isReversal || approvedIds.contains(entry.reversesEntryId);
      if (countsTowardTotal) {
        totalMinor += entry.signedAmountMinor;
      }
    }

    _sortNewestFirst(approved);
    _sortNewestFirst(pending);

    return LedgerSummary._(
      totalMinor: totalMinor,
      currency: currency,
      approved: List<Entry>.unmodifiable(approved),
      pending: List<Entry>.unmodifiable(pending),
    );
  }

  /// Running total of approved entries, with reversals subtracted.
  final int totalMinor;

  /// ISO 4217 code used for display.
  final String currency;

  /// Approved entries, newest first.
  final List<Entry> approved;

  /// Pending entries, newest first. They never affect [totalMinor].
  final List<Entry> pending;

  bool get isEmpty => approved.isEmpty && pending.isEmpty;

  static void _sortNewestFirst(List<Entry> entries) {
    entries.sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      if (byDate != 0) {
        return byDate;
      }
      return b.id.compareTo(a.id);
    });
  }
}
