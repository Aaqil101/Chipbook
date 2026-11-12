import 'package:flutter/foundation.dart';

import '../config.dart';
import '../domain/ledger.dart';
import '../models/entry.dart';
import '../repositories/entry_repository.dart';

/// Coordinates ledger reads and appends, and exposes the result to widgets.
class LedgerController extends ChangeNotifier {
  LedgerController(
    this._repository, {
    this.currency = AppConfig.defaultCurrency,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final EntryRepository _repository;
  final DateTime Function() _clock;

  /// ISO 4217 code assigned to new entries and used for display.
  final String currency;

  List<Entry> _entries = const <Entry>[];
  LedgerSummary? _summary;
  bool _isLoading = false;
  int _sequence = 0;

  /// Every entry in repository (append) order.
  List<Entry> get entries => _entries;

  /// Approved total and the approved/pending split, newest first.
  LedgerSummary get summary =>
      _summary ??= LedgerSummary.from(_entries, currency: currency);

  bool get isLoading => _isLoading;

  /// Loads all entries from the repository.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
      _summary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends a new entry and refreshes the exposed state.
  Future<Entry> addEntry({
    required int amountMinor,
    required String contributorName,
    String note = '',
    EntryStatus status = EntryStatus.pending,
    String? reversesEntryId,
  }) async {
    final createdAt = _clock();
    final entry = Entry(
      id: '${createdAt.microsecondsSinceEpoch}-${_sequence++}',
      amountMinor: amountMinor,
      currency: currency,
      contributorName: contributorName.trim(),
      note: note.trim(),
      createdAt: createdAt,
      status: status,
      reversesEntryId: reversesEntryId,
    );

    await _repository.add(entry);
    _entries = await _repository.getAll();
    _summary = null;
    notifyListeners();
    return entry;
  }
}
