import '../models/member_role.dart';

/// What a [role] may do inside a single fund.
///
/// Mirrors the RLS policies in `supabase/migrations`; the database remains
/// the authority, and the UI uses this to avoid showing actions that will
/// fail.
class FundPermissions {
  const FundPermissions(this.role);

  final MemberRole role;

  /// Every member of a fund can read its ledger.
  bool get canView => true;

  bool get canAddEntry =>
      role == MemberRole.organizer || role == MemberRole.member;

  bool get canApprove => role == MemberRole.organizer;

  bool get canReverse => role == MemberRole.organizer;

  bool get canManageMembers => role == MemberRole.organizer;
}
