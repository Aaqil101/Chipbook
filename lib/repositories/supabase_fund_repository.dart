import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fund.dart';
import 'fund_repository.dart';
import 'repository_exception.dart';
import 'supabase_errors.dart';

/// Supabase-backed [FundRepository]. RLS limits reads to the user's funds.
class SupabaseFundRepository implements FundRepository {
  SupabaseFundRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Fund>> getFunds({bool includeArchived = false}) async {
    try {
      final query = _client.from('funds').select();
      final rows =
          await (includeArchived ? query : query.isFilter('archived_at', null))
              .order('created_at');
      return rows.map(_fundFromRow).toList();
    } on Object catch (error) {
      throw supabaseFailure('Could not load funds', error);
    }
  }

  @override
  Future<Fund> createFund({
    required String name,
    required String defaultCurrency,
  }) async {
    try {
      final row = await _client
          .from('funds')
          .insert({'name': name.trim(), 'default_currency': defaultCurrency})
          .select()
          .single();
      return _fundFromRow(row);
    } on Object catch (error) {
      throw supabaseFailure('Could not create the fund', error);
    }
  }

  @override
  Future<void> archiveFund(String fundId) =>
      _setArchived(fundId, archived: true);

  @override
  Future<void> restoreFund(String fundId) =>
      _setArchived(fundId, archived: false);

  Future<void> _setArchived(String fundId, {required bool archived}) async {
    try {
      final rows = await _client
          .from('funds')
          .update({
            'archived_at': archived
                ? DateTime.now().toUtc().toIso8601String()
                : null,
          })
          .eq('id', fundId)
          .select('id');
      if (rows.isEmpty) {
        throw const RepositoryException('This fund could not be updated.');
      }
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure(
        archived ? 'Could not archive the fund' : 'Could not restore the fund',
        error,
      );
    }
  }

  @override
  Future<void> deleteFund(String fundId) async {
    try {
      await _client.rpc<dynamic>(
        'delete_fund',
        params: {'target_fund_id': fundId},
      );
    } on Object catch (error) {
      throw supabaseFailure('Could not delete the fund', error);
    }
  }

  Fund _fundFromRow(Map<String, dynamic> row) {
    final archivedAt = row['archived_at'] as String?;
    return Fund(
      id: row['id'] as String,
      name: row['name'] as String,
      defaultCurrency: (row['default_currency'] as String).trim(),
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      archivedAt: archivedAt == null
          ? null
          : DateTime.parse(archivedAt).toLocal(),
    );
  }
}
