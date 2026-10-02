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
    expect(
      find.text('Master Sporecap Mantle'),
      findsOneWidget,
      reason:
          'the roll is part of the name (§9b.5a) and the dialog must '
          'be given the instance to compose it',
    );
    expect(
      find.text('+17 max health'),
      findsOneWidget,
      reason:
          '12 × 1.40 → 17 — a tooltip printing the base 12 while the '
          'duel fights with 17 is exactly the disagreement the one-writer '
          'rule exists to prevent',
    );
  });

  testWidgets('an unrolled item still shows its plain numbers', (tester) async {
    await expectOpensCleanly(
      tester,
      (context) =>
          showItemDialog(context, def: ItemCatalogue.byId('sporecap_mantle')),
      reason: 'item dialog: no instance at all',
    );
    expect(
      find.text('+12 max health'),
      findsOneWidget,
      reason:
          'the Workbench previews items nobody owns yet — the base is '
          'the honest answer, and null must never scale',
    );
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

  /// ⭐ Ruling 2026-09-21: the generic damage-over-time mechanic is a **DoT**,
  /// never a "burn" — an aqua Torment is not on fire, and calling it a burn
  /// reads as a claim about Ignite. Every assertion below names a different
  /// place the old word lived, so a sweep that stopped after the heading (or
  /// after the body) fails here rather than shipping half-renamed.
  ///
  /// ⚠️ Deliberately NOT a blanket "no 'burn' anywhere" check: the status
  /// list underneath renders Ignite's own catalogue text, and Ignite KEEPS
  /// the word.
  ///
  /// ⚠️ The guide is a LAZY [ListView] taller than any surface, so the test
  /// scrolls it end to end and collects every [Text] it built on the way.
  /// Asserting against a live finder would make each `findsNothing` vacuous —
  /// an unswept section below the fold is simply never instantiated.
  testWidgets('the gameplay guide calls the mechanic a DoT, not a burn', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: GameplayGuideScreen()));
    await tester.pumpAndSettle();

    final rendered = <String>{};
    void collect() {
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.data case final data?) rendered.add(data);
      }
    }

    collect();
    for (var i = 0; i < 40; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      collect();
    }
    bool says(String fragment) => rendered.any((t) => t.contains(fragment));

    expect(
      rendered,
      contains('Elements carry effects'),
      reason:
          'the LAST section must have been built, or every negative below is '
          'vacuous — this is the guard on the scroll sweep above',
    );
    expect(
      rendered,
      contains('DoTs'),
      reason:
          'the section heading is the word the player learns first — a '
          'reword that touched only the body leaves it saying the old thing',
    );
    expect(
      rendered,
      isNot(contains('Burns and bleeds')),
      reason:
          'kills a mutant that ADDED a DoTs section instead of renaming the '
          'burns one, leaving both words taught at once',
    );
    expect(
      says('Fester adds three ticks to every DoT on them'),
      isTrue,
      reason:
          'the body is where the mechanic is actually explained; a '
          'title-only rename leaves "every burn on them" here',
    );
    expect(
      says('Recasting a DoT refreshes it'),
      isTrue,
      reason:
          'the refresh-not-stack rule is a second mechanic sentence — one '
          'replaced occurrence in the body must not pass for all of them',
    );
    expect(
      rendered,
      contains('DoTs & heals'),
      reason:
          'the End column of the resolution strip is outside the section, so '
          'a sweep scoped to the section body leaves "burns & heals"',
    );
    expect(
      says('heals land FIRST, then DoTs tick'),
      isTrue,
      reason:
          'the end-of-turn ordering note is the fourth site — and its '
          'wording is the one a player reads while dying to a tick',
    );
  });

  /// ⭐ Ruling 2026-09-30 (base crit 5%), damage half corrected 2026-10-02
  /// (+50, a gearless crit deals 150%): the guide states the base, and states
  /// it from the engine's consts rather than a typed copy.
  testWidgets('the gameplay guide states the base crit from the engine', (
    tester,
  ) async {
    expect(
      GameplayGuideScreen.critRule,
      allOf(
        contains('${MageState.baseCritChance}% chance to crit'),
        contains(
          'deals half again the damage (${100 + MageState.baseCritDamage}%)',
        ),
        isNot(contains('doubles')),
        contains('crit gear adds to both'),
      ),
      reason:
          '⚠️ kills a sentence typed without the const (a stale "5%" would '
          'survive a retune) and the 2026-09-30 "doubles the damage" wording '
          'the 2026-10-02 ruling (150%) corrected',
    );
    expect(
      GameplayGuideScreen.critRule,
      contains('(150%)'),
      reason:
          '⚠️ the ruled figure itself (2026-10-02: a gearless crit deals '
          '150%) — kills a const left at the 2026-09-30 +100 (200%)',
    );
    expect(
      MageState.baseCritDamage,
      50,
      reason:
          '"half again" is only honest at +50 (ruling 2026-10-02, 150%) — '
          'the const conditional in critRule falls back to a percentage '
          'otherwise',
    );

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: GameplayGuideScreen()));
    await tester.pumpAndSettle();

    // ⚠️ Lazy ListView — sweep it, as the DoT test above does.
    final rendered = <String>{};
    void collect() {
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.data case final data?) rendered.add(data);
      }
    }

    collect();
    for (var i = 0; i < 40; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      collect();
    }
    bool says(String fragment) => rendered.any((t) => t.contains(fragment));

    expect(
      says(GameplayGuideScreen.critRule),
      isTrue,
      reason:
          'the "Hits, crits and deflection" section must render the rule — '
          'kills a critRule that exists but is never shown',
    );
    expect(
      says('100% + your crit damage'),
      isFalse,
      reason: 'kills the pre-ruling sentence surviving beside the new one',
    );
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
