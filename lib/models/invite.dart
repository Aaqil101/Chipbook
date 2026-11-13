import 'member_role.dart';

/// A pending invitation to join a fund.
class Invite {
  const Invite({
    required this.id,
    required this.fundId,
    required this.email,
    required this.role,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
  });

  final String id;
  final String fundId;
  final String email;
  final MemberRole role;

  /// Secret the invitee redeems after signing in with [email].
  final String token;

  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  bool get isAccepted => acceptedAt != null;

  /// Whether the invite can no longer be redeemed at [now].
  bool isExpiredAt(DateTime now) => !isAccepted && !expiresAt.isAfter(now);
}
