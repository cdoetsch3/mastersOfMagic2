import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/tidewrack_shoals.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/tidewrack_shoals_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **Parallel-worktree exemption, and it is temporary.** Tidewrack defines
/// no motes and no consumables: it pays in `aqua_*` (Glimmerbrook, already on
/// main) and `lunar_*` (`the_mirrormere`), plus the Kiln Desert's two imported
/// consumables. The Mirrormere and Kiln Desert lanes are being authored in
/// sibling worktrees in the same wave, so those five ids cannot resolve until
/// the merge coordinator lands them.
///
/// ⭐ **Delete this set at the merge and the skipped test below stops being
/// skipped** — that is the whole mechanism, and `content_export_test.dart`
/// carries the same exemption for the same window.
const _crossLaneIds = <String>{
  'lunar_dust',
  'lunar_shard',
  'lunar_crystal',
  'pilgrims_ration',
  'glasswort_draught',
};

void main() {
  const zone = 'tidewrack_shoals';
  final all = TidewrackShoalsBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        TidewrackShoalsBestiary.commons,
        hasLength(5),
        reason: 'a zone with four commons repeats an encounter every run',
      );
      expect(
        TidewrackShoalsBestiary.minis,
        hasLength(4),
        reason: 'the mini pool draws 2 of 4; three makes the draw a formality',
      );
      expect(
        TidewrackShoalsBestiary.bosses,
        hasLength(2),
        reason: 'one boss is not a pool, and this pool IS the zone premise',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where the silent failure lives (§7.1) — an
      // unlisted zone compiles fine and never appears in an encounter.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'TidewrackShoalsBestiary.all is missing from Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'a creature is in `all` but not in commons/minis/bosses',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every
      // visit a different pair of tactical ROLES rather than just names.
      expect(TidewrackShoalsBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so the draw stopped mattering');
    });

    test('the boss pair is the hybrid\'s two elements, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e — the Kraken is what the tide UNCOVERS (Juggernaut,
      // a mass from the deep) and The Undertow is what it TAKES BACK (Aspect,
      // the element itself). No Tyrant in this zone.
      expect(
        TidewrackShoalsBestiary.kraken.archetype.id,
        'juggernaut',
        reason: 'the Kraken is a mass, not a mind — a Tyrant here is wrong',
      );
      expect(
        TidewrackShoalsBestiary.theUndertow.archetype.id,
        'aspect',
        reason: 'the Undertow is Lunar taken to an extreme, which is Aspect',
      );
      expect(
        TidewrackShoalsBestiary.kraken.archetype.id,
        isNot(TidewrackShoalsBestiary.theUndertow.archetype.id),
        reason: 'a mirrored boss pool says nothing about the zone',
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
        reason: 'two creatures share an id, so one of them can never be drawn',
      );
      expect(
        all.map((e) => e.name).toSet(),
        hasLength(all.length),
        reason: 'two creatures share a name, which the art pipeline keys on',
      );
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on
      // id. An id that drifts from its name is a rename nobody notices.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('every creature carries only Lunar and/or Aqua, and its own zone '
        'holds both', () {
      final loc = World.byId(zone);
      const legal = {MagicElement.lunar, MagicElement.aqua};
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is filed under another zone');
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
            reason: '${e.id} uses an element the zone itself does not hold',
          );
        }
      }
    });

    test('⚠️ no off-element move — ENEMIES §2e.2 names four creatures in '
        'fifteen zones and none of them is here', () {
      // §2h licenses a third element on minis and bosses only, one move,
      // and §2e.2 lists every instance by name. Tidewrack is not on it.
      for (final e in all) {
        expect(
          e.elements.length,
          lessThanOrEqualTo(2),
          reason: '${e.id} smuggled in a third element',
        );
      }
    });

    test('the per-creature element assignment matches ENEMIES §2e exactly', () {
      // ⭐ Hard-coded from the roster table rather than derived, so a
      // creature quietly re-elemented fails here and nowhere else.
      const lunar = [MagicElement.lunar];
      const aqua = [MagicElement.aqua];
      const both = [MagicElement.lunar, MagicElement.aqua];
      final expected = <String, List<MagicElement>>{
        'tidewrack_drowned': both,
        'wrackcrab': aqua,
        'lowwater_thing': aqua,
        'gullbone_flock': lunar,
        'spindrift': aqua,
        'tidal_empress': both,
        'leviathan': aqua,
        'maelstrom_horror': aqua,
        'the_turning': lunar,
        'kraken': aqua,
        'the_undertow': lunar,
      };
      for (final e in all) {
        expect(
          e.elements,
          expected[e.id],
          reason: '${e.id}\'s element list left the roster table',
        );
      }
    });

    test('⭐⭐ The Undertow is LUNAR — the pull, not the water', () {
      // ENEMIES §2h states it twice: "Tidewrack's Kraken is Aqua and its
      // Undertow is Lunar, because the undertow is not the water — it is the
      // pull." ⚠️ CELESTIAL_CONTRACT §2.4's row calls it Aqua; that row
      // predates the final roster and only its STAT BLOCK is taken. Kills
      // the mutant that "reconciles" the element back to the contract.
      expect(TidewrackShoalsBestiary.theUndertow.elements, const [
        MagicElement.lunar,
      ], reason: 'the Aspect must be single-element, and the element is Lunar');
      expect(TidewrackShoalsBestiary.kraken.elements, const [
        MagicElement.aqua,
      ], reason: 'the boss pool IS the hybrid\'s two elements, one each');
    });

    test('⭐ the Lowwater Thing is a Blighter, not a Siphon', () {
      // ENEMIES §2e, final: "Siphon cut — the zone's idea is a schedule, not
      // an appetite (§2f)." CELESTIAL_CONTRACT §1.2/§2.3 still carries a
      // Siphon row expecting this creature; the roster is the later document.
      expect(
        TidewrackShoalsBestiary.lowwaterThing.archetype.id,
        'blighter',
        reason: 'the Siphon was cut from this zone deliberately',
      );
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('siphon')),
        reason: 'no Siphon fights on the shoals',
      );
    });

    test('the anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason:
            'World.opponentNameFor points at a creature that does not '
            'exist, so the placeholder duel names a ghost',
      );
      // ⭐ The anchor is the zone's Adept — the yardstick (§2.3).
      expect(
        TidewrackShoalsBestiary.tidewrackDrowned.archetype.id,
        'adept',
        reason: 'a Drudge at level 38 was a wasted encounter slot (§2f)',
      );
    });

    test('the zone band is 36–40, and nothing else', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 36, reason: 'the band floor moved');
      expect(loc.maxLevel, 40, reason: 'the band ceiling moved');
      expect(
        loc.kind,
        LocationKind.route,
        reason: 'Tidewrack is a route, not a dungeon (§4.4)',
      );
    });
  });

  group('combat stats match CELESTIAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // reasonable, so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        TidewrackShoalsBestiary.tidewrackDrowned.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel reads as "everything lands softer"', () {
      expect(
        TidewrackShoalsBestiary.wrackcrab.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
        reason: 'the Wrackcrab is not wearing the §2.3 Sentinel row',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        TidewrackShoalsBestiary.lowwaterThing.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
        reason: 'the Lowwater Thing is not wearing the §2.3 Blighter row',
      );
    });

    test('the Lasher bites often and stings rarely', () {
      expect(
        TidewrackShoalsBestiary.gullboneFlock.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason: 'the flock is not wearing the §2.3 Lasher row',
      );
    });

    test('the Skirmisher is hard to pin and always first', () {
      expect(
        TidewrackShoalsBestiary.spindrift.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
        reason: 'the Spindrift is not wearing the §2.3 Skirmisher row',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        TidewrackShoalsBestiary.tidalEmpress.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Empress is not wearing the §2.3 Champion row',
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        TidewrackShoalsBestiary.leviathan.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason: 'the Leviathan is not wearing the §2.3 Redoubt row',
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        TidewrackShoalsBestiary.maelstromHorror.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason: 'the Horror is not wearing the §2.3 Executioner row',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        TidewrackShoalsBestiary.theTurning.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'The Turning is not wearing the §2.3 Hexer row',
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        TidewrackShoalsBestiary.kraken.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
        reason: 'the Kraken is not wearing the §2.3 Juggernaut row',
      );
    });

    test('the Aspect copies §2.4\'s own row, verbatim', () {
      // ⭐ Deliberately the same shape as Frostfell's The Road Under, one
      // tier up — defl 30/30 (EV 9.0%) with a little dodge.
      expect(
        TidewrackShoalsBestiary.theUndertow.combatStats,
        const EnemyCombatStats(deflectChance: 30, deflectAmount: 30, dodge: 4),
        reason: 'the Undertow\'s §2.4 stat block drifted',
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
        // ⚠️ §2.1's inert-stat traps: a "buff" with a zero chance to trigger is
        // dead weight nobody notices until they read the code. ⭐ Negative crit
        // damage counts — the Lasher's −20 is the case a `> 0` guard misses.
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
      // ⚠️ ENEMIES §3 — a crab does not cast Bolt. Sharing an id would also
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
      // ⚠️ The prefix is what keeps 31 zones' move ids from colliding
      // (§3.5's zone-prefix table). Checked against every zone, not just
      // this one — a within-zone check would pass on a collision with
      // Frostfell.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason: 'two moves in this zone share an id',
      );
      for (final id in mine) {
        expect(
          id.startsWith('tw_'),
          isTrue,
          reason: '$id is not zone-tagged with the tw_ prefix',
        );
      }
      // ⭐ Mages cast Spellbook ids by design (EnemyDef.isMage) — the law is
      // over CREATURE kits only.
      final everyone = [
        for (final e in Bestiary.all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(
        everyone.toSet(),
        hasLength(everyone.length),
        reason: 'a tw_ move id collides with another zone\'s',
      );
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
      // the moves. This is the seam where those two must agree.
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

    test('raw damage stays in the shared authoring band', () {
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so this zone's 36–40 band arrives via the ENCOUNTER LEVEL,
      // never through bigger raws. Kills the mutant that "levels up" a raw.
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

    test('the Blighter is multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule — a Blighter wins by out-lasting, not
      // out-hitting, and a single big hit is a different archetype.
      final thing = TidewrackShoalsBestiary.lowwaterThing;
      expect(thing.archetype.id, 'blighter');
      for (final m in thing.moves) {
        expect(
          m.effect,
          isA<DamageEffect>(),
          reason: '${m.name} is not damage',
        );
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} lands in one piece',
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
              '${e.id} is a ${e.archetype.name} with nothing to hide '
              'behind',
        );
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final turning = TidewrackShoalsBestiary.theTurning;
      expect(turning.archetype.id, 'hexer');
      expect(
        turning.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        turning.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing The Turning throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️ §1.3 — at L40 a mini five-charge raw would be a one-shot with
      // change. Kills the mutant that reverts to the Q1 cost-5 cap.
      final horror = TidewrackShoalsBestiary.maelstromHorror;
      expect(horror.archetype.id, 'executioner');
      for (final m in horror.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '${m.name} is a five-charge finisher at this band',
        );
      }
    });

    test('the Redoubt\'s wall lands ahead of the player\'s own shield', () {
      final wall = TidewrackShoalsBestiary.leviathan.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(3),
        reason: 'a Redoubt wall that queues behind yours is not a wall',
      );
    });

    test('no shield is ever thrown at attack priority', () {
      // ⚠️ The shipped integer ladder: shields 3 (2 for a Redoubt or a
      // Juggernaut), quick 5, aux 7/8, attack 9. A shield at 9 goes up after
      // the hit it was meant to stop.
      for (final e in all) {
        for (final m in e.moves) {
          if (m.effect is! ShieldEffect) continue;
          expect(
            m.priority,
            lessThanOrEqualTo(3),
            reason: '${e.id}\'s "${m.name}" raises a wall after the blow',
          );
        }
      }
    });

    test('nothing lifesteals except the Redoubt\'s finisher', () {
      // ⭐ ENEMIES §2.6 — the Siphon is Thornmire's lesson, and §2f cut the
      // Siphon out of this zone on purpose. A Redoubt's one lifesteal move
      // (§1.3) is the sole exception.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          if (e.archetype.id == 'redoubt' && effect.lifesteal > 0) continue;
          expect(
            effect.lifesteal,
            0,
            reason:
                '${e.id}\'s "${m.name}" gives the zone an appetite it was '
                'deliberately denied',
          );
        }
      }
      final swallow = TidewrackShoalsBestiary.leviathan.moves.firstWhere(
        (m) => m.id == 'tw_swallowwhole',
      );
      expect(
        (swallow.effect as DamageEffect).lifesteal,
        greaterThan(0),
        reason: 'the Redoubt\'s one allowed lifesteal went missing',
      );
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
  });

  group('drop tables resolve and are honest', () {
    test(
      'every id in every table is a real item',
      () {
        for (final e in all) {
          for (final id in e.drops.possibleDrops) {
            expect(
              ItemCatalogue.contains(id),
              isTrue,
              reason: '${e.id} drops "$id", which no catalogue defines',
            );
          }
        }
      },
      // ⚠️ SKIPPED FOR ONE MERGE WINDOW. `lunar_*` are defined by
      // `the_mirrormere` and `pilgrims_ration` / `glasswort_draught` by
      // `the_kiln_desert`, both authored in sibling worktrees in this wave
      // (§3.2's "the mote lives with the zone that first yields it", and
      // §4.4's imported consumables). ⭐ Un-skip at the merge — the
      // exemption below is what keeps the check live in the meantime.
    );

    test('every id that is NOT cross-lane resolves today', () {
      // ⭐ The live half of the check above: everything this zone owns, plus
      // the `aqua_*` family Glimmerbrook already ships, must resolve now.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_crossLaneIds.contains(id)) continue;
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
      expect(
        TidewrackShoalsBestiary.allDrops,
        containsAll(const ['aqua_dust', 'aqua_shard', 'aqua_crystal']),
        reason: 'the Q1 cross-quarter aqua reference (§3.2) was dropped',
      );
    });

    test('⭐ the material-A commons carry §4.4\'s 2% ration bonus, and only '
        'they do', () {
      // ⚠️ `bonus` is rolled independently ON TOP of the main draw, so it is
      // the one bucket a missing row leaves no trace of — the table still
      // resolves, still sums to 100, and quietly pays less forever.
      for (final e in [
        TidewrackShoalsBestiary.wrackcrab,
        TidewrackShoalsBestiary.spindrift,
      ]) {
        expect(e.drops.bonus.map((d) => d.defId), [
          'pilgrims_ration',
        ], reason: '${e.id} lost the material-A row\'s bonus ration');
        expect(
          e.drops.bonus.single.chance,
          0.02,
          reason: '${e.id} pays the bonus ration at the wrong rate',
        );
      }
      for (final e in all) {
        if (e.id == 'wrackcrab' || e.id == 'spindrift') continue;
        expect(
          e.drops.bonus,
          isEmpty,
          reason:
              '${e.id} grew a bonus row §4.4 never gave it — every entry '
              'there is unbounded loot',
        );
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
      for (final e in TidewrackShoalsBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out, which inflates every rare slot',
        );
      }
      for (final e in [
        ...TidewrackShoalsBestiary.minis,
        ...TidewrackShoalsBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in TidewrackShoalsBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          if (_crossLaneIds.contains(id)) continue;
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a hybrid drops BOTH parents\' mote ladders, at half chance', () {
      // ⭐ §4.4's shipped hybrid shape — two dusts at 0.5 each, so a hybrid
      // kill pays about as much mote as a pure one but in two currencies.
      final dropped = TidewrackShoalsBestiary.allDrops;
      for (final id in const [
        'lunar_dust',
        'lunar_shard',
        'lunar_crystal',
        'aqua_dust',
        'aqua_shard',
        'aqua_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      for (final e in TidewrackShoalsBestiary.commons) {
        final dusts = e.drops.always.where(
          (d) => d.defId == 'lunar_dust' || d.defId == 'aqua_dust',
        );
        expect(
          dusts,
          hasLength(2),
          reason: '${e.id} does not pay both ladders on every kill',
        );
        for (final d in dusts) {
          expect(
            d.chance,
            0.5,
            reason: '${e.id} pays a full pure-zone roll on BOTH families',
          );
        }
      }
      // ⚠️ Nothing from a third element.
      const foreign = {
        'solar_dust',
        'solar_shard',
        'solar_crystal',
        'astral_dust',
        'astral_shard',
        'astral_crystal',
        'aero_dust',
        'aero_shard',
        'aero_crystal',
        'geo_dust',
        'geo_shard',
        'geo_crystal',
      };
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in TidewrackShoalsBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in TidewrackShoalsBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️ no boss carries an essence or a key — this is a hybrid', () {
      // §4.4: "NO essence — hybrid." The Celestial Totem's three parts come
      // from the three PURE zones (ENEMIES §2e.1), which is the same rule
      // NARRATIVE used for the Kinetic Sigil.
      for (final b in TidewrackShoalsBestiary.bosses) {
        for (final id in b.drops.possibleDrops) {
          expect(
            id,
            isNot(contains('essence')),
            reason: '${b.id} drops a gate part it is not owed',
          );
          expect(
            id,
            isNot(contains('totem')),
            reason: '${b.id} drops the Rimeholt gate item itself',
          );
        }
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in TidewrackShoalsBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_turning_tide'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_turning_tide'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(
        ItemCatalogue.byId('the_turning_tide').rarity,
        Rarity.rare,
        reason: 'the chase stopped being a chase',
      );
    });

    test('the epic is boss-only, and no more than a one-in-seven', () {
      final epics = TidewrackShoalsItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(
        epics,
        contains('lowwater_tread'),
        reason: 'the zone lost its epic',
      );
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(
            e.drops.mainChanceOf(id),
            lessThanOrEqualTo(0.15),
            reason: '${e.id} hands out $id too freely',
          );
        }
      }
    });

    test('drownling_hide reaches the player only through the roles the '
        'roster gave it', () {
      // ⚠️ §3.1 — kill-only. The two hide commons, both minis' table and
      // both bosses' table are the whole supply; the material commons and
      // the Siphon row must not leak it.
      expect(
        TidewrackShoalsBestiary.wrackcrab.drops.possibleDrops,
        isNot(contains('drownling_hide')),
        reason: 'the material-A common leaked the hide',
      );
      expect(
        TidewrackShoalsBestiary.lowwaterThing.drops.possibleDrops,
        isNot(contains('drownling_hide')),
        reason: 'the Siphon row leaked the hide',
      );
      for (final e in [
        TidewrackShoalsBestiary.tidewrackDrowned,
        TidewrackShoalsBestiary.gullboneFlock,
      ]) {
        expect(
          e.drops.possibleDrops,
          contains('drownling_hide'),
          reason: '${e.id} carries the hide role and drops no hide',
        );
      }
    });

    test('every item in the zone catalogue is a real ItemDef with a real '
        'zone', () {
      for (final def in TidewrackShoalsItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
      expect(
        TidewrackShoalsItems.all,
        hasLength(11),
        reason: '§7.1 counts Tidewrack at 11 item definitions',
      );
    });

    test('drownling_hide is kill-only — no file authors a node for it', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('drownling_hide')),
        reason:
            'a node for a hide is a second source that contradicts its '
            'own fiction (§9b.7b)',
      );
    });
  });

  group('the catalogue obeys the contract\'s own numbers', () {
    test('every equipLevel sits inside the band, materials at or below it', () {
      final loc = World.byId(zone);
      for (final def in TidewrackShoalsItems.all) {
        if (def is EquipmentDef) {
          expect(
            def.equipLevel,
            inInclusiveRange(loc.minLevel, loc.maxLevel),
            reason: '${def.id} cannot be worn by anyone who farmed it',
          );
        } else {
          expect(
            def.equipLevel,
            lessThanOrEqualTo(loc.minLevel),
            reason: '${def.id} is a material gated above its own zone',
          );
        }
      }
    });

    test('⭐ the Wrackcotton set totals §4.4\'s published figures', () {
      // 67 HP · 5 acc · 5 dodge · 14/24 deflect — +15.1% against the L39
      // baseline. Kills the mutant that nudges one piece and leaves the
      // proportion §2.6 depends on quietly wrong.
      const setIds = {
        'wrackcotton_hood',
        'wrackcotton_robe',
        'wrackcotton_leggings',
        'wrackcotton_boots',
        'wrackcotton_gloves',
      };
      var total = ItemModifiers.none;
      for (final def in TidewrackShoalsItems.all.whereType<EquipmentDef>()) {
        if (setIds.contains(def.id)) total += def.modifiers;
      }
      expect(total.maxHpBonus, 67, reason: 'the set HP total moved');
      expect(total.accuracyBonus, 5, reason: 'the set accuracy total moved');
      expect(total.dodge, 5, reason: 'the set dodge total moved');
      expect(total.deflectChance, 14, reason: 'set deflect chance moved');
      expect(total.deflectAmount, 24, reason: 'set deflect amount moved');
    });

    test('⚠️ exactly one set piece carries deflection', () {
      // §2.1b's finding: deflect AMOUNT sums across pieces, and three pieces
      // breach the design cap. The gloves own the line and nothing else may.
      final carriers = TidewrackShoalsItems.all
          .whereType<EquipmentDef>()
          .where((d) => d.modifiers.deflectChance != 0)
          .map((d) => d.id);
      expect(carriers, [
        'wrackcotton_gloves',
      ], reason: 'deflection spread across more than the gloves');
    });

    test('⚠️ the belt carries capacity and nothing else', () {
      // The Q1 ruling (ITEMS §6b.2): capacity is the one axis that is
      // deliberately NOT combat power.
      final belt = TidewrackShoalsItems.drownlingBelt;
      expect(belt.modifiers.beltSlots, 5, reason: 'the capacity ladder moved');
      expect(
        belt.modifiers + const ItemModifiers(beltSlots: -5),
        isA<ItemModifiers>().having(
          (m) => m.isEmpty,
          'is otherwise empty',
          isTrue,
        ),
        reason: 'someone put a stat on a belt',
      );
    });

    test('⭐ both named drops mix Lunar dodge with Aqua shield strength', () {
      // §2.5a's affinity table, stated as a stat block: the tide obeys, and
      // obedience is a defence.
      for (final def in [
        TidewrackShoalsItems.theTurningTide,
        TidewrackShoalsItems.lowwaterTread,
      ]) {
        expect(
          def.modifiers.dodge,
          greaterThan(0),
          reason: '${def.id} lost the Lunar half',
        );
        expect(
          def.modifiers.shieldStrengthPercent,
          greaterThan(0),
          reason: '${def.id} lost the Aqua half',
        );
        expect(
          def.tradability,
          Tradability.untradeable,
          reason: '${def.id} is a drop-only name and must not be sellable',
        );
        expect(
          def.properName,
          isNotNull,
          reason: '${def.id} is a named drop and needs its bespoke name',
        );
      }
    });

    test('⚠️ crafted-grammar pieces leave properName null', () {
      // ITEMS §9b.5a — the name composes from material + form so it cannot
      // drift from the facts.
      for (final def in TidewrackShoalsItems.all.whereType<EquipmentDef>()) {
        if (def.rarity != Rarity.common) continue;
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
      }
    });

    test(
      'nacre is Jewelry t6 and banks — no recipe in this quarter eats it',
      () {
        final nacre = TidewrackShoalsItems.nacre;
        expect(nacre, isA<MaterialDef>());
        expect(
          nacre.skill,
          CraftSkill.jewelry,
          reason: 'nacre stopped being Jewelry\'s, so §3.1 banking breaks',
        );
        expect(nacre.tier, 6, reason: 'the material tier moved');
        expect(
          nacre.rarity,
          Rarity.uncommon,
          reason: 'nacre is the zone\'s one uncommon material',
        );
      },
    );
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final crab = TidewrackShoalsBestiary.wrackcrab;
      final kraken = TidewrackShoalsBestiary.kraken;
      expect(
        crab.maxHpAt(36),
        (MageState.scaledMaxHp(36) * Archetypes.sentinel.hpScale).round(),
        reason: 'the Wrackcrab grew a second HP curve',
      );
      expect(
        kraken.maxHpAt(40),
        (MageState.scaledMaxHp(40) * Archetypes.juggernaut.hpScale).round(),
        reason: 'the Kraken grew a second HP curve',
      );
      expect(
        kraken.maxHpAt(40),
        greaterThan(crab.maxHpAt(40)),
        reason: 'the boss is smaller than a common at the same level',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 36 and is reachable by sea from Galehaven, so a
      // player can arrive without passing Concordance. Anything that can open
      // with a kill from full health is a spike disguised as a wanderer.
      final startingHp = MageState.scaledMaxHp(36);
      for (final e in TidewrackShoalsBestiary.commons) {
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

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('two nodes — Drownling Hide is a hide and has none', () {
      expect(
        nodes,
        hasLength(2),
        reason: 'a hybrid holds three materials, one of which is kill-only',
      );
      expect(nodes.map((n) => n.id).toSet(), {
        'ts_wrackcotton_flat',
        'ts_nacre_bed',
      }, reason: '§3.5\'s node-id grammar is <zone prefix>_<place>');
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} is defined but never registered, so it never spawns',
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
          reason: '${n.id} gathers another zone\'s material',
        );
        expect(n.min, greaterThan(1), reason: '${n.id} is all-or-nothing');
        expect(
          n.max,
          greaterThanOrEqualTo(n.min),
          reason: '${n.id} has an inverted range, which throws on harvest',
        );
      }
    });

    test('the skill is read off the material\'s consuming skill', () {
      // §6a.1: Tailoring/Potions ← Foraging, Jewelry (gems) ← Mining. ⭐ Nacre
      // is a Jewelry material gathered by Mining, the `amber` precedent.
      final byId = {for (final n in nodes) n.id: n};
      expect(
        byId['ts_wrackcotton_flat']!.skill,
        GatherSkill.foraging,
        reason: 'wrackcotton feeds Tailoring, so Foraging harvests it',
      );
      expect(
        byId['ts_nacre_bed']!.skill,
        GatherSkill.mining,
        reason: 'gems are Mining\'s half, however Jewelry spends them',
      );
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 79, reason: 'the band floor moved under the formula');
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

    test('every item carries lore that is not a stat line', () {
      for (final def in TidewrackShoalsItems.all) {
        expect(def.lore, isNotEmpty, reason: '${def.id} has no lore');
        expect(
          def.lore.length,
          greaterThan(40),
          reason: '${def.id} lore is thin',
        );
        expect(
          RegExp(
            r'\d+\s*(hp|dodge|accuracy)',
            caseSensitive: false,
          ).hasMatch(def.lore),
          isFalse,
          reason: '${def.id} lore leaks mechanics',
        );
      }
    });
  });
}
