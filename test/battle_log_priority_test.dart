import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:mom_engine/mom_engine.dart';

/// ✅ Ruled 2026-09-25: every "X casts Y" line in the battle log names the
/// priority that cast RESOLVED at — "(pri N)".
///
/// ⭐ The report behind it: Christian expected a Discharge to beat an attack
/// and watched it not. The engine was right (a Waterlogged Discharge resolves
/// at 18, a Quickened attack at 2), but nothing on screen said which number
/// the turn actually sorted by. The event now carries the resolved number, and
/// the log prints it.
void main() {
  group('the battle log names priority', () {
    test('⭐ the resolved number, not the base one, reaches the line', () {
      final alice = MageState(name: 'Alice');
      final event = SpellCastEvent(
        alice,
        Spellbook.discharge,
        MagicElement.aqua,
        priority: 18,
      );
      expect(
        event.toString(),
        'Alice casts Aqua Discharge (pri 18)',
        reason:
            '⚠️ kills a renderer that prints Spell.priority (8) — the '
            'Waterlogged +10 is the whole explanation the player needs',
      );
    });

    test('an event built without one falls back to the base priority', () {
      final event = SpellCastEvent(
        MageState(name: 'Alice'),
        Spellbook.bolt,
        MagicElement.pyro,
      );
      expect(
        event.toString(),
        endsWith('(pri ${Spellbook.bolt.priority})'),
        reason: 'a hand-built event says the base number, never nothing',
      );
    });

    test('second person survives the suffix', () {
      expect(
        DuelController.toSecondPerson('You casts Aqua Discharge (pri 18)'),
        'You cast Aqua Discharge (pri 18)',
        reason: 'the verb fix reads the start of the line, not its end',
      );
    });

    test('⭐ end to end: the player\'s own cast line in the real log', () async {
      final c = DuelController(
        loadout: Loadout.starter,
        driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(3)),
        // Accuracy to cancel the base miss, so the Flick resolves and there
        // is a cast line to read.
        playerGear: const ItemModifiers(
          accuracyBonus: ElementTuning.baseMissPercent,
        ),
      );
      addTearDown(c.dispose);

      c.selectElement(c.loadout.elements.first);
      await c.submitTurn(c.castAction(Spellbook.flick));

      expect(
        c.battleLog.where(
          (l) =>
              l.startsWith('You cast ') &&
              l.endsWith('Flick (pri ${Spellbook.flick.priority})'),
        ),
        hasLength(1),
        reason:
            'the event carries it and the controller prints it — a break at '
            'either end leaves the log silent about the order again',
      );
    });
  });
}
