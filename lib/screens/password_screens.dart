import 'package:flutter/material.dart';

import '../game/auth_service.dart';
import '../ui/app_theme.dart';

/// Sends a password-reset email.
///
/// Reports the same confirmation whether or not the address has an account —
/// telling the truth here would turn the form into a way to test which emails
/// are registered.
class ForgotPasswordScreen extends StatefulWidget {
  /// Pre-fills the field with whatever was already typed on the sign-in form.
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send(AuthService? auth) async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (auth == null) {
      setState(() => _error = 'Accounts are unavailable right now.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent ? _confirmation() : _form(auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AuthService? auth) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Enter the email on your account and we will send you a link to '
        'set a new password.',
        style: TextStyle(color: AppColors.textDim, fontSize: 13.5),
      ),
      const SizedBox(height: 16),
      AuthTextField(
        controller: _email,
        label: 'Email',
        icon: Icons.mail_outline,
        keyboard: TextInputType.emailAddress,
        onSubmitted: _busy ? null : (_) => _send(auth),
      ),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(
          _error!,
          style: const TextStyle(color: AppColors.ember, fontSize: 13),
        ),
      ],
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _busy ? null : () => _send(auth),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.bg,
                ),
              )
            : const Text(
                'Send reset link',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    ],
  );

  Widget _confirmation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.mark_email_read, color: AppColors.green, size: 44),
      const SizedBox(height: 12),
      const Text(
        'Check your email',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'If an account exists for ${_email.text.trim()}, a reset link is on '
        'its way. It expires in an hour — check your spam folder if you do '
        'not see it.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textDim, fontSize: 13.5),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Back to sign in',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      TextButton(
        onPressed: () => setState(() => _sent = false),
        child: const Text('Use a different email'),
      ),
    ],
  );
}

/// Changes the password of the signed-in account.
///
/// Requires the current password: Firebase demands a recent login for this,
/// and it also means finding an unlocked device is not enough to take an
/// account over.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthService? auth) async {
    if (_current.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (_next.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    if (_next.text == _current.text) {
      setState(() => _error = 'That is already your password.');
      return;
    }
    if (auth == null) {
      setState(() => _error = 'Accounts are unavailable right now.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password changed.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Change password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Signed in as ${auth?.email ?? ''}.',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _current,
                    label: 'Current password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  AuthTextField(
                    controller: _next,
                    label: 'New password',
                    icon: Icons.lock_reset,
                    obscure: true,
                  ),
                  AuthTextField(
                    controller: _confirm,
                    label: 'Confirm new password',
                    icon: Icons.lock_reset,
                    obscure: true,
                    onSubmitted: _busy ? null : (_) => _submit(auth),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.ember,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : () => _submit(auth),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bg,
                            ),
                          )
                        : const Text(
                            'Change password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The account screens' shared text field, so sign-in, reset and change all
/// look and behave the same.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboard,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textDim),
          prefixIcon: Icon(icon, color: AppColors.textFaint, size: 19),
          filled: true,
          fillColor: AppColors.panel,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderDim),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderDim),
          ),
        ),
      ),
    );
  }
}
