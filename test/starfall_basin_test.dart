import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/starfall_basin.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/starfall_basin_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **The two ids Starfall Basin references but does not own.**
/// CELESTIAL_CONTRACT §7.3 assigns both consumables to
/// `the_kiln_desert_items.dart`, a sibling lane's file in a parallel
/// worktree. They resolve once the merge coordinator lands the quarter
/// together. ⭐ Named as a **closed list** rather than skipping the check, so
/// the resolution test still covers every other id and a typo in a third
/// cross-zone reference still fails.
const _pendingSiblingLane = <String>{}; // the Kiln Desert landed first

void main() {
  const zone = 'starfall_basin';
  final all = StarfallBasinBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        StarfallBasinBestiary.commons,
        hasLength(5),
        reason: 'a common was dropped or invented — the roster table is five',
      );
      expect(
        StarfallBasinBestiary.minis,
        hasLength(4),
        reason: 'a mini was dropped — §2g draws 2 of 4, so 3 shrinks the pool',
      );
      expect(
        StarfallBasinBestiary.bosses,
        hasLength(2),
        reason: 'a boss was dropped — the two-scale pool needs both scales',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives — an unlisted zone
      // compiles fine and never appears in an encounter.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'the zone is not registered in Bestiary.all, or zoneId drifted',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason:
            'a creature is in `all` but not reachable by zone, or vice versa',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(
        StarfallBasinBestiary.minis.map((e) => e.archetype.id).toSet(),
        {'champion', 'redoubt', 'executioner', 'hexer'},
        reason:
            'two minis share an archetype, so a run can draw the same '
            'tactical role twice',
      );
    });

    test('the boss pair is the same thing at two SCALES, not a mirror', () {
      // ⭐⭐ ENEMIES §2f — The Next One is enormous and still inbound
      // (Juggernaut: mass), What Landed is small and already down (Tyrant:
      // intelligence). Kills the mutant that makes them one archetype twice.
      expect(
        StarfallBasinBestiary.theNextOne.archetype.id,
        'juggernaut',
        reason: 'the big scale stopped being a mass',
      );
      expect(
        StarfallBasinBestiary.whatLanded.archetype.id,
        'tyrant',
        reason: 'the small scale stopped being an intelligence',
      );
      expect(
        StarfallBasinBestiary.theNextOne.archetype.id,
        isNot(StarfallBasinBestiary.whatLanded.archetype.id),
        reason: 'the two scales have collapsed into one',
      );
      // ⚠️ No Aspect here — §2.4 lists the quarter's six Aspects by name and
      // Starfall Basin fields none.
      for (final b in StarfallBasinBestiary.bosses) {
        expect(
          b.archetype.id,
          isNot('aspect'),
          reason: '${b.id} is an Aspect, which §2.4 does not grant this zone',
        );
      }
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

    test('the common archetypes are exactly the roster\'s five', () {
      // ⚠️ Kills the swapped-archetype mutant at the roster level: the table
      // names one Adept, one Sentinel, one Glasswing, one Lasher and one
      // Skirmisher, and a second Adept would still compile.
      expect(
        StarfallBasinBestiary.commons.map((e) => e.archetype.id).toList(),
        ['adept', 'sentinel', 'glasswing', 'lasher', 'skirmisher'],
        reason:
            'a common was given the wrong archetype, or the five were '
            'reordered away from the roster table',
      );
    });

    test('ids and names are unique', () {
      expect(
        all.map((e) => e.id).toSet(),
        hasLength(all.length),
        reason: 'two creatures share an id, so one shadows the other',
      );
      expect(
        all.map((e) => e.name).toSet(),
        hasLength(all.length),
        reason: 'two creatures share a name, so one has no art entry',
      );
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      // An id that drifts from its name is a rename nobody notices.
      // ⭐ ENEMIES §3.4 spells this zone's one hyphen case out by name:
      // *Sky-Iron Husk* → `sky_iron_husk`.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r"[^a-z0-9]+"),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('⭐ every creature is Astral and ONLY Astral — a pure zone', () {
      // ⚠️ §2.4's audit: `the_kiln_desert`, `the_mirrormere` and
      // `starfall_basin` are the quarter's three pure zones, so the three
      // Celestial elements each keep exactly one pure region. A second
      // element anywhere here costs Astral its only one.
      final loc = World.byId(zone);
      for (final e in all) {
        expect(
          e.zoneId,
          zone,
          reason: '${e.id} is filed under another zone and will never spawn',
        );
        expect(e.elements, [
          MagicElement.astral,
        ], reason: '${e.id} is not purely Astral');
        for (final el in e.elements) {
          expect(
            loc.elements,
            contains(el),
            reason: '${e.id} carries ${el.name}, which the zone does not hold',
          );
        }
      }
      expect(loc.elements, [
        MagicElement.astral,
      ], reason: 'world.dart stopped calling this a pure Astral zone');
    });

    test('the per-creature element assignment matches the roster exactly', () {
      // ⭐ Hard-coded rather than derived, so a roster table read wrong fails
      // here instead of agreeing with itself.
      const astral = [MagicElement.astral];
      final byName = <String, EnemyDef>{
        'Crater Revenant': StarfallBasinBestiary.craterRevenant,
        'Sky-Iron Husk': StarfallBasinBestiary.skyIronHusk,
        'Fallpoint': StarfallBasinBestiary.fallpoint,
        'Scatterling': StarfallBasinBestiary.scatterling,
        'Cold Ejecta': StarfallBasinBestiary.coldEjecta,
        'The Zodiac Ascendant': StarfallBasinBestiary.theZodiacAscendant,
        'Constellation Warden': StarfallBasinBestiary.constellationWarden,
        'Rift Walker': StarfallBasinBestiary.riftWalker,
        'Echo of the Between': StarfallBasinBestiary.echoOfTheBetween,
        'The Next One': StarfallBasinBestiary.theNextOne,
        'What Landed': StarfallBasinBestiary.whatLanded,
      };
      expect(
        byName.keys.toSet(),
        all.map((e) => e.name).toSet(),
        reason:
            'a creature was renamed, added or cut without this table '
            'following it',
      );
      byName.forEach((name, def) {
        expect(
          def.elements,
          astral,
          reason: '$name drifted off the roster table\'s `astral`',
        );
      });
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason:
            'world.dart\'s anchor names a creature this roster does not '
            'define, so the duel screen would show a stranger',
      );
      // ✅ ENEMIES §2e — Crater Revenant is Bruiser → Adept, the zone's
      // anchor and its yardstick: a person who came back.
      expect(
        StarfallBasinBestiary.craterRevenant.archetype.id,
        'adept',
        reason:
            'the anchor reverted to Bruiser and the zone lost its yardstick',
      );
      expect(
        World.opponentNameFor(World.byId(zone)),
        'Crater Revenant',
        reason: 'the anchor moved off the creature the roster names',
      );
    });

    test('the zone band is 34–39, and it is a Celestial route', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 34, reason: 'the band floor moved off the contract');
      expect(
        loc.maxLevel,
        39,
        reason: 'the band ceiling moved off the contract',
      );
      expect(
        loc.tier,
        MagicTier.celestial,
        reason: 'the zone left the quarter its contract belongs to',
      );
      expect(
        loc.kind,
        LocationKind.route,
        reason: 'a route became a dungeon, which changes its adventure shape',
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
        StarfallBasinBestiary.craterRevenant.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel reads as "everything lands softer"', () {
      expect(
        StarfallBasinBestiary.skyIronHusk.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
        reason: 'the Sentinel\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        StarfallBasinBestiary.fallpoint.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
        reason: 'the Glasswing\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Lasher crits often and each crit is worth LESS', () {
      // ⚠️ The only negative crit damage in the game (§2.3) — a mutant that
      // "fixes" the sign turns the zone's chip-damage common into a spike.
      expect(
        StarfallBasinBestiary.scatterling.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason:
            'the Lasher\'s row was copied from another archetype, or the negative crit damage lost its sign (§2.3)',
      );
    });

    test('the Skirmisher is quick and a little slippery', () {
      expect(
        StarfallBasinBestiary.coldEjecta.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
        reason:
            'the Skirmisher\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        StarfallBasinBestiary.theZodiacAscendant.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Champion\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        StarfallBasinBestiary.constellationWarden.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason: 'the Redoubt\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        StarfallBasinBestiary.riftWalker.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason:
            'the Executioner\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        StarfallBasinBestiary.echoOfTheBetween.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'the Hexer\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        StarfallBasinBestiary.theNextOne.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
        reason:
            'the Juggernaut\'s row was copied from another archetype (§2.3)',
      );
    });

    test('the Tyrant carries a little of everything — §2.3\'s row, '
        'verbatim', () {
      // ⭐ The widest stat block in the game, and that IS the archetype:
      // "the intelligence is the threat," written as numbers.
      expect(
        StarfallBasinBestiary.whatLanded.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 5,
          dodge: 5,
          critChance: 10,
          critDamage: 15,
          deflectChance: 10,
          deflectAmount: 15,
        ),
        reason:
            'the Tyrant\'s row was copied from another archetype, or one of its six numbers drifted (§2.3)',
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

    test(
      'crit damage and deflect amount never appear without their chance',
      () {
        // ⚠️ §2.1's inert-stat traps: a "buff" with a zero chance to trigger
        // is dead weight nobody notices until they read the code. ⚠️ The
        // crit-damage arm tests `!= 0`, not `> 0`, so the Lasher's deliberate
        // negative is still required to carry a chance.
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
      },
    );
  });

  group('creatures are creatures, not mages', () {
    test('no move borrows an id from the player Spellbook', () {
      // ⚠️ ENEMIES §3 — a boar does not cast Bolt. Sharing an id would also
      // make the two catalogues collide in the battle log.
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

    test('move ids are unique across the WHOLE bestiary, and all prefixed', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (CELESTIAL_CONTRACT §3.5's zone-prefix table: `sb_` is Starfall's).
      // ⭐ Checked against every shipped zone, not just this one — a
      // collision with a sibling lane is exactly the failure the prefix
      // exists to prevent, and a zone-local check would never see it.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason:
            'two moves in this zone share an id, so one silently shadows the other in the battle log',
      );
      for (final id in mine) {
        expect(id.startsWith('sb_'), isTrue, reason: '$id is not zone-tagged');
      }
      final foreign = <String>{
        for (final e in Bestiary.all)
          if (e.zoneId != zone) ...e.moves.map((m) => m.id),
      };
      for (final id in mine) {
        expect(
          foreign,
          isNot(contains(id)),
          reason: '$id collides with a move another zone already owns',
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

    test('every creature has at least one move it can afford from zero', () {
      for (final e in all) {
        expect(e.moves, isNotEmpty, reason: '${e.id} has no moves');
        expect(
          e.moves.map((m) => m.chargeCost).reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(5),
          reason: '${e.id} cannot reach any of its own moves',
        );
      }
    });

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree.
      // 📝 No mage in this zone, so no loadout exemption is needed: ENEMIES
      // §3.4's `isMage` bosses are the Collapsed Academy's and the Citadel's.
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

    test('raw damage never leaves the shared authoring band', () {
      // ⚠️ §1.1/§1.3's double-scaling trap, and the single most important
      // thing a builder can get wrong. The engine already scales damage by
      // level, so this zone's 34–39 band arrives via the ENCOUNTER LEVEL,
      // never through bigger raws. §1.3 is byte-for-byte the Kinetic table.
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

    test('the Lasher deals its damage in PIECES', () {
      // ⚠️ §1.3's per-archetype rule, and the lesson the roster names:
      // "damage in pieces" — a shield spends itself on the first of four.
      final scatterling = StarfallBasinBestiary.scatterling;
      expect(
        scatterling.archetype.id,
        'lasher',
        reason:
            'the multi-hit law is being checked against a creature that is no longer a Lasher',
      );
      for (final m in scatterling.moves) {
        expect(
          m.effect,
          isA<DamageEffect>(),
          reason:
              'a Lasher move stopped dealing damage, so the hits check below tests nothing',
        );
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '"${m.name}" lands as one lump, which is not a Lasher',
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

    test('the Skirmisher gets ahead of the player, without being Quickened', () {
      // ⭐ Priority 5 is the shipped "quick" rung (Old Quarry's Chiselback).
      // ⚠️ 1–2 is reserved for genuinely Quickened strikes, so a Skirmisher
      // sitting there would steal the Hexer's whole signature.
      final ejecta = StarfallBasinBestiary.coldEjecta;
      expect(
        ejecta.archetype.id,
        'skirmisher',
        reason:
            'the priority law is being checked against a creature that is no longer a Skirmisher',
      );
      for (final m in ejecta.moves) {
        expect(m.priority, 5, reason: '"${m.name}" is off the quick rung');
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final echo = StarfallBasinBestiary.echoOfTheBetween;
      expect(
        echo.archetype.id,
        'hexer',
        reason:
            'the priority-1 law is being checked against a creature that is no longer a Hexer',
      );
      expect(
        echo.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        echo.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️ §1.3 — the ruling that keeps a band-39 finisher from one-shotting
      // a shielded player. Kills a mutant that reverts to the cost-5 cap the
      // archetype's own maxMoveCost still permits.
      final walker = StarfallBasinBestiary.riftWalker;
      expect(
        walker.archetype.id,
        'executioner',
        reason:
            'the cost cap is being checked against a creature that is no longer an Executioner',
      );
      expect(
        walker.archetype.maxMoveCost,
        5,
        reason:
            'the archetype\'s own cap moved, so the lowered-to-4 ruling below is no longer a ruling',
      );
      for (final m in walker.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" is back at the un-lowered cap',
        );
      }
    });

    test('no shield is ever thrown at attack priority', () {
      // ⚠️ The shipped priority ladder: shields 3, quick 5, aux 7/8,
      // attack 9. A wall that resolves at 9 goes up after the hit it was
      // meant to absorb.
      for (final e in all) {
        for (final m in e.moves) {
          if (m.effect is! ShieldEffect) continue;
          expect(
            m.priority,
            lessThanOrEqualTo(3),
            reason: '${e.id}\'s "${m.name}" raises a wall too late to matter',
          );
        }
      }
    });

    test('nothing in this zone lifesteals except the Redoubt\'s finisher', () {
      // ⭐ ENEMIES §2.6 — casual lifesteal is the Siphon's reveal, and §1.3
      // grants the Redoubt exactly one. Starfall fields no Siphon.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          if (e.archetype.id == 'redoubt' && effect.lifesteal > 0) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" spoils the Siphon\'s reveal',
          );
        }
      }
      final warden = StarfallBasinBestiary.constellationWarden;
      expect(
        warden.moves.whereType<Spell>().where(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        hasLength(1),
        reason: 'the Redoubt is granted ONE lifesteal move, not two',
      );
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every table is a real item', () {
      // ⚠️ `_pendingSiblingLane` is the Kiln Desert lane's two consumables
      // (§7.3). Everything else must resolve today.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_pendingSiblingLane.contains(id)) continue;
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('the sibling-lane exemption stays a CLOSED list', () {
      // ⭐ The exemption is a merge window, not a licence. If a third
      // unresolved id appears, it is a typo rather than a pending lane.
      final unresolved = <String>{
        for (final e in all)
          for (final id in e.drops.possibleDrops)
            if (!ItemCatalogue.contains(id)) id,
      };
      expect(
        unresolved,
        unresolved.isEmpty ? isEmpty : equals(_pendingSiblingLane),
        reason:
            'an id outside the Kiln Desert pair does not resolve — or the '
            'pair landed and this exemption should now be deleted',
      );
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

    test('every main table\'s weights sum to 100, as the contract writes '
        'them', () {
      // ⭐ §4.3 authors every row as percentages. A table summing to 97 still
      // resolves and silently pays different rates than the document says.
      for (final e in all) {
        if (e.drops.main.isEmpty) continue;
        expect(
          e.drops.totalWeight,
          100,
          reason: '${e.id}\'s main table does not read as percentages',
        );
      }
    });

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in StarfallBasinBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...StarfallBasinBestiary.minis,
        ...StarfallBasinBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in StarfallBasinBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          if (_pendingSiblingLane.contains(id)) continue;
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a pure zone pays in ONE mote family, and it is Astral', () {
      final dropped = StarfallBasinBestiary.allDrops;
      for (final id in ['astral_dust', 'astral_shard', 'astral_crystal']) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ Nothing from any other element — a pure zone that leaked a second
      // family would cost §2.4's audit one of its three pure regions.
      final foreign = <String>{
        for (final d in ItemCatalogue.all.whereType<MoteDef>())
          if (d.element != MagicElement.astral) d.id,
      };
      expect(
        foreign,
        isNotEmpty,
        reason: 'the foreign-mote net caught nothing',
      );
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('⚠️ no zone but this one defines the astral_* family', () {
      // ⭐ §3.2's assertion — the one that would have caught `arcane_*` being
      // written twice. The mote lives with the zone that first yields it.
      for (final id in ['astral_dust', 'astral_shard', 'astral_crystal']) {
        expect(
          ItemCatalogue.zoneOf(id),
          zone,
          reason: '$id is owned by another zone\'s catalogue',
        );
      }
      // 📝 2026-10-01 (the enchanting build): the family DID grow a Core and a
      // Heart (ENCHANTING_DESIGN §3.1) — made, never found, so they live in
      // ItemCatalogue.byWorkshop['refined'] and no zone owns them. The law
      // this pinned is "no TWIN in any zone", so it now counts zone-owned
      // motes, and the two refined ones are pinned to their workshop below.
      final astralMotes = ItemCatalogue.all.whereType<MoteDef>().where(
        (d) => d.element == MagicElement.astral,
      );
      expect(
        astralMotes.where((d) => ItemCatalogue.zoneOf(d.id) != null),
        hasLength(3),
        reason: 'a zone has grown a twin of the astral Dust/Shard/Crystal',
      );
      expect(
        {
          for (final d in astralMotes)
            if (ItemCatalogue.zoneOf(d.id) == null)
              d.id: ItemCatalogue.homeOf(d.id),
        },
        {'astral_core': 'refined', 'astral_heart': 'refined'},
        reason:
            'the only zone-less astral motes are the refined Core and Heart '
            '— anything else is a mote filed under no zone and no workshop',
      );
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8, §7.5's "never on a common").
      for (final e in StarfallBasinBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final m in StarfallBasinBestiary.minis) {
        final crystal = m.drops.always.firstWhere(
          (d) => d.defId == 'astral_crystal',
        );
        expect(
          crystal.chance,
          0.15,
          reason:
              '${m.id}\'s Crystal is not 15% — the 2026-09-30 lean took it '
              'from 0.25 to 0.15; kills a zone the lean missed',
        );
      }
      for (final b in StarfallBasinBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(1),
          reason: '${b.id} does not guarantee its Crystal',
        );
      }
    });

    test('⚠️ the gate essence is guaranteed, on BOTH bosses, never '
        'weighted', () {
      // ⭐⭐ §3.4 and ETHEREAL_CONTRACT §3.5.3. `astral_essence` is the
      // Celestial Totem's Astral charge and therefore the Rimeholt gate. The
      // adventure draws ONE of the two bosses, so a key on only one — or on
      // a weighted `main` row — means a player can clear the zone and still
      // be locked out of the next town by a dice roll.
      for (final b in StarfallBasinBestiary.bosses) {
        final entry = b.drops.always.where((d) => d.defId == 'astral_essence');
        expect(
          entry,
          hasLength(1),
          reason: '${b.id} does not carry the gate essence on `always`',
        );
        expect(
          entry.single.chance,
          1,
          reason: '${b.id} rolls for the gate key',
        );
        expect(
          b.drops.main.map((d) => d.defId),
          isNot(contains('astral_essence')),
          reason: '${b.id} put the gate key on a weighted table',
        );
      }
      // ⚠️ And nothing below a boss may ever hand it over.
      for (final e in [
        ...StarfallBasinBestiary.commons,
        ...StarfallBasinBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('astral_essence')),
          reason: '${e.id} leaks the gate part',
        );
      }
    });

    test('⭐ the hide role pays in the zone\'s SECOND material', () {
      // ⚠️ ETHEREAL_CONTRACT §3.5.1 — Starfall Basin defines no hide item
      // (nothing here has skin), so the Adept's `hide` role resolves to
      // `fallstone` at the weight a hide would have carried. Kills the
      // mutant that invents a `crater_hide` nobody ruled.
      expect(
        StarfallBasinBestiary.craterRevenant.drops.possibleDrops,
        contains('fallstone'),
        reason: 'the anchor\'s hide role resolved to nothing',
      );
      for (final def in StarfallBasinItems.all) {
        expect(
          def.id,
          isNot(contains('hide')),
          reason: '${def.id} is a hide this zone was never granted',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in StarfallBasinBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('zodiac_pendant'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('zodiac_pendant'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(
        ItemCatalogue.byId('zodiac_pendant').rarity,
        Rarity.rare,
        reason:
            'the chase stopped being Rare, which changes what a mini is allowed to hand out',
      );
    });

    test('the epic is boss-only, and stays rare enough to chase', () {
      final epics = StarfallBasinItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(
        epics,
        contains('the_aimed_sky'),
        reason:
            'the zone\'s epic was renamed or cut, so the boss pool has nothing to chase',
      );
      for (final id in epics) {
        for (final e in all) {
          if (e.drops.possibleDrops.contains(id)) {
            expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
            expect(
              e.drops.mainChanceOf(id),
              lessThanOrEqualTo(0.15),
              reason: '$id is handed out too freely for an epic',
            );
          }
        }
      }
    });
  });

  group('the catalogue matches CELESTIAL_CONTRACT §4.3', () {
    test('nine definitions, exactly as the contract counts them', () {
      expect(
        StarfallBasinItems.all,
        hasLength(9),
        reason: 'a def was added or cut against §4.3\'s nine',
      );
      expect(
        StarfallBasinItems.all.map((d) => d.id).toSet(),
        {
          'skyiron_ore',
          'fallstone',
          'skysteel_ingot',
          'astral_essence',
          'astral_dust',
          'astral_shard',
          'astral_crystal',
          'zodiac_pendant',
          'the_aimed_sky',
        },
        reason:
            'an id drifted from the contract\'s table, so a drop or recipe now points at nothing',
      );
    });

    test('every item is resolvable, and owned by this zone', () {
      for (final def in StarfallBasinItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⚠️ every equipLevel sits inside the 34–39 band', () {
      // ⚠️ §7.6 — and materials, motes and gate parts sit at 1, because a
      // material with an equip level is a material nobody can pick up early.
      final loc = World.byId(zone);
      for (final def in StarfallBasinItems.all) {
        if (def is EquipmentDef) {
          expect(
            def.equipLevel,
            inInclusiveRange(loc.minLevel, loc.maxLevel),
            reason: '${def.id} cannot be worn in the zone that drops it',
          );
        } else {
          expect(
            def.equipLevel,
            lessThanOrEqualTo(loc.minLevel),
            reason: '${def.id} is not equipment and must not gate on level',
          );
          expect(def.equipLevel, 1, reason: '${def.id} should sit at 1');
        }
      }
      expect(
        ItemCatalogue.byId('zodiac_pendant').equipLevel,
        37,
        reason: 'the rare\'s equip level moved off §4.3',
      );
      expect(
        ItemCatalogue.byId('the_aimed_sky').equipLevel,
        39,
        reason: 'the epic\'s equip level moved off §4.3',
      );
    });

    test('the two drop-only pieces are named, and the ladder is one slot', () {
      // ⭐ §3.5 — drop-only jewelry and boss uniques set `properName`;
      // crafted equipment must leave it null so material+form composes.
      // ⚠️ Both pendants are `neck`: §4.3's deliberate rare→epic ladder
      // inside one zone, which no Kinetic zone offered.
      for (final id in ['zodiac_pendant', 'the_aimed_sky']) {
        final def = ItemCatalogue.byId(id) as EquipmentDef;
        expect(def.properName, isNotNull, reason: '$id is a named drop');
        expect(
          def.slot,
          EquipSlot.neck,
          reason:
              'the rare-to-epic ladder broke into two slots, which §4.3 calls a sidegrade',
        );
        expect(
          def.tradability,
          Tradability.untradeable,
          reason:
              'a drop-only piece became tradeable, so gold can buy what the boss gated',
        );
        expect(
          def.material,
          'Sky-Iron',
          reason:
              'the material string drifted, which is half of the composed display name',
        );
      }
    });

    test('⭐ both drops are crit — Astral is the crit element (§2.5a)', () {
      final rare = ItemCatalogue.byId('zodiac_pendant') as EquipmentDef;
      final epic = ItemCatalogue.byId('the_aimed_sky') as EquipmentDef;
      expect(
        rare.modifiers.critChance,
        10,
        reason: 'the rare\'s crit chance moved off §4.3',
      );
      expect(
        rare.modifiers.critDamage,
        12,
        reason: 'the rare\'s crit damage moved off §4.3',
      );
      expect(
        rare.modifiers.damagePerCast,
        0,
        reason: 'the rare is PURE crit — the damage is what the epic adds',
      );
      expect(
        epic.modifiers.critChance,
        10,
        reason: 'the epic\'s crit chance moved off §4.3',
      );
      expect(
        epic.modifiers.critDamage,
        18,
        reason: 'the epic\'s crit damage moved off §4.3',
      );
      expect(
        epic.modifiers.damagePerCast,
        9,
        reason:
            'the epic lost the damage line that makes its crits worth landing',
      );
    });

    test('the motes carry the ruled per-tier value, and no Core or Heart', () {
      const perTier = {
        MoteTier.dust: 2,
        MoteTier.shard: 25,
        MoteTier.crystal: 150,
      };
      final motes = StarfallBasinItems.all.whereType<MoteDef>().toList();
      expect(
        motes,
        hasLength(3),
        reason: 'the astral family grew or shrank away from dust/shard/crystal',
      );
      for (final m in motes) {
        expect(
          m.element,
          MagicElement.astral,
          reason:
              'a mote in this zone\'s file is not Astral, so the family has two owners',
        );
        expect(
          m.value,
          perTier[m.tier],
          reason: '${m.id} drifted off ECONOMY §14c\'s uniform tier value',
        );
        expect(
          {MoteTier.core, MoteTier.heart},
          isNot(contains(m.tier)),
          reason: '${m.id} is a Core or Heart, which §3.2 does not ship',
        );
      }
      expect(
        motes.map((m) => m.rarity).toList(),
        [Rarity.common, Rarity.common, Rarity.uncommon],
        reason:
            'a mote rarity drifted off ITEMS §8, which is what keeps Crystal off a common table',
      );
    });

    test('⚠️ the gate essence is Bound, valueless and kill-only', () {
      final essence = ItemCatalogue.byId('astral_essence') as MaterialDef;
      expect(
        essence.tradability,
        Tradability.bound,
        reason:
            'the gate part became tradeable, so the Rimeholt gate can be bought',
      );
      expect(
        essence.rarity,
        Rarity.rare,
        reason: 'the gate part\'s rarity moved off §3.4',
      );
      expect(essence.value, 0, reason: 'a gate part must not be vendorable');
      expect(
        essence.skill,
        CraftSkill.enchanting,
        reason:
            'the gate part stopped feeding Enchanting, which is what charges the Totem',
      );
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('astral_essence')),
        reason: 'a node for the gate part is a second source for the gate',
      );
    });

    test('the two materials feed the skills §3.1 assigns them', () {
      final ore = ItemCatalogue.byId('skyiron_ore') as MaterialDef;
      final stone = ItemCatalogue.byId('fallstone') as MaterialDef;
      expect(
        ore.skill,
        CraftSkill.metalworking,
        reason: 'skyiron_ore stopped feeding Metalworking (§3.1)',
      );
      expect(
        ore.tier,
        5,
        reason:
            'skyiron_ore\'s tier moved, which is what drives the level band it serves',
      );
      expect(
        ore.value,
        26,
        reason:
            'skyiron_ore\'s value moved off §4.3, which the recipe conservation audit reads',
      );
      // ⭐ The first Enchanting material with a consumer in its own quarter,
      // and the one that finally spends the Kinetic quarter's Hum Quartz.
      expect(
        stone.skill,
        CraftSkill.enchanting,
        reason:
            'fallstone stopped feeding Enchanting, and it is the quarter\'s only in-band Enchanting material',
      );
      expect(
        stone.tier,
        5,
        reason:
            'fallstone\'s tier moved, which is what drives the level band it serves',
      );
      expect(
        stone.value,
        60,
        reason:
            'fallstone\'s value moved off §4.3, which the recipe conservation audit reads',
      );
      expect(
        stone.rarity,
        Rarity.uncommon,
        reason: 'fallstone is the ceiling of what a common may pay',
      );
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('⭐ two Mining nodes and nothing else — the only zone like it', () {
      // ⚠️ §4.3: no cloth, no wood, no herb. Everything here came down and
      // nothing grew, so both materials are prised out of craters.
      expect(
        nodes,
        hasLength(2),
        reason: 'a node was added or cut — §6 gives this zone exactly two',
      );
      expect(
        nodes.map((n) => n.id).toSet(),
        {'sb_skyiron_field', 'sb_fallstone_crater'},
        reason:
            'a node id drifted off §6\'s table, or the sb_ prefix was dropped',
      );
      for (final n in nodes) {
        expect(
          n.skill,
          GatherSkill.mining,
          reason: '${n.id} is not Mining, and nothing here grows',
        );
      }
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason:
              '${n.id} is authored but missing from GatherNodes.all, so it never spawns',
        );
      }
    });

    test('every node yields a real material OF THIS ZONE', () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields ${n.yieldsDefId}, which is not stackable',
        );
        expect(
          def,
          isA<MaterialDef>(),
          reason: '${n.id} yields something that is not a crafting material',
        );
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} yields another zone\'s material',
        );
        expect(
          n.min,
          greaterThan(0),
          reason: '${n.id} can harvest nothing at all',
        );
        expect(
          n.max,
          greaterThanOrEqualTo(n.min),
          reason: '${n.id} has an inverted yield range',
        );
      }
      // ⭐ Between them the nodes cover both gatherable materials, and
      // neither covers the kill-only gate part.
      expect(nodes.map((n) => n.yieldsDefId).toSet(), {
        'skyiron_ore',
        'fallstone',
      }, reason: 'the two nodes no longer cover both gatherable materials');
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(
        expectedXp,
        75,
        reason:
            'the band floor moved, so the XP formula below is checking a stale number',
      );
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
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

    test('every catalogue entry carries lore and a written name', () {
      for (final def in StarfallBasinItems.all) {
        expect(def.lore, isNotEmpty, reason: '${def.id} has no lore');
        expect(
          def.properName,
          isNotNull,
          reason: '${def.id} has no written name',
        );
      }
    });
  });
}
