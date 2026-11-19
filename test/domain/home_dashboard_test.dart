import 'package:chipbook/domain/home_dashboard.dart';
import 'package:chipbook/models/entry.dart';
import 'package:chipbook/models/fund.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each fund is summarised in its own currency', () {
    final dashboard = HomeDashboard.from(
      funds: [_fund('fund-usd', 'USD'), _fund('fund-jpy', 'JPY')],
      archivedFunds: const <Fund>[],
      entriesByFund: {
        'fund-usd': [
          _entry('a', fundId: 'fund-usd', amountMinor: 2500, currency: 'USD'),
          _entry(
            'b',
            fundId: 'fund-usd',
            amountMinor: 500,
            currency: 'USD',
            kind: EntryKind.payout,
          ),
        ],
        'fund-jpy': [
          _entry('c', fundId: 'fund-jpy', amountMinor: 1000, currency: 'JPY'),
        ],
      },
    );

    final usd = dashboard.funds.first;
    expect(usd.raisedMinor, 2500);
    expect(usd.paidOutMinor, 500);
    expect(usd.balanceMinor, 2000);

    final jpy = dashboard.funds.last;
    expect(jpy.raisedMinor, 1000);
    expect(jpy.paidOutMinor, 0);
    expect(jpy.balanceMinor, 1000);
  });

  test('amounts in different currencies are never added together', () {
    final dashboard = HomeDashboard.from(
      funds: [_fund('fund-usd', 'USD'), _fund('fund-jpy', 'JPY')],
      archivedFunds: const <Fund>[],
      entriesByFund: {
        'fund-usd': [
          _entry('a', fundId: 'fund-usd', amountMinor: 1000, currency: 'USD'),
        ],
        'fund-jpy': [
          _entry('b', fundId: 'fund-jpy', amountMinor: 5000, currency: 'JPY'),
        ],
      },
    );

    expect(
      dashboard.funds.map((snapshot) => snapshot.raisedMinor),
      [1000, 5000],
    );
  });

  test('pending entries are counted but never change a total', () {
    final dashboard = HomeDashboard.from(
      funds: [_fund('fund-a', 'USD'), _fund('fund-b', 'USD')],
      archivedFunds: const <Fund>[],
      entriesByFund: {
        'fund-a': [
          _entry('a', fundId: 'fund-a', amountMinor: 1000, currency: 'USD'),
          _entry(
            'b',
            fundId: 'fund-a',
            amountMinor: 300,
            currency: 'USD',
            status: EntryStatus.pending,
          ),
        ],
        'fund-b': [
          _entry(
            'c',
            fundId: 'fund-b',
            amountMinor: 700,
            currency: 'USD',
            status: EntryStatus.pending,
          ),
        ],
      },
    );

    expect(dashboard.pendingCount, 2);
    expect(dashboard.funds.first.raisedMinor, 1000);
    expect(dashboard.funds.last.raisedMinor, 0);
  });

  test('a fund without entries still shows its currency at zero', () {
    final dashboard = HomeDashboard.from(
      funds: [_fund('fund-a', 'USD')],
      archivedFunds: const <Fund>[],
      entriesByFund: const {},
    );

    final snapshot = dashboard.funds.single;
    expect(snapshot.raisedMinor, 0);
    expect(snapshot.balanceMinor, 0);
    expect(snapshot.paidOutMinor, 0);
    expect(snapshot.summary.totals.single.currency, 'USD');
  });

  test('archived funds are counted but not listed', () {
    final dashboard = HomeDashboard.from(
      funds: [_fund('fund-a', 'USD')],
      archivedFunds: [
        _fund('fund-b', 'USD', archivedAt: DateTime(2026, 2, 1)),
      ],
      entriesByFund: const {},
    );

    expect(dashboard.funds, hasLength(1));
    expect(dashboard.archivedCount, 1);
  });

  test('no funds at all is empty rather than broken', () {
    final dashboard = HomeDashboard.fromSummaries(
      funds: const <Fund>[],
      archivedFunds: const <Fund>[],
      summaries: const {},
    );

    expect(dashboard.isEmpty, isTrue);
    expect(dashboard.pendingCount, 0);
  });
}

Fund _fund(String id, String currency, {DateTime? archivedAt}) {
  return Fund(
    id: id,
    name: 'Fund $id',
    defaultCurrency: currency,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    archivedAt: archivedAt,
  );
}

Entry _entry(
  String id, {
  required String fundId,
  required int amountMinor,
  required String currency,
  EntryStatus status = EntryStatus.approved,
  EntryKind kind = EntryKind.contribution,
}) {
  return Entry(
    id: id,
    fundId: fundId,
    amountMinor: amountMinor,
    currency: currency,
    contributorName: 'Ada',
    createdAt: DateTime(2026, 1, 1),
    status: status,
    kind: kind,
  );
}
