import '../models/member_role.dart';
import '../models/membership.dart';

/// Members and roles within a fund.
abstract interface class MembershipRepository {
  Future<List<Membership>> getMemberships({required String fundId});

  Future<void> setRole({
    required String fundId,
    required String userId,
    required MemberRole role,
  });

  Future<void> removeMember({required String fundId, required String userId});
}
