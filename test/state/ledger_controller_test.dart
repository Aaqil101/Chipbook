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
    expect(controller.summary.totalMinorFor('USD'), 0);
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

    expect(controller.summary.totalMinorFor('USD'), 2500);
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
    expect(controller.summary.totalMinorFor('USD'), 0);
    expect(controller.summary.approved, hasLength(2));
  });

  test('adds entries in the selected currency', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final usd = await controller.addEntry(
      amountMinor: 2500,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );
    final jpy = await controller.addEntry(
      amountMinor: 1500,
      contributorName: 'Grace',
      currency: 'JPY',
      status: EntryStatus.approved,
    );

    expect(usd.currency, 'USD');
    expect(jpy.currency, 'JPY');
    expect(controller.summary.totalMinorFor('USD'), 2500);
    expect(controller.summary.totalMinorFor('JPY'), 1500);
  });

  test('reversals use the target currency and leave others alone', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();
    final usd = await controller.addEntry(
      amountMinor: 5000,
      contributorName: 'Ada',
      status: EntryStatus.approved,
    );
    await controller.addEntry(
      amountMinor: 3000,
      contributorName: 'Grace',
      currency: 'EUR',
      status: EntryStatus.approved,
    );

    final reversal = await controller.reverse(target: usd, reason: 'Mistake');

    expect(reversal.currency, 'USD');
    expect(controller.summary.totalMinorFor('USD'), 0);
    expect(controller.summary.totalMinorFor('EUR'), 3000);
  });

  test('rejects unknown currency codes', () async {
    final repository = InMemoryEntryRepository();
    final controller = LedgerController(repository, fundId: 'fund-a');
    addTearDown(controller.dispose);

    await controller.load();

    await expectLater(
      controller.addEntry(
        amountMinor: 1000,
        contributorName: 'Ada',
        currency: 'ZZZ',
      ),
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
