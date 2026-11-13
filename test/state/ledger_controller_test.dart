import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/models/entry.dart';
import 'package:chipbook/repositories/entry_repository.dart';
import 'package:chipbook/state/ledger_controller.dart';

void main() {
  test('adds pending entries scoped to the controller fund', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(
      repository,
      fundId: 'fund-a',
      clock: () => DateTime(2026, 1, 1),
    );
    addTearDown(controller.dispose);

    await controller.load();
    final entry = await controller.addEntry(
      amountMinor: 2500,
      contributorName: 'Ada',
    );

    expect(entry.fundId, 'fund-a');
    expect(entry.status, EntryStatus.pending);
    expect(controller.summary.balanceMinorFor('USD'), 0);
    expect(controller.summary.pending, hasLength(1));
  });

  test('approving moves an entry into the total', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final entry = await controller.addEntry(
      amountMinor: 2500,
      contributorName: 'Ada',
    );
    await controller.approve(entry.id);

    expect(controller.summary.balanceMinorFor('USD'), 2500);
    expect(controller.summary.approved.single.id, entry.id);
  });

  test('deleting a pending entry removes it from the ledger', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final entry = await controller.addEntry(
      amountMinor: 2500,
      contributorName: 'Ada',
    );
    await controller.deletePending(entry.id);

    expect(controller.entries, isEmpty);
    expect(controller.summary.pending, isEmpty);
    expect(controller.summary.balanceMinorFor('USD'), 0);
  });

  test('rejects deleting an approved entry', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final entry = await controller.addEntry(
      amountMinor: 2500,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );

    await expectLater(controller.deletePending(entry.id), throwsArgumentError);
    expect(controller.summary.approved, hasLength(1));
  });

  test('rejects deleting an unknown entry', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();

    await expectLater(controller.deletePending('missing'), throwsArgumentError);
  });

  test('a reversal is approved immediately and reduces the total', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(
      repository,
      fundId: 'fund-a',
      clock: () => DateTime(2026, 1, 1),
    );
    addTearDown(controller.dispose);

    await controller.load();
    final target = await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );

    final reversal = await controller.reverse(
      target: target,
      reason: '  Recorded twice  ',
    );

    expect(reversal.status, EntryStatus.approved);
    expect(reversal.isReversal, isTrue);
    expect(reversal.reversesEntryId, target.id);
    expect(reversal.amountMinor, target.amountMinor);
    expect(reversal.contributorName, target.contributorName);
    expect(reversal.note, 'Recorded twice');
    expect(controller.summary.balanceMinorFor('USD'), 0);
    expect(controller.summary.approved, hasLength(2));
  });

  test('records entries in the fund currency', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(
      repository,
      fundId: 'fund-a',
      currency: 'JPY',
    );
    addTearDown(controller.dispose);

    await controller.load();
    final entry = await controller.addEntry(
      amountMinor: 1500,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );

    expect(entry.currency, 'JPY');
    expect(controller.summary.balanceMinorFor('JPY'), 1500);
    expect(controller.summary.balanceMinorFor('USD'), 0);
  });

  test('reversals keep the fund currency', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(
      repository,
      fundId: 'fund-a',
      currency: 'LKR',
    );
    addTearDown(controller.dispose);

    await controller.load();
    final target = await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );

    final reversal = await controller.reverse(
      target: target,
      reason: 'Mistake',
    );

    expect(reversal.currency, 'LKR');
    expect(controller.summary.balanceMinorFor('LKR'), 0);
  });

  test('rejects an unsupported fund currency', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(
      repository,
      fundId: 'fund-a',
      currency: 'ZZZ',
    );
    addTearDown(controller.dispose);

    await controller.load();

    await expectLater(
      controller.addEntry(amountMinor: 1000, contributorName: 'Ada'),
      throwsArgumentError,
    );
    expect(controller.entries, isEmpty);
  });

  test('rejects reversing a pending entry', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final target = await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
    );

    await expectLater(
      controller.reverse(target: target, reason: 'Mistake'),
      throwsArgumentError,
    );
  });

  test('rejects an empty reversal reason', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final target = await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );

    await expectLater(
      controller.reverse(target: target, reason: '   '),
      throwsArgumentError,
    );
  });

  test('rejects reversing the same entry twice', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final target = await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );
    await controller.reverse(target: target, reason: 'Mistake');

    await expectLater(
      controller.reverse(target: target, reason: 'Mistake again'),
      throwsArgumentError,
    );
  });

  test('a payout is approved immediately and lowers the balance', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );
    final payout = await controller.addEntry(
      amountMinor: 2000,
      contributorName: 'Teacher',
      note: '  Monthly class fee  ',
      kind: EntryKind.payout,
    );

    expect(payout.status, EntryStatus.approved);
    expect(payout.isPayout, isTrue);
    expect(payout.note, 'Monthly class fee');
    expect(controller.summary.raisedMinorFor('USD'), 5000);
    expect(controller.summary.balanceMinorFor('USD'), 3000);
    expect(controller.summary.paidOutMinorFor('USD'), 2000);
  });

  test('a payout ignores a requested pending status', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final payout = await controller.addEntry(
      amountMinor: 1000,
      contributorName: 'Teacher',
      note: 'Class fee',
      kind: EntryKind.payout,
      status: EntryStatus.pending,
    );

    expect(payout.status, EntryStatus.approved);
  });

  test('rejects a payout without a reason', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();

    await expectLater(
      controller.addEntry(
        amountMinor: 1000,
        contributorName: 'Teacher',
        note: '   ',
        kind: EntryKind.payout,
      ),
      throwsArgumentError,
    );
    expect(controller.entries, isEmpty);
  });

  test('reversing a payout restores the balance with its kind', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );
    final payout = await controller.addEntry(
      amountMinor: 2000,
      contributorName: 'Teacher',
      note: 'Class fee',
      kind: EntryKind.payout,
    );

    final reversal = await controller.reverse(
      target: payout,
      reason: 'Paid twice',
    );

    expect(reversal.kind, EntryKind.payout);
    expect(reversal.isReversal, isTrue);
    expect(controller.summary.balanceMinorFor('USD'), 5000);
    expect(controller.summary.paidOutMinorFor('USD'), 0);
  });

  test('does not load entries from other funds', () async {
    final repository = InMemoryEntryRepository();

    final other = LedgerController(repository, fundId: 'fund-b');
    addTearDown(other.dispose);
    await other.load();
    await other.addEntry(amountMinor: 1000, contributorName: 'Grace');

    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.entries, isEmpty);
  });
}
