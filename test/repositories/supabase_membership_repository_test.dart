import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/models/member_role.dart';
import 'package:chipbook/repositories/supabase_membership_repository.dart';

const _fundId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  test('parses a member directory row without a fund id column', () {
    final membership = parseMemberDirectoryRow({
      'user_id': '11111111-1111-4111-8111-111111111111',
      'email': 'organizer@example.com',
      'role': 'organizer',
      'created_at': '2026-11-13T03:03:43.14981+00:00',
    }, _fundId);

    expect(membership.fundId, _fundId);
    expect(membership.userId, '11111111-1111-4111-8111-111111111111');
    expect(membership.role, MemberRole.organizer);
    expect(membership.email, 'organizer@example.com');
    expect(membership.createdAt.isUtc, isFalse);
    expect(
      membership.createdAt.toUtc(),
      DateTime.utc(2026, 11, 13, 3, 3, 43, 149, 810),
    );
  });

  test('keeps the queried fund when the row has no fund id', () {
    final membership = parseMemberDirectoryRow({
      'user_id': '22222222-2222-4222-8222-222222222222',
      'email': '',
      'role': 'observer',
      'created_at': '2026-11-13T03:03:43.14981+00:00',
    }, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');

    expect(membership.fundId, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
    expect(membership.role, MemberRole.observer);
    expect(membership.email, '');
    expect(membership.displayName, isNotEmpty);
  });
}
