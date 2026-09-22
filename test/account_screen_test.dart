import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/auth_service.dart';
import 'package:masters_of_magic_2/screens/account_screen.dart';

/// Enter submits the sign-in form (Christian, 2026-09-21): "I want to enter
/// my email, tab, enter my password, enter to login."
///
/// ⭐ Every case here drives the SAME `_submit` the button drives, which is
/// the whole point of the ruling — a second, keyboard-only submit path would
/// eventually validate differently or skip the busy guard.

/// An [AuthService] that has never met Firebase. Answers from memory and
/// counts what the screen asked it for.
class _FakeAuth extends AuthService {
  _FakeAuth() : super.forTesting();

  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastEmail;
  String? lastPassword;

  /// Nobody is signed in, so the screen shows its form. Every other identity
  /// getter on [AuthService] is derived from this one, so overriding it is
  /// enough to keep the real Firebase out of the tree.
  @override
  User? get user => null;

  /// ⚠️ Answers with an ERROR on purpose. A null return means success, and
  /// success navigates the player home — off the very form these tests are
  /// reading. The failure path leaves the screen up and still proves the
  /// request went out.
  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    return 'Wrong email or password.';
  }

  @override
  Future<String?> signUp({
    required String email,
    required String password,
    required String characterName,
  }) async {
    signUpCalls++;
    lastEmail = email;
    lastPassword = password;
    return 'That email already has an account.';
  }
}

void main() {
  Future<_FakeAuth> pumpForm(
    WidgetTester tester, {
    bool createMode = false,
  }) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final auth = _FakeAuth();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          service: auth,
          child: AccountScreen(startInCreateMode: createMode),
        ),
      ),
    );
    await tester.pump();
    return auth;
  }

  /// The field whose floating label reads [label].
  Finder field(String label) => find.widgetWithText(TextField, label);

  TextField fieldOf(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label));

  group('sign in', () {
    testWidgets('Enter in the password field submits the sign-in', (
      tester,
    ) async {
      final auth = await pumpForm(tester);
      await tester.enterText(field('Email'), 'mage@example.com');
      await tester.enterText(field('Password'), 'starlight');

      // Enter, with the password still holding focus.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        auth.signInCalls,
        1,
        reason:
            'a mutant with no onSubmitted on the password field leaves this '
            'at 0 — Enter would do nothing at all, which is the bug',
      );
      expect(
        auth.lastEmail,
        'mage@example.com',
        reason:
            'the keyboard path must read the same controllers the button '
            'does, not a stale or empty value',
      );
      expect(
        auth.lastPassword,
        'starlight',
        reason: 'and the same password the button would have sent',
      );
    });

    testWidgets('the button sends exactly the same request', (tester) async {
      final auth = await pumpForm(tester);
      await tester.enterText(field('Email'), 'mage@example.com');
      await tester.enterText(field('Password'), 'starlight');

      // ⚠️ By widget, not by text: the app bar's title reads 'Sign in' too.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      expect(
        auth.signInCalls,
        1,
        reason:
            'the parity check the ruling asks for — Enter and the button '
            'are one code path, so this is the same assertion as above',
      );
      expect(auth.lastPassword, 'starlight', reason: 'and the same payload');
    });

    testWidgets('Enter runs the SAME validation the button runs', (
      tester,
    ) async {
      final auth = await pumpForm(tester);
      await tester.enterText(field('Email'), 'not-an-email');
      await tester.enterText(field('Password'), 'starlight');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('Enter a valid email address.'),
        findsOneWidget,
        reason:
            'a mutant that wired Enter straight to auth.signIn, skipping '
            '_submit\'s _validate, would show no error here',
      );
      expect(
        auth.signInCalls,
        0,
        reason: 'and it would have fired a request off a bad address',
      );
    });

    testWidgets('the keyboard walks email to password and stops there', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(
        fieldOf(tester, 'Email').textInputAction,
        TextInputAction.next,
        reason:
            'Tab/Enter on the email advances to the password — a mutant '
            'that left this null gives the platform default and breaks the '
            '"email, tab, password" half of the ruling',
      );
      expect(
        fieldOf(tester, 'Password').textInputAction,
        TextInputAction.done,
        reason:
            'and the password is the end of the form, so its key says so — '
            'on a phone this is what turns the return key into "done"',
      );
    });
  });

  group('create account', () {
    testWidgets('Enter in the CONFIRM field submits the sign-up', (
      tester,
    ) async {
      final auth = await pumpForm(tester, createMode: true);
      await tester.enterText(field('Character name'), 'Vela');
      await tester.enterText(field('Email'), 'mage@example.com');
      await tester.enterText(field('Password'), 'starlight');
      await tester.enterText(field('Confirm password'), 'starlight');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        auth.signUpCalls,
        1,
        reason:
            'the last field of the form is the one that submits it — a '
            'mutant that only ever wired the field literally named '
            '"Password" would leave create-account unfinishable by keyboard',
      );
    });

    testWidgets('the password field only ADVANCES while a confirm follows it', (
      tester,
    ) async {
      final auth = await pumpForm(tester, createMode: true);
      await tester.enterText(field('Character name'), 'Vela');
      await tester.enterText(field('Email'), 'mage@example.com');
      await tester.enterText(field('Password'), 'starlight');

      expect(
        fieldOf(tester, 'Password').textInputAction,
        TextInputAction.next,
        reason:
            'in create mode the password is not the last field — the '
            'confirm box is',
      );

      // Enter, with the password focused and the confirm box still empty.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        auth.signUpCalls,
        0,
        reason:
            'submitting from here would answer a perfectly good password '
            'with "Passwords do not match." — a mutant that wires Enter to '
            '_submit on the password field in BOTH modes would fail this',
      );
      expect(
        find.text('Passwords do not match.'),
        findsNothing,
        reason: 'and it would put that accusation on screen',
      );
    });
  });
}
