import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/fund_period.dart';
import 'package:chipbook/domain/ledger.dart';
import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund_cadence.dart';

void main() {
  group('FundPeriod.current', () {
    test('weekly runs from Monday to the next Monday', () {
      final period = FundPeriod.current(
        FundCadence.weekly,
        now: DateTime(2026, 11, 13, 15, 30),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(period.start, DateTime(2026, 11, 9));
      expect(period.endExclusive, DateTime(2026, 11, 16));
      expect(period.endInclusive, DateTime(2026, 11, 15));
    });

    test('weekly includes the whole of Sunday', () {
      final period = FundPeriod.current(
        FundCadence.weekly,
        now: DateTime(2026, 11, 15, 23, 59),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(period.start, DateTime(2026, 11, 9));
      expect(period.contains(DateTime(2026, 11, 15, 23, 59)), isTrue);
      expect(period.contains(DateTime(2026, 11, 16)), isFalse);
    });

    test('weekly crosses a year boundary', () {
      final period = FundPeriod.current(
        FundCadence.weekly,
        now: DateTime(2026, 1, 1),
        createdAt: DateTime(2025, 1, 1),
      );

      expect(period.start, DateTime(2025, 12, 29));
      expect(period.endExclusive, DateTime(2026, 1, 5));
    });

    test('monthly runs from the 1st to the next month', () {
      final period = FundPeriod.current(
        FundCadence.monthly,
        now: DateTime(2026, 11, 13),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(period.start, DateTime(2026, 11, 1));
      expect(period.endExclusive, DateTime(2026, 12, 1));
      expect(period.endInclusive, DateTime(2026, 11, 30));
    });

    test('monthly rolls over at midnight on the 1st', () {
      final period = FundPeriod.current(
        FundCadence.monthly,
        now: DateTime(2026, 12, 31, 23, 59),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(period.start, DateTime(2026, 12, 1));
      expect(period.endExclusive, DateTime(2027, 1, 1));
    });

    test('yearly runs from 1 January to 1 January', () {
      final period = FundPeriod.current(
        FundCadence.yearly,
        now: DateTime(2026, 6, 5),
        createdAt: DateTime(2024, 3, 1),
      );

      expect(period.start, DateTime(2026, 1, 1));
      expect(period.endExclusive, DateTime(2027, 1, 1));
      expect(period.endInclusive, DateTime(2026, 12, 31));
    });

    test('one-off starts on the creation day and never ends', () {
      final period = FundPeriod.current(
        FundCadence.oneOff,
        now: DateTime(2026, 11, 13),
        createdAt: DateTime(2026, 3, 4, 18, 30),
      );

      expect(period.start, DateTime(2026, 3, 4));
      expect(period.endExclusive, isNull);
      expect(period.endInclusive, isNull);
      expect(period.contains(DateTime(2026, 11, 13)), isTrue);
      expect(period.contains(DateTime(2026, 3, 3, 23, 59)), isFalse);
    });

    test('contains includes the start and excludes the end', () {
      final period = FundPeriod.current(
        FundCadence.monthly,
        now: DateTime(2026, 11, 13),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(period.contains(DateTime(2026, 11, 1)), isTrue);
      expect(period.contains(DateTime(2026, 12, 1)), isFalse);
      expect(period.contains(DateTime(2026, 10, 31, 23, 59, 59)), isFalse);
    });
  });

  group('FundPeriod.entriesFrom', () {
    test('keeps only entries inside the current month', () {
      final period = _november();
      final entries = [
        _entry('old', DateTime(2026, 10, 31)),
        _entry('first', DateTime(2026, 11, 1)),
        _entry('later', DateTime(2026, 11, 30, 23, 59)),
        _entry('next', DateTime(2026, 12, 1)),
      ];

      expect(period.entriesFrom(entries).map((entry) => entry.id), [
        'first',
        'later',
      ]);
    });

    test('attributes a reversal to the period of its target', () {
      final period = _november();
      final old = _entry('old', DateTime(2026, 10, 20));
      final reversal = _entry(
        'reversal',
        DateTime(2026, 11, 3),
        reversesEntryId: 'old',
      );

      expect(period.entriesFrom([old, reversal]), isEmpty);
    });

    test('correcting last month does not change this month', () {
      final thisMonth = _november();
      final lastMonth = _october();
      final old = _entry('old', DateTime(2026, 10, 20));
      final reversal = _entry(
        'reversal',
        DateTime(2026, 11, 3),
        reversesEntryId: 'old',
      );
      final all = [old, reversal];

      expect(
        LedgerSummary.from(
          thisMonth.entriesFrom(all),
          defaultCurrency: 'USD',
        ).raisedMinorFor('USD'),
        0,
      );
      expect(
        LedgerSummary.from(
          lastMonth.entriesFrom(all),
          defaultCurrency: 'USD',
        ).raisedMinorFor('USD'),
        0,
      );
    });

    test('falls back to its own date when the target is not loaded', () {
      final period = _november();
      final reversal = _entry(
        'orphan',
        DateTime(2026, 11, 3),
        reversesEntryId: 'missing',
      );

      expect(period.entriesFrom([reversal]).single.id, 'orphan');
    });
  });
}

FundPeriod _november() => FundPeriod.current(
  FundCadence.monthly,
  now: DateTime(2026, 11, 13),
  createdAt: DateTime(2026, 1, 1),
);

FundPeriod _october() => FundPeriod.current(
  FundCadence.monthly,
  now: DateTime(2026, 10, 13),
  createdAt: DateTime(2026, 1, 1),
);

Entry _entry(
  String id,
  DateTime createdAt, {
  int amountMinor = 1000,
  String currency = 'USD',
  EntryStatus status = EntryStatus.approved,
  String? reversesEntryId,
}) {
  return Entry(
    id: id,
    fundId: 'fund-a',
    amountMinor: amountMinor,
    currency: currency,
    contributorName: 'Ada',
    createdAt: createdAt,
    status: status,
    reversesEntryId: reversesEntryId,
  );
}
