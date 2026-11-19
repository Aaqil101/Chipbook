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
import '../state/theme_controller.dart';
import 'landing_page.dart';
import 'profile_setup_page.dart';
import 'sign_in_page.dart';
import 'signed_in_page.dart';

/// Shows the ledger only when a session exists and a username has been chosen.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.themes,
    required this.auth,
    required this.fundRepository,
    required this.entryRepository,
    required this.membershipRepository,
    required this.inviteRepository,
    required this.profileRepository,
  });

  final ThemeController themes;
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
          return _SignedOutGate(auth: auth);
        }

        final userId = auth.userId;
        if (userId == null) {
          return _ProfileLoadingPage(onSignOut: auth.signOut);
        }

        return _ProfileGate(
          key: ValueKey<String>(userId),
          themes: themes,
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

/// Explains the app before the sign-in form, and returns to that explanation.
///
/// The state lives here rather than in [AuthGate] so signing out lands on the
/// landing page again: this subtree is dropped while a session exists.
class _SignedOutGate extends StatefulWidget {
  const _SignedOutGate({required this.auth});

  final AuthController auth;

  @override
  State<_SignedOutGate> createState() => _SignedOutGateState();
}

class _SignedOutGateState extends State<_SignedOutGate> {
  bool _showSignIn = false;

  @override
  Widget build(BuildContext context) {
    if (!_showSignIn) {
      return LandingPage(onSignIn: () => setState(() => _showSignIn = true));
    }

    return SignInPage(
      auth: widget.auth,
      onBack: () => setState(() => _showSignIn = false),
    );
  }
}

/// Loads the profile before the app, so a new account sees the setup screen.
class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    super.key,
    required this.themes,
    required this.auth,
    required this.userId,
    required this.profileRepository,
    required this.fundRepository,
    required this.entryRepository,
    required this.membershipRepository,
    required this.inviteRepository,
  });

  final ThemeController themes;
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
          themes: widget.themes,
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
