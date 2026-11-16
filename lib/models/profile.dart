/// A user's public handle and the only profile data Chipbook stores.
class Profile {
  const Profile({
    required this.userId,
    required this.username,
    required this.createdAt,
  });

  final String userId;
  final String username;
  final DateTime createdAt;
}
