import 'package:supabase_flutter/supabase_flutter.dart';

import 'magic_link_redirect.dart';

/// Authentication operations the app needs, independent of Supabase.
abstract interface class AuthService {
  bool get isSignedIn;

  /// Supabase user id, or null when signed out.
  String? get userId;

  String? get email;

  /// Emits whenever the signed-in state changes.
  Stream<bool> get signedInChanges;

  Future<void> sendMagicLink(String email);

  Future<void> signOut();
}

/// Supabase-backed [AuthService].
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  String? get email => _client.auth.currentUser?.email;

  @override
  Stream<bool> get signedInChanges => _client.auth.onAuthStateChange
      .map((state) => state.session != null)
      .distinct();

  @override
  Future<void> sendMagicLink(String email) {
    return _client.auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: magicLinkRedirect(),
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
