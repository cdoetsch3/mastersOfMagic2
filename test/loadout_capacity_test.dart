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

/// Elements and spells are TWO SEPARATE pools — 5 elements and 10 spells, each
/// with its own cap and unlock schedule. (This reverted a merged single-pool
/// experiment; a legible hand the opponent can be read against beat the
/// flexibility of one big budget.)
void main() {
  test('the caps are 5 elements and 10 spells', () {
    expect(Loadout.maxElementSlots, 5);
    expect(Loadout.maxSpellSlots, 10);
  });

  test('the unlock schedules climb to those caps, and no further', () {
    // Elements: 1 at level 1, +1 at 10/20/30/40 -> 5.
    expect(Progression.elementsAtLevel(1), 1);
    expect(Progression.elementsAtLevel(40), Loadout.maxElementSlots);
    expect(Progression.elementsAtLevel(60), Loadout.maxElementSlots);

    // Spells: 4 at level 1, +1 at 8/16/24/32/40/48 -> 10.
    expect(Progression.spellsAtLevel(1), 4);
    expect(Progression.spellsAtLevel(48), Loadout.maxSpellSlots);
    expect(Progression.spellsAtLevel(60), Loadout.maxSpellSlots);

    // Monotonic, never past the cap.
    var pe = 0, ps = 0;
    for (var level = 1; level <= 60; level++) {
      final e = Progression.elementsAtLevel(level);
      final s = Progression.spellsAtLevel(level);
      expect(e, greaterThanOrEqualTo(pe));
      expect(s, greaterThanOrEqualTo(ps));
      expect(e, lessThanOrEqualTo(Loadout.maxElementSlots));
      expect(s, lessThanOrEqualTo(Loadout.maxSpellSlots));
      pe = e;
      ps = s;
    }
  });

  test('pools are NOT level-gated yet, so playtesting keeps the full caps', () {
    // Deliberate: gating is the last thing to turn on. If this flips, the two
    // expectations below should flip with it on purpose, not by accident.
    expect(Progression.enforceSlotLimits, isFalse);
    expect(Progression.usableElementsAtLevel(1), Loadout.maxElementSlots);
    expect(Progression.usableSpellsAtLevel(1), Loadout.maxSpellSlots);
  });

  test('a Loadout keeps elements and spells as separate lists', () {
    final loadout = Loadout(
      elements: const [MagicElement.pyro, MagicElement.aqua],
      spells: [Spellbook.flick, Spellbook.bolt, Spellbook.ward],
    );
    expect(loadout.elements, [MagicElement.pyro, MagicElement.aqua]);
    expect(loadout.spells.map((s) => s.id), ['flick', 'bolt', 'ward']);
  });

  test('a loadout survives a save/load round trip', () {
    final original = Loadout(
      elements: const [MagicElement.lunar, MagicElement.geo],
      spells: [Spellbook.surge, Spellbook.hallow],
    );
    final restored = Loadout.fromIds(
      elementIds: original.elementIds(),
      spellIds: original.spellIds(),
    );
    expect(restored.elementIds(), original.elementIds());
    expect(restored.spellIds(), original.spellIds());
  });

  test('unrecognised ids are dropped on load, never thrown on', () {
    final restored = Loadout.fromIds(
      elementIds: ['pyro', 'radiant', 'nonesuch'],
      spellIds: ['bolt', 'gone'],
    );
    expect(restored.elementIds(), ['pyro']);
    expect(restored.spellIds(), ['bolt']);
  });

  test('there is a keyboard shortcut for every slot in each pool', () {
    // 1-5 for elements; QWERTASDFG for spells. One key per slot, or the last
    // slots are unreachable.
    expect(5, greaterThanOrEqualTo(Loadout.maxElementSlots));
    expect('QWERTASDFG'.length, greaterThanOrEqualTo(Loadout.maxSpellSlots));
  });

  test('there are enough elements and spells to fill both pools', () {
    expect(
      MagicElement.values.length,
      greaterThanOrEqualTo(Loadout.maxElementSlots),
    );
    expect(Spellbook.all.length, greaterThanOrEqualTo(Loadout.maxSpellSlots));
  });

  group('clampToCaps', () {
    test('a preset at the caps is left alone', () {
      final preset = LoadoutPreset(
        name: 'Full',
        elementIds: MagicElement.values.take(5).map((e) => e.name).toList(),
        spellIds: Spellbook.all.take(10).map((s) => s.id).toList(),
      )..clampToCaps();
      expect(preset.elementCount, 5);
      expect(preset.spellCount, 10);
    });

    test('an over-large preset is trimmed to each cap independently', () {
      final preset = LoadoutPreset(
        name: 'Too big',
        elementIds: MagicElement.values.map((e) => e.name).toList(), // 12
        spellIds: Spellbook.all.map((s) => s.id).toList(), // 26
      )..clampToCaps();
      expect(preset.elementCount, Loadout.maxElementSlots);
      expect(preset.spellCount, Loadout.maxSpellSlots);
    });

    test('trimming one pool does not touch the other', () {
      // Too many elements, spells already within cap.
      final preset = LoadoutPreset(
        name: 'Element-heavy',
        elementIds: MagicElement.values.map((e) => e.name).toList(), // 12
        spellIds: const ['flick', 'bolt'],
      )..clampToCaps();
      expect(preset.elementCount, 5);
      expect(
        preset.spellIds,
        ['flick', 'bolt'],
        reason: 'the spell pool was already legal and must be untouched',
      );
    });

    test(
      'a tighter (future gating) budget clamps each pool to its own limit',
      () {
        final preset = LoadoutPreset(
          name: 'Level 1 player',
          elementIds: MagicElement.values.take(4).map((e) => e.name).toList(),
          spellIds: Spellbook.all.take(8).map((s) => s.id).toList(),
        )..clampToCaps(elementBudget: 1, spellBudget: 4);
        expect(preset.elementCount, 1);
        expect(preset.spellCount, 4);
      },
    );
  });

  testWidgets('a maxed loadout fits the arena without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final loadout = Loadout(
      elements: MagicElement.values.take(5).toList(),
      spells: Spellbook.all.take(10).toList(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          loadout: loadout,
          driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
        ),
      ),
    );
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
    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          loadout: loadout,
          driver: LocalAiDriver(persona: AiRoster.all.first, rng: Random(1)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
