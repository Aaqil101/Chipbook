import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../domain/ledger.dart';
import '../models/entry.dart';
import '../repositories/entry_repository.dart';

/// Coordinates ledger reads and appends for a single fund.
class LedgerController extends ChangeNotifier {
  LedgerController(
    this._repository, {
    required this.fundId,
    this.currency = AppConfig.defaultCurrency,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final EntryRepository _repository;
  final DateTime Function() _clock;
  final Uuid _uuid = const Uuid();

  /// Fund whose entries this controller manages.
  final String fundId;

  /// ISO 4217 code assigned to new entries and used for display.
  final String currency;

  List<Entry> _entries = const <Entry>[];
  LedgerSummary? _summary;
  bool _isLoading = false;

  /// Every entry in repository (append) order.
  List<Entry> get entries => _entries;

  /// Approved total and the approved/pending split, newest first.
  LedgerSummary get summary =>
      _summary ??= LedgerSummary.from(_entries, currency: currency);

  bool get isLoading => _isLoading;

  /// Loads all entries for [fundId] from the repository.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _repository.getAll(fundId: fundId);
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
    final entry = Entry(
      id: _uuid.v4(),
      fundId: fundId,
      amountMinor: amountMinor,
      currency: currency,
      contributorName: contributorName.trim(),
      note: note.trim(),
      createdAt: _clock(),
      status: status,
      reversesEntryId: reversesEntryId,
    );

    await _repository.add(entry);
    await _reload();
    return entry;
  }

  /// Approves a pending entry. Organizers only, enforced by the backend.
  Future<void> approve(String entryId) async {
    await _repository.approve(fundId: fundId, entryId: entryId);
    await _reload();
  }

  /// Records a new approved entry that reverses [target].
  ///
  /// Reversals carry the original amount and contributor, so the total drops
  /// by exactly the reversed amount. The original entry is never changed.
  Future<Entry> reverse({required Entry target, required String reason}) async {
    final note = reason.trim();
    if (note.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'a reason is required');
    }
    if (target.fundId != fundId) {
      throw ArgumentError.value(target.id, 'target', 'belongs to another fund');
    }
    if (!target.isApproved) {
      throw ArgumentError.value(target.id, 'target', 'must be approved');
    }
    if (target.isReversal) {
      throw ArgumentError.value(target.id, 'target', 'is already a reversal');
    }
    if (_entries.any((entry) => entry.reversesEntryId == target.id)) {
      throw ArgumentError.value(target.id, 'target', 'is already reversed');
    }

    return addEntry(
      amountMinor: target.amountMinor,
      contributorName: target.contributorName,
      note: note,
      status: EntryStatus.approved,
      reversesEntryId: target.id,
    );
  }

  Future<void> _reload() async {
    _entries = await _repository.getAll(fundId: fundId);
    _summary = null;
    notifyListeners();
  }
}
