import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_failure.dart';
import 'auth_redirect.dart';

/// Authentication operations the app needs, independent of Supabase.
abstract interface class AuthService {
  bool get isSignedIn;

  /// Supabase user id, or null when signed out.
  String? get userId;

  String? get email;

  /// The provider behind the current session, such as `google` or `email`.
  String? get provider;

  /// Emits whenever the signed-in state changes.
  Stream<bool> get signedInChanges;

  Future<void> signInWithGoogle();

  /// Emails a 6-digit sign-in code.
  Future<void> sendSignInCode(String email);

  /// Completes the sign-in with the code from [sendSignInCode].
  Future<void> verifySignInCode(String email, String code);

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
  String? get provider {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final provider = user.appMetadata['provider'];
    if (provider is String && provider.isNotEmpty) {
      return provider;
    }

    final identities = user.identities;
    if (identities != null && identities.isNotEmpty) {
      return identities.first.provider;
    }
    return null;
  }

  @override
  Stream<bool> get signedInChanges => _client.auth.onAuthStateChange
      .map((state) => state.session != null)
      .distinct();

  @override
  Future<void> signInWithGoogle() async {
    try {
      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: authRedirect(),
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthFailure('Could not open Google sign-in. Try again.');
      }
    } on AuthFailure {
      rethrow;
    } on Object catch (error) {
      throw authFailure(error);
    }
  }

  @override
  Future<void> sendSignInCode(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email.trim());
    } catch (error) {
      throw authFailure(error);
    }
  }

  @override
  Future<void> verifySignInCode(String email, String code) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.email,
      );
    } catch (error) {
      throw authFailure(error);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
