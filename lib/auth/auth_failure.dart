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
