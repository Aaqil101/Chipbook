import 'package:material_ui/material_ui.dart';

import '../domain/username_validation.dart';

/// Renames the current profile without leaving Settings.
class RenameUsernameDialog extends StatefulWidget {
  const RenameUsernameDialog({
    super.key,
    required this.initialUsername,
    required this.onSave,
  });

  final String initialUsername;
  final Future<void> Function(String username) onSave;

  @override
  State<RenameUsernameDialog> createState() => _RenameUsernameDialogState();
}

class _RenameUsernameDialogState extends State<RenameUsernameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(_usernameController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Change username'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _usernameController,
              autofocus: true,
              maxLength: 20,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
              ),
              validator: (value) => UsernameValidation.error(value ?? ''),
              onFieldSubmitted: (_) => _save(),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
