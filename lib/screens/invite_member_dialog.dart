import 'package:material_ui/material_ui.dart';

import '../domain/invite_validation.dart';
import '../models/member_role.dart';

/// Values collected by [InviteMemberDialog].
typedef InviteDraft = ({String email, MemberRole role});

/// Collects an email address and the role to grant on acceptance.
class InviteMemberDialog extends StatefulWidget {
  const InviteMemberDialog({super.key});

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  MemberRole _role = MemberRole.member;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context)
        .pop<InviteDraft>((email: _emailController.text.trim(), role: _role));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite a member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (value) => InviteValidation.emailError(value ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MemberRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final role in MemberRole.values)
                  DropdownMenuItem<MemberRole>(
                    value: role,
                    child: Text(role.label),
                  ),
              ],
              onChanged: (role) {
                if (role != null) {
                  setState(() => _role = role);
                }
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Invites expire after 7 days.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create invite')),
      ],
    );
  }
}
