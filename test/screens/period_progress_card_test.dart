import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund.dart';
import 'package:chipbook/models/fund_cadence.dart';
import 'package:chipbook/screens/period_progress_card.dart';

void main() {
  testWidgets('shows the current period total and target progress', (
    tester,
  ) async {
    await _pump(
      tester,
      fund: _fund(cadence: FundCadence.monthly, targetMinor: 50000),
      entries: [_entry('a', DateTime(2026, 11, 5), amountMinor: 12000)],
    );

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
    expect(find.text('USD 120.00'), findsOneWidget);
    expect(find.text('of USD 500.00 · 24% of target'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.24, 0.0001),
    );
  });

  testWidgets('ignores entries from other periods', (tester) async {
    await _pump(
      tester,
      fund: _fund(cadence: FundCadence.monthly, targetMinor: 50000),
      entries: [_entry('a', DateTime(2026, 10, 20), amountMinor: 12000)],
    );

    expect(find.text('USD 0.00'), findsOneWidget);
    expect(find.text('of USD 500.00 · 0% of target'), findsOneWidget);
  });

  testWidgets('payouts never count toward period progress', (tester) async {
    await _pump(
      tester,
      fund: _fund(cadence: FundCadence.monthly, targetMinor: 50000),
      entries: [
        _entry('in', DateTime(2026, 11, 5), amountMinor: 12000),
        _entry(
          'out',
          DateTime(2026, 11, 6),
          amountMinor: 5000,
          kind: EntryKind.payout,
        ),
      ],
    );

    expect(find.text('USD 120.00'), findsOneWidget);
  });

  testWidgets('shows only the period total when there is no target', (
    tester,
  ) async {
    await _pump(
      tester,
      fund: _fund(cadence: FundCadence.weekly),
      entries: [_entry('a', DateTime(2026, 11, 5), amountMinor: 12000)],
    );

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('raised in this period'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a one-off fund without a target shows nothing', (tester) async {
    await _pump(
      tester,
      fund: _fund(cadence: FundCadence.oneOff),
      entries: [_entry('a', DateTime(2026, 11, 5), amountMinor: 12000)],
    );

    expect(find.byType(Card), findsNothing);
  });

  testWidgets('a one-off target is a lifetime goal', (tester) async {
    await _pump(
      tester,
      fund: _fund(cadence: FundCadence.oneOff, targetMinor: 50000),
      entries: [_entry('a', DateTime(2026, 11, 5), amountMinor: 60000)],
    );

    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Since Jan 1, 2026'), findsOneWidget);
    expect(find.text('of USD 500.00 · target reached'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1.0,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Fund fund,
  required List<Entry> entries,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PeriodProgressCard(
          fund: fund,
          entries: entries,
          now: DateTime(2026, 11, 13, 12),
        ),
      ),
    ),
  );
}

Fund _fund({FundCadence cadence = FundCadence.oneOff, int? targetMinor}) {
  return Fund(
    id: 'fund-a',
    name: 'Class fund',
    defaultCurrency: 'USD',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    cadence: cadence,
    targetMinor: targetMinor,
  );
}

Entry _entry(
  String id,
  DateTime createdAt, {
  required int amountMinor,
  EntryKind kind = EntryKind.contribution,
}) {
  return Entry(
    id: id,
    fundId: 'fund-a',
    amountMinor: amountMinor,
    currency: 'USD',
    contributorName: 'Ada',
    createdAt: createdAt,
    status: EntryStatus.approved,
    kind: kind,
  );
}
