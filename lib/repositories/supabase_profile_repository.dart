import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'profile_repository.dart';
import 'repository_exception.dart';
import 'supabase_errors.dart';

/// Supabase-backed [ProfileRepository]. Row Level Security keeps each profile
/// readable and writable by its owner only.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile?> getProfile({required String userId}) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : parseProfileRow(row);
    } on Object catch (error) {
      throw supabaseFailure('Could not load your profile', error);
    }
  }

  @override
  Future<Profile> saveUsername({
    required String userId,
    required String username,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .upsert({
            'user_id': userId,
            'username': username.trim(),
          }, onConflict: 'user_id')
          .select()
          .single();
      return parseProfileRow(row);
    } on Object catch (error) {
      throw profileSaveFailure(error);
    }
  }
}

/// Builds a [Profile] from a `profiles` row.
@visibleForTesting
Profile parseProfileRow(Map<String, dynamic> row) {
  return Profile(
    userId: row['user_id'] as String,
    username: row['username'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

/// Turns a rejected username into a message the setup screen can show.
@visibleForTesting
RepositoryException profileSaveFailure(Object error) {
  if (error is PostgrestException) {
    if (error.code == '23505') {
      return RepositoryException('That username is taken.', error);
    }
    if (error.code == '23514') {
      return RepositoryException('That username is not allowed.', error);
    }
  }
  return supabaseFailure('Could not save your username', error);
}
