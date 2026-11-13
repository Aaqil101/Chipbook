/// Role a user holds within a single fund.
///
/// [code] matches the `member_role` enum in Postgres and [label] is the
/// user-facing name.
enum MemberRole {
  organizer('organizer', 'Organizer'),
  member('member', 'Member'),
  observer('observer', 'Observer');

  const MemberRole(this.code, this.label);

  final String code;
  final String label;

  static MemberRole fromCode(String code) {
    for (final role in values) {
      if (role.code == code) {
        return role;
      }
    }
    throw ArgumentError.value(code, 'code', 'unknown member role');
  }
}
