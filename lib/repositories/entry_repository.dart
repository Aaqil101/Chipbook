import '../models/entry.dart';

/// Read and append access to ledger entries.
///
/// Entries are append-only by design: there is deliberately no update or
/// delete operation. Implement this interface to swap in a remote store
/// without changing the rest of the app.
abstract interface class EntryRepository {
  /// Returns every entry in append order.
  Future<List<Entry>> getAll();

  /// Appends [entry].
  ///
  /// Throws an [ArgumentError] when an entry with the same id already
  /// exists.
  Future<void> add(Entry entry);
}

/// In-memory [EntryRepository] for local use and tests.
class InMemoryEntryRepository implements EntryRepository {
  final List<Entry> _entries = <Entry>[];

  @override
  Future<List<Entry>> getAll() async => List<Entry>.unmodifiable(_entries);

  @override
  Future<void> add(Entry entry) async {
    if (_entries.any((existing) => existing.id == entry.id)) {
      throw ArgumentError.value(
        entry.id,
        'entry.id',
        'an entry with this id already exists',
      );
    }
    _entries.add(entry);
  }
}
