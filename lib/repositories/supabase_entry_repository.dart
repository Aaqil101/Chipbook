import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entry.dart';
import 'entry_repository.dart';
import 'repository_exception.dart';
import 'supabase_errors.dart';

/// Supabase-backed [EntryRepository].
class SupabaseEntryRepository implements EntryRepository {
  SupabaseEntryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Entry>> getAll({required String fundId}) async {
    try {
      final rows = await _client
          .from('entries')
          .select()
          .eq('fund_id', fundId)
          .order('created_at', ascending: false);
      return rows.map(_entryFromRow).toList();
    } on Object catch (error) {
      throw supabaseFailure('Could not load entries', error);
    }
  }

  @override
  Future<void> add(Entry entry) async {
    try {
      await _client.from('entries').insert({
        'id': entry.id,
        'fund_id': entry.fundId,
        'amount_minor': entry.amountMinor,
        'currency': entry.currency,
        'contributor_name': entry.contributorName,
        'note': entry.note,
        'status': entry.status == EntryStatus.approved ? 'approved' : 'pending',
        'reverses_entry_id': entry.reversesEntryId,
        'kind': entry.kind == EntryKind.payout ? 'payout' : 'contribution',
      });
    } on Object catch (error) {
      throw supabaseFailure('Could not add the entry', error);
    }
  }

  @override
  Future<void> approve({
    required String fundId,
    required String entryId,
  }) async {
    try {
      final rows = await _client
          .from('entries')
          .update({'status': 'approved'})
          .eq('id', entryId)
          .eq('fund_id', fundId)
          .select('id');
      if (rows.isEmpty) {
        throw const RepositoryException('Entry could not be approved.');
      }
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure('Could not approve the entry', error);
    }
  }

  Entry _entryFromRow(Map<String, dynamic> row) {
    return Entry(
      id: row['id'] as String,
      fundId: row['fund_id'] as String,
      amountMinor: (row['amount_minor'] as num).toInt(),
      currency: (row['currency'] as String).trim(),
      contributorName: row['contributor_name'] as String,
      note: (row['note'] as String?) ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: row['status'] == 'approved'
          ? EntryStatus.approved
          : EntryStatus.pending,
      reversesEntryId: row['reverses_entry_id'] as String?,
      kind: row['kind'] == 'payout' ? EntryKind.payout : EntryKind.contribution,
    );
  }
}
