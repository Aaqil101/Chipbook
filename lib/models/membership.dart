import 'member_role.dart';

/// A user's role within a single fund.
class Membership {
  const Membership({
    required this.fundId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.email,
  });

  final String fundId;
  final String userId;
  final MemberRole role;
  final DateTime createdAt;

  /// Email address from the auth directory, when the backend provides it.
  final String? email;

  /// Name to show in the member list.
  String get displayName {
    final value = email?.trim() ?? '';
    return value.isEmpty ? userId : value;
  }
}
