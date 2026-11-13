import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/models/member_role.dart';

void main() {
  group('MemberRole', () {
    test('codes match the database enum', () {
      expect(MemberRole.organizer.code, 'organizer');
      expect(MemberRole.member.code, 'member');
      expect(MemberRole.observer.code, 'observer');
    });

    test('labels match the UI vocabulary', () {
      expect(MemberRole.organizer.label, 'Organizer');
      expect(MemberRole.member.label, 'Member');
      expect(MemberRole.observer.label, 'Observer');
    });

    test('fromCode round-trips every role', () {
      for (final role in MemberRole.values) {
        expect(MemberRole.fromCode(role.code), role);
      }
    });

    test('fromCode rejects unknown codes', () {
      expect(() => MemberRole.fromCode('owner'), throwsArgumentError);
    });
  });
}
