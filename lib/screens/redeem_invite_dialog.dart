import 'package:material_ui/material_ui.dart';

import '../domain/invite_code.dart';

/// Collects the code an invitee was given.
class RedeemInviteDialog extends StatefulWidget {
  const RedeemInviteDialog({super.key});

  @override
  State<RedeemInviteDialog> createState() => _RedeemInviteDialogState();
}

class _RedeemInviteDialogState extends State<RedeemInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context)
        .pop<String>(InviteCode.tryParse(_codeController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Redeem invite'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the invite code or link from the fund organizer. '
              'Use the email address the invite was sent to.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Invite code or link',
              ),
              validator: (value) => InviteCode.error(value ?? ''),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Join fund')),
      ],
    );
  }
}
