import 'package:flutter_test/flutter_test.dart';
import 'package:mom_engine/mom_engine.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/progression.dart';

/// Guards the roster invariants that are otherwise only asserted in comments:
/// the level spread, the 1-10 intelligence scale, and — most importantly —
/// that no persona wields magic a player of that level could not yet face.
void main() {
  /// Tier unlock levels, PROGRESSION_DESIGN.md §"Unlock schedule".
  const tierUnlockLevel = {
    MagicTier.primal: 1,
    MagicTier.kinetic: 15,
    MagicTier.celestial: 30,
    MagicTier.ethereal: 45,
  };

  test('levels spread from 1 to the cap, with Procarius alone above it', () {
    final levels = AiRoster.all.map((p) => p.level).toList();

    expect(levels, [1, 15, 28, 40, 50, 60], reason: 'evenly spread 1..50, +60');
    expect(levels, orderedEquals(List.of(levels)..sort()),
        reason: 'AiRoster.all must stay weakest-to-strongest');

    final aboveCap = AiRoster.all.where((p) => p.level > 50).toList();
    expect(aboveCap.map((p) => p.name), ['Procarius'],
        reason: 'only the Eclipsed sits above the player level cap');
  });

  test('intelligence stays on the 1-10 ladder and rises with level', () {
    for (final p in AiRoster.all) {
      expect(p.intelligence, inInclusiveRange(1, 10), reason: p.name);
    }

    // "Generally higher level enemies can be smarter" — monotonic here, though
    // the two axes are independent by design, so this is a roster convention
    // rather than a property of AiPersona.
    final byLevel = List.of(AiRoster.all)
      ..sort((a, b) => a.level.compareTo(b.level));
    final smarts = byLevel.map((p) => p.intelligence).toList();
    expect(smarts, orderedEquals(List.of(smarts)..sort()));
  });

  test('every persona loadout is legal for its own level', () {
    for (final p in AiRoster.all) {
      for (final element in p.loadout.elements) {
        final needs = tierUnlockLevel[element.tier]!;
        expect(p.level, greaterThanOrEqualTo(needs),
            reason: '${p.name} (L${p.level}) carries ${element.name}, but '
                '${element.tier.name} unlocks at L$needs');
      }
      for (final spell in p.loadout.spells) {
        expect(p.level, greaterThanOrEqualTo(Progression.unlockLevelOf(spell)),
            reason: '${p.name} (L${p.level}) carries ${spell.id}, which '
                'unlocks at L${Progression.unlockLevelOf(spell)}');
      }
    }
  });

  // Elements and spells share one pool now, so a persona's kit has to fit the
  // pool a *player* of that level would have — otherwise the opponent is
  // carrying more than the person fighting it. This caught Wick at 8 slots
  // against a level-1 budget of 5.
  test('every persona fits the slot pool for its own level', () {
    for (final p in AiRoster.all) {
      expect(p.loadout.slotsUsed,
          lessThanOrEqualTo(Progression.slotsAtLevel(p.level)),
          reason: '${p.name} (L${p.level}) fills ${p.loadout.slotsUsed} slots, '
              'but L${p.level} grants ${Progression.slotsAtLevel(p.level)}');
    }
  });

  test('loadouts respect the per-kind keybind limits and scale with level',
      () {
    for (final p in AiRoster.all) {
      expect(p.loadout.elements.length,
          inInclusiveRange(1, Loadout.maxElementSlots),
          reason: p.name);
      expect(p.loadout.spells.length,
          inInclusiveRange(1, Loadout.maxSpellSlots),
          reason: p.name);
      expect(p.loadout.slotsUsed, lessThanOrEqualTo(Loadout.maxSlots),
          reason: p.name);
      expect(p.loadout.elements.toSet().length, p.loadout.elements.length,
          reason: '${p.name} lists a duplicate element');
      expect(p.loadout.spells.map((s) => s.id).toSet().length,
          p.loadout.spells.length,
          reason: '${p.name} lists a duplicate spell');
    }

    // A level-50 opponent should bring what a level-50 player brings: the full
    // 15-slot pool, not the 8 a persona used to carry.
    for (final p in AiRoster.all.where((p) => p.level >= 50)) {
      expect(p.loadout.slotsUsed, Progression.slotsAtCap,
          reason: '${p.name} is under-equipped for its level');
    }
  });

  test('blunder rate falls as intelligence rises, and 10 never blunders', () {
    double? previous;
    for (var i = 1; i <= 10; i++) {
      final rate = blunderChanceForIntelligence(i);
      expect(rate, inInclusiveRange(0.0, 1.0));
      if (previous != null) expect(rate, lessThan(previous));
      previous = rate;
    }
    expect(previous, 0.0, reason: 'intelligence 10 is as optimal as we can make it');
  });

  test('each persona reports the blunder rate its rating implies', () {
    for (final p in AiRoster.all) {
      expect(p.mistakeChance, blunderChanceForIntelligence(p.intelligence),
          reason: p.name);
    }
  });

  test('the ladder is clamped, so an out-of-range rating cannot go wild', () {
    expect(blunderChanceForIntelligence(0), blunderChanceForIntelligence(1));
    expect(blunderChanceForIntelligence(99), blunderChanceForIntelligence(10));
  });

  test('every persona builds a usable brain', () {
    for (final p in AiRoster.all) {
      expect(p.buildBrain(), isNotNull, reason: p.name);
    }
  });

  // campaignFoe overrides the level while keeping a borrowed kit, so the
  // borrow direction decides whether wild opponents stay legal. Sweep the whole
  // player range — this caught a L9 foe carrying Brightgale's Aero.
  test('campaign foes never wield magic locked at their own level', () {
    for (var level = 1; level <= 60; level++) {
      final foe = AiRoster.campaignFoe(name: 'Wild', level: level);
      for (final element in foe.loadout.elements) {
        final needs = tierUnlockLevel[element.tier]!;
        expect(level, greaterThanOrEqualTo(needs),
            reason: 'a L$level campaign foe borrowed ${element.name} '
                '(${element.tier.name}, unlocks L$needs) from '
                '${AiRoster.strongestAtOrBelow(level).name}');
      }
      for (final spell in foe.loadout.spells) {
        expect(level, greaterThanOrEqualTo(Progression.unlockLevelOf(spell)),
            reason: 'a L$level campaign foe borrowed ${spell.id} '
                '(unlocks L${Progression.unlockLevelOf(spell)})');
      }
    }
  });

  test('kit borrowing never reaches above the requested level', () {
    expect(AiRoster.strongestAtOrBelow(60).name, 'Procarius');
    expect(AiRoster.strongestAtOrBelow(50).name, "Al'Dorian");
    expect(AiRoster.strongestAtOrBelow(49).name, 'Morwen');
    expect(AiRoster.strongestAtOrBelow(14).name, 'Wick');
    // Below the weakest persona there is nothing to borrow down to, so it
    // falls back rather than reaching up.
    expect(AiRoster.strongestAtOrBelow(0).name, 'Wick');
  });

  test('ids are unique and stable', () {
    final ids = AiRoster.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(AiRoster.byId(id).id, id);
    }
  });
}
