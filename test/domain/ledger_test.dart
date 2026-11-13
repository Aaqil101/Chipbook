import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/ledger.dart';
import 'package:chipbook/models/entry.dart';

void main() {
  group('LedgerSummary', () {
    test('empty ledger has no totals', () {
      final summary = LedgerSummary.from(const []);

      expect(summary.totals, isEmpty);
      expect(summary.approved, isEmpty);
      expect(summary.pending, isEmpty);
      expect(summary.isEmpty, isTrue);
    });

    test('empty ledger can still show its default currency', () {
      final summary = LedgerSummary.from(const [], defaultCurrency: 'USD');

      expect(summary.totals, hasLength(1));
      expect(summary.totalMinorFor('USD'), 0);
    });

    test('sums approved entries only', () {
      final summary = LedgerSummary.from([
        _entry(id: 'a', amountMinor: 1000),
        _entry(id: 'b', amountMinor: 2500),
        _entry(id: 'c', amountMinor: 9000, status: EntryStatus.pending),
      ]);

      expect(summary.totalMinorFor('USD'), 3500);
      expect(summary.approved, hasLength(2));
      expect(summary.pending, hasLength(1));
      expect(summary.pending.single.id, 'c');
    });

    test('groups totals by currency instead of mixing them', () {
      final summary = LedgerSummary.from([
        _entry(id: 'usd-a', amountMinor: 1000),
        _entry(id: 'eur', amountMinor: 2000, currency: 'EUR'),
        _entry(id: 'usd-b', amountMinor: 500),
        _entry(
          id: 'jpy',
          amountMinor: 300,
          currency: 'JPY',
          status: EntryStatus.pending,
        ),
      ]);

      expect(summary.totals, hasLength(2));
      expect(summary.totalMinorFor('USD'), 1500);
      expect(summary.totalMinorFor('EUR'), 2000);
      expect(summary.totalMinorFor('JPY'), 0);
      expect(summary.totals.map((total) => total.currency), ['EUR', 'USD']);
    });

    test('an approved reversal subtracts from its own currency', () {
      final summary = LedgerSummary.from([
        _entry(id: 'usd', amountMinor: 5000),
        _entry(id: 'eur', amountMinor: 3000, currency: 'EUR'),
        _entry(id: 'r', amountMinor: 5000, reversesEntryId: 'usd'),
      ]);

      expect(summary.totalMinorFor('USD'), 0);
      expect(summary.totalMinorFor('EUR'), 3000);
      expect(summary.approved, hasLength(3));
    });

    test('a cross-currency reversal never changes a total', () {
      final summary = LedgerSummary.from([
        _entry(id: 'usd', amountMinor: 5000),
        _entry(
          id: 'r',
          amountMinor: 5000,
          currency: 'EUR',
          reversesEntryId: 'usd',
        ),
      ]);

      expect(summary.totalMinorFor('USD'), 5000);
      expect(summary.totalMinorFor('EUR'), 0);
    });

    test('a partial reversal subtracts only its own amount', () {
      final summary = LedgerSummary.from([
        _entry(id: 'a', amountMinor: 5000),
        _entry(id: 'r', amountMinor: 2000, reversesEntryId: 'a'),
      ]);

      expect(summary.totalMinorFor('USD'), 3000);
    });

    test('reversing a pending entry does not change the total', () {
      final summary = LedgerSummary.from([
        _entry(id: 'a', amountMinor: 5000, status: EntryStatus.pending),
        _entry(id: 'r', amountMinor: 5000, reversesEntryId: 'a'),
      ]);

      expect(summary.totals, isEmpty);
      expect(summary.approved, hasLength(1));
      expect(summary.pending, hasLength(1));
    });

    test('a pending reversal does not change the total', () {
      final summary = LedgerSummary.from([
        _entry(id: 'a', amountMinor: 5000),
        _entry(
          id: 'r',
          amountMinor: 5000,
          status: EntryStatus.pending,
          reversesEntryId: 'a',
        ),
      ]);

      expect(summary.totalMinorFor('USD'), 5000);
    });

    test('tracks which entries already have a reversal', () {
      final summary = LedgerSummary.from([
        _entry(id: 'a', amountMinor: 5000),
        _entry(id: 'b', amountMinor: 3000),
        _entry(id: 'r', amountMinor: 5000, reversesEntryId: 'a'),
      ]);

      expect(summary.reversedEntryIds, {'a'});
      expect(summary.canReverse(_find(summary.approved, 'a')), isFalse);
      expect(summary.canReverse(_find(summary.approved, 'b')), isTrue);
      expect(summary.canReverse(_find(summary.approved, 'r')), isFalse);
    });

    test('only approved, unreversed, normal entries can be reversed', () {
      final summary = LedgerSummary.from([
        _entry(id: 'approved', amountMinor: 5000),
        _entry(id: 'pending', amountMinor: 5000, status: EntryStatus.pending),
        _entry(id: 'reversal', amountMinor: 5000, reversesEntryId: 'approved'),
      ]);

      expect(summary.canReverse(_find(summary.approved, 'approved')), isFalse);
      expect(summary.canReverse(summary.pending.single), isFalse);
      expect(summary.canReverse(_find(summary.approved, 'reversal')), isFalse);
    });

    test('sorts approved and pending entries newest first', () {
      final summary = LedgerSummary.from([
        _entry(id: 'old', amountMinor: 1000, createdAt: DateTime(2026, 1, 1)),
        _entry(id: 'new', amountMinor: 1000, createdAt: DateTime(2026, 2, 1)),
      ]);

      expect(summary.approved.map((entry) => entry.id), ['new', 'old']);
    });

    test('exposes unmodifiable lists and totals', () {
      final summary = LedgerSummary.from([_entry(id: 'a', amountMinor: 1000)]);

      expect(
        () => summary.approved.add(_entry(id: 'b', amountMinor: 1000)),
        throwsUnsupportedError,
      );
      expect(
        () => summary.totals.add(
          const CurrencyTotal(currency: 'EUR', totalMinor: 0),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

Entry _find(List<Entry> entries, String id) {
  return entries.firstWhere((entry) => entry.id == id);
}

Entry _entry({
  required String id,
  required int amountMinor,
  String currency = 'USD',
  EntryStatus status = EntryStatus.approved,
  String? reversesEntryId,
  DateTime? createdAt,
}) {
  return Entry(
    id: id,
    fundId: 'fund-a',
    amountMinor: amountMinor,
    currency: currency,
    contributorName: 'Ada',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    status: status,
    reversesEntryId: reversesEntryId,
  );
}
