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

  test('an expired or reused link asks for a new one', () {
    final failure = linkFailure(
      const AuthException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      ),
    );

    expect(failure.message, contains('expired or was already used'));
  });

  test('a link from another device explains why it cannot be used', () {
    final failure = linkFailure(
      const AuthException('Code verifier could not be found in local storage.'),
    );

    expect(failure.message, contains('cannot be used on this device'));
  });

  test('an unexplained link failure still offers a new link', () {
    final failure = linkFailure(Exception('boom'));

    expect(failure.message, contains('Send a new one'));
  });
}
