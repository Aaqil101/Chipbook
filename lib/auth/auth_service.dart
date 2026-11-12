import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication operations the app needs, independent of Supabase.
abstract interface class AuthService {
  bool get isSignedIn;

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
  String? get email => _client.auth.currentUser?.email;

  @override
  Stream<bool> get signedInChanges => _client.auth.onAuthStateChange
      .map((state) => state.session != null)
      .distinct();

  @override
  Future<void> sendMagicLink(String email) {
    return _client.auth.signInWithOtp(email: email.trim());
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
