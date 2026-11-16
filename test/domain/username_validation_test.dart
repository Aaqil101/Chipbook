import 'package:chipbook/domain/username_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts lowercase letters, digits, and underscores', () {
    for (final value in ['ada', 'ada_lovelace', 'user_01', 'abc']) {
      expect(UsernameValidation.error(value), isNull, reason: value);
    }
  });

  test('requires a username', () {
    expect(UsernameValidation.error(''), 'Choose a username');
    expect(UsernameValidation.error('   '), 'Choose a username');
  });

  test('enforces the length bounds', () {
    expect(UsernameValidation.error('ab'), 'Use at least 3 characters');
    expect(UsernameValidation.error('a' * 21), 'Use 20 characters or fewer');
    expect(UsernameValidation.error('a' * 20), isNull);
  });

  test('rejects uppercase letters', () {
    expect(UsernameValidation.error('Ada'), 'Use lowercase letters only');
    expect(UsernameValidation.error('ADA'), 'Use lowercase letters only');
  });

  test('rejects spaces and punctuation', () {
    expect(
      UsernameValidation.error('ada lovelace'),
      'Use letters, numbers, and underscores only',
    );
    expect(
      UsernameValidation.error('ada-lovelace'),
      'Use letters, numbers, and underscores only',
    );
    expect(
      UsernameValidation.error('ada@example.com'),
      'Use letters, numbers, and underscores only',
    );
  });

  test('trims before validating', () {
    expect(UsernameValidation.error('  ada  '), isNull);
  });
}
