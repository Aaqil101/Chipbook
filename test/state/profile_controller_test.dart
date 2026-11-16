import 'package:chipbook/models/profile.dart';
import 'package:chipbook/repositories/profile_repository.dart';
import 'package:chipbook/repositories/repository_exception.dart';
import 'package:chipbook/state/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository implements ProfileRepository {
  Profile? profile;
  Object? loadError;
  Object? saveError;
  int saveCount = 0;

  @override
  Future<Profile?> getProfile({required String userId}) async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return profile;
  }

  @override
  Future<Profile> saveUsername({
    required String userId,
    required String username,
  }) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }
    saveCount++;
    final saved = Profile(
      userId: userId,
      username: username,
      createdAt: DateTime(2026, 1, 1),
    );
    profile = saved;
    return saved;
  }
}

Profile _profile(String username) {
  return Profile(
    userId: 'user-1',
    username: username,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('starts loading and exposes the saved profile', () async {
    final repository = _FakeProfileRepository()..profile = _profile('ada');
    final controller = ProfileController(repository, userId: 'user-1');
    addTearDown(controller.dispose);

    expect(controller.isLoading, isTrue);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.profile?.username, 'ada');
  });

  test('a missing profile means the setup screen is due', () async {
    final repository = _FakeProfileRepository();
    final controller = ProfileController(repository, userId: 'user-1');
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.profile, isNull);
  });

  test('a load failure is reported and cleared on retry', () async {
    final repository = _FakeProfileRepository()
      ..loadError = const RepositoryException('offline');
    final controller = ProfileController(repository, userId: 'user-1');
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.error, 'offline');

    repository.loadError = null;
    repository.profile = _profile('ada');
    await controller.load();

    expect(controller.error, isNull);
    expect(controller.profile?.username, 'ada');
  });

  test('saving a username notifies listeners', () async {
    final repository = _FakeProfileRepository();
    final controller = ProfileController(repository, userId: 'user-1');
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setUsername('ada_l');

    expect(controller.profile?.username, 'ada_l');
    expect(repository.saveCount, 1);
    expect(notifications, 1);
  });

  test('a rejected username is rethrown for the form to show', () async {
    final repository = _FakeProfileRepository()
      ..saveError = const RepositoryException('That username is taken.');
    final controller = ProfileController(repository, userId: 'user-1');
    addTearDown(controller.dispose);

    await expectLater(
      controller.setUsername('ada'),
      throwsA(
        isA<RepositoryException>().having(
          (error) => error.message,
          'message',
          'That username is taken.',
        ),
      ),
    );
    expect(controller.profile, isNull);
  });
}
