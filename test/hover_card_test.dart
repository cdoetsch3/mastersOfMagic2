import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/screens/spell_detail_dialog.dart';
import 'package:masters_of_magic_2/ui/hover_card.dart';
import 'package:mom_engine/mom_engine.dart';

/// The hover card: the ⓘ dialog's own panel, floating while a MOUSE rests on
/// a tile. Every assertion names the mutant it kills.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HoverCard(
              delay: const Duration(milliseconds: 300),
              card: (_) => const SpellDetailCard(
                spell: Spellbook.torment,
                showDone: false,
                note: 'Unlocks at level 20',
              ),
              child: const SizedBox(width: 200, height: 60, child: Text('tile')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('⭐ a resting mouse opens the card; leaving closes it', (
    tester,
  ) async {
    await pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('tile')));
    await tester.pump();
    expect(
      find.byType(SpellDetailCard),
      findsNothing,
      reason: '⚠️ the mutant this kills: a card that pops the instant the '
          'pointer crosses a tile — a grid of 60 would flicker like a '
          'marquee as the mouse travels',
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byType(SpellDetailCard),
      findsOneWidget,
      reason: 'after the rest, the SAME card the ⓘ dialog shows — not a '
          'second, plainer description',
    );
    expect(find.text('Unlocks at level 20'), findsOneWidget,
        reason: 'the note rides along on the card');
    expect(find.text('Done'), findsNothing,
        reason: 'a hover card has no button to press');

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(
      find.byType(SpellDetailCard),
      findsNothing,
      reason: '⚠️ the mutant this kills: a card that stays open once shown '
          '— a modal in disguise',
    );
  });

  testWidgets('leaving before the delay never opens it', (tester) async {
    await pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('tile')));
    await tester.pump(const Duration(milliseconds: 100));
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SpellDetailCard), findsNothing,
        reason: '⚠️ the mutant this kills: a pending timer that fires after '
            'the pointer has already left');
  });

  testWidgets('a touch never opens it — the ⓘ dialog is the touch path', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('tile'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SpellDetailCard), findsNothing);
  });
}
