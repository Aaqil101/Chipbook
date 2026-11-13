import '../models/entry.dart';

/// Read and append access to ledger entries.
///
/// Entries are append-only by design: there is deliberately no update or
/// delete operation. Implement this interface to swap in a remote store
/// without changing the rest of the app.
abstract interface class EntryRepository {
  /// Returns every entry in [fundId] in append order.
  Future<List<Entry>> getAll({required String fundId});

  /// Appends [entry].
  ///
  /// Throws an [ArgumentError] when an entry with the same id already
  /// exists.
  Future<void> add(Entry entry);

  /// Approves a pending entry in [fundId].
  ///
  /// This is the only permitted mutation; financial fields stay immutable.
  Future<void> approve({required String fundId, required String entryId});
}

/// In-memory [EntryRepository] for local use and tests.
class InMemoryEntryRepository implements EntryRepository {
  final List<Entry> _entries = <Entry>[];

  @override
  Future<List<Entry>> getAll({required String fundId}) async {
    return List<Entry>.unmodifiable(
      _entries.where((entry) => entry.fundId == fundId),
    );
  }

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

  @override
  Future<void> approve({
    required String fundId,
    required String entryId,
  }) async {
    final index = _entries.indexWhere(
      (entry) => entry.fundId == fundId && entry.id == entryId,
    );
    if (index == -1) {
      throw ArgumentError.value(entryId, 'entryId', 'no such entry');
    }

    final entry = _entries[index];
    if (entry.status == EntryStatus.approved) {
      return;
    }
    _entries[index] = entry.copyWith(status: EntryStatus.approved);
  }
}
