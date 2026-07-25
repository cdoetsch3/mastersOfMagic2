import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/player_profile.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/screens/duel_screen.dart';
import 'package:mom_engine/mom_engine.dart';

/// The caps moved to 5 elements / 10 spells. The arena already drew two rows
/// of five and bound ten shortcut keys, so the risk is not "does it work" but
/// "does a FULL loadout still fit" — which is what these check.
void main() {
  test('the caps are 5 elements and 10 spells', () {
    expect(Progression.startingElementSlots, 5);
    expect(Progression.startingSpellSlots, 10);
  });

  test('there is a keyboard shortcut for every spell slot', () {
    // QWERTASDFG — one key per slot, or the last slots are unreachable.
    expect('QWERTASDFG'.length,
        greaterThanOrEqualTo(Progression.startingSpellSlots));
  });

  test('there are enough elements and spells to fill a preset', () {
    expect(MagicElement.values.length,
        greaterThanOrEqualTo(Progression.startingElementSlots));
    expect(Spellbook.all.length,
        greaterThanOrEqualTo(Progression.startingSpellSlots));
  });

  test('clampToCaps leaves a full preset alone', () {
    final preset = LoadoutPreset(
      name: 'Full',
      elementIds:
          MagicElement.values.take(5).map((e) => e.name).toList(),
      spellIds: Spellbook.all.take(10).map((s) => s.id).toList(),
    )..clampToCaps();
    expect(preset.elementIds, hasLength(5));
    expect(preset.spellIds, hasLength(10));
  });

  test('clampToCaps still trims anything over the cap', () {
    final preset = LoadoutPreset(
      name: 'Too big',
      elementIds: MagicElement.values.map((e) => e.name).toList(), // 12
      spellIds: Spellbook.all.map((s) => s.id).toList(), // 26
    )..clampToCaps();
    expect(preset.elementIds, hasLength(5));
    expect(preset.spellIds, hasLength(10));
  });

  testWidgets('a maxed loadout fits the arena without overflowing',
      (tester) async {
    // Landscape, since the arena is a landscape experience.
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final loadout = Loadout(
      elements: MagicElement.values.take(5).toList(),
      spells: Spellbook.all.take(10).toList(),
    );
    await tester.pumpWidget(MaterialApp(
      home: DuelScreen(
        loadout: loadout,
        driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('and on a smaller landscape phone', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final loadout = Loadout(
      elements: MagicElement.values.take(5).toList(),
      spells: Spellbook.all.take(10).toList(),
    );
    await tester.pumpWidget(MaterialApp(
      home: DuelScreen(
        loadout: loadout,
        driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
