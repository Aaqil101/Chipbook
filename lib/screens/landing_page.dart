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
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onSignIn: onSignIn),
                    const SizedBox(height: 24),
                    _Hero(onSignIn: onSignIn),
                    const SizedBox(height: 40),
                    const _FeatureGrid(),
                    const SizedBox(height: 28),
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
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.volunteer_activism,
            size: 18,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppInfo.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
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
    final isDark = theme.brightness == Brightness.dark;

    // In dark mode a light-teal hero would glare against the page, so the
    // container tone carries the brand instead and the button supplies the
    // contrast.
    final heroBase = isDark ? scheme.primaryContainer : scheme.primary;
    final heroDeep = Color.alphaBlend(
      scheme.surface.withValues(alpha: isDark ? 0.35 : 0.28),
      heroBase,
    );
    final onHero = isDark ? scheme.onPrimaryContainer : scheme.onPrimary;
    final buttonBackground = isDark ? scheme.primary : scheme.surface;
    final buttonForeground = isDark ? scheme.onPrimary : scheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [heroBase, heroDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -80,
              child: _Glow(
                size: 280,
                color: onHero.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              left: -70,
              bottom: -110,
              child: _Glow(
                size: 260,
                color: onHero.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  final copy = _HeroCopy(
                    onSignIn: onSignIn,
                    onHero: onHero,
                    buttonBackground: buttonBackground,
                    buttonForeground: buttonForeground,
                  );
                  const preview = _LedgerPreview();

                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy,
                        const SizedBox(height: 28),
                        preview,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: copy),
                      const SizedBox(width: 32),
                      const Expanded(flex: 4, child: preview),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.onSignIn,
    required this.onHero,
    required this.buttonBackground,
    required this.buttonForeground,
  });

  final VoidCallback onSignIn;
  final Color onHero;
  final Color buttonBackground;
  final Color buttonForeground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: onHero.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: onHero.withValues(alpha: 0.24)),
          ),
          child: Text(
            'Record-only · no payments',
            style: theme.textTheme.labelSmall?.copyWith(
              color: onHero,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Keep the record straight.',
          style: theme.textTheme.displaySmall?.copyWith(
            color: onHero,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A shared ledger for group fundraising.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: onHero.withValues(alpha: 0.92),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Track who gave what, what was approved, and what was paid out. '
          'Chipbook only keeps the record. It never holds or moves money.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onHero.withValues(alpha: 0.8),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onSignIn,
          style: FilledButton.styleFrom(
            backgroundColor: buttonBackground,
            foregroundColor: buttonForeground,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Sign in to Chipbook'),
        ),
        const SizedBox(height: 12),
        Text(
          'Google or a one-time email link. No password to remember.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onHero.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// A still-life of a fund, so the page shows the product rather than telling.
class _LedgerPreview extends StatelessWidget {
  const _LedgerPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trip fund',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Organizer',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'USD · Weekly · USD 500 target',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _Figure(label: 'Raised', value: 'USD 320.00')),
              Expanded(child: _Figure(label: 'Paid out', value: 'USD 0.00')),
              Expanded(child: _Figure(label: 'Balance', value: 'USD 320.00')),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          const _PreviewEntry(
            name: 'Ada',
            amount: 'USD 50.00',
            label: 'Approved',
            approved: true,
          ),
          const SizedBox(height: 8),
          const _PreviewEntry(
            name: 'Grace',
            amount: 'USD 25.00',
            label: 'Pending',
            approved: false,
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PreviewEntry extends StatelessWidget {
  const _PreviewEntry({
    required this.name,
    required this.amount,
    required this.label,
    required this.approved,
  });

  final String name;
  final String amount;
  final String label;
  final bool approved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = approved ? scheme.primary : scheme.tertiary;

    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: scheme.surfaceContainerHighest,
          child: Text(
            name.substring(0, 1),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: theme.textTheme.bodySmall),
        ),
        Text(
          amount,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What it does',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Everything a group needs to agree on the numbers, and nothing that '
          'touches the money itself.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 2 : 1;
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
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
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
