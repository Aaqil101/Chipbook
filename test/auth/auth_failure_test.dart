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
}
