import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_shattered_orrery.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_shattered_orrery_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **Parallel-lane ids.** `astral_*` ships with the Starfall Basin lane and
/// `pilgrims_ration` with The Kiln Desert lane, both in flight as this file is
/// written (CELESTIAL_CONTRACT §7.3). Everything this zone OWNS is asserted
/// unconditionally; the whole-table resolution law is written and skipped
/// until the merge coordinator lands the siblings.
const _parallelLaneIds = {
  'astral_dust',
  'astral_shard',
  'astral_crystal',
  'pilgrims_ration',
};

void main() {
  const zone = 'the_shattered_orrery';
  final all = ShatteredOrreryBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        ShatteredOrreryBestiary.commons,
        hasLength(5),
        reason: 'a sixth common (or a missing one) drifts from §4.6',
      );
      expect(
        ShatteredOrreryBestiary.minis,
        hasLength(4),
        reason: 'a run draws 2 of 4 — a short pool repeats itself',
      );
      expect(
        ShatteredOrreryBestiary.bosses,
        hasLength(2),
        reason: 'the process and the result are both required',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (§7.1) — an unlisted
      // zone compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'the zone is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'Bestiary.all and the zone file disagree about the roster',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(ShatteredOrreryBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so the pool repeats a role');
    });

    test('the boss pair is a process and its result, NOT a mirror', () {
      // ⭐⭐ §4.6: The Calculation is the power (Juggernaut — a mass that
      // grinds); The Answer is what the power was for (Tyrant — the one thing
      // here that decided). No Aspect in this zone.
      expect(
        ShatteredOrreryBestiary.theCalculation.archetype.id,
        'juggernaut',
        reason: 'the process must be a mass, not a will',
      );
      expect(
        ShatteredOrreryBestiary.theAnswer.archetype.id,
        'tyrant',
        reason: 'drawing The Answer must mean something decided and finished',
      );
      expect(
        ShatteredOrreryBestiary.theCalculation.archetype.id,
        isNot(ShatteredOrreryBestiary.theAnswer.archetype.id),
        reason: 'a mirrored pair says nothing (ENEMIES §2f)',
      );
    });

    test('archetypes sit in the tier their rank calls for', () {
      const expected = {
        EnemyRank.common: EnemyTier.common,
        EnemyRank.mini: EnemyTier.mini,
        EnemyRank.boss: EnemyTier.boss,
      };
      for (final e in all) {
        expect(
          e.archetype.tier,
          expected[e.rank],
          reason: '${e.id} is a ${e.rank.name} but its archetype is not',
        );
      }
    });

    test('ids and names are unique', () {
      expect(
        all.map((e) => e.id).toSet(),
        hasLength(all.length),
        reason: 'two creatures share an id, so one is unreachable',
      );
      expect(
        all.map((e) => e.name).toSet(),
        hasLength(all.length),
        reason: 'two creatures share a name, so the log is ambiguous',
      );
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      // An id that drifts from its name is a rename nobody notices.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r"[^a-z0-9]+"),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('every creature carries only Astral and/or Electro, and its own zone '
        'holds both', () {
      final loc = World.byId(zone);
      const legal = {MagicElement.astral, MagicElement.electro};
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is filed under the wrong zone');
        expect(e.elements, isNotEmpty, reason: '${e.id} has no element');
        for (final el in e.elements) {
          expect(
            legal,
            contains(el),
            reason: '${e.id} carries a foreign element',
          );
          expect(
            loc.elements,
            contains(el),
            reason: '${e.id} uses an element world.dart does not give the zone',
          );
        }
      }
    });

    test('the per-creature element assignment matches §4.6 exactly', () {
      // ⚠️ Hard-coded from the roster table — a hybrid assigns element PER
      // CREATURE, and "both by default" is the mutant this kills.
      const astral = [MagicElement.astral];
      const electro = [MagicElement.electro];
      const both = [MagicElement.astral, MagicElement.electro];
      const expected = {
        'orrery_automaton': both,
        'gear_ghost': astral,
        'armature': electro,
        'arcflock': electro,
        'errant_ring': astral,
        'sidereal_fault': astral,
        'escapement': electro,
        'long_division': both,
        'the_remainder': astral,
        'the_calculation': electro,
        'the_answer': astral,
      };
      for (final e in all) {
        expect(
          e.elements,
          expected[e.id],
          reason: '${e.id} does not carry §4.6\'s element assignment',
        );
      }
    });

    test('no creature carries an off-element move', () {
      // ⚠️ ENEMIES §2e.2 names the only FOUR creatures in fifteen zones that
      // may carry a third element, and none of them is here. The elements
      // list is the whole surface an off-element would show on.
      const legal = {MagicElement.astral, MagicElement.electro};
      for (final e in all) {
        expect(
          e.elements.toSet().difference(legal),
          isEmpty,
          reason: '${e.id} took an off-element §2e.2 never granted this zone',
        );
      }
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'the anchor name in world.dart matches no creature',
      );
      // ✅ §4.6 — Orrery Automaton is Sentinel → Adept, the zone's anchor and
      // its yardstick.
      expect(
        ShatteredOrreryBestiary.orreryAutomaton.archetype.id,
        'adept',
        reason: 'the anchor was re-banded to Adept; a Sentinel here is stale',
      );
    });

    test('the zone band is 40–44, and it is a dungeon', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 40, reason: 'the band floor drifted');
      expect(loc.maxLevel, 44, reason: 'the band ceiling drifted');
      expect(
        loc.kind,
        LocationKind.dungeon,
        reason: '🏰 stands even though the structure is deferred (§4.6)',
      );
    });
  });

  group('combat stats match CELESTIAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present in this zone is checked
    // against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        ShatteredOrreryBestiary.orreryAutomaton.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        ShatteredOrreryBestiary.gearGhost.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
        reason: 'the Gear-Ghost is not carrying §2.3\'s Glasswing row',
      );
    });

    test('the Bruiser telegraphs and hits hard when it lands', () {
      expect(
        ShatteredOrreryBestiary.armature.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
        reason: 'the Armature is not carrying §2.3\'s Bruiser row',
      );
    });

    test('the Lasher crits often and softly', () {
      expect(
        ShatteredOrreryBestiary.arcflock.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason:
            'the Arcflock is not carrying §2.3\'s Lasher row — the NEGATIVE '
            'crit damage is the whole point of "chips rather than shatters"',
      );
    });

    test('the Skirmisher is accurate and slippery', () {
      expect(
        ShatteredOrreryBestiary.errantRing.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
        reason: 'the Errant Ring is not carrying §2.3\'s Skirmisher row',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        ShatteredOrreryBestiary.siderealFault.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Sidereal Fault is not carrying §2.3\'s Champion row',
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        ShatteredOrreryBestiary.escapement.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason: 'the Escapement is not carrying §2.3\'s Redoubt row',
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        ShatteredOrreryBestiary.longDivision.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason: 'Long Division is not carrying §2.3\'s Executioner row',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        ShatteredOrreryBestiary.theRemainder.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'The Remainder is not carrying §2.3\'s Hexer row',
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        ShatteredOrreryBestiary.theCalculation.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
        reason: 'The Calculation is not carrying §2.3\'s Juggernaut row',
      );
    });

    test('the Tyrant carries every lever at once', () {
      expect(
        ShatteredOrreryBestiary.theAnswer.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 5,
          dodge: 5,
          critChance: 10,
          critDamage: 15,
          deflectChance: 10,
          deflectAmount: 15,
        ),
        reason: 'The Answer is not carrying §2.3\'s Tyrant row',
      );
    });

    test('no boss in this zone is an Aspect', () {
      // ⚠️ §2.4 lists the quarter's six Aspects by name and neither of these
      // is one — an Aspect must be single-element and lean entirely on its
      // element's passive, which is not what a process-and-result pair does.
      for (final b in ShatteredOrreryBestiary.bosses) {
        expect(
          b.archetype.id,
          isNot('aspect'),
          reason: '${b.id} became an Aspect §2.4 never authorised',
        );
      }
    });

    test('enemy dodge never exceeds the §2.3 cap of 10', () {
      for (final e in all) {
        expect(
          e.combatStats.dodge,
          lessThanOrEqualTo(10),
          reason:
              '${e.id} — enemy dodge should read as slippery, never '
              'unhittable',
        );
      }
    });

    test('crit damage and deflect amount never appear without their '
        'chance', () {
      // ⚠️ §2.1's inert-stat traps: a "buff" with a zero chance to trigger is
      // dead weight nobody notices until they read the code.
      for (final e in all) {
        final s = e.combatStats;
        expect(
          s.critDamage == 0 || s.critChance > 0,
          isTrue,
          reason: '${e.id} has crit damage but critChance == 0',
        );
        expect(
          s.deflectAmount == 0 || s.deflectChance > 0,
          isTrue,
          reason: '${e.id} has deflect amount but deflectChance == 0',
        );
        expect(
          s.deflectChance == 0 || s.deflectAmount > 0,
          isTrue,
          reason: '${e.id} has deflect chance but deflectAmount == 0',
        );
      }
    });
  });

  group('creatures are creatures, not mages', () {
    test('no creature here is a mage', () {
      // ⚠️ ENEMIES §3.4 — only the Collapsed Academy and Citadel lanes field
      // a mage boss, whose moves are a Spellbook loadout rather than a kit.
      // This zone's bosses are a machine and a number.
      final spellIds = Spellbook.all.map((s) => s.id).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          expect(
            spellIds.contains(m.id),
            isFalse,
            reason: '${e.id}\'s "${m.name}" reuses a Spellbook id',
          );
        }
      }
    });

    test('move ids are unique across the WHOLE bestiary, and all so_ '
        'prefixed', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding (§3.5).
      // Checked against every shipped zone, not just this one.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason: 'two moves in this zone share an id',
      );
      for (final id in mine) {
        expect(id.startsWith('so_'), isTrue, reason: '$id is not zone-tagged');
      }
      final foreign = [
        for (final e in Bestiary.all)
          if (e.zoneId != zone) ...e.moves.map((m) => m.id),
      ];
      for (final id in mine) {
        expect(
          foreign,
          isNot(contains(id)),
          reason: '$id collides with a move in another zone',
        );
      }
    });

    test('no move name collides with the game\'s own vocabulary', () {
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          final n = m.name.toLowerCase();
          expect(
            reservedVerbs.contains(n),
            isFalse,
            reason: '"${m.name}" is one of the game\'s own verbs',
          );
          expect(
            elements.contains(n),
            isFalse,
            reason: '"${m.name}" is an element name',
          );
        }
      }
    });

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree. ⚠️ No mage in
      // this zone, so nothing is exempt from the move-count law.
      for (final e in all) {
        final a = e.archetype;
        expect(
          e.moves.length,
          a.moveCount,
          reason: '${e.id} is a ${a.name}, which wants ${a.moveCount} moves',
        );
        final costs = e.moves.map((m) => m.chargeCost);
        expect(
          costs.reduce((x, y) => x < y ? x : y),
          greaterThanOrEqualTo(a.minMoveCost),
          reason: '${e.id} has a cheaper move than a ${a.name} should',
        );
        expect(
          costs.reduce((x, y) => x > y ? x : y),
          lessThanOrEqualTo(a.maxMoveCost),
          reason: '${e.id} has a more expensive move than a ${a.name} should',
        );
      }
    });

    test('raw damage stays inside §1.3\'s shared ceiling', () {
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so this zone's 40–44 band arrives via the ENCOUNTER LEVEL,
      // never bigger raws — §1.3 is byte-for-byte KINETIC's and does not grow.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.maxAmount * effect.hits,
            lessThanOrEqualTo(60),
            reason: '${e.id}\'s "${m.name}" is above the shared ceiling',
          );
          expect(
            effect.averageTotal / m.chargeCost,
            lessThanOrEqualTo(12),
            reason: '${e.id}\'s "${m.name}" is too efficient per charge',
          );
        }
      }
    });

    test('priorities use the shipped integer ladder', () {
      // ⚠️ A shield at 9 arrives after the attack it was meant to stop, and
      // 1–2 is reserved for genuinely Quickened strikes.
      for (final e in all) {
        for (final m in e.moves) {
          expect(
            m.priority,
            inInclusiveRange(1, 10),
            reason: '${e.id}\'s "${m.name}" is off the 1–10 ladder',
          );
          if (m.effect is ShieldEffect) {
            expect(
              m.priority,
              lessThanOrEqualTo(3),
              reason:
                  '${e.id}\'s "${m.name}" is a shield that lands after the '
                  'attack it should have stopped',
            );
          }
        }
      }
    });

    test('the Lasher chips — both its moves are multi-hit', () {
      // ⚠️ §2.5's lesson: "shields chip rather than shatter" only reads if
      // every hit meets the shield separately.
      final arcflock = ShatteredOrreryBestiary.arcflock;
      expect(arcflock.archetype.id, 'lasher');
      for (final m in arcflock.moves) {
        expect(
          m.effect,
          isA<DamageEffect>(),
          reason: 'a Lasher that shields is not chipping anything',
        );
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.id} is a single big hit, which shatters, not chips',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Redoubt/Juggernaut are defined partly by attrition. Without a
      // ShieldEffect the archetype is only a bigger HP number.
      for (final e in all) {
        if (!{'sentinel', 'redoubt', 'juggernaut'}.contains(e.archetype.id)) {
          continue;
        }
        expect(
          e.moves.any((m) => m.effect is ShieldEffect),
          isTrue,
          reason:
              '${e.id} is a ${e.archetype.name} with nothing to hide behind',
        );
      }
    });

    test('the Redoubt\'s wall lands ahead of the player\'s own shield', () {
      final escapement = ShatteredOrreryBestiary.escapement;
      final wall = escapement.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(
        wall.priority,
        lessThan(3),
        reason: 'the Escapement\'s lock arrives after the player commits',
      );
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final remainder = ShatteredOrreryBestiary.theRemainder;
      expect(remainder.archetype.id, 'hexer');
      expect(
        remainder.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        remainder.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing The Remainder throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays at 4, and it executes', () {
      // ⚠️ §1.3 — at cost 5 a mini Executioner's raw is a one-shot with
      // change. Kills a mutant that reverts to the archetype's own cap of 5.
      final division = ShatteredOrreryBestiary.longDivision;
      expect(division.archetype.id, 'executioner');
      for (final m in division.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '${m.id} breaches §1.3\'s lowered Executioner cap',
        );
      }
      expect(
        division.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).executeBelowPercent > 0,
        ),
        isTrue,
        reason: 'long division that never finishes dividing is not the joke',
      );
    });

    test('nothing in this zone lifesteals', () {
      // ⭐ ENEMIES §2.6 — the Siphon is Thornmire's reveal and this quarter's
      // own archetype; no creature here takes what is yours.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" spoils the Siphon\'s reveal',
          );
        }
      }
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id this zone OWNS is a real item', () {
      // ⚠️ Excludes the two parallel lanes' ids only — everything the Orrery
      // defines itself, plus Q2's electro_*, must resolve today.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_parallelLaneIds.contains(id)) continue;
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('every id in every table is a real item', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('every main table draws exactly one entry, by weight', () {
      for (final e in all) {
        if (e.drops.main.isEmpty) continue;
        expect(
          e.drops.totalWeight,
          greaterThan(0),
          reason: '${e.id} has a main table that can never resolve',
        );
      }
    });

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in ShatteredOrreryBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...ShatteredOrreryBestiary.minis,
        ...ShatteredOrreryBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in ShatteredOrreryBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          final def = ItemCatalogue.tryById(id);
          if (def == null) continue; // parallel lane; the law above covers it
          expect(
            def.rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a hybrid drops BOTH parents\' mote ladders, and no third', () {
      // ⭐ §3.2 — the Orrery defines NO motes of its own; it pays in the
      // astral_* (Starfall Basin) and electro_* (Stormcliff Coast, **Q2**)
      // families. The Q2 half is the only reason a level-40 player ever sees
      // an Electro Dust again.
      final dropped = ShatteredOrreryBestiary.allDrops;
      for (final id in [
        'astral_dust',
        'astral_shard',
        'astral_crystal',
        'electro_dust',
        'electro_shard',
        'electro_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      const foreign = {
        'solar_dust', 'solar_shard', 'solar_crystal', //
        'lunar_dust', 'lunar_shard', 'lunar_crystal',
        'arcane_dust', 'arcane_shard', 'arcane_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'aero_dust', 'aero_shard', 'aero_crystal',
        'geo_dust', 'geo_shard', 'geo_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
        'flora_dust', 'flora_shard', 'flora_crystal',
      };
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight the
      // player chose (§7.5: never on a common).
      for (final e in ShatteredOrreryBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final e in ShatteredOrreryBestiary.minis) {
        expect(
          e.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${e.id} does not offer both Crystals',
        );
      }
      for (final b in ShatteredOrreryBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️ neither boss carries a gate part — a hybrid never did', () {
      // ⭐ ENEMIES §2e.1: the Celestial Totem is supplied by the quarter's
      // three PURE zones. A fourth supplier here would silently loosen the
      // gate. Kills the mutant that copies a pure zone's boss table wholesale.
      for (final b in ShatteredOrreryBestiary.bosses) {
        for (final id in b.drops.possibleDrops) {
          expect(
            id,
            isNot(contains('essence')),
            reason: '${b.id} drops a gate part this zone must not supply',
          );
          expect(
            id,
            isNot(contains('totem')),
            reason: '${b.id} drops the gate item itself',
          );
        }
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in ShatteredOrreryBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('sidereal_signet'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('sidereal_signet'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(
        ItemCatalogue.byId('sidereal_signet').rarity,
        Rarity.rare,
        reason: 'the chase stopped being Rare',
      );
    });

    test('the epic is boss-only, and rationed', () {
      final epics = ShatteredOrreryItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(
        epics,
        contains('the_running_count'),
        reason: 'the zone lost its epic',
      );
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(
            e.drops.mainChanceOf(id),
            lessThanOrEqualTo(0.15),
            reason: '${e.id} hands the epic out too freely',
          );
        }
      }
    });

    test('the Automaton is the only common that yields the lens or a '
        'draught', () {
      // ⚠️ §4.6's "the Sentinel" row — named for the archetype this creature
      // carried before the re-band, and the only common table carrying
      // sidereal_glass or arcsalt_draught.
      for (final e in ShatteredOrreryBestiary.commons) {
        final rich =
            e.drops.possibleDrops.contains('sidereal_glass') ||
            e.drops.possibleDrops.contains('arcsalt_draught');
        expect(
          rich,
          e.id == 'orrery_automaton',
          reason: '${e.id} does not match §4.6\'s common drop-table shape',
        );
      }
    });
  });

  group('the catalogue matches §4.6', () {
    test('9 defs, and that is the whole zone', () {
      expect(
        ShatteredOrreryItems.all,
        hasLength(9),
        reason:
            'the quarter\'s smallest catalogue is correct — the Orrery has '
            'no wood, no cloth and no hide. 📝 7 → 9 on 2026-10-01: the '
            'Jewelry ladder\'s top rung (sidereal ring + pendant, ENCHANTING '
            '§5.3) is defined here',
      );
    });

    test('every item is resolvable under this zone', () {
      for (final def in ShatteredOrreryItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⚠️ the zone defines NO mote family', () {
      // ⭐ §3.2 — a hybrid never defines one, and both parents already have
      // theirs. A MoteDef here would give astral_* or electro_* a second home.
      expect(
        ShatteredOrreryItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'a hybrid that defines motes re-homes another zone\'s ladder',
      );
    });

    test('every material is tier 7 salvage on the right skill', () {
      const expected = {
        'orrery_scrap': CraftSkill.metalworking,
        'arcsalt': CraftSkill.potionsAndAlchemy,
        'sidereal_glass': CraftSkill.jewelry,
        'starbrass_ingot': CraftSkill.metalworking,
      };
      final materials = ShatteredOrreryItems.all.whereType<MaterialDef>();
      expect(
        materials.map((m) => m.id).toSet(),
        expected.keys.toSet(),
        reason: 'the material set drifted from §4.6',
      );
      for (final m in materials) {
        expect(
          m.skill,
          expected[m.id],
          reason: '${m.id} feeds the wrong skill',
        );
        expect(m.tier, 7, reason: '${m.id} is off the band-40 material tier');
      }
    });

    test('values are §4.6\'s, verbatim', () {
      const expected = {
        'orrery_scrap': 48,
        'arcsalt': 32,
        'sidereal_glass': 160,
        'starbrass_ingot': 200,
        'arcsalt_draught': 95,
        'sidereal_signet': 1600,
        'the_running_count': 4500,
        // 📝 2026-10-01, ENCHANTING §5.3 / ECONOMY §8.8 — the Jewelry ladder.
        'sidereal_ring': 390,
        'sidereal_pendant': 530,
      };
      for (final def in ShatteredOrreryItems.all) {
        expect(
          def.value,
          expected[def.id],
          reason: '${def.id} has drifted from the contract value',
        );
      }
    });

    test('the draught heals 185 — the band-40 rung of the ladder', () {
      final draught = ShatteredOrreryItems.arcsaltDraught;
      expect(
        draught.effect.heal,
        185,
        reason: 'the Orrery\'s rung on §3.3\'s potion ladder moved',
      );
    });

    test('both named drops set properName and stay untradeable', () {
      // ⚠️ §3.5 — crafted equipment composes its name from material + form
      // and MUST leave properName null; drop-only jewelry and boss uniques
      // set it. These two are drops.
      for (final def in [
        ShatteredOrreryItems.siderealSignet,
        ShatteredOrreryItems.theRunningCount,
      ]) {
        expect(
          def.properName,
          isNotNull,
          reason: '${def.id} would compose its name from material + form',
        );
        expect(
          def.tradability,
          Tradability.untradeable,
          reason: '${def.id} could be bought instead of earned',
        );
        expect(
          def.material,
          'Starbrass',
          reason: '${def.id} is not made of the zone\'s own remelted mechanism',
        );
      }
    });

    test('every equipLevel sits in the band; materials sit at or below it', () {
      final loc = World.byId(zone);
      for (final def in ShatteredOrreryItems.all) {
        if (def is EquipmentDef) {
          expect(
            def.equipLevel,
            inInclusiveRange(loc.minLevel, loc.maxLevel),
            reason: '${def.id} cannot be worn by anyone who farms it',
          );
        } else {
          expect(
            def.equipLevel,
            lessThanOrEqualTo(loc.minLevel),
            reason: '${def.id} is gated above the zone that yields it',
          );
        }
      }
    });

    test('gear rarity stays common / rare / epic', () {
      // ⚠️ §7.5 — no Uncommon, Mythic or Legendary equipment in this quarter.
      const legal = {Rarity.common, Rarity.rare, Rarity.epic};
      for (final def in ShatteredOrreryItems.all.whereType<EquipmentDef>()) {
        expect(
          legal,
          contains(def.rarity),
          reason: '${def.id} uses a rarity the quarter does not ship for gear',
        );
      }
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('three nodes, and all three are salvage', () {
      // ⭐ §9b.8's 3-per-hybrid rule, met entirely out of a broken machine —
      // the zone has no hide, so nothing is kill-only here.
      expect(nodes, hasLength(3), reason: 'the node count drifted from §6');
      expect(nodes.map((n) => n.id).toSet(), {
        'so_scrap_ring',
        'so_arcsalt_earthing',
        'so_lens_shatter',
      }, reason: 'a node id drifted from the contract');
    });

    test('the three nodes cover the three gatherable materials, on the '
        'skill §3.1 assigns each', () {
      // ⚠️ Kills the swapped-yield mutant: a node pointed at the WRONG
      // material of the same zone still yields "a real material of this
      // zone", so the check above blesses it — and `sidereal_glass` would
      // then have no source at all while `orrery_scrap` quietly had two.
      const expected = {
        'so_scrap_ring': ('orrery_scrap', GatherSkill.mining),
        'so_arcsalt_earthing': ('arcsalt', GatherSkill.foraging),
        'so_lens_shatter': ('sidereal_glass', GatherSkill.mining),
      };
      for (final n in nodes) {
        expect(
          (n.yieldsDefId, n.skill),
          expected[n.id],
          reason: '${n.id} yields or is worked by the wrong thing',
        );
      }
      expect(
        nodes.map((n) => n.yieldsDefId).toSet(),
        hasLength(3),
        reason: 'two nodes yield the same material, so one material has none',
      );
      // ⭐ §4.6: the ingot is the only non-gathered material here. Everything
      // else the zone defines is dug or scraped off the machine.
      expect(
        nodes.map((n) => n.yieldsDefId).toSet(),
        ShatteredOrreryItems.all
            .whereType<MaterialDef>()
            .map((m) => m.id)
            .toSet()
            .difference({'starbrass_ingot'}),
        reason:
            'a material of this zone has no node, or a node has no material',
      );
    });

    test('every node is reachable from GatherNodes.all', () {
      // ⚠️ An unlisted node compiles fine and simply never spawns.
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} is not in GatherNodes.all',
        );
      }
    });

    test('every node yields a real, fungible material of THIS zone', () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields ${n.yieldsDefId}, which is not stackable',
        );
        expect(def, isA<MaterialDef>(), reason: '${n.id} yields non-material');
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} yields another zone\'s material',
        );
        expect(n.min, greaterThan(0), reason: '${n.id} can yield nothing');
        expect(
          n.max,
          greaterThanOrEqualTo(n.min),
          reason: '${n.id} has an inverted yield range',
        );
      }
    });

    test('the ingot has no node — it is remelted, not dug up', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('starbrass_ingot')),
        reason:
            'a node for an intermediate good is a second source that skips '
            'the recipe it exists for',
      );
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 87, reason: 'the band-40 XP rung moved');
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final ghost = ShatteredOrreryBestiary.gearGhost;
      final calculation = ShatteredOrreryBestiary.theCalculation;
      expect(
        ghost.maxHpAt(40),
        (MageState.scaledMaxHp(40) * Archetypes.glasswing.hpScale).round(),
        reason: 'the Glasswing grew a second HP curve',
      );
      expect(
        calculation.maxHpAt(44),
        (MageState.scaledMaxHp(44) * Archetypes.juggernaut.hpScale).round(),
        reason: 'the Juggernaut grew a second HP curve',
      );
      expect(
        calculation.maxHpAt(44),
        greaterThan(ghost.maxHpAt(44)),
        reason: 'the boss is not the bigger body',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 40. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(40);
      for (final e in ShatteredOrreryBestiary.commons) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          final worst = effect.maxAmount * effect.hits;
          expect(
            worst,
            lessThan(startingHp),
            reason: '${e.id}\'s "${m.name}" can hit for $worst',
          );
        }
      }
    });
  });

  group('the lore channel is populated', () {
    test('every creature carries a field note, in the right voice', () {
      for (final e in all) {
        expect(e.lore.length, greaterThan(40), reason: '${e.id} lore is thin');
        expect(
          e.lore.endsWith('.'),
          isTrue,
          reason: '${e.id} lore is not a sentence',
        );
        expect(
          RegExp(
            r'\d+\s*(hp|damage|dmg)',
            caseSensitive: false,
          ).hasMatch(e.lore),
          isFalse,
          reason: '${e.id} lore leaks mechanics',
        );
      }
    });

    test('every item carries lore that is not a stat line', () {
      for (final def in ShatteredOrreryItems.all) {
        expect(
          def.lore.length,
          greaterThan(40),
          reason: '${def.id} lore is thin',
        );
        expect(
          RegExp(r'\d').hasMatch(def.lore),
          isFalse,
          reason: '${def.id} lore leaks a number',
        );
      }
    });
  });
}
