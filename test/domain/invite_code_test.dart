import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/invite_code.dart';

const _token = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

void main() {
  group('InviteCode', () {
    test('accepts a bare uuid and normalizes case', () {
      expect(
        InviteCode.tryParse('AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE'),
        _token,
      );
    });

    test('extracts the invite parameter from a link', () {
      expect(
        InviteCode.tryParse('https://chipbook.example/?invite=$_token'),
        _token,
      );
    });

    test('rejects malformed codes', () {
      expect(InviteCode.tryParse(''), isNull);
      expect(InviteCode.tryParse('not-a-code'), isNull);
      expect(InviteCode.tryParse('https://chipbook.example/'), isNull);
      expect(InviteCode.error('not-a-code'), isNotNull);
    });
  });
}
