import 'package:flutter/material.dart';

import '../game/app_version.dart';
import '../game/auth_service.dart';
import '../game/game_state.dart';
import '../ui/app_theme.dart';
import 'home_shell.dart';

/// Sign-in / create-account flow. Optional in Phase 1 — the game is playable
/// as a guest; an account is what will carry friends, challenges, and cloud
/// saves. Required to create an account: character name, email, password, and
/// (planned) an App Check captcha; email verification is sent on signup.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _createMode = true;
  bool _busy = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_createMode) {
      if (_name.text.trim().isEmpty) return 'Choose a character name.';
      if (_password.text != _confirm.text) return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit(AuthService auth) async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = _createMode
        ? await auth.signUp(
            email: _email.text,
            password: _password.text,
            characterName: _name.text)
        : await auth.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      // On sign-up, adopt the character name into the local profile.
      if (_createMode && _name.text.trim().isNotEmpty) {
        GameStateScope.read(context).setName(_name.text.trim());
      }
      // Signed in — head back to Home rather than lingering here.
      HomeShell.goHome();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(auth.signedIn
            ? 'Account'
            : (_createMode ? 'Create account' : 'Sign in')),
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
                  auth.signedIn ? _AccountView(auth: auth) : _form(auth),
                  const SizedBox(height: 20),
                  const _AboutPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_createMode)
          _field(_name, 'Character name', icon: Icons.person),
        _field(_email, 'Email',
            icon: Icons.mail, keyboard: TextInputType.emailAddress),
        _field(_password, 'Password', icon: Icons.lock, obscure: true),
        if (_createMode)
          _field(_confirm, 'Confirm password',
              icon: Icons.lock_outline, obscure: true),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!,
              style: const TextStyle(color: AppColors.ember, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ember,
              foregroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _busy ? null : () => _submit(auth),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg))
                : Text(_createMode ? 'Create account' : 'Sign in',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _createMode = !_createMode;
                    _error = null;
                  }),
          child: Text(_createMode
              ? 'Already have an account? Sign in'
              : 'Need an account? Create one'),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 13, color: AppColors.textFaint),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                  'Bot protection (App Check captcha) arrives before public launch.',
                  style:
                      TextStyle(color: AppColors.textFaint, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label,
      {required IconData icon,
      bool obscure = false,
      TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textDim),
          prefixIcon: Icon(icon, color: AppColors.textDim, size: 20),
          filled: true,
          fillColor: AppColors.panelHi,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _AccountView extends StatelessWidget {
  final AuthService auth;
  const _AccountView({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle,
                      color: AppColors.gold, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName ?? 'Mage',
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text(auth.email ?? '',
                            style: const TextStyle(
                                color: AppColors.textDim, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                      auth.emailVerified
                          ? Icons.verified
                          : Icons.mark_email_unread,
                      size: 16,
                      color: auth.emailVerified
                          ? AppColors.green
                          : AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                      auth.emailVerified
                          ? 'Email verified'
                          : 'Email not verified',
                      style: TextStyle(
                          color: auth.emailVerified
                              ? AppColors.green
                              : AppColors.gold,
                          fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        if (!auth.emailVerified) ...[
          const SizedBox(height: 12),
          const Text(
              'Check your inbox for a verification link, then refresh.',
              style: TextStyle(color: AppColors.textDim, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => auth.resendVerification(),
                  icon: const Icon(Icons.mail),
                  label: const Text('Resend'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => auth.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('I verified'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => auth.signOut(),
          icon: const Icon(Icons.logout, color: AppColors.ember),
          label: const Text('Sign out',
              style: TextStyle(color: AppColors.ember)),
        ),
      ],
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      color: AppColors.panel,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const WizardHatIcon(size: 20, color: AppColors.gold),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Masters of Magic 2',
                    style: TextStyle(color: AppColors.text, fontSize: 13.5)),
                Text('An elemental mage-dueling game — early preview',
                    style:
                        TextStyle(color: AppColors.textDim, fontSize: 11.5)),
              ],
            ),
          ),
          Text('v$appVersion ($appBuild)',
              style:
                  const TextStyle(color: AppColors.textFaint, fontSize: 12)),
        ],
      ),
    );
  }
}
