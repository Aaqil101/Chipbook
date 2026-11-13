import '../models/entry.dart';

/// Approved total for a single currency.
class CurrencyTotal {
  const CurrencyTotal({required this.currency, required this.totalMinor});

  final String currency;
  final int totalMinor;
}

/// Aggregated view of a set of ledger entries.
///
/// Totals are grouped by currency; amounts in different currencies are never
/// added together.
class LedgerSummary {
  LedgerSummary._({
    required this.totals,
    required this.approved,
    required this.pending,
    required this.reversedEntryIds,
  });

  /// Builds a summary from [entries].
  ///
  /// Only approved entries count toward a total. An approved reversal
  /// subtracts from its own currency only when the entry it reverses is also
  /// approved and uses the same currency, so reversing a pending entry or
  /// crossing currencies has no effect.
  ///
  /// When there are no approved totals, [defaultCurrency] is included as a
  /// zero total so the ledger still has a currency to display.
  factory LedgerSummary.from(
    Iterable<Entry> entries, {
    String? defaultCurrency,
  }) {
    final approved = <Entry>[];
    final pending = <Entry>[];
    final reversedEntryIds = <String>{};

    for (final entry in entries) {
      final targetId = entry.reversesEntryId;
      if (targetId != null) {
        reversedEntryIds.add(targetId);
      }

      if (entry.isApproved) {
        approved.add(entry);
      } else {
        pending.add(entry);
      }
    }

    final approvedById = {for (final entry in approved) entry.id: entry};
    final totalsByCurrency = <String, int>{};

    for (final entry in approved) {
      if (!_countsTowardTotal(entry, approvedById)) {
        continue;
      }
      totalsByCurrency.update(
        entry.currency,
        (total) => total + entry.signedAmountMinor,
        ifAbsent: () => entry.signedAmountMinor,
      );
    }

    if (totalsByCurrency.isEmpty && defaultCurrency != null) {
      totalsByCurrency[defaultCurrency] = 0;
    }

    final totals = [
      for (final entry in totalsByCurrency.entries)
        CurrencyTotal(currency: entry.key, totalMinor: entry.value),
    ]..sort((a, b) => a.currency.compareTo(b.currency));

    _sortNewestFirst(approved);
    _sortNewestFirst(pending);

    return LedgerSummary._(
      totals: List<CurrencyTotal>.unmodifiable(totals),
      approved: List<Entry>.unmodifiable(approved),
      pending: List<Entry>.unmodifiable(pending),
      reversedEntryIds: Set<String>.unmodifiable(reversedEntryIds),
    );
  }

  /// Approved totals, one per currency, sorted by currency code.
  final List<CurrencyTotal> totals;

  /// Approved entries, newest first.
  final List<Entry> approved;

  /// Pending entries, newest first. They never affect [totals].
  final List<Entry> pending;

  /// Ids of entries that already have a reversal.
  final Set<String> reversedEntryIds;

  bool get isEmpty => approved.isEmpty && pending.isEmpty;

  /// Approved total for [currency], or zero when it has no entries.
  int totalMinorFor(String currency) {
    for (final total in totals) {
      if (total.currency == currency) {
        return total.totalMinor;
      }
    }
    return 0;
  }

  /// Whether [entry] may be corrected with a new reversal entry.
  ///
  /// Only approved, non-reversal entries qualify, and each entry can be
  /// reversed once. The database enforces the same rules.
  bool canReverse(Entry entry) {
    return entry.isApproved &&
        !entry.isReversal &&
        !reversedEntryIds.contains(entry.id);
  }

  static bool _countsTowardTotal(Entry entry, Map<String, Entry> approvedById) {
    if (!entry.isReversal) {
      return true;
    }
    final target = approvedById[entry.reversesEntryId];
    return target != null && target.currency == entry.currency;
  }

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
