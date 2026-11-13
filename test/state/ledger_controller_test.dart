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
    expect(controller.summary.totalMinor, 0);
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

    expect(controller.summary.totalMinor, 2500);
    expect(controller.summary.approved.single.id, entry.id);
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
    expect(controller.summary.totalMinor, 0);
    expect(controller.summary.approved, hasLength(2));
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
