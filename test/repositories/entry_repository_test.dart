import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/models/entry.dart';
import 'package:chipbook/repositories/entry_repository.dart';

void main() {
  late InMemoryEntryRepository repository;

  setUp(() {
    repository = InMemoryEntryRepository();
  });

  test('starts empty', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('appends entries in order', () async {
    await repository.add(_entry('a'));
    await repository.add(_entry('b'));

    final entries = await repository.getAll();
    expect(entries.map((entry) => entry.id), ['a', 'b']);
  });

  test('rejects duplicate ids', () async {
    await repository.add(_entry('a'));

    await expectLater(repository.add(_entry('a')), throwsArgumentError);
    expect(await repository.getAll(), hasLength(1));
  });

  test('rejects the same entry object twice', () async {
    final entry = _entry('a');
    await repository.add(entry);

    await expectLater(repository.add(entry), throwsArgumentError);
  });

  test('returned lists cannot mutate the store', () async {
    await repository.add(_entry('a'));
    final entries = await repository.getAll();

    expect(() => entries.add(_entry('b')), throwsUnsupportedError);
    expect(await repository.getAll(), hasLength(1));
  });
}

Entry _entry(String id) {
  return Entry(
    id: id,
    amountMinor: 1000,
    currency: 'USD',
    contributorName: 'Ada',
    createdAt: DateTime(2026, 1, 1),
    status: EntryStatus.approved,
  );
}
