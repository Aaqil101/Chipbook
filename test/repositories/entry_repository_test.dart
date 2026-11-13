import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/models/entry.dart';
import 'package:chipbook/repositories/entry_repository.dart';

const _fundId = 'fund-a';

void main() {
  late InMemoryEntryRepository repository;

  setUp(() {
    repository = InMemoryEntryRepository();
  });

  test('starts empty', () async {
    expect(await repository.getAll(fundId: _fundId), isEmpty);
  });

  test('appends entries in order', () async {
    await repository.add(_entry('a'));
    await repository.add(_entry('b'));

    final entries = await repository.getAll(fundId: _fundId);
    expect(entries.map((entry) => entry.id), ['a', 'b']);
  });

  test('only returns entries from the requested fund', () async {
    await repository.add(_entry('a'));
    await repository.add(_entry('b', fundId: 'fund-b'));

    final entries = await repository.getAll(fundId: _fundId);
    expect(entries.map((entry) => entry.id), ['a']);
  });

  test('rejects duplicate ids', () async {
    await repository.add(_entry('a'));

    await expectLater(repository.add(_entry('a')), throwsArgumentError);
    expect(await repository.getAll(fundId: _fundId), hasLength(1));
  });

  test('rejects the same entry object twice', () async {
    final entry = _entry('a');
    await repository.add(entry);

    await expectLater(repository.add(entry), throwsArgumentError);
  });

  test('keeps mixed currencies without converting them', () async {
    await repository.add(_entry('usd', currency: 'USD', amountMinor: 1000));
    await repository.add(_entry('eur', currency: 'EUR', amountMinor: 2000));
    await repository.add(
      _entry('jpy', fundId: 'fund-b', currency: 'JPY', amountMinor: 300),
    );

    final entries = await repository.getAll(fundId: _fundId);
    expect(entries.map((entry) => entry.currency), ['USD', 'EUR']);
    expect(entries.map((entry) => entry.amountMinor), [1000, 2000]);
  });

  test('stores reversals alongside their targets', () async {
    await repository.add(_entry('target', currency: 'KWD', amountMinor: 5000));
    await repository.add(
      _entry(
        'reversal',
        currency: 'KWD',
        amountMinor: 5000,
        reversesEntryId: 'target',
      ),
    );

    final entries = await repository.getAll(fundId: _fundId);
    final target = entries.firstWhere((entry) => entry.id == 'target');
    final reversal = entries.firstWhere((entry) => entry.id == 'reversal');

    expect(target.status, EntryStatus.approved);
    expect(reversal.isReversal, isTrue);
    expect(reversal.reversesEntryId, 'target');
    expect(reversal.currency, 'KWD');
    expect(reversal.signedAmountMinor, -5000);
  });

  test('stores payouts alongside contributions', () async {
    await repository.add(_entry('in', amountMinor: 5000));
    await repository.add(
      _entry('out', amountMinor: 2000, kind: EntryKind.payout),
    );

    final entries = await repository.getAll(fundId: _fundId);
    final payout = entries.firstWhere((entry) => entry.id == 'out');

    expect(payout.kind, EntryKind.payout);
    expect(payout.isPayout, isTrue);
    expect(payout.signedAmountMinor, -2000);
  });

  test('approves a pending entry', () async {
    await repository.add(_entry('a', status: EntryStatus.pending));

    await repository.approve(fundId: _fundId, entryId: 'a');

    final entries = await repository.getAll(fundId: _fundId);
    expect(entries.single.status, EntryStatus.approved);
  });

  test('approval does not touch the same id in another fund', () async {
    await repository.add(_entry('a', status: EntryStatus.pending));
    await repository.add(
      _entry('b', fundId: 'fund-b', status: EntryStatus.pending),
    );

    await repository.approve(fundId: _fundId, entryId: 'a');

    final other = await repository.getAll(fundId: 'fund-b');
    expect(other.single.status, EntryStatus.pending);
  });

  test('rejects approving an entry from another fund', () async {
    await repository.add(
      _entry('a', fundId: 'fund-b', status: EntryStatus.pending),
    );

    await expectLater(
      repository.approve(fundId: _fundId, entryId: 'a'),
      throwsArgumentError,
    );
  });

  test('returned lists cannot mutate the store', () async {
    await repository.add(_entry('a'));
    final entries = await repository.getAll(fundId: _fundId);

    expect(() => entries.add(_entry('b')), throwsUnsupportedError);
    expect(await repository.getAll(fundId: _fundId), hasLength(1));
  });
}

Entry _entry(
  String id, {
  String fundId = _fundId,
  String currency = 'USD',
  int amountMinor = 1000,
  EntryStatus status = EntryStatus.approved,
  String? reversesEntryId,
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
    reversesEntryId: reversesEntryId,
    kind: kind,
  );
}
