import 'member_role.dart';

/// A user's role within a single fund.
class Membership {
  const Membership({
    required this.fundId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.username,
  });

  final String fundId;
  final String userId;
  final MemberRole role;
  final DateTime createdAt;

  /// The handle the user chose, as returned by the member directory.
  ///
  /// Empty when the user has not set a profile yet.
  final String username;

  /// Name to show in the member list.
  String get displayName {
    final value = username.trim();
    return value.isEmpty ? userId : value;
  }
}
