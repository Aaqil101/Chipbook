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

/// Explains why a sign-in request could not be made.
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
        'Too many sign-in attempts were made. '
        'Wait a few minutes and try again.',
        error,
      );
    }

    final message = error.message.trim();
    final lowered = message.toLowerCase();
    if (error.code == 'otp_expired' ||
        lowered.contains('expired') ||
        lowered.contains('invalid token') ||
        lowered.contains('invalid otp')) {
      return AuthFailure(
        'That code is incorrect or has expired. '
        'Check the email and try again, or send a new code.',
        error,
      );
    }

    if (message.isNotEmpty) {
      return AuthFailure(message, error);
    }
  }

  return AuthFailure(
    'Could not sign in. Check your connection and try again.',
    error,
  );
}

/// Explains why a sign-in could not be completed.
///
/// This arrives on the auth state stream rather than from a call the UI makes,
/// and the raw text is usually about internals the user cannot act on.
AuthFailure signInFailure(Object error) {
  if (kDebugMode) {
    debugPrint('sign-in failed: $error');
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (error.code == 'otp_expired' || message.contains('expired')) {
      return AuthFailure(
        'That code has expired or was already used. Send a new one.',
        error,
      );
    }
  }

  return AuthFailure('Could not sign in. Try again.', error);
}
