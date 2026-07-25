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

  testWidgets('the reset form carries the email over from sign-in',
      (tester) async {
    await pumpAt(tester, const ForgotPasswordScreen(initialEmail: 'a@b.com'),
        const Size(360, 720));
    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('an invalid email is rejected before any request goes out',
      (tester) async {
    await pumpAt(tester, const ForgotPasswordScreen(initialEmail: 'nope'),
        const Size(360, 720));
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    // Still on the form — no confirmation shown for a bad address.
    expect(find.text('Check your email'), findsNothing);
  });
}
