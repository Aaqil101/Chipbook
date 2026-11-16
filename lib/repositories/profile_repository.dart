import '../models/profile.dart';

/// The signed-in user's profile.
abstract interface class ProfileRepository {
  /// Returns the profile for [userId], or null when it has not been set up.
  Future<Profile?> getProfile({required String userId});

  /// Creates or renames the profile for [userId].
  ///
  /// Throws a `RepositoryException` when the username is already taken.
  Future<Profile> saveUsername({
    required String userId,
    required String username,
  });
}
