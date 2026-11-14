import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A sign-in failure with a message the sign-in screen can show.
class AuthFailure implements Exception {
  const AuthFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Explains why a magic link could not be sent.
///
/// Supabase reports rate limits and rejected addresses as [AuthException].
/// Those are not connection problems, so keep its message instead of telling
/// the user to check the network.
AuthFailure authFailure(Object error) {
  if (kDebugMode) {
    debugPrint('sign-in failed: $error');
  }

  if (error is AuthException) {
    if (error.statusCode == '429') {
      return AuthFailure(
        'Too many sign-in emails were requested. '
        'Wait a few minutes and try again.',
        error,
      );
    }

    final message = error.message.trim();
    if (message.isNotEmpty) {
      return AuthFailure(message, error);
    }
  }

  return AuthFailure(
    'Could not send the link. Check your connection and try again.',
    error,
  );
}

/// Explains why a magic link could not be used.
///
/// This arrives on the auth state stream rather than from a call the UI makes,
/// and the raw text is usually about PKCE internals the user cannot act on.
AuthFailure linkFailure(Object error) {
  if (kDebugMode) {
    debugPrint('magic link failed: $error');
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (error.code == 'otp_expired' || message.contains('expired')) {
      return AuthFailure(
        'That link has expired or was already used. Send a new one.',
        error,
      );
    }

    if (message.contains('code verifier')) {
      return AuthFailure(
        'That link cannot be used on this device. Send a new one.',
        error,
      );
    }
  }

  return AuthFailure(
    'Could not sign in with that link. Send a new one.',
    error,
  );
}
