import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fund.dart';
import 'fund_repository.dart';
import 'supabase_errors.dart';

/// Supabase-backed [FundRepository]. RLS limits reads to the user's funds.
class SupabaseFundRepository implements FundRepository {
  SupabaseFundRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Fund>> getFunds() async {
    try {
      final rows = await _client.from('funds').select().order('created_at');
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

  Fund _fundFromRow(Map<String, dynamic> row) {
    return Fund(
      id: row['id'] as String,
      name: row['name'] as String,
      defaultCurrency: (row['default_currency'] as String).trim(),
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
