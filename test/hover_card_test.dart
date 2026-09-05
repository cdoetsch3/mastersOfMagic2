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

  testWidgets('⭐ inside a centred column with its own Overlay, the card '
      'lands beside the tile, not a column-width to the right', (tester) async {
    // The app centres itself as a column on wide screens and that column has
    // its own Overlay. The mutant this kills: positioning in WINDOW
    // coordinates inside the column's overlay — which put the Aegis card
    // 800px right of Aegis on the designer's monitor.
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              height: 900,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => Align(
                      alignment: Alignment.topLeft,
                      // Off the overlay's edge, so the 8px edge margin does
                      // not enter the measurement.
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40, top: 40),
                        child: HoverCard(
                        delay: const Duration(milliseconds: 100),
                        card: (_) => const SpellDetailCard(
                          spell: Spellbook.aegis,
                          showDone: false,
                        ),
                        child: const SizedBox(
                          width: 200,
                          height: 60,
                          child: Text('tile'),
                        ),
                      ),
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
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('tile')));
    await tester.pump(const Duration(milliseconds: 200));
    final tile = tester.getRect(find.text('tile'));
    final card = tester.getRect(find.byType(SpellDetailCard));
    expect(
      (card.left - tile.left).abs(),
      lessThan(2),
      reason: 'the card starts at the tile\'s left edge — the column is at '
          'x=400, and a window-coordinate placement would land at ~800',
    );
    expect(
      card.top,
      greaterThan(tile.bottom),
      reason: 'and below it, since there is plenty of room below',
    );
  });
}
