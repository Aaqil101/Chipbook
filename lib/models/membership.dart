import 'member_role.dart';

/// A user's role within a single fund.
class Membership {
  const Membership({
    required this.fundId,
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  final String fundId;
  final String userId;
  final MemberRole role;
  final DateTime createdAt;
}
