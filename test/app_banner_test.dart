/// The notice component the designer's 2026-08-26 ruling asked for.
///
/// ⭐ **The mutant every test here exists to kill is "it is just a SnackBar
/// with extra steps".** A SnackBar satisfies "shows a message", "goes away by
/// itself" and "one at a time" — all three, exactly. The only thing it fails
/// is WHERE it does them, which is the entire point of the ruling, so the
/// position assertions are pinned by real geometry (`tester.getRect`) against
/// a harness that has a real bottom action bar, and a re-implementation via
/// `ScaffoldMessenger` fails them on the first pump.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/ui/app_banner.dart';
import 'package:masters_of_magic_2/ui/app_theme.dart';

const _bottomBarKey = Key('bottom-action-bar');

/// A screen shaped like the ones the ruling is about: an app bar on top, and
/// an action area glued to the bottom where a SnackBar would land.
Widget _host(void Function(BuildContext context) onPressed) => MaterialApp(
  home: Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Hearthwood')),
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => onPressed(context),
          child: const Text('Do the thing'),
        ),
      ),
    ),
    bottomNavigationBar: const SizedBox(
      key: _bottomBarKey,
      height: 72,
      child: Center(child: Text('Settle · 40g')),
    ),
  ),
);

void main() {
  group('showAppBanner', () {
    testWidgets('shows the message it was given', (tester) async {
      await tester.pumpWidget(_host((c) => showAppBanner(c, 'Code copied')));
      expect(
        find.byType(AppBanner),
        findsNothing,
        reason: 'a banner nobody asked for is worse than the SnackBar was',
      );

      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBanner), findsOneWidget);
      expect(
        find.text('Code copied'),
        findsOneWidget,
        reason: 'the banner carries the caller\'s words, not a summary',
      );
    });

    testWidgets('⭐ floats in the TOP half, below the app bar', (tester) async {
      await tester.pumpWidget(_host((c) => showAppBanner(c, 'Code copied')));
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      final screen = tester.getSize(find.byType(MaterialApp));
      final banner = tester.getRect(find.byType(AppBanner));
      final appBar = tester.getRect(find.byType(AppBar));

      expect(
        banner.bottom,
        lessThan(screen.height / 2),
        reason: '⭐ THE ruling: the whole banner sits in the top half. A '
            'SnackBar re-implementation lands at the bottom and fails here',
      );
      expect(
        banner.top,
        greaterThanOrEqualTo(appBar.bottom),
        reason: 'below the app bar — a notice covering the title bar is a '
            'different obstruction, not a fix for the first one',
      );
    });

    testWidgets('⭐ never overlaps the bottom action area', (tester) async {
      await tester.pumpWidget(_host((c) => showAppBanner(c, 'Code copied')));
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byKey(_bottomBarKey));
      final banner = tester.getRect(find.byType(AppBanner));

      expect(
        banner.overlaps(bar),
        isFalse,
        reason: '⭐ the bug being fixed: the notice sat on top of the button '
            'the player was reaching for',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: '⚠️ kills the "just call showSnackBar" mutant outright — no '
            'SnackBar may exist anywhere in the tree',
      );
    });

    testWidgets('⭐ auto-dismisses without anyone touching it', (tester) async {
      await tester.pumpWidget(_host((c) => showAppBanner(c, 'Code copied')));
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBanner), findsOneWidget);

      // A beat short of the hold: still there, so the expiry is the timer's
      // doing and not the pump's.
      await tester.pump(kAppBannerHold - const Duration(milliseconds: 200));
      expect(
        find.byType(AppBanner),
        findsOneWidget,
        reason: 'a banner that vanishes early is a banner nobody finishes '
            'reading',
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        find.byType(AppBanner),
        findsNothing,
        reason: 'no interaction required — it retires itself',
      );
      expect(find.text('Code copied'), findsNothing);
    });

    testWidgets('⭐ a second banner REPLACES the first', (tester) async {
      var n = 0;
      await tester.pumpWidget(
        _host((c) => showAppBanner(c, 'Notice ${++n}')),
      );

      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();
      expect(find.text('Notice 1'), findsOneWidget);

      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      expect(
        find.byType(AppBanner),
        findsOneWidget,
        reason: '⭐ one at a time — two stacked notices would re-create the '
            'obstruction this component removes',
      );
      expect(
        find.text('Notice 1'),
        findsNothing,
        reason: 'replaced, not queued: a player who taps twice wants the '
            'SECOND answer, not to wait out the first',
      );
      expect(find.text('Notice 2'), findsOneWidget);
    });

    testWidgets('the replacement gets a FULL hold, not the remainder', (
      tester,
    ) async {
      var n = 0;
      await tester.pumpWidget(
        _host((c) => showAppBanner(c, 'Notice ${++n}')),
      );
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      // Two thirds of the way through the first banner's life, replace it.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      // Past when the FIRST banner would have expired.
      await tester.pump(const Duration(milliseconds: 1200));
      expect(
        find.text('Notice 2'),
        findsOneWidget,
        reason: '⚠️ the timer belongs to the banner, not to the module — a '
            'shared timer would cut the replacement short at 900ms',
      );

      await tester.pump(kAppBannerHold);
      await tester.pumpAndSettle();
      expect(find.byType(AppBanner), findsNothing);
    });

    testWidgets('⚠️ taps fall THROUGH the banner to the screen beneath', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Hearthwood')),
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () {
                      taps++;
                      showAppBanner(context, 'Nothing stored here.');
                    },
                    child: const Text('Under the banner'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // The button sits directly under where the banner lands, so a banner
      // that swallowed pointers would make the second tap impossible.
      await tester.tap(find.text('Under the banner'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBanner), findsOneWidget);

      await tester.tap(find.text('Under the banner'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        taps,
        2,
        reason: '⭐ no interaction required AND none possible: the banner is '
            'IgnorePointer, so it cannot eat the button under it',
      );
    });

    testWidgets('survives the route it was raised from being popped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (home) => TextButton(
                onPressed: () => Navigator.of(home).push(
                  MaterialPageRoute<void>(
                    builder: (pushed) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () {
                            showAppBanner(pushed, 'Password changed.');
                            Navigator.of(pushed).pop();
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password changed.'),
        findsOneWidget,
        reason: '⚠️ raised in the ROOT overlay — several callers report an '
            'outcome and then leave, and a notice that pops with the route '
            'is a notice nobody ever sees',
      );
      expect(find.text('Open'), findsOneWidget, reason: 'the pop still ran');
    });

    testWidgets('the accent colours the border, never the words', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host((c) => showAppBanner(c, 'Your pack is full.',
            color: AppColors.ember)),
      );
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Your pack is full.'));
      expect(
        text.style?.color,
        AppColors.text,
        reason: '⚠️ a refusal is the message a player most needs to READ; '
            'ember-on-plum body text would make it the hardest one',
      );
      expect(
        tester.widget<AppBanner>(find.byType(AppBanner)).color,
        AppColors.ember,
        reason: 'the accent still has to land somewhere — the border',
      );
    });
  });

  group('showAppAlert', () {
    testWidgets('⭐ stops the player and names the refusal', (tester) async {
      await tester.pumpWidget(
        _host(
          (c) => showAppAlert(
            c,
            title: 'The trade did not go through',
            message: 'The shop has only 3 of those left.',
          ),
        ),
      );
      await tester.tap(find.text('Do the thing'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('The trade did not go through'), findsOneWidget);
      expect(find.text('The shop has only 3 of those left.'), findsOneWidget);
      expect(
        find.byType(AppBanner),
        findsNothing,
        reason: '⚠️ the escalation REPLACES the banner — a refusal that is '
            'worth a modal must not also flash past as a banner',
      );

      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'unlike a banner it waits, so it must also be dismissible',
      );
    });
  });
}
