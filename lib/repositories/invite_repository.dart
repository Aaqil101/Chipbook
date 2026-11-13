import '../models/invite.dart';
import '../models/member_role.dart';

/// Pending invites and invite redemption.
abstract interface class InviteRepository {
  /// Unaccepted invites for [fundId]. Organizers only, enforced by RLS.
  Future<List<Invite>> getPendingInvites({required String fundId});

  Future<Invite> createInvite({
    required String fundId,
    required String email,
    required MemberRole role,
  });

  Future<void> cancelInvite({required String fundId, required String inviteId});

  /// Redeems [token] for the signed-in user and returns the joined fund id.
  ///
  /// The backend verifies that the invite matches the user's email, has not
  /// expired, and has not already been used.
  Future<String> acceptInvite({required String token});
}
