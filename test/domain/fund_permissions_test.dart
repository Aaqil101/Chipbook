import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/fund_permissions.dart';
import 'package:chipbook/models/member_role.dart';

void main() {
  group('FundPermissions', () {
    test('observer can only view', () {
      const permissions = FundPermissions(MemberRole.observer);

      expect(permissions.canView, isTrue);
      expect(permissions.canAddEntry, isFalse);
      expect(permissions.canApprove, isFalse);
      expect(permissions.canReverse, isFalse);
      expect(permissions.canManageMembers, isFalse);
      expect(permissions.canManageFund, isFalse);
    });

    test('member can view and add entries', () {
      const permissions = FundPermissions(MemberRole.member);

      expect(permissions.canView, isTrue);
      expect(permissions.canAddEntry, isTrue);
      expect(permissions.canApprove, isFalse);
      expect(permissions.canReverse, isFalse);
      expect(permissions.canManageMembers, isFalse);
      expect(permissions.canManageFund, isFalse);
    });

    test('organizer can do everything', () {
      const permissions = FundPermissions(MemberRole.organizer);

      expect(permissions.canView, isTrue);
      expect(permissions.canAddEntry, isTrue);
      expect(permissions.canApprove, isTrue);
      expect(permissions.canReverse, isTrue);
      expect(permissions.canManageMembers, isTrue);
      expect(permissions.canManageFund, isTrue);
    });
  });
}
