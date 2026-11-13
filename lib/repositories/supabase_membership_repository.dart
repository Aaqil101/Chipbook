import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/member_role.dart';
import '../models/membership.dart';
import 'membership_repository.dart';
import 'repository_exception.dart';
import 'supabase_errors.dart';

/// Supabase-backed [MembershipRepository]. Organizer-only writes are
/// enforced by RLS and the last-organizer trigger.
class SupabaseMembershipRepository implements MembershipRepository {
  SupabaseMembershipRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Membership>> getMemberships({required String fundId}) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'list_fund_members',
        params: {'target_fund_id': fundId},
      );
      if (rows is! List) {
        throw const RepositoryException('Could not load members.');
      }
      return rows
          .cast<Map<String, dynamic>>()
          .map((row) => parseMemberDirectoryRow(row, fundId))
          .toList();
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure('Could not load members', error);
    }
  }

  @override
  Future<void> setRole({
    required String fundId,
    required String userId,
    required MemberRole role,
  }) async {
    try {
      final rows = await _client
          .from('memberships')
          .update({'role': role.code})
          .eq('fund_id', fundId)
          .eq('user_id', userId)
          .select('user_id');
      if (rows.isEmpty) {
        throw const RepositoryException('Membership could not be updated.');
      }
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure('Could not update the member', error);
    }
  }

  @override
  Future<void> removeMember({
    required String fundId,
    required String userId,
  }) async {
    try {
      final rows = await _client
          .from('memberships')
          .delete()
          .eq('fund_id', fundId)
          .eq('user_id', userId)
          .select('user_id');
      if (rows.isEmpty) {
        throw const RepositoryException('Membership could not be removed.');
      }
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure('Could not remove the member', error);
    }
  }
}

/// Builds a [Membership] from a `list_fund_members` row.
///
/// The function returns the directory fields but not the fund id, so the fund
/// that was queried is supplied by the caller.
@visibleForTesting
Membership parseMemberDirectoryRow(Map<String, dynamic> row, String fundId) {
  return Membership(
    fundId: fundId,
    userId: row['user_id'] as String,
    role: MemberRole.fromCode(row['role'] as String),
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    email: row['email'] as String?,
  );
}
