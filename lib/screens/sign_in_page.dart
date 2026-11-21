import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_failure.dart';
import '../domain/auth_validation.dart';

/// Signs in with Google, or falls back to an emailed 6-digit code.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _openingGoogle = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _openingGoogle = true;
      _error = null;
    });

    try {
      await widget.auth.signInWithGoogle();
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _error = failure.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = 'Could not sign in with Google. Check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _openingGoogle = false);
      }
    }
  }

  Future<void> _send({bool resend = false}) async {
    if (!resend && !_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.auth.sendSignInCode(_emailController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _sent = true;
        _codeController.clear();
      });
      if (resend) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code is on its way.')),
        );
      }
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
            'Could not send the code. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _verify() async {
    if (!_codeFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await widget.auth.verifySignInCode(
        _emailController.text,
        _codeController.text,
      );
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
            'Could not check the code. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  void _startOver() {
    widget.auth.clearFailure();
    setState(() {
      _sent = false;
      _error = null;
      _codeController.clear();
    });
  }

  String? _codeError(String? value) {
    final code = (value ?? '').trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'Enter the 6-digit code from the email';
    }
    return null;
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
    final busy = _sending || _openingGoogle;

    return Form(
      key: _emailFormKey,
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
          OutlinedButton.icon(
            onPressed: busy ? null : _signInWithGoogle,
            icon: _openingGoogle
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or use email', style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
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
            onPressed: busy ? null : _send,
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Email me a sign-in code'),
          ),
          const SizedBox(height: 12),
          Text(
            'We email you a 6-digit code. No password needed. '
            'Check your spam folder if it does not arrive.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _sentConfirmation(ThemeData theme, String? error) {
    final busy = _verifying || _sending;

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
          'We sent a 6-digit code to ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'It may take a minute. Check your spam folder if it is missing.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Form(
          key: _codeFormKey,
          child: TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: '6-digit code',
              hintText: '123456',
            ),
            validator: _codeError,
            onFieldSubmitted: (_) => _verify(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : _verify,
          child: _verifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify code'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : () => _send(resend: true),
          child: const Text('Resend code'),
        ),
        TextButton(
          onPressed: _startOver,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
