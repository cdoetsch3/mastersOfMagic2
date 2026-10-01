/// The Umbral Wastes (Lv 47–51, Umbra) — roster, catalogue and node laws.
///
/// ⭐ **Mutation-verified**: every `expect` names the wrong implementation it
/// kills, per `testing-conventions.md`. The sources are ENEMIES_DESIGN
/// §2e/§2e.1/§2e.2/§2f/§2g and ETHEREAL_CONTRACT §1.3, §2.3, §2.4, §3.2,
/// §3.4, §3.5.1, §4.3 and §6.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_umbral_wastes.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_umbral_wastes_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **Hallowmarch (ETHEREAL_CONTRACT §4.1) owns these two ids**, and this
/// zone's drop tables reference both because §4.3 puts them there. This lane
/// must NOT define them — a second definition would shadow Hallowmarch's and
/// make `ItemCatalogue.zoneOf` answer the wrong zone — so until that lane
/// lands they are the only two ids here that do not resolve.
///
/// ⭐ The checks below assert *at most* these two are unresolved rather than
/// skipping the resolution law, so an invented id still fails today and the
/// file keeps passing unchanged once Hallowmarch ships.
const _pendingFromHallowmarch = {'climbers_ration', 'goldenrood_draught'};

void main() {
  const zone = 'the_umbral_wastes';
  final all = UmbralWastesBestiary.all;

  /// Drop ids this suite can look up right now.
  Iterable<String> resolvable(Iterable<String> ids) =>
      ids.where((id) => ItemCatalogue.tryById(id) != null);

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        UmbralWastesBestiary.commons,
        hasLength(5),
        reason:
            'a sixth or fourth common silently changes every encounter slot '
            'in the zone',
      );
      expect(
        UmbralWastesBestiary.minis,
        hasLength(4),
        reason: 'a run draws 2 of 4 minis; any other count changes the draw',
      );
      expect(
        UmbralWastesBestiary.bosses,
        hasLength(2),
        reason:
            'the gate ruling assumes exactly two bosses, both carrying the '
            'Dark Third',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (§7.1) — an unlisted
      // zone compiles fine and never appears in an encounter.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'the bestiary is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'a creature is defined but missing from the zone lists',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(UmbralWastesBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so some draws repeat a role');
    });

    test('the boss pair is a will and a shape, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e — Nightbringer is *who made it dark*, and §2g reserves
      // the Tyrant for "a person, a will, something that decided." What Was
      // Thought About is *the shape it was given*, so an Aspect. A Juggernaut
      // here would be a mass, and a mass cannot impose anything.
      expect(
        UmbralWastesBestiary.nightbringer.archetype.id,
        'tyrant',
        reason: 'demoting Nightbringer to a mass takes the will out of it',
      );
      expect(
        UmbralWastesBestiary.whatWasThoughtAbout.archetype.id,
        'aspect',
        reason: 'the Aspect is what makes this pair the theme, not a rematch',
      );
      expect(
        UmbralWastesBestiary.bosses.map((e) => e.archetype.id).toSet(),
        hasLength(2),
        reason: 'a mirrored boss pair teaches the same fight twice',
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
        reason: 'two creatures share an id, so one is unreachable by lookup',
      );
      expect(
        all.map((e) => e.name).toSet(),
        hasLength(all.length),
        reason: 'two creatures share a display name',
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

    test('no creature id collides with the rest of the game', () {
      final ids = Bestiary.all.map((e) => e.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'an Umbral Wastes id shadows a creature from another zone',
      );
    });

    test('every creature is pure Umbra — this is the quarter\'s Umbra pure '
        'zone', () {
      // ⭐ ETHEREAL_CONTRACT §3.2: the `umbra_*` family is defined here
      // because this zone yields it first, which only holds while the whole
      // roster pays in that one ladder.
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is tagged to another zone');
        expect(e.elements, const [
          MagicElement.umbra,
        ], reason: '${e.id} is not pure Umbra, which breaks the §3.2 sourcing');
      }
      expect(loc.elements, const [
        MagicElement.umbra,
      ], reason: 'world.dart no longer calls this a pure Umbra zone');
    });

    test('the per-creature element assignment matches the roster table '
        'exactly', () {
      // ⚠️ Hard-coded rather than derived: a mutant that flips one creature
      // to sanctus must fail here, not pass a "they all match each other"
      // loop.
      const umbra = [MagicElement.umbra];
      expect(UmbralWastesBestiary.umbralDevourer.elements, umbra);
      expect(UmbralWastesBestiary.edgewalker.elements, umbra);
      expect(UmbralWastesBestiary.consideredIce.elements, umbra);
      expect(UmbralWastesBestiary.nightspill.elements, umbra);
      expect(UmbralWastesBestiary.thoughtform.elements, umbra);
      expect(UmbralWastesBestiary.umbralKnight.elements, umbra);
      expect(UmbralWastesBestiary.theEdge.elements, umbra);
      expect(UmbralWastesBestiary.voidStalker.elements, umbra);
      expect(UmbralWastesBestiary.eclipseWeaver.elements, umbra);
      expect(UmbralWastesBestiary.nightbringer.elements, umbra);
      // ⚠️ The Aspect MUST be single-element (ENEMIES §2.5).
      expect(
        UmbralWastesBestiary.whatWasThoughtAbout.elements,
        umbra,
        reason: 'an Aspect with two elements leans on neither passive',
      );
    });

    test('the roster table\'s archetype assignment survived', () {
      // ⭐ ENEMIES §2e — the three rows the audit argued about: the Siphon is
      // KEPT here (one of only three zones), Edgewalker was re-banded from
      // Skirmisher to Adept, and Nightspill is the Creeping Dark tutor.
      expect(
        UmbralWastesBestiary.umbralDevourer.archetype.id,
        'siphon',
        reason:
            'the Devourer is one of the three Siphons §2f kept; cutting it '
            'here is cutting the archetype from the game',
      );
      expect(
        UmbralWastesBestiary.edgewalker.archetype.id,
        'adept',
        reason: 'the Edgewalker is the zone yardstick, not a Skirmisher',
      );
      expect(
        UmbralWastesBestiary.nightspill.archetype.id,
        'blighter',
        reason: 'the Creeping Dark tutor must be the status archetype',
      );
      expect(
        UmbralWastesBestiary.consideredIce.archetype.id,
        'sentinel',
        reason: 'ice that holds its shape because it was decided IS the wall',
      );
    });

    test('the anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'world.dart advertises a creature this zone does not field',
      );
      expect(
        World.opponentNameFor(World.byId(zone)),
        'Umbral Devourer',
        reason: 'the anchor moved away from the roster table\'s creature',
      );
    });

    test('the zone band is 47–51, and it is a route', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 47, reason: 'the band floor moved under the items');
      expect(loc.maxLevel, 51, reason: 'the band ceiling moved');
      expect(
        loc.kind,
        LocationKind.route,
        reason:
            'a dungeon here would break the 2026-09-21 road ruling — '
            'Hallowmarch rounds the shoulder INTO the Wastes and the '
            'Reliquary\'s door is above it',
      );
      expect(
        loc.tier,
        MagicTier.ethereal,
        reason: 'the zone slipped out of the Ethereal quarter',
      );
    });
  });

  group('combat stats match ETHEREAL_CONTRACT §2.3 / §2.4', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        UmbralWastesBestiary.edgewalker.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Siphon connects, survives, and NEVER crits', () {
      // ⚠️ §2.3's Siphon row and its reasoning: a lifesteal crit heals for
      // the crit too, and a 0.95-HP body that double-heals off one roll is
      // the stalemate ENEMIES §2.2 fears.
      expect(
        UmbralWastesBestiary.umbralDevourer.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, dodge: 6),
        reason: 'the Umbral Devourer is off its §2.3 row',
      );
      expect(
        UmbralWastesBestiary.umbralDevourer.combatStats.critChance,
        0,
        reason: 'a crit on a lifesteal body is the §2.3 stalemate',
      );
    });

    test('the Sentinel deflects', () {
      expect(
        UmbralWastesBestiary.consideredIce.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
        reason: 'the Considered Ice is off its §2.3 row',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        UmbralWastesBestiary.nightspill.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
        reason: 'Nightspill is off its §2.3 row',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        UmbralWastesBestiary.thoughtform.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
        reason: 'the Thoughtform is off its §2.3 row',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        UmbralWastesBestiary.umbralKnight.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Umbral Knight is off its §2.3 row',
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      // 📝 §2.3 recommends trimming the Redoubt to 25/24 in the two DUNGEONS
      // (The Buried Sky, The Reliquary Deep) where a player cannot retreat.
      // ⚠️ This zone is a ROUTE, so it keeps the published 35/30.
      expect(
        UmbralWastesBestiary.theEdge.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason:
            'The Edge was trimmed as if it were one of the two dungeon '
            'Redoubts; this is a route and the retreat exists',
      );
    });

    test('the Executioner keeps the FULL §2.3 row at this band', () {
      expect(
        UmbralWastesBestiary.voidStalker.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason: 'the Void Stalker was trimmed as if it were entry band',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        UmbralWastesBestiary.eclipseWeaver.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'the Eclipse Weaver is off its §2.3 row',
      );
    });

    test('the Tyrant carries a little of everything', () {
      expect(
        UmbralWastesBestiary.nightbringer.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 5,
          dodge: 5,
          critChance: 10,
          critDamage: 15,
          deflectChance: 10,
          deflectAmount: 15,
        ),
        reason: 'Nightbringer is off its §2.3 row',
      );
    });

    test('the Aspect is §2.4\'s Umbra row, verbatim — the largest crit '
        'damage in the game, behind the smallest crit chance', () {
      expect(
        UmbralWastesBestiary.whatWasThoughtAbout.combatStats,
        const EnemyCombatStats(
          critChance: 15,
          critDamage: 70,
          deflectChance: 20,
          deflectAmount: 18,
        ),
        reason:
            'What Was Thought About is off §2.4 — crit DAMAGE is Umbra\'s '
            'affinity, and +70 is deliberately paired with a low 15% chance',
      );
      final stats = UmbralWastesBestiary.whatWasThoughtAbout.combatStats;
      expect(
        stats.critDamage,
        greaterThan(
          Bestiary.all
              .where((e) => e.id != 'what_was_thought_about')
              .map((e) => e.combatStats.critDamage)
              .reduce((a, b) => a > b ? a : b),
        ),
        reason:
            '§2.4 claims this is the largest crit damage on any stat block '
            'in the game; something else now ties or beats it',
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
        // ⚠️ §2.1's three inert-stat traps: a "buff" with a zero chance to
        // trigger is dead weight nobody notices until they read the code.
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

    test('move ids are unique across the WHOLE bestiary, and all prefixed '
        'uw_', () {
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason: 'two Umbral Wastes moves share an id',
      );
      for (final id in mine) {
        expect(id.startsWith('uw_'), isTrue, reason: '$id is not zone-tagged');
      }
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (ETHEREAL_CONTRACT §3.5/§7.2) — proved against every shipped zone,
      // not just this one.
      // ⭐ Mages cast Spellbook ids by design (EnemyDef.isMage), and two
      // mages may share one — the law is over CREATURE kits only.
      final everything = [
        for (final e in Bestiary.all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(
        everything.toSet(),
        hasLength(everything.length),
        reason: 'a uw_ move id collides with another zone\'s',
      );
    });

    test('no move name collides with the game\'s own vocabulary', () {
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      final spellNames = Spellbook.all.map((s) => s.name.toLowerCase()).toSet();
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
          expect(
            spellNames.contains(n),
            isFalse,
            reason: '"${m.name}" is a player spell name (ENEMIES §3.3)',
          );
        }
      }
    });

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree.
      // 📝 No mage in this zone, so nothing is exempt from the move-count law
      // (the Collapsed Academy and Citadel lanes own `isMage`).
      for (final e in all) {
        final a = e.archetype;
        expect(
          e.moves.length,
          a.moveCount,
          reason: '${e.id} is a ${a.name}, which wants ${a.moveCount} moves',
        );
        for (final m in e.moves) {
          expect(
            m.chargeCost,
            greaterThanOrEqualTo(a.minMoveCost),
            reason:
                '${e.id}\'s "${m.name}" is cheaper than a ${a.name} '
                'should have',
          );
          expect(
            m.chargeCost,
            lessThanOrEqualTo(a.maxMoveCost),
            reason:
                '${e.id}\'s "${m.name}" is dearer than a ${a.name} '
                'should have',
          );
        }
      }
    });

    test('raw damage stays in the shared authoring band', () {
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so this zone's 47–51 band arrives via the ENCOUNTER LEVEL,
      // never bigger raws. Hard ceilings: ≤ 60 raw on a move, ≤ 12 per charge.
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
      // ⚠️ Shields 3 (2 or less only to beat the player's own), quick 5,
      // aux 7/8, attack 9; 1–2 reserved for genuinely Quickened strikes.
      // ⚠️ A shield at 9 is the specific mutant: it would go up AFTER the
      // hit it was meant to absorb.
      for (final e in all) {
        for (final m in e.moves) {
          expect(
            m.priority,
            inInclusiveRange(1, 9),
            reason: '${e.id}\'s "${m.name}" is off the ladder entirely',
          );
          if (m.effect is ShieldEffect) {
            expect(
              m.priority,
              lessThanOrEqualTo(3),
              reason: '${e.id}\'s "${m.name}" is a wall that goes up last',
            );
          }
        }
      }
    });

    test('the Blighter is multi-hit only — and that is how Creeping Dark '
        'is taught', () {
      // ⚠️ §1.3's per-archetype rule: a Blighter out-lasts rather than
      // out-hits. ⭐ The engine grows Creeping Dark by charge SPENT, so a
      // cheap constant kit is a stack that never stops climbing.
      final spill = UmbralWastesBestiary.nightspill;
      expect(spill.archetype.id, 'blighter');
      for (final m in spill.moves) {
        expect(
          m.effect,
          isA<DamageEffect>(),
          reason: '${m.name} is not an attack at all',
        );
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} landed as one big hit, which is a Bruiser',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Sentinel/Redoubt are defined partly by attrition. Without a
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

    test('the Sentinel\'s wall is its DEAR move — the telegraph', () {
      // ⭐ §2.5's tempo lean: the wall at cost 4 against an attack at cost 2
      // is what makes the Considered Ice readable. A cheap wall would remove
      // the only tell it has.
      final ice = UmbralWastesBestiary.consideredIce;
      final wall = ice.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(
        wall.chargeCost,
        ice.moves.map((m) => m.chargeCost).reduce((a, b) => a > b ? a : b),
        reason:
            'the wall is no longer the expensive move, so it stops '
            'telegraphing',
      );
    });

    test('the Redoubt\'s wall lands ahead of the player\'s own shield', () {
      final wall = UmbralWastesBestiary.theEdge.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(3),
        reason: 'The Edge\'s wall resolves after the player\'s',
      );
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final weaver = UmbralWastesBestiary.eclipseWeaver;
      expect(weaver.archetype.id, 'hexer');
      expect(
        weaver.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        weaver.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Eclipse Weaver throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap is lowered to 4, and it executes', () {
      // ⚠️ §1.3 — at the mini five-charge raw a level-60 Executioner lands
      // 884–1153 against a 1012 HP bar. Kills a mutant that restores cost 5.
      final stalker = UmbralWastesBestiary.voidStalker;
      expect(stalker.archetype.id, 'executioner');
      for (final m in stalker.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" is a one-shot with change at the band top',
        );
      }
      expect(
        stalker.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).executeBelowPercent > 0,
        ),
        isTrue,
        reason:
            'the Executioner\'s whole lesson is the finisher rider; without '
            'it this is a Champion with two moves',
      );
    });

    test('only the Siphon and the Redoubt drink', () {
      // ⭐ ENEMIES §2.6 — casual lifesteal belongs to the Siphon, and §1.3
      // allows the Redoubt exactly one move.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect || effect.lifesteal == 0) continue;
          expect(
            e.archetype.id,
            anyOf('siphon', 'redoubt'),
            reason: '${e.id}\'s "${m.name}" drinks, which is not its archetype',
          );
        }
      }
      expect(
        UmbralWastesBestiary.umbralDevourer.moves.every(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        isTrue,
        reason:
            'a Siphon that does not siphon is a small Bruiser — "chip damage '
            'never accumulates" is taught by it healing off your chip',
      );
      expect(
        UmbralWastesBestiary.theEdge.moves.where(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        hasLength(1),
        reason:
            'the Redoubt should have exactly ONE lifesteal move (§1.3) — '
            'zero makes it a plain wall, two make it a Siphon',
      );
    });

    test('the Aspect\'s dear move is cost 4 — Creeping Dark in one lump', () {
      // ⭐ The engine grows the stack by charge SPENT, so charge cost IS the
      // status magnitude. A cheaper finisher would make the Aspect's whole
      // premise quieter than a common's.
      final aspect = UmbralWastesBestiary.whatWasThoughtAbout;
      expect(
        aspect.moves.map((m) => m.chargeCost).reduce((a, b) => a > b ? a : b),
        4,
        reason: 'the Aspect stacks less darkness in a cast than Nightspill',
      );
      expect(
        aspect.moves.map((m) => m.chargeCost).toList(),
        [1, 2, 4],
        reason:
            'the kit must CLIMB, because the climb is what the player reads '
            'off the charge bar',
      );
    });

    test('no off-element move — §2e.2 names none in this zone', () {
      // ⚠️ Off-element is licensed for four creatures in fifteen zones and
      // The Umbral Wastes is not one of them.
      for (final e in all) {
        expect(
          e.elements,
          hasLength(1),
          reason: '${e.id} carries a second element',
        );
      }
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every table is a real item, bar the two Hallowmarch '
        'still owes', () {
      final unresolved = <String>{};
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (ItemCatalogue.tryById(id) == null) unresolved.add(id);
        }
      }
      expect(
        unresolved.difference(_pendingFromHallowmarch),
        isEmpty,
        reason:
            'a drop id no catalogue defines — either a typo or an item this '
            'lane forgot to author',
      );
      for (final id in _pendingFromHallowmarch) {
        expect(
          UmbralWastesBestiary.allDrops,
          contains(id),
          reason:
              '$id is declared pending but nothing drops it any more; a '
              'stale allowance quietly stops covering anything',
        );
      }
    });

    test('this lane defines neither Hallowmarch consumable', () {
      // ⚠️ §4.1 owns both ids. A second definition here would shadow the
      // first and make ItemCatalogue.zoneOf answer the wrong zone for an
      // icon that already exists.
      for (final id in _pendingFromHallowmarch) {
        expect(
          UmbralWastesItems.all.map((d) => d.id),
          isNot(contains(id)),
          reason: '$id belongs to Hallowmarch and must not be authored twice',
        );
      }
    });

    test(
      'every main table draws exactly one entry, by weight, summing 100',
      () {
        // 🚫 Kills the arithmetic slip: moving weight off a Shard and onto a
        // Dust is two edits, and dropping one of them changes every OTHER
        // slot's percentage on that table silently.
        for (final e in all) {
          if (e.drops.main.isEmpty) continue;
          expect(
            e.drops.totalWeight,
            100,
            reason: '${e.id}\'s main table no longer reads as percentages',
          );
        }
      },
    );

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in UmbralWastesBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...UmbralWastesBestiary.minis,
        ...UmbralWastesBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in UmbralWastesBestiary.commons) {
        for (final id in resolvable(e.drops.possibleDrops)) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a pure zone pays ONE mote ladder, and it is Umbra', () {
      final dropped = UmbralWastesBestiary.allDrops;
      for (final id in ['umbra_dust', 'umbra_shard', 'umbra_crystal']) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      for (final id in dropped) {
        if (!id.endsWith('_dust') &&
            !id.endsWith('_shard') &&
            !id.endsWith('_crystal')) {
          continue;
        }
        expect(
          id.startsWith('umbra_'),
          isTrue,
          reason:
              '$id is a foreign mote in the quarter\'s Umbra PURE zone, '
              'which is also the zone that defines the family (§3.2)',
        );
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8; §4.3's "mini and boss and nowhere else").
      for (final e in UmbralWastesBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final m in UmbralWastesBestiary.minis) {
        final shards = m.drops.always.where(
          (d) => d.defId?.endsWith('_shard') == true,
        );
        expect(
          shards.fold(0.0, (a, d) => a + d.chance),
          closeTo(1, 1e-9),
          reason: '${m.id} owes exactly one Shard a kill',
        );
      }
      for (final b in UmbralWastesBestiary.bosses) {
        expect(
          b.drops.always.any((d) => d.defId == 'umbra_crystal'),
          isTrue,
          reason: '${b.id} does not guarantee a Crystal',
        );
      }
    });

    test('⭐ the Dark Third drops from BOTH bosses, on the always line', () {
      // ⚠️ ENEMIES §2e.1 / ETHEREAL_CONTRACT §3.4 — a run draws one boss of
      // two. A key on the weighted table, or on only one boss, turns a
      // mandatory progression item into a coin flip.
      for (final b in UmbralWastesBestiary.bosses) {
        final entry = b.drops.always.where((d) => d.defId == 'the_dark_third');
        expect(
          entry,
          hasLength(1),
          reason: '${b.id} does not guarantee The Dark Third',
        );
        expect(
          entry.single.chance,
          1,
          reason: '${b.id} rolls for a tier gate part',
        );
        expect(
          b.drops.main.any((d) => d.defId == 'the_dark_third'),
          isFalse,
          reason: '${b.id} also weights the key, which double-counts it',
        );
      }
      for (final e in [
        ...UmbralWastesBestiary.commons,
        ...UmbralWastesBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('the_dark_third')),
          reason: '${e.id} is not a boss and must not carry the gate part',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in UmbralWastesBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_considered_ring'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_considered_ring'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('the_considered_ring').rarity, Rarity.rare);
    });

    test('the epic is boss-only', () {
      final epics = UmbralWastesItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(
        epics,
        contains('the_deliberate_dark'),
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

    test('the hide role resolves to thoughtglass — the zone\'s SECOND '
        'material', () {
      // ⭐ ETHEREAL_CONTRACT §3.5.1: this zone defines no hide, so "something
      // died" pays in the zone's own stuff. ⚠️ Kills a mutant that invents an
      // `umbral_hide` or drops the role silently.
      expect(
        UmbralWastesBestiary.edgewalker.drops.possibleDrops,
        contains('thoughtglass'),
        reason: 'the Edgewalker carries the hide role and pays nothing for it',
      );
      expect(
        UmbralWastesBestiary.voidStalker.drops.possibleDrops,
        contains('thoughtglass'),
        reason: 'the Void Stalker carries the hide role and pays nothing',
      );
      for (final id in UmbralWastesBestiary.allDrops) {
        expect(
          id,
          isNot(contains('hide')),
          reason: '$id looks like an invented hide; this zone has none',
        );
      }
    });

    test('⚠️ the Siphon\'s row is §4.3\'s hand-written one, not §3.5.1\'s '
        'rule', () {
      // ⭐ The contract writes the Umbral Devourer's table out by hand and
      // pays it in `umbralweave` — the FIRST material — even though its role
      // is `hide`. The explicit table outranks the general rule, and this is
      // the one place in the zone where they disagree.
      final table = UmbralWastesBestiary.umbralDevourer.drops;
      expect(
        table.possibleDrops,
        contains('umbralweave'),
        reason: 'the Siphon row was "corrected" to the §3.5.1 default',
      );
      expect(
        table.mainChanceOf('umbralweave'),
        closeTo(0.65, 1e-9),
        reason:
            'the Siphon row drifted off §4.3\'s 40/45/15 as leaned on '
            '2026-09-30 (nothing halved to 20, its 20 moved onto '
            'umbralweave: 20/65/15) — kills a lean that skipped this row',
      );
    });

    test('every zone item is a real ItemDef owned by this zone', () {
      for (final def in UmbralWastesItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
      expect(
        UmbralWastesItems.all,
        hasLength(13),
        reason:
            '§4.3\'s table lists 12 and §7.1 counts the three Thirds inside '
            'the same 79 — the Dark Third is the thirteenth def',
      );
    });
  });

  group('the catalogue obeys the contract', () {
    test('equipment sits inside the band; stock sits at or below its '
        'floor', () {
      final loc = World.byId(zone);
      for (final def in _Split.equipment) {
        expect(
          def.equipLevel,
          inInclusiveRange(loc.minLevel, loc.maxLevel),
          reason: '${def.id} cannot be worn anywhere in its own zone',
        );
      }
      for (final def in _Split.notEquipment) {
        expect(
          def.equipLevel,
          lessThanOrEqualTo(loc.minLevel),
          reason: '${def.id} is stock and must be usable from the band floor',
        );
      }
    });

    test('crafted equipment leaves properName null; drops set it', () {
      // ⚠️ §3.5 — a crafted name composes from material + form (ITEMS
      // §9b.5a). A properName on a crafted piece freezes it.
      for (final id in [
        'umbralweave_hood',
        'umbralweave_robe',
        'umbralweave_leggings',
        'umbralweave_boots',
        'umbralweave_gloves',
      ]) {
        expect(
          ItemCatalogue.byId(id).properName,
          isNull,
          reason: '$id is crafted and must compose its own name',
        );
      }
      for (final id in ['the_considered_ring', 'the_deliberate_dark']) {
        expect(
          ItemCatalogue.byId(id).properName,
          isNotNull,
          reason: '$id is a named drop and must carry its name',
        );
      }
    });

    test('⭐ the Umbralweave set totals §4.3\'s published line', () {
      // ⚠️ 88 HP · 6 acc · 6 dodge · 16/22 deflect — the number §4.3 measures
      // +13.9% health against the level-48 baseline with. A single piece
      // edited in isolation moves the audit and nothing else says so.
      final set = [
        UmbralWastesItems.umbralweaveHood,
        UmbralWastesItems.umbralweaveRobe,
        UmbralWastesItems.umbralweaveLeggings,
        UmbralWastesItems.umbralweaveBoots,
        UmbralWastesItems.umbralweaveGloves,
      ];
      expect(
        set.fold(0, (a, d) => a + d.modifiers.maxHpBonus),
        88,
        reason: 'the set\'s flat HP moved off §4.3\'s +13.9% measurement',
      );
      expect(set.fold(0, (a, d) => a + d.modifiers.accuracyBonus), 6);
      expect(set.fold(0, (a, d) => a + d.modifiers.dodge), 6);
      expect(
        UmbralWastesItems.umbralweaveGloves.modifiers.deflectChance,
        16,
        reason:
            '§2.1b: chance and amount travel together, and the glove '
            'carries the quarter\'s one deflect drop',
      );
      expect(UmbralWastesItems.umbralweaveGloves.modifiers.deflectAmount, 22);
      expect(
        set.every((d) => d.rarity == Rarity.common),
        isTrue,
        reason:
            '§3.6 — every armour piece is a plain Common so Phase 8 can add '
            'Tier III/IV sets BESIDE them rather than instead of them',
      );
    });

    test('⚠️ the Epic has LOWER crit than the Rare, and that is not a bug', () {
      // ⭐ §4.3's most likely row to be "fixed": the rare is 8/+34 and the
      // epic is 6/+28 with 20 HP. It is ITEMS §4.1a's glass-cannon axis with
      // both ends built — the rare is the gamble, the epic is the version you
      // can survive wearing. Read the block comment in the catalogue before
      // touching these numbers.
      final rare = UmbralWastesItems.theConsideredRing;
      final epic = UmbralWastesItems.theDeliberateDark;
      expect(rare.modifiers.critChance, 8);
      expect(rare.modifiers.critDamage, 34);
      expect(epic.modifiers.critChance, 6);
      expect(epic.modifiers.critDamage, 28);
      expect(epic.modifiers.maxHpBonus, 20);
      expect(
        epic.modifiers.critDamage,
        lessThan(rare.modifiers.critDamage),
        reason:
            'someone "laddered" the epic above the rare and deleted the one '
            'place the rarity ladder buys SAFETY rather than power',
      );
      expect(
        [rare.slot, epic.slot],
        [EquipSlot.ring, EquipSlot.ring],
        reason:
            'they are both rings so they cannot be worn together, which is '
            'what makes the choice a choice',
      );
      for (final d in [rare, epic]) {
        expect(
          d.tradability,
          Tradability.untradeable,
          reason: '${d.id} became sellable, so the chase can be bought',
        );
      }
    });

    test('the mote ladder is ECONOMY §14c\'s values, uniform by tier', () {
      expect(ItemCatalogue.byId('umbra_dust').value, 2);
      expect(ItemCatalogue.byId('umbra_shard').value, 25);
      expect(
        ItemCatalogue.byId('umbra_crystal').value,
        150,
        reason: 'mote values are per TIER and uniform across elements',
      );
      expect(
        ItemCatalogue.byId('umbra_crystal').rarity,
        Rarity.uncommon,
        reason: 'Crystal is the one uncommon rung (ITEMS §8)',
      );
      // ⭐⭐ §3.2: this zone DEFINES the family, so no other catalogue may.
      for (final id in ['umbra_dust', 'umbra_shard', 'umbra_crystal']) {
        expect(
          ItemCatalogue.zoneOf(id),
          zone,
          reason:
              '$id is defined outside the first Umbra zone, so §3.2\'s '
              'sourcing table is wrong for four later zones',
        );
        expect(
          (ItemCatalogue.byId(id) as MoteDef).element,
          MagicElement.umbra,
          reason: '$id is tagged to the wrong element',
        );
      }
    });

    test('the two materials are the tier-8 pair §3.1 names', () {
      final weave = ItemCatalogue.byId('umbralweave') as MaterialDef;
      final glass = ItemCatalogue.byId('thoughtglass') as MaterialDef;
      expect(
        weave.skill,
        CraftSkill.tailoring,
        reason: 'umbralweave stopped feeding the Tailoring ladder',
      );
      expect(
        glass.skill,
        CraftSkill.jewelry,
        reason: 'thoughtglass stopped feeding the Jewelry ladder',
      );
      expect(
        weave.tier,
        8,
        reason:
            'the material tier drives the band it '
            'serves; 8 is the Ethereal rung',
      );
      expect(glass.tier, 8);
      expect(weave.value, 290);
      expect(glass.value, 200);
      expect(
        glass.rarity,
        Rarity.uncommon,
        reason: 'thoughtglass is gem-grade stock, not bulk',
      );
    });

    test('the gate fragment is Bound, valueless and kill-only', () {
      final third = ItemCatalogue.byId('the_dark_third');
      expect(third, isA<KeyDef>(), reason: 'the Third stopped being a key');
      expect((third as KeyDef).gates, 'the_eclipsed_citadel');
      expect(third.tradability, Tradability.bound);
      expect(third.value, 0, reason: 'a gate part must not be vendorable');
      expect(third.rarity, Rarity.rare);
      expect(
        third.equipLevel,
        1,
        reason: '§3.4 — a fragment is carried, not worn',
      );
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('the_dark_third')),
        reason: 'a node for the gate part is a second source (§3.4)',
      );
    });

    test('nothing here re-defines another zone\'s id', () {
      // ⚠️ §7.2's uniqueness audit, run against the live catalogue rather
      // than against the contract's count.
      final ids = ItemCatalogue.all.map((d) => d.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'an Umbral Wastes id shadows an item from another zone',
      );
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final ice = UmbralWastesBestiary.consideredIce;
      final night = UmbralWastesBestiary.nightbringer;
      expect(
        ice.maxHpAt(47),
        (MageState.scaledMaxHp(47) * Archetypes.sentinel.hpScale).round(),
        reason: 'a second HP curve crept in',
      );
      expect(
        night.maxHpAt(51),
        (MageState.scaledMaxHp(51) * Archetypes.tyrant.hpScale).round(),
        reason: 'a second HP curve crept in',
      );
      expect(
        night.maxHpAt(51),
        greaterThan(ice.maxHpAt(51)),
        reason: 'the boss no longer out-bulks a common',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 47. Anything that can open with a kill
      // from full health is a difficulty spike disguised as a wandering
      // monster.
      final startingHp = MageState.scaledMaxHp(47);
      for (final e in UmbralWastesBestiary.commons) {
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

    test('three nodes for two materials — the §6 throughput ruling', () {
      // ⭐ `umbralweave` is consumed by four or more recipes, and one node per
      // run section cannot keep a level-50 crafter supplied. ⚠️ A second node
      // is a THROUGHPUT fix, not a second source: both yield the same id, and
      // gather_node.dart's no-second-source rule is about the fiction (a hide
      // must have no node at all), not about node count.
      expect(nodes, hasLength(3), reason: 'a node is missing or duplicated');
      expect(nodes.map((n) => n.id).toSet(), {
        'uw_umbralweave_drift',
        'uw_thoughtglass_face',
        'uw_shoulder_drift',
      }, reason: 'a node id drifted from ETHEREAL_CONTRACT §6');
      expect(
        nodes.where((n) => n.yieldsDefId == 'umbralweave'),
        hasLength(2),
        reason:
            'the second umbralweave node was "deduplicated" away and the '
            'Tailoring ladder is now supply-starved',
      );
    });

    test('every node is reachable from GatherNodes.all', () {
      // ⚠️ An unlisted node compiles fine and simply never spawns.
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} is defined but not in GatherNodes.all',
        );
      }
    });

    test('every node yields a real material of THIS zone', () {
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
          reason: '${n.id} gathers something that is not a material',
        );
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} gathers another zone\'s material',
        );
        expect(n.min, greaterThan(0));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('node skill matches the material\'s consuming skill (§6a.1)', () {
      // ⭐ Tailoring ← Foraging, Jewelry ← Mining.
      expect(
        GatherNodes.byId('uw_umbralweave_drift')!.skill,
        GatherSkill.foraging,
        reason: 'umbralweave is Tailoring stock and Foraging is its half',
      );
      expect(
        GatherNodes.byId('uw_shoulder_drift')!.skill,
        GatherSkill.foraging,
        reason: 'the second drift must agree with the first',
      );
      expect(
        GatherNodes.byId('uw_thoughtglass_face')!.skill,
        GatherSkill.mining,
        reason: 'thoughtglass is a gem and gems are mined',
      );
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 101, reason: 'the band floor moved under the formula');
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });

    test('no node id collides with the rest of the game', () {
      final ids = GatherNodes.all.map((n) => n.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'a uw_ node id shadows another zone\'s',
      );
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

    test('every item carries lore too', () {
      for (final def in UmbralWastesItems.all) {
        expect(
          def.lore.length,
          greaterThan(20),
          reason: '${def.id} has no lore line',
        );
      }
    });
  });
}

/// Small split of the zone catalogue, so the equip-level law can say two
/// different things about gear and about stock without repeating the filter.
abstract final class _Split {
  static final equipment = UmbralWastesItems.all.whereType<EquipmentDef>();
  static final notEquipment = UmbralWastesItems.all.where(
    (d) => d is! EquipmentDef,
  );
}
