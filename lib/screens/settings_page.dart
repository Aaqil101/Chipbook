import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../domain/fund_permissions.dart';
import '../domain/sign_in_provider.dart';
import '../models/fund.dart';
import '../state/theme_controller.dart';
import 'about_page.dart';
import 'rename_username_dialog.dart';

/// Account, current fund management, and app information.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.fund,
    required this.username,
    this.permissions,
    this.email,
    this.provider,
    this.themePreference = ThemePreference.system,
    this.onThemePreferenceChanged,
    this.onRenameUsername,
    this.onManageFund,
    this.onSignOut,
  });

  /// The fund currently shown in the Ledger tab.
  final Fund fund;

  /// The name other members see.
  final String username;

  /// The signed-in user's role in [fund], or null until it is known.
  final FundPermissions? permissions;

  /// The verified address behind the session, shown read-only.
  final String? email;

  /// The provider behind the session, such as `google` or `email`.
  final String? provider;

  /// The appearance choice this device is using.
  final ThemePreference themePreference;

  /// Applies a new appearance choice for this device.
  final ValueChanged<ThemePreference>? onThemePreferenceChanged;

  /// Opens the rename dialog for [username].
  final Future<void> Function(String username)? onRenameUsername;

  /// Opens timing, target, archive, and delete actions for [fund].
  final VoidCallback? onManageFund;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = permissions?.canManageFund ?? false;
    final signOut = onSignOut;
    final accountEmail = email;
    final rename = onRenameUsername;

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
                  title: Text('@$username'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (accountEmail != null)
                        Text(accountEmail, overflow: TextOverflow.ellipsis),
                      Text(signInProviderLabel(provider)),
                    ],
                  ),
                  trailing: rename == null
                      ? null
                      : IconButton(
                          tooltip: 'Change username',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _renameUsername(context, rename),
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
          const _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < ThemePreference.values.length;
                  index++
                ) ...[
                  if (index > 0) const Divider(height: 1),
                  _ThemeOption(
                    preference: ThemePreference.values[index],
                    selected:
                        ThemePreference.values[index] == themePreference,
                    onSelected: onThemePreferenceChanged,
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

  Future<void> _renameUsername(
    BuildContext context,
    Future<void> Function(String username) rename,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          RenameUsernameDialog(initialUsername: username, onSave: rename),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.preference,
    required this.selected,
    this.onSelected,
  });

  final ThemePreference preference;
  final bool selected;
  final ValueChanged<ThemePreference>? onSelected;

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;

    return ListTile(
      leading: Icon(_iconFor(preference)),
      title: Text(_labelFor(preference)),
      subtitle: Text(_descriptionFor(preference)),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onSelected == null ? null : () => onSelected(preference),
    );
  }

  static IconData _iconFor(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.system => Icons.brightness_auto_outlined,
      ThemePreference.light => Icons.light_mode_outlined,
      ThemePreference.dark => Icons.dark_mode_outlined,
    };
  }

  static String _labelFor(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.system => 'System',
      ThemePreference.light => 'Light',
      ThemePreference.dark => 'Dark',
    };
  }

  static String _descriptionFor(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.system => 'Match this device',
      ThemePreference.light => 'Always light',
      ThemePreference.dark => 'Always dark',
    };
  }
}
