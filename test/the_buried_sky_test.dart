import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_buried_sky.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_buried_sky_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **Parallel-lane ids.** `climbers_ration` and `goldenrood_draught` ship
/// with the **Hallowmarch** lane, in flight as this file is written
/// (ETHEREAL_CONTRACT §7.3). Everything this zone OWNS — plus `geo_*` from Q2
/// and `astral_*` from Q3, both already on main — is asserted
/// unconditionally; the whole-table resolution law is written and skipped
/// until the merge coordinator lands the sibling.
const _parallelLaneIds = {'climbers_ration', 'goldenrood_draught'};

const _skipUntilSiblings =
    'climbers_ration and goldenrood_draught land with the hallowmarch lane — '
    'un-skip when it is on main';

void main() {
  const zone = 'the_buried_sky';
  final all = BuriedSkyBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        BuriedSkyBestiary.commons,
        hasLength(5),
        reason: 'a sixth common (or a missing one) drifts from §2e',
      );
      expect(
        BuriedSkyBestiary.minis,
        hasLength(4),
        reason: 'a run draws 2 of 4 — a short pool repeats itself',
      );
      expect(
        BuriedSkyBestiary.bosses,
        hasLength(2),
        reason: 'what buries and what lasts are both required',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives — an unlisted zone
      // compiles fine and never appears in an encounter.
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
      expect(BuriedSkyBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so the pool repeats a role');
    });

    test('the boss pair is what buries and what lasts, NOT a mirror', () {
      // ⭐⭐ §2e: Geo buries (Juggernaut — a weight), Astral survives (Aspect —
      // one element taken further than the player has met it).
      expect(
        BuriedSkyBestiary.theOverburden.archetype.id,
        'juggernaut',
        reason: 'what buries must be a weight, not a will',
      );
      expect(
        BuriedSkyBestiary.theBuriedConstellation.archetype.id,
        'aspect',
        reason: 'what survives is the quarter\'s Astral Aspect (§2.4)',
      );
      expect(
        BuriedSkyBestiary.theOverburden.archetype.id,
        isNot(BuriedSkyBestiary.theBuriedConstellation.archetype.id),
        reason: 'a mirrored pair says nothing (ENEMIES §2f)',
      );
    });

    test('the Aspect is single-element, and it is the Astral half', () {
      // ⚠️ §2.4 — an Aspect leans entirely on its own element's passive, so it
      // must be single-element. ⚠️ ASTRAL, not Geo: "Geo is what buried it;
      // Astral is what survived."
      final aspect = BuriedSkyBestiary.theBuriedConstellation;
      expect(aspect.elements, [
        MagicElement.astral,
      ], reason: 'a two-element Aspect leans on nothing in particular');
      expect(
        BuriedSkyBestiary.theOverburden.archetype.id,
        isNot('aspect'),
        reason: 'the zone fields exactly one Aspect (§2.4)',
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

    test('⚠️ the Corebiter is a Bruiser — the Siphon was cut', () {
      // ⭐ ENEMIES §2f: "it eats rock, not you." The Siphon was cut from eight
      // zones to three and this is one of the cuts. Kills the mutant that
      // restores the roster table's parenthesised old archetype.
      expect(
        BuriedSkyBestiary.corebiter.archetype.id,
        'bruiser',
        reason: 'the Corebiter takes what is the rock\'s, never what is yours',
      );
      for (final e in all) {
        expect(
          e.archetype.id,
          isNot('siphon'),
          reason: '${e.id} re-introduces an archetype §2f cut from this zone',
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
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('every creature is filed under this zone, and world.dart gives the '
        'zone both its elements', () {
      final loc = World.byId(zone);
      expect(loc.elements, [
        MagicElement.geo,
        MagicElement.astral,
      ], reason: 'world.dart no longer calls this zone Geo + Astral');
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is filed under the wrong zone');
        expect(e.elements, isNotEmpty, reason: '${e.id} has no element');
      }
    });

    test('the per-creature element assignment matches §2e exactly', () {
      // ⚠️ Hard-coded from the roster table — a hybrid assigns element PER
      // CREATURE, and "both by default" is the mutant this kills.
      const geo = [MagicElement.geo];
      const astral = [MagicElement.astral];
      const both = [MagicElement.geo, MagicElement.astral];
      const expected = {
        'stratum_warden': geo,
        'constellate': astral,
        'fadelight': astral,
        'corebiter': geo,
        'deadreckoner': both,
        'stonefall_herald': both,
        'bedrock_colossus': geo,
        'nadir': geo,
        'the_long_count': [MagicElement.astral],
        'the_overburden': geo,
        'the_buried_constellation': astral,
      };
      for (final e in all) {
        expect(
          e.elements,
          expected[e.id],
          reason: '${e.id} does not carry §2e\'s element assignment',
        );
      }
    });

    test('✅ the zone carries NO off-element creature — the lunar grant was '
        'withdrawn', () {
      // §2e.2 once granted The Long Count a lunar move, reasoning that Lunar
      // is "neither" of the zone's counters. The wheel says otherwise:
      // astral.counteredBy IS lunar, and §2h's law wins. Pinned both ways.
      const zoneElements = {MagicElement.geo, MagicElement.astral};
      expect(
        all.where((e) => e.elements.any((el) => !zoneElements.contains(el))),
        isEmpty,
        reason:
            'a mutant restoring the lunar grant hands the Hexer the '
            'zone\'s own counter, which §2h forbids',
      );
      expect(
        MagicElement.astral.counteredBy,
        MagicElement.lunar,
        reason:
            'the fact the withdrawal rests on — if the wheel ever changes, '
            're-read §2e.2 before touching this zone',
      );
    });

    test('the anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      expect(
        World.opponentNameFor(World.byId(zone)),
        'Stratum Warden',
        reason: 'the zone\'s anchor name drifted',
      );
      // ⚠️ Unlike most zones, the anchor is NOT the Adept here — the Warden is
      // the Sentinel and the Deadreckoner is the yardstick.
      expect(
        BuriedSkyBestiary.stratumWarden.archetype.id,
        'sentinel',
        reason: 'the anchor is the shield-breaking lesson, not the yardstick',
      );
      expect(
        BuriedSkyBestiary.deadreckoner.archetype.id,
        'adept',
        reason: 'the zone lost its yardstick',
      );
    });

    test('the zone band is 46–50, and it is a dungeon', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 46, reason: 'the band floor drifted');
      expect(loc.maxLevel, 50, reason: 'the band ceiling drifted');
      expect(
        loc.kind,
        LocationKind.dungeon,
        reason: '🏰 stands even though the structure is deferred',
      );
    });
  });

  group('combat stats match CELESTIAL §2.3, as ETHEREAL §2.3 carries it', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present in this zone is checked
    // against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        BuriedSkyBestiary.deadreckoner.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel is a wall that chips', () {
      expect(
        BuriedSkyBestiary.stratumWarden.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
        reason: 'the Stratum Warden is not carrying §2.3\'s Sentinel row',
      );
    });

    test('the Lasher crits often and softly', () {
      expect(
        BuriedSkyBestiary.constellate.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason:
            'the Constellate is not carrying §2.3\'s Lasher row — the '
            'NEGATIVE crit damage is the whole point of "chips, not shatters"',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        BuriedSkyBestiary.fadelight.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
        reason: 'the Fadelight is not carrying §2.3\'s Glasswing row',
      );
    });

    test('the Bruiser telegraphs and hits hard when it lands', () {
      expect(
        BuriedSkyBestiary.corebiter.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
        reason: 'the Corebiter is not carrying §2.3\'s Bruiser row',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        BuriedSkyBestiary.stonefallHerald.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Stonefall Herald is not carrying §2.3\'s Champion row',
      );
    });

    test('⚠️ the Redoubt takes ETHEREAL §2.3\'s zone-local deviation', () {
      // ⭐ §2.3 names this creature by name: a 2.20 HP body at the standard
      // 35/30 (EV 10.5%) inside a DUNGEON, where a player cannot retreat
      // between sections, is the fight the balance probe will flag. The
      // deviation stands until the fatigue clock ships — and nothing in lib/
      // implements one. Kills the mutant that "corrects" it back to 35/30.
      expect(
        BuriedSkyBestiary.bedrockColossus.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 24),
        reason:
            'the Bedrock Colossus is back on the standard Redoubt row, which '
            '§2.3 asks this zone NOT to use',
      );
      // EV = chance × amount / 100, and §2.3 asks for 6.0%.
      final s = BuriedSkyBestiary.bedrockColossus.combatStats;
      expect(
        s.deflectChance * s.deflectAmount,
        600,
        reason: 'the deviation\'s expected value is no longer 6.0%',
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        BuriedSkyBestiary.nadir.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason: 'Nadir is not carrying §2.3\'s Executioner row',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        BuriedSkyBestiary.theLongCount.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'The Long Count is not carrying §2.3\'s Hexer row',
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        BuriedSkyBestiary.theOverburden.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
        reason: 'The Overburden is not carrying §2.3\'s Juggernaut row',
      );
    });

    test('the Astral Aspect leans on crit chance, per §2.4', () {
      // ⭐ Astral's lean is crit CHANCE — a constellation in the rock is a
      // pattern that was already complete, and a crit is the same statement.
      expect(
        BuriedSkyBestiary.theBuriedConstellation.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 5,
          critChance: 25,
          critDamage: 45,
        ),
        reason: 'The Buried Constellation is not carrying §2.4\'s stat block',
      );
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
      // ⚠️ ENEMIES §3.4 — only the Collapsed Academy and Citadel lanes field a
      // mage boss, whose moves are a Spellbook loadout rather than a kit. This
      // zone's bosses are a weight and a pattern.
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

    test('move ids are unique across the WHOLE bestiary, and all bs_ '
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
        expect(id.startsWith('bs_'), isTrue, reason: '$id is not zone-tagged');
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

    test('move names are verbs, not nouns or the game\'s own vocabulary', () {
      // ⚠️ §3.3/§3.3a — a move is something the creature DOES. A name that is
      // one of the game's own verbs, or an element, reads as a system message.
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
      // by level, so this zone's 46–50 band arrives via the ENCOUNTER LEVEL,
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
      // ⚠️ §2.5's lesson: "why a big shield is not always the answer" only
      // reads if every hit meets the shield separately.
      final constellate = BuriedSkyBestiary.constellate;
      expect(constellate.archetype.id, 'lasher');
      for (final m in constellate.moves) {
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
      // ⚠️ Sentinel/Redoubt/Juggernaut are defined partly by attrition.
      // Without a ShieldEffect the archetype is only a bigger HP number.
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

    test(
      '⭐ the Sentinel\'s shield is its EXPENSIVE move, so it telegraphs',
      () {
        // ⚠️ §2e's kit sketch is explicit: "slow on purpose — the shield is the
        // expensive move." A cheap wall would make the Warden un-Barrage-able,
        // which is the one lesson the zone's anchor exists to teach.
        final warden = BuriedSkyBestiary.stratumWarden;
        final wall = warden.moves.firstWhere((m) => m.effect is ShieldEffect);
        final attack = warden.moves.firstWhere((m) => m.effect is DamageEffect);
        expect(
          wall.chargeCost,
          greaterThan(attack.chargeCost),
          reason: 'the Warden can raise a band without ever charging for it',
        );
        expect(
          wall.chargeCost,
          warden.archetype.maxMoveCost,
          reason: 'the wall is no longer the top of the Sentinel\'s cost band',
        );
      },
    );

    test('the Redoubt\'s wall lands ahead of the player\'s own shield, and '
        'it heals off the lever the engine has', () {
      final colossus = BuriedSkyBestiary.bedrockColossus;
      final wall = colossus.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(
        wall.priority,
        lessThan(3),
        reason: 'the Colossus\'s weight arrives after the player commits',
      );
      // ⭐ §2e's kit sketch: "the Redoubt's heal, using the lever the engine
      // actually has." No creature-facing heal effect exists, so attrition is
      // written as lifesteal on a damage move.
      expect(
        colossus.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        isTrue,
        reason: 'the Redoubt cannot out-last anything it cannot heal from',
      );
    });

    test('⚠️ the Colossus is the ONLY thing here that lifesteals', () {
      // ⭐ ENEMIES §2.6 — the Siphon is Thornmire's reveal, and §2f explicitly
      // cut it from this zone. The one lifesteal here is the Redoubt's
      // attrition clause, not a second Siphon by the back door.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect || effect.lifesteal == 0) continue;
          expect(
            e.id,
            'bedrock_colossus',
            reason: '${e.id}\'s "${m.name}" takes what is yours',
          );
        }
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final count = BuriedSkyBestiary.theLongCount;
      expect(count.archetype.id, 'hexer');
      expect(
        count.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        count.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing The Long Count throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays at 4, and it executes', () {
      // ⚠️ §1.3 lowered the Executioner's cap to 4 and did not raise it back.
      // ENEMIES §2e's kit sketch says 5; at L50 a five-charge mini raw lands
      // 460–600 against a 632 HP bar, which is a one-shot with change. Kills
      // the mutant that restores the sketch's number.
      final nadir = BuriedSkyBestiary.nadir;
      expect(nadir.archetype.id, 'executioner');
      for (final m in nadir.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '${m.id} breaches §1.3\'s lowered Executioner cap',
        );
      }
      expect(
        nadir.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).executeBelowPercent > 0,
        ),
        isTrue,
        reason: 'a descent that never finishes is not the lesson',
      );
    });

    test('⭐⭐ the Aspect\'s whole kit walks through shields, except the '
        'opener', () {
      // ⭐ §2e: "Astral Alignment taken to an extreme — by the end, the shield
      // you are holding is not where the damage is going." The cheap opener is
      // an ordinary hit on purpose; everything the player pays to survive is
      // not.
      final aspect = BuriedSkyBestiary.theBuriedConstellation;
      final through = aspect.moves
          .where(
            (m) =>
                m.effect is DamageEffect &&
                (m.effect as DamageEffect).ignoresShields,
          )
          .map((m) => m.id)
          .toSet();
      expect(through, {
        'bs_risewhereitshouldnot',
        'bs_thepatternholds',
      }, reason: 'the Aspect\'s extreme is no longer an extreme');
      expect(
        aspect.moves.every((m) => m.effect is DamageEffect),
        isTrue,
        reason: 'an Aspect that shields is hiding, not aligning',
      );
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id this zone OWNS is a real item', () {
      // ⚠️ Excludes the Hallowmarch lane's two consumables only — everything
      // this zone defines, plus Q2's geo_* and Q3's astral_*, must resolve
      // today.
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
    }, skip: _skipUntilSiblings);

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
      for (final e in BuriedSkyBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...BuriedSkyBestiary.minis,
        ...BuriedSkyBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in BuriedSkyBestiary.commons) {
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
      // ⭐ §3.2 — the Buried Sky defines NO motes of its own; it pays in the
      // geo_* (Old Quarry, **Q2**) and astral_* (Starfall Basin, **Q3**)
      // families. The Q2 half is the only reason a level-46 player ever sees a
      // Geo Dust again.
      final dropped = BuriedSkyBestiary.allDrops;
      for (final id in [
        'geo_dust',
        'geo_shard',
        'geo_crystal',
        'astral_dust',
        'astral_shard',
        'astral_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      const foreign = {
        'solar_dust', 'solar_shard', 'solar_crystal', //
        'lunar_dust', 'lunar_shard', 'lunar_crystal',
        'arcane_dust', 'arcane_shard', 'arcane_crystal',
        'sanctus_dust', 'sanctus_shard', 'sanctus_crystal',
        'umbra_dust', 'umbra_shard', 'umbra_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'aero_dust', 'aero_shard', 'aero_crystal',
        'electro_dust', 'electro_shard', 'electro_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
        'flora_dust', 'flora_shard', 'flora_crystal',
      };
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
      // ⚠️ The off-element MOVE is a move, not a currency — a lunar mote here
      // would make §2e.2's one-move licence a drop-table change too.
      expect(
        dropped.where((id) => id.startsWith('lunar_')),
        isEmpty,
        reason: 'the off-element leaked out of the move list and into loot',
      );
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight the
      // player chose.
      for (final e in BuriedSkyBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final e in BuriedSkyBestiary.minis) {
        expect(
          e.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${e.id} does not offer both Crystals',
        );
      }
      for (final b in BuriedSkyBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️ neither boss carries a gate part — this is not a gate zone', () {
      // ⭐ ENEMIES §2e.1 / §3.4: the three Ethereal Thirds come from the
      // quarter's three PURE zones. §4.2's drop table still shows
      // `the_dark_third` here; its own catalogue row strikes it out and moves
      // it to The Umbral Wastes, and §7.3 lists no key among this zone's ids.
      // A fourth supplier would silently loosen the Citadel's door.
      for (final b in BuriedSkyBestiary.bosses) {
        for (final id in b.drops.possibleDrops) {
          expect(
            id,
            isNot(contains('third')),
            reason: '${b.id} drops a gate part this zone must not supply',
          );
        }
      }
      expect(
        World.byId('the_buried_sky').gateItemIds,
        isEmpty,
        reason: 'the Buried Sky became a gate zone nobody designed it to be',
      );
    });

    test('the hybrid pays BOTH ladders at half chance on every common', () {
      // ⭐ The shipped Frostfell shape: two 0.5 rolls instead of one 0.75, so
      // the total handed over stays comparable to a pure zone's.
      for (final e in BuriedSkyBestiary.commons) {
        final dusts = e.drops.always
            .where((d) => d.defId?.endsWith('_dust') ?? false)
            .toList();
        expect(dusts.map((d) => d.defId), [
          'geo_dust',
          'astral_dust',
        ], reason: '${e.id} does not pay both parents');
        for (final d in dusts) {
          expect(
            d.chance,
            0.5,
            reason:
                '${e.id} pays ${d.defId} at a pure zone\'s rate, doubling the '
                'zone\'s mote income',
          );
        }
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in BuriedSkyBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('stonefall_signet'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('stonefall_signet'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(
        ItemCatalogue.byId('stonefall_signet').rarity,
        Rarity.rare,
        reason: 'the chase stopped being Rare',
      );
    });

    test('the epic is boss-only, and rationed', () {
      final epics = BuriedSkyItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(
        epics,
        contains('bedrock_greaves'),
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

    test('the Corebiter is the only common that yields the garnet or a '
        'draught', () {
      // ⚠️ §4.2's "the Siphon" row — named for the archetype this creature
      // carried before the re-band (§2f), and the only common table carrying
      // nadir_garnet or goldenrood_draught.
      for (final e in BuriedSkyBestiary.commons) {
        final rich =
            e.drops.possibleDrops.contains('nadir_garnet') ||
            e.drops.possibleDrops.contains('goldenrood_draught');
        expect(
          rich,
          e.id == 'corebiter',
          reason: '${e.id} does not match §4.2\'s common drop-table shape',
        );
      }
    });

    test('⭐ the hide is kill-only everywhere it appears', () {
      // ⚠️ §3.1 — `corebiter_hide` exists only because something died. A node
      // for it would be a second source contradicting its own fiction, and a
      // `hide` role with no hide item would have fallen through to §3.5.1's
      // second-material rule instead. This zone has a real hide, so it does
      // not.
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('corebiter_hide')),
        reason: 'the hide grew a node, which is a second source',
      );
      expect(
        BuriedSkyBestiary.allDrops,
        contains('corebiter_hide'),
        reason: 'the zone\'s hide role resolves to nothing',
      );
    });
  });

  group('the catalogue matches §4.2', () {
    test('9 defs — 10 minus the key §3.4 moved out', () {
      // ⚠️ §4.2's heading says 10 and its own table strikes `the_dark_third`
      // out; §7.1's count was written before that move. Nine is the
      // reconciled figure, and the key belongs to The Umbral Wastes.
      expect(
        BuriedSkyItems.all,
        hasLength(9),
        reason: 'the catalogue drifted from §4.2 as §3.4 reconciled it',
      );
      expect(
        BuriedSkyItems.all.map((d) => d.id),
        isNot(contains('the_dark_third')),
        reason: 'the Ethereal gate gained a fourth supplier',
      );
      expect(
        BuriedSkyItems.all.whereType<KeyDef>(),
        isEmpty,
        reason: 'a key here makes an optional dungeon mandatory',
      );
    });

    test('every item is resolvable under this zone', () {
      for (final def in BuriedSkyItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⚠️ the zone defines NO mote family', () {
      // ⭐ §3.2 — a hybrid never defines one, and both parents already have
      // theirs. A MoteDef here would give geo_* or astral_* a second home.
      expect(
        BuriedSkyItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'a hybrid that defines motes re-homes another zone\'s ladder',
      );
    });

    test('every material is tier 8 on the skill §3.1 assigns it', () {
      const expected = {
        'deepstratum_ore': CraftSkill.metalworking,
        'nadir_garnet': CraftSkill.jewelry,
        'corebiter_hide': CraftSkill.tailoring,
        'deepsteel_ingot': CraftSkill.metalworking,
      };
      final materials = BuriedSkyItems.all.whereType<MaterialDef>();
      expect(
        materials.map((m) => m.id).toSet(),
        expected.keys.toSet(),
        reason: 'the material set drifted from §4.2',
      );
      for (final m in materials) {
        expect(
          m.skill,
          expected[m.id],
          reason: '${m.id} feeds the wrong skill',
        );
        expect(m.tier, 8, reason: '${m.id} is off the band-46 material tier');
      }
    });

    test('the garnet is the only Uncommon material — the rest are Common', () {
      // ⭐ §4.2 — the garnet is the Jewelry stone and the one thing here worth
      // more than the rock it came out of.
      expect(
        BuriedSkyItems.nadirGarnet.rarity,
        Rarity.uncommon,
        reason: 'the zone\'s Jewelry stone stopped being a step up',
      );
      for (final m in BuriedSkyItems.all.whereType<MaterialDef>()) {
        if (m.id == 'nadir_garnet') continue;
        expect(m.rarity, Rarity.common, reason: '${m.id} inflated past §4.2');
      }
    });

    test('values are §4.2\'s, verbatim', () {
      const expected = {
        'deepstratum_ore': 120,
        'nadir_garnet': 180,
        'corebiter_hide': 700,
        'deepsteel_ingot': 360,
        'corebiter_belt': 1690,
        'everice_band': 260,
        'nacre_pendant': 680,
        'stonefall_signet': 2700,
        'bedrock_greaves': 7600,
      };
      for (final def in BuriedSkyItems.all) {
        expect(
          def.value,
          expected[def.id],
          reason: '${def.id} has drifted from the contract value',
        );
      }
    });

    test('modifiers are §4.2\'s, verbatim', () {
      // ⚠️ The single most copy-pasteable table in the contract, and a swapped
      // number compiles, ships and reads as a balance decision nobody made.
      expect(
        BuriedSkyItems.corebiterBelt.modifiers,
        const ItemModifiers(beltSlots: 7),
        reason: 'the belt ladder\'s Ethereal rung moved off Palimpsest 6 → 7',
      );
      expect(
        BuriedSkyItems.evericeBand.modifiers,
        const ItemModifiers(
          shieldStrengthPercent: 12,
          maxHpBonus: 15,
          dodge: 3,
        ),
        reason: 'the first Jewelry craft in the game drifted',
      );
      expect(
        BuriedSkyItems.nacrePendant.modifiers,
        const ItemModifiers(maxHpBonus: 25, dodge: 6, shieldStrengthPercent: 8),
        reason: 'the second banking payoff drifted',
      );
      expect(
        BuriedSkyItems.stonefallSignet.modifiers,
        const ItemModifiers(deflectChance: 18, maxHpBonus: 22, critChance: 6),
        reason: 'the Rare chase drifted',
      );
      expect(
        BuriedSkyItems.bedrockGreaves.modifiers,
        const ItemModifiers(
          maxHpBonus: 45,
          deflectChance: 10,
          deflectAmount: 10,
        ),
        reason: 'the epic drifted',
      );
    });

    test('⚠️ the signet\'s bare deflectChance is a BUILD, not the inert-stat '
        'bug', () {
      // ⭐ §4.2 bends KINETIC §2.1's rule in exactly one place: §2.1b caps
      // deflect AMOUNT, so a chance-only ring is real value to a player who
      // already owns gloves and dead weight to one who does not. Kills the
      // well-meaning mutant that "fixes" it by adding an amount.
      final signet = BuriedSkyItems.stonefallSignet;
      expect(
        signet.modifiers.deflectChance,
        18,
        reason: 'the deliberate chance-only ring lost its chance',
      );
      expect(
        signet.modifiers.deflectAmount,
        0,
        reason:
            '§4.2 rules this piece chance-only on purpose; if it is ever '
            'given an amount the contract says 6, and the_corona drops to 8',
      );
    });

    test('both named drops set properName and stay untradeable; the crafted '
        'three leave it null and salvage', () {
      // ⚠️ §3.5 / ITEMS §9b.5a — crafted equipment composes its name from
      // material + form and MUST leave properName null; drop-only jewelry and
      // boss uniques set it.
      for (final def in [
        BuriedSkyItems.stonefallSignet,
        BuriedSkyItems.bedrockGreaves,
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
      }
      for (final def in [
        BuriedSkyItems.corebiterBelt,
        BuriedSkyItems.evericeBand,
        BuriedSkyItems.nacrePendant,
      ]) {
        expect(
          def.properName,
          isNull,
          reason: '${def.id} would let its name drift from its facts',
        );
        expect(
          def.salvage,
          isNotEmpty,
          reason: '${def.id} cannot be broken back down',
        );
        for (final y in def.salvage) {
          expect(
            ItemCatalogue.zoneOf(y.defId),
            zone,
            reason: '${def.id} salvages into a foreign material',
          );
        }
      }
    });

    test('⭐ everice_band is deliberately wearable one level BELOW the band', () {
      // ⚠️ §4.2 — a player learns Jewelry at Rimeholt (L45) and should be able
      // to wear the first thing they make before they walk anywhere. It is the
      // one item in the zone allowed outside the band, and it is the reason
      // two quarters of banking clauses were written.
      expect(
        BuriedSkyItems.evericeBand.equipLevel,
        45,
        reason: 'the first Jewelry craft moved off Rimeholt\'s doorstep',
      );
      expect(
        BuriedSkyItems.evericeBand.equipLevel,
        lessThan(World.byId(zone).minLevel),
        reason: 'the deliberate one-level exemption stopped being one',
      );
      expect(
        BuriedSkyItems.evericeBand.rarity,
        Rarity.common,
        reason: 'the most load-bearing item in the contract is a Common ring',
      );
    });

    test('every other equipLevel sits in the band; materials sit at or below '
        'it', () {
      final loc = World.byId(zone);
      for (final def in BuriedSkyItems.all) {
        if (def.id == 'everice_band') continue; // its own law, above
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
      // ⚠️ §3.6 — no Uncommon, Mythic or Legendary equipment in this quarter;
      // Mythic and Legendary are exactly what Phase 8's sets will need.
      const legal = {Rarity.common, Rarity.rare, Rarity.epic};
      for (final def in BuriedSkyItems.all.whereType<EquipmentDef>()) {
        expect(
          legal,
          contains(def.rarity),
          reason: '${def.id} uses a rarity the quarter does not ship for gear',
        );
        expect(
          def.setId,
          isNull,
          reason: '${def.id} authored a set §3.6 reserves for Phase 8',
        );
        expect(
          def.socketCount,
          0,
          reason: '${def.id} authored a socket §3.6 reserves for Phase 8',
        );
      }
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('two nodes — the hide is kill-only, so the hybrid\'s three '
        'materials are two', () {
      expect(nodes, hasLength(2), reason: 'the node count drifted from §6');
      expect(nodes.map((n) => n.id).toSet(), {
        'bs_stratum_seam',
        'bs_nadir_pocket',
      }, reason: 'a node id drifted from the contract');
    });

    test('the two nodes cover the two gatherable materials, on the skill '
        '§3.1 assigns each', () {
      // ⚠️ Kills the swapped-yield mutant: a node pointed at the WRONG
      // material of the same zone still yields "a real material of this zone",
      // so the check below blesses it — and `nadir_garnet` would then have no
      // source while `deepstratum_ore` quietly had two.
      const expected = {
        'bs_stratum_seam': ('deepstratum_ore', GatherSkill.mining),
        'bs_nadir_pocket': ('nadir_garnet', GatherSkill.mining),
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
        hasLength(2),
        reason: 'two nodes yield the same material, so one material has none',
      );
      // ⭐ §3.1: the hide is kill-only and the ingot is smelted. Everything
      // else the zone defines is dug.
      expect(
        nodes.map((n) => n.yieldsDefId).toSet(),
        BuriedSkyItems.all
            .whereType<MaterialDef>()
            .map((m) => m.id)
            .toSet()
            .difference({'corebiter_hide', 'deepsteel_ingot'}),
        reason:
            'a gatherable material of this zone has no node, or a node has '
            'no material',
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

    test('the ingot has no node — it is smelted, not dug up', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('deepsteel_ingot')),
        reason:
            'a node for an intermediate good is a second source that skips '
            'the recipe it exists for',
      );
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 99, reason: 'the band-46 XP rung moved');
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final fadelight = BuriedSkyBestiary.fadelight;
      final overburden = BuriedSkyBestiary.theOverburden;
      expect(
        fadelight.maxHpAt(46),
        (MageState.scaledMaxHp(46) * Archetypes.glasswing.hpScale).round(),
        reason: 'the Glasswing grew a second HP curve',
      );
      expect(
        overburden.maxHpAt(50),
        (MageState.scaledMaxHp(50) * Archetypes.juggernaut.hpScale).round(),
        reason: 'the Juggernaut grew a second HP curve',
      );
      expect(
        overburden.maxHpAt(50),
        greaterThan(fadelight.maxHpAt(50)),
        reason: 'the boss is not the bigger body',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 46. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(46);
      for (final e in BuriedSkyBestiary.commons) {
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
      for (final def in BuriedSkyItems.all) {
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
