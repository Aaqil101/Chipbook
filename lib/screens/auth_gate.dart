import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../auth/auth_controller.dart';
import '../repositories/entry_repository.dart';
import '../repositories/fund_repository.dart';
import '../repositories/invite_repository.dart';
import '../repositories/membership_repository.dart';
import '../repositories/profile_repository.dart';
import '../state/profile_controller.dart';
import 'profile_setup_page.dart';
import 'sign_in_page.dart';
import 'signed_in_page.dart';

/// Shows the ledger only when a session exists and a username has been chosen.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.fundRepository,
    required this.entryRepository,
    required this.membershipRepository,
    required this.inviteRepository,
    required this.profileRepository,
  });

  final AuthController auth;
  final FundRepository fundRepository;
  final EntryRepository entryRepository;
  final MembershipRepository membershipRepository;
  final InviteRepository inviteRepository;
  final ProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (!auth.isSignedIn) {
          return SignInPage(auth: auth);
        }

        final userId = auth.userId;
        if (userId == null) {
          return _ProfileLoadingPage(onSignOut: auth.signOut);
        }

        return _ProfileGate(
          key: ValueKey<String>(userId),
          auth: auth,
          userId: userId,
          profileRepository: profileRepository,
          fundRepository: fundRepository,
          entryRepository: entryRepository,
          membershipRepository: membershipRepository,
          inviteRepository: inviteRepository,
        );
      },
    );
  }
}

/// Loads the profile before the app, so a new account sees the setup screen.
class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    super.key,
    required this.auth,
    required this.userId,
    required this.profileRepository,
    required this.fundRepository,
    required this.entryRepository,
    required this.membershipRepository,
    required this.inviteRepository,
  });

  final AuthController auth;
  final String userId;
  final ProfileRepository profileRepository;
  final FundRepository fundRepository;
  final EntryRepository entryRepository;
  final MembershipRepository membershipRepository;
  final InviteRepository inviteRepository;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final ProfileController _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = ProfileController(
      widget.profileRepository,
      userId: widget.userId,
    );
    unawaited(_profiles.load());
  }

  @override
  void dispose() {
    _profiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _profiles,
      builder: (context, _) {
        if (_profiles.isLoading) {
          return _ProfileLoadingPage(onSignOut: widget.auth.signOut);
        }

        final error = _profiles.error;
        if (error != null) {
          return _ProfileErrorPage(
            message: error,
            onRetry: () => unawaited(_profiles.load()),
            onSignOut: widget.auth.signOut,
          );
        }

        final profile = _profiles.profile;
        if (profile == null) {
          return ProfileSetupPage(
            email: widget.auth.email,
            onSave: _profiles.setUsername,
          );
        }

        return SignedInPage(
          auth: widget.auth,
          profile: profile,
          onRenameUsername: _profiles.setUsername,
          fundRepository: widget.fundRepository,
          entryRepository: widget.entryRepository,
          membershipRepository: widget.membershipRepository,
          inviteRepository: widget.inviteRepository,
        );
      },
    );
  }
}

class _ProfileLoadingPage extends StatelessWidget {
  const _ProfileLoadingPage({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [
          IconButton(
            onPressed: onSignOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [
          IconButton(
            onPressed: onSignOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load your profile',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
