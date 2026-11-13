import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/invite.dart';

/// Shows the code an organizer shares after creating an invite.
class InviteCreatedDialog extends StatelessWidget {
  const InviteCreatedDialog({super.key, required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expires = MaterialLocalizations.of(context)
        .formatShortDate(invite.expiresAt.toLocal());

    return AlertDialog(
      title: const Text('Invite code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share this code with ${invite.email}.'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              invite.token,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'They redeem it after signing in with that email. '
            'It expires on $expires.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: invite.token));
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
          child: const Text('Copy code'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
