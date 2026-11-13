import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../domain/currency.dart';
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

  /// ISO 4217 code every entry in this fund is recorded in.
  final String currency;

  List<Entry> _entries = const <Entry>[];
  LedgerSummary? _summary;
  bool _isLoading = false;

  /// Every entry in repository (append) order.
  List<Entry> get entries => _entries;

  /// Per-currency totals and the approved/pending split, newest first.
  LedgerSummary get summary =>
      _summary ??= LedgerSummary.from(_entries, defaultCurrency: currency);

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

  /// Appends a new entry in the fund's [currency] and refreshes the state.
  ///
  /// Unknown ISO 4217 codes are rejected before anything reaches the
  /// repository. A [kind] of [EntryKind.payout] that is not a reversal is
  /// always approved, because paying money out is an organizer decision, and
  /// requires a non-empty [note] as its reason.
  Future<Entry> addEntry({
    required int amountMinor,
    required String contributorName,
    String note = '',
    EntryStatus status = EntryStatus.pending,
    String? reversesEntryId,
    EntryKind kind = EntryKind.contribution,
  }) {
    return _insert(
      amountMinor: amountMinor,
      contributorName: contributorName,
      note: note,
      currency: currency,
      status: status,
      reversesEntryId: reversesEntryId,
      kind: kind,
    );
  }

  /// Approves a pending entry. Organizers only, enforced by the backend.
  Future<void> approve(String entryId) async {
    await _repository.approve(fundId: fundId, entryId: entryId);
    await _reload();
  }

  /// Deletes a pending entry. Organizers only, enforced by the backend.
  ///
  /// Approved entries cannot be deleted; correct them with [reverse] instead.
  Future<void> deletePending(String entryId) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) {
      throw ArgumentError.value(entryId, 'entryId', 'no such entry');
    }
    if (_entries[index].isApproved) {
      throw ArgumentError.value(
        entryId,
        'entryId',
        'only pending entries can be deleted',
      );
    }

    await _repository.deletePending(fundId: fundId, entryId: entryId);
    await _reload();
  }

  /// Records a new approved entry that reverses [target].
  ///
  /// Reversals carry the original amount, contributor, currency, and kind, so
  /// only the fund's figures change. The original entry is never changed.
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

    return _insert(
      amountMinor: target.amountMinor,
      contributorName: target.contributorName,
      note: note,
      currency: target.currency,
      status: EntryStatus.approved,
      reversesEntryId: target.id,
      kind: target.kind,
    );
  }

  Future<Entry> _insert({
    required int amountMinor,
    required String contributorName,
    required String note,
    required String currency,
    required EntryStatus status,
    required String? reversesEntryId,
    required EntryKind kind,
  }) async {
    final isPayout = kind == EntryKind.payout && reversesEntryId == null;
    final trimmedNote = note.trim();
    if (isPayout && trimmedNote.isEmpty) {
      throw ArgumentError.value(note, 'note', 'a payout needs a reason');
    }

    final entry = Entry(
      id: _uuid.v4(),
      fundId: fundId,
      amountMinor: amountMinor,
      currency: _normalizeCurrency(currency),
      contributorName: contributorName.trim(),
      note: trimmedNote,
      createdAt: _clock(),
      status: isPayout ? EntryStatus.approved : status,
      reversesEntryId: reversesEntryId,
      kind: kind,
    );

    await _repository.add(entry);
    await _reload();
    return entry;
  }

  String _normalizeCurrency(String raw) {
    final code = raw.trim().toUpperCase();
    if (CurrencyCatalog.byCode(code) == null) {
      throw ArgumentError.value(
        raw,
        'currency',
        'not a supported ISO 4217 currency',
      );
    }
    return code;
  }

  Future<void> _reload() async {
    _entries = await _repository.getAll(fundId: fundId);
    _summary = null;
    notifyListeners();
  }
}
