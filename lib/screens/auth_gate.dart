import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../repositories/entry_repository.dart';
import '../repositories/fund_repository.dart';
import '../repositories/membership_repository.dart';
import 'sign_in_page.dart';
import 'signed_in_page.dart';

/// Shows the ledger only when a session exists.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.fundRepository,
    required this.entryRepository,
    required this.membershipRepository,
  });

  final AuthController auth;
  final FundRepository fundRepository;
  final EntryRepository entryRepository;
  final MembershipRepository membershipRepository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (!auth.isSignedIn) {
          return SignInPage(auth: auth);
        }
        return SignedInPage(
          auth: auth,
          fundRepository: fundRepository,
          entryRepository: entryRepository,
          membershipRepository: membershipRepository,
        );
      },
    );
  }
}
