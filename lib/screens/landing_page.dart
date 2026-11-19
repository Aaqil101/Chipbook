import 'package:material_ui/material_ui.dart';

import '../app_info.dart';

/// Signed-out entry point: explains Chipbook before asking for an email.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onSignIn});

  /// Opens the existing sign-in flow.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onSignIn: onSignIn),
                    const SizedBox(height: 20),
                    _Hero(onSignIn: onSignIn),
                    const SizedBox(height: 32),
                    const _FeatureGrid(),
                    const SizedBox(height: 32),
                    const _RecordOnlyNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.volunteer_activism,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          AppInfo.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(onPressed: onSignIn, child: const Text('Sign in')),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.12),
              scheme.primaryContainer,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppInfo.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppInfo.tagline,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep an honest shared record of who gave what, what was approved, '
            'and what was paid out. Chipbook only keeps the record. It never '
            'holds or moves money.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onSignIn,
            icon: const Icon(Icons.login),
            label: const Text('Sign in to Chipbook'),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _features = <({IconData icon, String title, String body})>[
    (
      icon: Icons.how_to_reg_outlined,
      title: 'Approvals you can trust',
      body:
          'Members add entries and organizers approve them. Approved entries '
          'are append-only, so the record cannot be quietly rewritten.',
    ),
    (
      icon: Icons.undo,
      title: 'Corrections, not edits',
      body:
          'A mistake becomes a reversal entry with a reason and the original '
          'amount attached, so history stays visible.',
    ),
    (
      icon: Icons.payments_outlined,
      title: 'Payouts and targets',
      body:
          'Record payouts against the balance, and track a weekly, monthly, '
          'yearly or one-off fund against its optional target.',
    ),
    (
      icon: Icons.lock_outline,
      title: 'Private by default',
      body:
          'Funds are visible only to their members, and people are shown by '
          'the username they choose rather than their email address.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What it does',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 2 : 1;
            final spacing = columns == 1 ? 12.0 : 16.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final feature in _features)
                  SizedBox(
                    width: itemWidth,
                    child: _FeatureCard(
                      icon: feature.icon,
                      title: feature.title,
                      body: feature.body,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordOnlyNote extends StatelessWidget {
  const _RecordOnlyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chipbook has no payments, wallets, or custody features. You and '
              'your friends still move money between yourselves; the app keeps '
              'the shared note of what happened.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
