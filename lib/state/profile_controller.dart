import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../repositories/profile_repository.dart';

/// Loads and saves the signed-in user's profile.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repository, {required this.userId});

  final ProfileRepository _repository;
  final String userId;

  Profile? _profile;
  bool _isLoading = true;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the profile, or null when the user has not chosen a username yet.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.getProfile(userId: userId);
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates or renames the profile.
  ///
  /// Errors are rethrown so the form that called this can show them inline.
  Future<void> setUsername(String username) async {
    _profile = await _repository.saveUsername(
      userId: userId,
      username: username,
    );
    _error = null;
    notifyListeners();
  }
}
