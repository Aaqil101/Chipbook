import 'package:chipbook/auth/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('rate limiting asks the user to wait, not to check the network', () {
    final failure = authFailure(
      const AuthException('Email rate limit exceeded', statusCode: '429'),
    );

    expect(failure.message, contains('Wait a few minutes'));
    expect(failure.message, isNot(contains('connection')));
  });

  test('a rejected address keeps the message from the server', () {
    final failure = authFailure(
      const AuthException('Invalid email', statusCode: '400'),
    );

    expect(failure.message, 'Invalid email');
  });

  test('a transport failure falls back to the connection hint', () {
    final failure = authFailure(Exception('SocketException'));

    expect(failure.message, contains('Check your connection'));
  });

  test('a wrong or expired code points at the email', () {
    final wrong = authFailure(
      const AuthException('Invalid token', statusCode: '403'),
    );
    final expired = authFailure(
      const AuthException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      ),
    );

    expect(wrong.message, contains('code is incorrect or has expired'));
    expect(expired.message, contains('code is incorrect or has expired'));
    expect(expired.message, contains('send a new code'));
  });

  test('an expired code on the auth stream asks for a new one', () {
    final failure = signInFailure(
      const AuthException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      ),
    );

    expect(failure.message, contains('code has expired'));
  });

  test('an unexplained sign-in failure still asks the user to try again', () {
    final failure = signInFailure(Exception('boom'));

    expect(failure.message, contains('Try again'));
  });
}
