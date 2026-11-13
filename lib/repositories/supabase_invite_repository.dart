import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invite.dart';
import '../models/member_role.dart';
import 'invite_repository.dart';
import 'repository_exception.dart';
import 'supabase_errors.dart';

/// Supabase-backed [InviteRepository].
///
/// Organizer-only table access is enforced by RLS. Acceptance goes through
/// the `accept_invite` function so invitees never touch the invites table.
class SupabaseInviteRepository implements InviteRepository {
  SupabaseInviteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Invite>> getPendingInvites({required String fundId}) async {
    try {
      final rows = await _client
          .from('invites')
          .select()
          .eq('fund_id', fundId)
          .isFilter('accepted_at', null)
          .order('created_at', ascending: false);
      return rows.map(_inviteFromRow).toList();
    } on Object catch (error) {
      throw supabaseFailure('Could not load invites', error);
    }
  }

  @override
  Future<Invite> createInvite({
    required String fundId,
    required String email,
    required MemberRole role,
  }) async {
    try {
      final row = await _client
          .from('invites')
          .insert({'fund_id': fundId, 'email': email.trim(), 'role': role.code})
          .select()
          .single();
      return _inviteFromRow(row);
    } on Object catch (error) {
      throw supabaseFailure('Could not create the invite', error);
    }
  }

  @override
  Future<void> cancelInvite({
    required String fundId,
    required String inviteId,
  }) async {
    try {
      final rows = await _client
          .from('invites')
          .delete()
          .eq('id', inviteId)
          .eq('fund_id', fundId)
          .select('id');
      if (rows.isEmpty) {
        throw const RepositoryException('Invite could not be cancelled.');
      }
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure('Could not cancel the invite', error);
    }
  }

  @override
  Future<String> acceptInvite({required String token}) async {
    try {
      final result = await _client.rpc<dynamic>(
        'accept_invite',
        params: {'invite_token': token},
      );
      if (result is String) {
        return result;
      }
      throw const RepositoryException('Invite could not be accepted.');
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw supabaseFailure('Could not accept the invite', error);
    }
  }

  Invite _inviteFromRow(Map<String, dynamic> row) {
    return Invite(
      id: row['id'] as String,
      fundId: row['fund_id'] as String,
      email: row['email'] as String,
      role: MemberRole.fromCode(row['role'] as String),
      token: row['token'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
      acceptedAt: row['accepted_at'] == null
          ? null
          : DateTime.parse(row['accepted_at'] as String).toLocal(),
    );
  }
}
