import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

/// Two things the player is supposed to be able to SEE in the arena and could
/// not: how big the thing in front of them is, and whether a hit crit.
///
/// ⚠️ Both failures were invisible to the suite for the same reason — the
/// information existed on the engine's state and events and simply was never
/// asked for by the UI. Nothing crashes when a field goes unread, so only a
/// test that names the rendered string can catch it.
void main() {
  group('the nameplates name a level', () {
    testWidgets('both sides show one, and they are the real levels', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // The highest persona on the ladder, so the enemy's level is provably
      // not just the default 1 echoed back.
      final foe = AiRoster.all.last;
      expect(foe.level, greaterThan(1));
      const playerLevel = 7;
      expect(
        foe.level,
        isNot(playerLevel),
        reason: 'the two pills must be distinguishable for this test to mean '
            'anything',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DuelScreen(
            loadout: Loadout.starter,
            driver: LocalAiDriver(persona: foe, rng: Random(1)),
            playerLevel: playerLevel,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('LV $playerLevel'),
        findsOneWidget,
        reason: "the player's own level anchors the comparison — without it "
            "the enemy's number has nothing to be big relative to",
      );
      expect(
        find.text('LV ${foe.level}'),
        findsOneWidget,
        reason: 'a level-${foe.level} boss must not look like a level-1 fawn',
      );
    });

    testWidgets('a veiled panel still shows the level', (tester) async {
      // ⚠️ Creeping Dark hides charge and health. Level is not secret, and a
      // veil that swallowed it would leave the player unable to tell what they
      // are fighting at exactly the moment they most need to.
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: DuelScreen(
            loadout: Loadout.starter,
            driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
            playerLevel: 2,
          ),
        ),
      );
      await tester.pump();
      final state = tester.state<State<DuelScreen>>(find.byType(DuelScreen));
      // ignore: avoid_dynamic_calls
      final controller = (state as dynamic).c as DuelController;
      // Max stacks = Midnight, which veils BOTH panels — the strictest case.
      controller.enemy.statuses.add(
        CreepingDarkStatus(CreepingDarkStatus.maxStacks),
      );
      controller.notifyListeners();
      await tester.pump();

      expect(
        find.text('MIDNIGHT'),
        findsWidgets,
        reason: 'guard: the veil must actually be up for this test to bite',
      );
      expect(find.text('LV 2'), findsOneWidget);
      expect(find.text('LV ${AiRoster.all.first.level}'), findsOneWidget);
    });
  });

  group('a crit announces itself', () {
    final target = MageState(name: 'Morwen');

    DamageEvent hit({required bool crit, int toHp = 12}) =>
        DamageEvent(target, Spellbook.bolt, toShield: 0, toHp: toHp, crit: crit);

    test('the impact float says CRIT!, and says it first', () {
      final text = impactFloatText(hit(crit: true));
      expect(text, contains('CRIT!'));
      expect(
        text.startsWith('CRIT!'),
        isTrue,
        reason: 'the tag leads so the eye meets it on the way to the number',
      );
      expect(text, contains('-12'), reason: 'the damage is still shown');
    });

    test('an ordinary hit says nothing about crits', () {
      expect(impactFloatText(hit(crit: false)), isNot(contains('CRIT')));
      expect(impactFloatText(hit(crit: false)), '-12');
    });

    test('the crit tag rides alongside the other tags, not instead of them', () {
      final shattering = DamageEvent(
        target,
        Spellbook.bolt,
        toShield: 8,
        toHp: 3,
        shieldBroken: true,
        crit: true,
      );
      final text = impactFloatText(shattering);
      expect(text, contains('CRIT!'));
      expect(text, contains('shield shattered'));
    });

    test('the impact FX is meaningfully stronger', () {
      // ⚠️ "Stronger" has to mean *visibly* stronger: 2.4 is the threshold at
      // which _FxPainter flashes the whole screen. A crit on any single-hit
      // spell must clear it, or the boost is a rounding difference nobody
      // could report having seen.
      const perHit = 1.0; // one hit of a one-charge spell — the cheapest crit
      expect(
        impactIntensity(perHit, crit: true),
        greaterThan(impactIntensity(perHit, crit: false)),
      );
      expect(impactIntensity(perHit, crit: true), greaterThanOrEqualTo(2.4));
      expect(impactIntensity(perHit, crit: false), lessThan(2.4));
    });

    test('the log line carries the crit', () {
      expect(hit(crit: true).toString(), contains('CRIT'));
      expect(hit(crit: false).toString(), isNot(contains('CRIT')));
    });

    test('and it survives the trip into the battle log', () async {
      // ⭐ End to end through the real controller: crits are rare in play
      // (0% base chance), so this pins the *display path* by guaranteeing the
      // roll rather than waiting for one. Accuracy is topped up past the base
      // miss floor so the cast cannot whiff and leave nothing to crit.
      final c = DuelController(
        loadout: Loadout.starter,
        driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(3)),
        playerGear: const ItemModifiers(
          critChance: 100,
          accuracyBonus: ElementTuning.baseMissPercent,
        ),
      );
      addTearDown(c.dispose);

      c.selectElement(c.loadout.elements.first);
      // Flick costs no charge, so one submitted turn is one landed hit.
      await c.submitTurn(c.castAction(Spellbook.flick));

      expect(
        c.battleLog.where((line) => line.contains('CRIT')),
        isNotEmpty,
        reason: 'a guaranteed crit must be readable in the log afterwards',
      );
    });
  });

  test('the float still carries the shield-bypass tag after extraction', () {
    // ⚠️ Kills the regression the merge caught: extracting the float builder
    // dropped 'ignores shields', silently undoing the Murmur legibility fix.
    final m = MageState(name: 'A');
    final t = MageState(name: 'B');
    const spell = Spell(
        id: 's', name: 'S', chargeCost: 1, priority: 9,
        effect: DamageEffect(5, 5, ignoresShields: true));
    final e = DamageEvent(t, spell,
        toShield: 0, toHp: 5, shieldMultiplierPercent: 100,
        shieldBroken: false, bypassedShield: true);
    expect(impactFloatText(e), contains('ignores shields'));
    expect(m.alive, isTrue); // silence unused warning honestly
  });
}
