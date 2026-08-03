import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  test('⚠️ a creature only ever charges its own elements', () {
    // The bug this guards: the element of a cast comes from what the mage
    // CHARGED, not from the spell. A brain handed all twelve elements charges
    // at random, so a Flora creature's own move lands as Astral. Shipped once
    // — a Listening Fawn cast Astral and Aqua.
    for (final def in Bestiary.all) {
      final brain = EnemyEncounter(def: def, level: 3).toPersona().buildBrain();
      final self = MageState(name: def.name, level: 3);
      final foe = MageState(name: 'You', level: 3);
      final rng = Random(7);
      for (var turn = 0; turn < 300; turn++) {
        final action = brain.chooseAction(self, foe, rng);
        final element = switch (action) {
          ChargeAction(:final element) => element,
          CastAction(:final element) => element,
          _ => null,
        };
        if (element != null) {
          expect(
            def.elements,
            contains(element),
            reason: '${def.name} used ${element.name}, but it is '
                '${def.elements.map((e) => e.name).join("/")}',
          );
        }
        // Let it accumulate charge so casts actually happen.
        self.charge = (self.charge + 1) % 6;
        self.element = element ?? self.element;
      }
    }
  });
}
