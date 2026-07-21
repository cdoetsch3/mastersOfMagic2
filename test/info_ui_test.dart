import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/screens/element_detail_dialog.dart';
import 'package:masters_of_magic_2/screens/gameplay_guide_screen.dart';
import 'package:masters_of_magic_2/screens/spell_detail_dialog.dart';
import 'package:mom_engine/mom_engine.dart';

/// Layout regression tests for the info UI. These drive the real render
/// pipeline, so unbounded-constraint crashes (a `stretch` Row inside a scroll
/// view) and overflows fail the test instead of reaching a player.
void main() {
  /// Pumps [open] behind a button, taps it, and fails on any layout exception.
  Future<void> expectOpensCleanly(
    WidgetTester tester,
    void Function(BuildContext) open, {
    required String reason,
    Size surface = const Size(400, 800), // phone portrait — the tight case
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Tear the previous tree down first: a dialog left open from the last
    // iteration would swallow the tap that opens the next one.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: reason);
  }

  testWidgets('element dialog lays out for all nine elements', (tester) async {
    for (final element in MagicElement.values) {
      await expectOpensCleanly(
        tester,
        (context) => showElementDetail(context, element),
        reason: 'element dialog: ${element.name}',
      );
      expect(find.text('Done'), findsOneWidget, reason: element.name);
    }
  });

  testWidgets('spell dialog lays out for every spell in the book',
      (tester) async {
    for (final spell in Spellbook.all) {
      await expectOpensCleanly(
        tester,
        (context) => showSpellDetail(context, spell),
        reason: 'spell dialog: ${spell.id}',
      );
      expect(find.text(spell.name), findsWidgets, reason: spell.id);
    }
  });

  testWidgets('the gameplay guide lays out on a phone screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: GameplayGuideScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('How dueling works'), findsOneWidget);
    expect(find.text('RESOLUTION ORDER'), findsOneWidget);
  });

  testWidgets('the gameplay guide also lays out on a narrow screen',
      (tester) async {
    // The phase strip is the tightest row — check it survives a small phone.
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: GameplayGuideScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
