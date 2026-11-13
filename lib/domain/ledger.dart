import '../models/entry.dart';

/// Approved figures for a single currency.
///
/// [raisedMinor] counts contributions only, while [balanceMinor] is what is
/// left after payouts. Amounts in different currencies are never combined.
class CurrencyTotal {
  const CurrencyTotal({
    required this.currency,
    required this.raisedMinor,
    required this.balanceMinor,
  });

  final String currency;

  /// Contributions net of their reversals.
  final int raisedMinor;

  /// Contributions minus payouts, both net of their reversals.
  final int balanceMinor;

  /// Money paid out of the fund so far.
  int get paidOutMinor => raisedMinor - balanceMinor;
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
  /// crossing currencies has no effect. Reversals carry the kind of their
  /// target, so reversing a payout restores the balance without touching the
  /// raised figure.
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
    final raisedByCurrency = <String, int>{};
    final balanceByCurrency = <String, int>{};

    for (final entry in approved) {
      if (!_countsTowardTotal(entry, approvedById)) {
        continue;
      }
      balanceByCurrency.update(
        entry.currency,
        (total) => total + entry.signedAmountMinor,
        ifAbsent: () => entry.signedAmountMinor,
      );
      if (entry.kind == EntryKind.contribution) {
        raisedByCurrency.update(
          entry.currency,
          (total) => total + entry.signedAmountMinor,
          ifAbsent: () => entry.signedAmountMinor,
        );
      }
    }

    if (balanceByCurrency.isEmpty && defaultCurrency != null) {
      balanceByCurrency[defaultCurrency] = 0;
      raisedByCurrency[defaultCurrency] = 0;
    }

    final totals = [
      for (final entry in balanceByCurrency.entries)
        CurrencyTotal(
          currency: entry.key,
          raisedMinor: raisedByCurrency[entry.key] ?? 0,
          balanceMinor: entry.value,
        ),
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

  /// Contributions raised in [currency], or zero when it has no entries.
  int raisedMinorFor(String currency) {
    for (final total in totals) {
      if (total.currency == currency) {
        return total.raisedMinor;
      }
    }
    return 0;
  }

  /// What is left in [currency] after payouts, or zero without entries.
  int balanceMinorFor(String currency) {
    for (final total in totals) {
      if (total.currency == currency) {
        return total.balanceMinor;
      }
    }
    return 0;
  }

  /// Money paid out of [currency], or zero when nothing was paid out.
  int paidOutMinorFor(String currency) {
    for (final total in totals) {
      if (total.currency == currency) {
        return total.paidOutMinor;
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
    return target != null &&
        target.currency == entry.currency &&
        target.kind == entry.kind;
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
