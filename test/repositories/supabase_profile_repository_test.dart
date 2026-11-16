import 'package:chipbook/repositories/supabase_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('parses a profile row and converts its timestamp', () {
    final profile = parseProfileRow({
      'user_id': '11111111-1111-4111-8111-111111111111',
      'username': 'ada_l',
      'created_at': '2026-11-16T03:03:43.14981+00:00',
    });

    expect(profile.userId, '11111111-1111-4111-8111-111111111111');
    expect(profile.username, 'ada_l');
    expect(profile.createdAt.isUtc, isFalse);
    expect(
      profile.createdAt.toUtc(),
      DateTime.utc(2026, 11, 16, 3, 3, 43, 149, 810),
    );
  });

  test('a duplicate username asks for another one', () {
    final failure = profileSaveFailure(
      const PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      ),
    );

    expect(failure.message, 'That username is taken.');
  });

  test('a username rejected by the database check is explained', () {
    final failure = profileSaveFailure(
      const PostgrestException(
        message: 'check constraint failed',
        code: '23514',
      ),
    );

    expect(failure.message, 'That username is not allowed.');
  });

  test('an unexpected save failure keeps the connection hint', () {
    final failure = profileSaveFailure(Exception('SocketException'));

    expect(failure.message, contains('Check your connection'));
  });
}
