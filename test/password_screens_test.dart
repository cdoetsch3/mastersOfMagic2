import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/screens/password_screens.dart';

/// The password screens have no Firebase dependency until a button is pressed,
/// so their layout is testable — which is what catches an overflow on a small
/// phone before it reaches a player.
void main() {
  Future<void> pumpAt(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
  }

  for (final (label, size) in [
    ('a phone', Size(360, 720)),
    ('a very narrow phone', Size(320, 568)),
    ('a tablet', Size(900, 1200)),
  ]) {
    testWidgets('the reset form lays out on $label', (tester) async {
      await pumpAt(tester, const ForgotPasswordScreen(), size);
      expect(tester.takeException(), isNull);
      expect(find.text('Send reset link'), findsOneWidget);
    });
  }

  testWidgets('the reset form carries the email over from sign-in', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const ForgotPasswordScreen(initialEmail: 'a@b.com'),
      const Size(360, 720),
    );
    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('an invalid email is rejected before any request goes out', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const ForgotPasswordScreen(initialEmail: 'nope'),
      const Size(360, 720),
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    // Still on the form — no confirmation shown for a bad address.
    expect(find.text('Check your email'), findsNothing);
  });

  // ======================================================================
  // Enter submits (Christian, 2026-09-21) — every account form, not just
  // sign-in. Both screens validate before touching Firebase, so the
  // keyboard path is provable here without an account.
  // ======================================================================
  group('the return key', () {
    testWidgets('Enter on the reset form sends it', (tester) async {
      await pumpAt(
        tester,
        const ForgotPasswordScreen(initialEmail: 'nope'),
        const Size(360, 720),
      );

      await tester.tap(find.widgetWithText(TextField, 'Email'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('Enter a valid email address.'),
        findsOneWidget,
        reason:
            'Enter runs the same _send the button runs — a mutant that '
            'dropped the field\'s onSubmitted would leave the form silent '
            'and the reset unsendable from the keyboard',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Email'))
            .textInputAction,
        TextInputAction.done,
        reason:
            'the only field on the form is the last one, so its return key '
            'says "done" rather than offering a next field that is not there',
      );
    });

    testWidgets('Enter on the last change-password field submits it', (
      tester,
    ) async {
      // ⭐ No AuthScope: `AuthScope.maybeOf` answers null, and _submit's own
      // validation fires long before the null auth would matter. The point
      // is that Enter REACHES _submit at all.
      await pumpAt(tester, const ChangePasswordScreen(), const Size(360, 720));

      await tester.tap(find.widgetWithText(TextField, 'Confirm new password'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('Enter your current password.'),
        findsOneWidget,
        reason:
            'a mutant with no onSubmitted on the confirm field would show '
            'nothing — Enter would be a dead key on this form',
      );
    });

    testWidgets('the earlier password fields advance instead of submitting', (
      tester,
    ) async {
      await pumpAt(tester, const ChangePasswordScreen(), const Size(360, 720));

      for (final label in ['Current password', 'New password']) {
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, label))
              .textInputAction,
          TextInputAction.next,
          reason:
              '"$label" is not the last field, so Enter walks to the next '
              'one — a mutant that left this null hands the platform '
              'default and breaks keyboard-only entry',
        );
      }
    });
  });
}
