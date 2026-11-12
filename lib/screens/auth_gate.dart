import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../state/ledger_controller.dart';
import 'entries_page.dart';
import 'sign_in_page.dart';

/// Shows the ledger only when a session exists.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, required this.ledger});

  final AuthController auth;
  final LedgerController ledger;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (!auth.isSignedIn) {
          return SignInPage(auth: auth);
        }
        return EntriesPage(controller: ledger, onSignOut: auth.signOut);
      },
    );
  }
}
