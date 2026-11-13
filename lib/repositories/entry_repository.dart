import '../models/entry.dart';

/// Read, append, and pending-entry access to ledger entries.
///
/// Approved entries are append-only by design: there is deliberately no update
/// or delete for them. The only permitted mutations are approval and deleting
/// a pending entry that was never approved. Implement this interface to swap
/// in a remote store without changing the rest of the app.
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
  /// Approval leaves the financial fields untouched.
  Future<void> approve({required String fundId, required String entryId});

  /// Deletes a pending entry in [fundId].
  ///
  /// Only entries that were never approved can be deleted. Approved entries
  /// are immutable and must be corrected with a reversal instead.
  Future<void> deletePending({required String fundId, required String entryId});
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

  @override
  Future<void> deletePending({
    required String fundId,
    required String entryId,
  }) async {
    final index = _entries.indexWhere(
      (entry) => entry.fundId == fundId && entry.id == entryId,
    );
    if (index == -1) {
      throw ArgumentError.value(entryId, 'entryId', 'no such entry');
    }
    if (_entries[index].status == EntryStatus.approved) {
      throw ArgumentError.value(
        entryId,
        'entryId',
        'only pending entries can be deleted',
      );
    }
    _entries.removeAt(index);
  }
}
