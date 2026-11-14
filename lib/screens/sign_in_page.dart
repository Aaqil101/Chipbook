import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_failure.dart';
import '../domain/auth_validation.dart';

/// Sends an email magic link and waits for the session to appear.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.auth.sendMagicLink(_emailController.text);
      if (!mounted) {
        return;
      }
      setState(() => _sent = true);
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _error = failure.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'Could not send the link. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error ?? widget.auth.failure?.message;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent
                  ? _sentConfirmation(theme, error)
                  : _signInForm(context, theme, error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInForm(BuildContext context, ThemeData theme, String? error) {
    return Form(
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
          const SizedBox(height: 8),
          Text(
            'Sign in to record and review contributions.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
            validator: (value) => AuthValidation.emailError(value ?? ''),
            onFieldSubmitted: (_) => _send(),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send magic link'),
          ),
          const SizedBox(height: 12),
          Text(
            'We email you a one-time link. No password needed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _sentConfirmation(ThemeData theme, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a sign-in link to ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            widget.auth.clearFailure();
            setState(() => _sent = false);
          },
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
