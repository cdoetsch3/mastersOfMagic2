import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/screens/element_detail_dialog.dart';
import 'package:masters_of_magic_2/screens/gameplay_guide_screen.dart';
import 'package:masters_of_magic_2/screens/spell_detail_dialog.dart';
import 'package:masters_of_magic_2/ui/item_display.dart';
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
    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: reason);
  }

  testWidgets('element dialog lays out for every element in the roster', (
    tester,
  ) async {
    for (final element in MagicElement.values) {
      await expectOpensCleanly(
        tester,
        (context) => showElementDetail(context, element),
        reason: 'element dialog: ${element.name}',
      );
      expect(find.text('Done'), findsOneWidget, reason: element.name);
    }
  });

  testWidgets('spell dialog lays out for every spell in the book', (
    tester,
  ) async {
    for (final spell in Spellbook.all) {
      await expectOpensCleanly(
        tester,
        (context) => showSpellDetail(context, spell),
        reason: 'spell dialog: ${spell.id}',
      );
      expect(find.text(spell.name), findsWidgets, reason: spell.id);
    }
  });

  testWidgets('⭐ the item dialog quotes the INSTANCE, not the definition', (
    tester,
  ) async {
    // Sporecap Mantle is +12 HP / +2 accuracy in the catalogue; a Master one
    // is worth ×1.40 of that (ruling 2026-08-18).
    const master = ItemInstance(
      instanceId: 'm1',
      defId: 'sporecap_mantle',
      quality: Quality.master,
    );
    await expectOpensCleanly(
      tester,
      (context) => showItemDialog(
        context,
        def: ItemCatalogue.byId('sporecap_mantle'),
        instance: master,
      ),
      reason: 'item dialog: a Master mantle',
    );
    expect(find.text('Master Sporecap Mantle'), findsOneWidget,
        reason: 'the roll is part of the name (§9b.5a) and the dialog must '
            'be given the instance to compose it');
    expect(find.text('+17 max health'), findsOneWidget,
        reason: '12 × 1.40 → 17 — a tooltip printing the base 12 while the '
            'duel fights with 17 is exactly the disagreement the one-writer '
            'rule exists to prevent');
  });

  testWidgets('an unrolled item still shows its plain numbers', (tester) async {
    await expectOpensCleanly(
      tester,
      (context) => showItemDialog(
        context,
        def: ItemCatalogue.byId('sporecap_mantle'),
      ),
      reason: 'item dialog: no instance at all',
    );
    expect(find.text('+12 max health'), findsOneWidget,
        reason: 'the Workbench previews items nobody owns yet — the base is '
            'the honest answer, and null must never scale');
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

  testWidgets('the gameplay guide also lays out on a narrow screen', (
    tester,
  ) async {
    // The phase strip is the tightest row — check it survives a small phone.
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: GameplayGuideScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
