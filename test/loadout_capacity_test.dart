import 'dart:io';
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

/// Elements and spells now share ONE slot pool (5 at level 1 -> 15 at 50, up to
/// 20 with equipment). The arena already drew two rows of five and bound ten
/// shortcut keys, so the risk is not "does it work" but "does a FULL loadout
/// still fit" — which is what these check.
void main() {
  test('the pool runs 5 slots at level 1 to 15 at the cap', () {
    expect(Progression.startingSlots, 5);
    expect(Progression.slotsAtLevel(1), 5);
    expect(Progression.slotsAtLevel(50), Progression.slotsAtCap);
    expect(Progression.slotsAtCap, 15);

    // Monotonic, and never past the level curve's ceiling.
    var previous = 0;
    for (var level = 1; level <= 60; level++) {
      final slots = Progression.slotsAtLevel(level);
      expect(slots, greaterThanOrEqualTo(previous));
      expect(slots, lessThanOrEqualTo(Progression.slotsAtCap));
      previous = slots;
    }
  });

  test('equipment can lift the pool to the absolute ceiling of 20', () {
    expect(Progression.slotsAtCap + Progression.maxEquipmentSlots,
        Loadout.maxSlots);
    expect(Loadout.maxSlots, 20);
  });

  test('slot limits are NOT enforced yet, so playtesting keeps everything', () {
    // Deliberate: level gating is the last thing to turn on. If this flips,
    // the expectation below should flip with it on purpose, not by accident.
    expect(Progression.enforceSlotLimits, isFalse);
    expect(Progression.usableSlotsAtLevel(1), Loadout.maxSlots);
  });

  test('a Loadout is one pool, with elements and spells as views over it', () {
    final loadout = Loadout(
      elements: const [MagicElement.pyro, MagicElement.aqua],
      spells: [Spellbook.flick, Spellbook.bolt, Spellbook.ward],
    );

    expect(loadout.slotsUsed, 5, reason: '2 elements + 3 spells share the pool');
    expect(loadout.slots.length, 5);
    expect(loadout.elements, [MagicElement.pyro, MagicElement.aqua]);
    expect(loadout.spells.map((s) => s.id), ['flick', 'bolt', 'ward']);
  });

  test('a pool survives a save/load round trip', () {
    final original = Loadout(
      elements: const [MagicElement.lunar, MagicElement.geo],
      spells: [Spellbook.surge, Spellbook.hallow],
    );
    final restored = Loadout.fromIds(original.toIds());

    expect(restored.toIds(), original.toIds());
    expect(restored.elements, original.elements);
    expect(restored.spells.map((s) => s.id), original.spells.map((s) => s.id));
  });

  test('unrecognised ids are dropped on load, never thrown on', () {
    final restored = Loadout.fromIds(['pyro', 'radiant', 'bolt', 'nonesuch']);
    expect(restored.toIds(), ['pyro', 'bolt']);
  });

  test('there is a keyboard shortcut for every spell slot', () {
    // QWERTASDFG — one key per slot, or the last slots are unreachable.
    expect('QWERTASDFG'.length,
        greaterThanOrEqualTo(Loadout.maxSpellSlots));
  });

  test('there are enough elements and spells to fill a preset', () {
    expect(MagicElement.values.length,
        greaterThanOrEqualTo(Loadout.maxElementSlots));
    expect(Spellbook.all.length, greaterThanOrEqualTo(Loadout.maxSpellSlots));
  });

  test('a preset counts elements and spells against one shared pool', () {
    final preset = LoadoutPreset(
      name: 'Mixed',
      elementIds: const ['pyro', 'aqua', 'flora'],
      spellIds: const ['flick', 'bolt'],
    );
    expect(preset.slotsUsed, 5);
  });

  test('clampToCaps leaves a preset at the ceiling alone', () {
    // 8 elements + 10 spells = 18, inside the 20-slot ceiling and inside both
    // per-kind arena limits, so nothing should move.
    final preset = LoadoutPreset(
      name: 'Full',
      elementIds: MagicElement.values.take(8).map((e) => e.name).toList(),
      spellIds: Spellbook.all.take(10).map((s) => s.id).toList(),
    )..clampToCaps();
    expect(preset.elementIds, hasLength(8));
    expect(preset.spellIds, hasLength(10));
    expect(preset.slotsUsed, 18);
  });

  test('clampToCaps trims to the per-kind arena limits first', () {
    final preset = LoadoutPreset(
      name: 'Too big',
      elementIds: MagicElement.values.map((e) => e.name).toList(), // 12
      spellIds: Spellbook.all.map((s) => s.id).toList(), // 26
    )..clampToCaps();

    // 12 -> 8 elements and 26 -> 10 spells, then the total is still 18, under
    // the 20-slot ceiling, so the shared clamp has nothing left to do.
    expect(preset.elementIds, hasLength(Loadout.maxElementSlots));
    expect(preset.spellIds, hasLength(Loadout.maxSpellSlots));
    expect(preset.slotsUsed, lessThanOrEqualTo(Loadout.maxSlots));
  });

  test('the absolute ceiling cannot bite while the arena limits are 8 and 10', () {
    // 8 + 10 = 18 < 20, so Loadout.maxSlots is not reachable by clamping alone.
    // Documented rather than hidden: the shared clamp exists for when level
    // gating turns on and the budget drops to slotsAtLevel().
    expect(Loadout.maxElementSlots + Loadout.maxSpellSlots,
        lessThan(Loadout.maxSlots));
  });

  test('clampToCaps drops spells before elements when the pool overflows', () {
    final preset = LoadoutPreset(
      name: 'Over budget',
      elementIds: const ['pyro', 'aqua', 'flora', 'geo'],
      spellIds: const ['flick', 'bolt', 'ward', 'sap'],
    )..clampToCaps(slotBudget: 6); // 8 used, 2 too many

    expect(preset.slotsUsed, 6);
    expect(preset.elementIds, ['pyro', 'aqua', 'flora', 'geo'],
        reason: 'elements are kept — spells absorb the trim first');
    expect(preset.spellIds, ['flick', 'bolt']);
  });

  test('clampToCaps eats into elements only once spells are gone', () {
    final preset = LoadoutPreset(
      name: 'Far over budget',
      elementIds: const ['pyro', 'aqua', 'flora', 'geo'],
      spellIds: const ['flick', 'bolt'],
    )..clampToCaps(slotBudget: 3); // 6 used, 3 too many

    expect(preset.slotsUsed, 3);
    expect(preset.spellIds, isEmpty);
    expect(preset.elementIds, ['pyro', 'aqua', 'flora']);
  });

  test('clampToCaps at a level-curve budget matches the pool for that level',
      () {
    final preset = LoadoutPreset(
      name: 'Level 1 player',
      elementIds: MagicElement.values.take(4).map((e) => e.name).toList(),
      spellIds: Spellbook.all.take(6).map((s) => s.id).toList(),
    )..clampToCaps(slotBudget: Progression.slotsAtLevel(1));

    expect(preset.slotsUsed, Progression.slotsAtLevel(1));
    expect(preset.slotsUsed, 5);
  });

  // The slot curve lives in two places — the code and the PROGRESSION_DESIGN
  // table. Scrape the doc so they cannot drift apart silently.
  test('the code slot schedule matches the PROGRESSION_DESIGN table', () {
    final doc = File('PROGRESSION_DESIGN.md').readAsStringSync();
    final row = RegExp(r'\|\s*\*\*Level\*\*\s*\|([^\n]*)\|')
        .firstMatch(doc);
    expect(row, isNotNull,
        reason: 'the slot-growth table in PROGRESSION_DESIGN §1 moved or '
            'changed shape — update this test with it');

    final levels = row!
        .group(1)!
        .split('|')
        .map((cell) => int.tryParse(cell.trim()))
        .whereType<int>()
        .toList();

    expect(levels, Progression.slotUnlockLevels,
        reason: 'doc table and Progression.slotUnlockLevels disagree');
    expect(Progression.startingSlots + levels.length, Progression.slotsAtCap,
        reason: 'the schedule must land exactly on the level-50 slot count');
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
