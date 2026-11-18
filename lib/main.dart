import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_info.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'repositories/entry_repository.dart';
import 'repositories/fund_repository.dart';
import 'repositories/invite_repository.dart';
import 'repositories/membership_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/shared_preferences_store.dart';
import 'repositories/supabase_entry_repository.dart';
import 'repositories/supabase_fund_repository.dart';
import 'repositories/supabase_invite_repository.dart';
import 'repositories/supabase_membership_repository.dart';
import 'repositories/supabase_profile_repository.dart';
import 'screens/auth_gate.dart';
import 'screens/splash_page.dart';
import 'state/theme_controller.dart';
import 'supabase_config.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the appearance choice before the first frame, so a saved Dark or
  // Light preference never starts with a flash of the other theme.
  final themes = ThemeController(SharedPreferencesStore());
  await themes.load();

  if (!SupabaseConfig.isConfigured) {
    runApp(_MissingConfigApp(themes: themes));
    return;
  }

  // The web splash is plain HTML and stays up until Flutter's first frame, so
  // initializing before runApp avoids showing a second splash there.
  if (kIsWeb) {
    await _initializeSupabase();
    runApp(_buildApp(Supabase.instance.client, themes));
    return;
  }

  runApp(_StartupApp(themes: themes));
}

Future<void> _initializeSupabase() {
  return Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
}

ChipbookApp _buildApp(SupabaseClient client, ThemeController themes) {
  return ChipbookApp(
    themes: themes,
    auth: AuthController(SupabaseAuthService(client)),
    fundRepository: SupabaseFundRepository(client),
    entryRepository: SupabaseEntryRepository(client),
    membershipRepository: SupabaseMembershipRepository(client),
    inviteRepository: SupabaseInviteRepository(client),
    profileRepository: SupabaseProfileRepository(client),
  );
}

/// Initializes Supabase behind the animated splash on mobile.
class _StartupApp extends StatefulWidget {
  const _StartupApp({required this.themes});

  final ThemeController themes;

  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  /// Long enough for the splash animation to read as deliberate.
  static const _minimumSplash = Duration(milliseconds: 1800);

  AuthController? _auth;
  FundRepository? _fundRepository;
  EntryRepository? _entryRepository;
  MembershipRepository? _membershipRepository;
  InviteRepository? _inviteRepository;
  ProfileRepository? _profileRepository;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (_error != null) {
      setState(() => _error = null);
    }

    final started = DateTime.now();
    try {
      await _initializeSupabase();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
      return;
    }

    final client = Supabase.instance.client;
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minimumSplash) {
      await Future<void>.delayed(_minimumSplash - elapsed);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _auth = AuthController(SupabaseAuthService(client));
      _fundRepository = SupabaseFundRepository(client);
      _entryRepository = SupabaseEntryRepository(client);
      _membershipRepository = SupabaseMembershipRepository(client);
      _inviteRepository = SupabaseInviteRepository(client);
      _profileRepository = SupabaseProfileRepository(client);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    final error = _error;

    return _ThemedApp(
      themes: widget.themes,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: error != null
            ? _StartupErrorPage(
                key: const ValueKey<String>('error'),
                onRetry: () => unawaited(_initialize()),
              )
            : auth == null
            ? const SplashPage(key: ValueKey<String>('splash'))
            : AuthGate(
                key: const ValueKey<String>('app'),
                themes: widget.themes,
                auth: auth,
                fundRepository: _fundRepository!,
                entryRepository: _entryRepository!,
                membershipRepository: _membershipRepository!,
                inviteRepository: _inviteRepository!,
                profileRepository: _profileRepository!,
              ),
      ),
    );
  }
}

/// Supplies both schemes and the saved mode to the whole app.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.themes, required this.home});

  final ThemeController themes;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themes,
      builder: (context, _) => MaterialApp(
        title: AppInfo.name,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themes.themeMode,
        home: home,
      ),
    );
  }
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not start ${AppInfo.name}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
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

class ChipbookApp extends StatelessWidget {
  const ChipbookApp({
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
    return _ThemedApp(
      themes: themes,
      home: AuthGate(
        themes: themes,
        auth: auth,
        fundRepository: fundRepository,
        entryRepository: entryRepository,
        membershipRepository: membershipRepository,
        inviteRepository: inviteRepository,
        profileRepository: profileRepository,
      ),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp({required this.themes});

  final ThemeController themes;

  @override
  Widget build(BuildContext context) {
    return _ThemedApp(
      themes: themes,
      home: const _MissingConfigPage(),
    );
  }
}

class _MissingConfigPage extends StatelessWidget {
  const _MissingConfigPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Supabase is not configured',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Copy .env.example to .env, fill in the project URL and '
                'publishable key, then run with '
                '--dart-define-from-file=.env.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
