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

  test('approves a pending entry', () async {
    await repository.add(_entry('a', status: EntryStatus.pending));

    await repository.approve(fundId: _fundId, entryId: 'a');

    final entries = await repository.getAll(fundId: _fundId);
    expect(entries.single.status, EntryStatus.approved);
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
  EntryStatus status = EntryStatus.approved,
}) {
  return Entry(
    id: id,
    fundId: fundId,
    amountMinor: 1000,
    currency: 'USD',
    contributorName: 'Ada',
    createdAt: DateTime(2026, 1, 1),
    status: status,
  );
}
