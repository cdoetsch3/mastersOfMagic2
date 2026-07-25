import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Thin wrapper over Firebase Auth exposing just what the UI needs, with
/// human-readable error strings. Notifies listeners on any auth change.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService() {
    _auth.userChanges().listen((_) => notifyListeners());
  }

  User? get user => _auth.currentUser;
  bool get signedIn => user != null;
  bool get emailVerified => user?.emailVerified ?? false;
  String? get displayName => user?.displayName;
  String? get email => user?.email;

  /// Creates an account, sets the character name, and sends a verification
  /// email. Returns null on success, or a friendly error message.
  Future<String?> signUp({
    required String email,
    required String password,
    required String characterName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user?.updateDisplayName(characterName.trim());
      await cred.user?.sendEmailVerification();
      await cred.user?.reload();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> resendVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Sends a password-reset email. Returns null on success, or a friendly
  /// error.
  ///
  /// ⚠️ Deliberately reports success even when no account exists for [email]:
  /// saying "no account found" would turn this form into an oracle for which
  /// addresses are registered. The caller's confirmation text is worded to
  /// match ("if an account exists…").
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return null; // don't leak account existence
      return _message(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Changes the signed-in user's password.
  ///
  /// Firebase treats this as a sensitive operation, so it requires a recent
  /// login — we re-authenticate with [currentPassword] first, which doubles as
  /// proof the person at the keyboard is the account owner and not someone who
  /// found an unlocked device.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return 'You are not signed in.';
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: currentPassword));
      await user.updatePassword(newPassword);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      // Re-auth failures surface as credential errors; name the actual field
      // so the user doesn't hunt for a typo in the new password.
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'That is not your current password.';
      }
      return _message(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Reloads the user so [emailVerified] reflects a link clicked elsewhere.
  Future<void> refresh() async {
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  String _message(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' => 'That email already has an account.',
        'invalid-email' => 'That email address looks invalid.',
        'weak-password' => 'Choose a stronger password (6+ characters).',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Wrong email or password.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'operation-not-allowed' =>
          'Email sign-in is not enabled for this project yet.',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => e.message ?? 'Authentication failed.',
      };
}

/// Inherited access to the single [AuthService].
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService service,
    required super.child,
  }) : super(notifier: service);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found in context');
    return scope!.notifier!;
  }

  /// Null when accounts are unavailable (Firebase failed to initialize).
  static AuthService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}
