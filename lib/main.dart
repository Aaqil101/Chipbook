import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_info.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'repositories/entry_repository.dart';
import 'screens/auth_gate.dart';
import 'state/ledger_controller.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final auth = AuthController(SupabaseAuthService(Supabase.instance.client));
  final ledger = LedgerController(
    InMemoryEntryRepository(),
    fundId: _localFundId,
  );
  unawaited(ledger.load());

  runApp(ChipbookApp(auth: auth, ledger: ledger));
}

// Temporary scope until fund selection lands; entries stay local for now.
const _localFundId = 'local-fund';

class ChipbookApp extends StatelessWidget {
  const ChipbookApp({super.key, required this.auth, required this.ledger});

  final AuthController auth;
  final LedgerController ledger;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      theme: _theme(),
      home: AuthGate(auth: auth, ledger: ledger),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      theme: _theme(),
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

ThemeData _theme() {
  return ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal));
}
