import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../domain/fund_permissions.dart';
import '../models/fund.dart';
import 'about_page.dart';

/// Account, current fund management, and app information.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.fund,
    this.permissions,
    this.email,
    this.onManageFund,
    this.onSignOut,
  });

  /// The fund currently shown in the Ledger tab.
  final Fund fund;

  /// The signed-in user's role in [fund], or null until it is known.
  final FundPermissions? permissions;

  final String? email;

  /// Opens timing, target, archive, and delete actions for [fund].
  final VoidCallback? onManageFund;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = permissions?.canManageFund ?? false;
    final signOut = onSignOut;
    final account = email;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionHeader(title: 'Account'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(account ?? 'Signed in'),
                  subtitle: Text(
                    account == null
                        ? 'Magic-link session'
                        : 'Signed in with a magic link',
                  ),
                ),
                if (signOut != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: signOut,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Current fund'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(fund.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${fund.defaultCurrency} · ${fund.cadence.label}',
                  ),
                ),
                if (canManage) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Manage fund'),
                    subtitle: const Text('Timing, target, archive, or delete'),
                    onTap: onManageFund,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('About ${AppInfo.name}'),
              subtitle: Text(AppInfo.tagline),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const AboutPage()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${AppInfo.name} only keeps the record. It never moves money.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
