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
