import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/invite_validation.dart';

void main() {
  group('InviteValidation', () {
    test('accepts a normal email address', () {
      expect(InviteValidation.emailError('ada@example.com'), isNull);
    });

    test('requires an email address', () {
      expect(InviteValidation.emailError(''), 'Enter an email address');
      expect(InviteValidation.emailError('   '), 'Enter an email address');
    });

    test('rejects malformed addresses', () {
      expect(InviteValidation.emailError('ada'), isNotNull);
      expect(InviteValidation.emailError('ada@'), isNotNull);
      expect(InviteValidation.emailError('ada@example'), isNotNull);
      expect(InviteValidation.emailError('ada @example.com'), isNotNull);
    });
  });
}
