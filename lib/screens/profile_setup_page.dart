import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../domain/username_validation.dart';

/// Asks a signed-in user for the username other members will see.
///
/// The verified email is shown as a read-only reference, never edited here:
/// the database checks invites against `auth.users`, so a second copy would
/// only be able to drift.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({
    super.key,
    required this.email,
    required this.onSave,
  });

  final String? email;
  final Future<void> Function(String username) onSave;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _saving = false;
  String? _error;

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
    final email = widget.email;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppInfo.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Choose a username',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Other members see this instead of your email address. '
                      'You can change it later in Settings.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      autofocus: true,
                      maxLength: 20,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'ada_lovelace',
                        prefixText: '@',
                      ),
                      validator: (value) =>
                          UsernameValidation.error(value ?? ''),
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3-20 lowercase letters, numbers, or underscores.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(email, overflow: TextOverflow.ellipsis),
                          subtitle: const Text(
                            'Your verified email. Only you can see it.',
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
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
