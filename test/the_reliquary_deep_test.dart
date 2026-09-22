/// The Reliquary Deep's roster LAWS (Lv 52–56, Sanctus + Umbra) and its
/// catalogue checks — ENEMIES §2e plus ETHEREAL_CONTRACT §4.6.
///
/// ⚠️ **`sanctus_*`, `umbra_*` and `climbers_ration` are owned by parallel
/// Ethereal worktrees** (Hallowmarch and The Umbral Wastes). Everything this
/// zone DEFINES is asserted normally; the cross-lane ids are asserted in one
/// `skip:`ped test whose skip reason names the dependency, so the merge
/// coordinator has exactly one line to delete once the lanes land together.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_reliquary_deep.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_reliquary_deep_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id the Reliquary itself authors — that is what
/// the "no local id hides in here" test below proves.
const _parallelLaneIds = <String>{
  'sanctus_dust',
  'sanctus_shard',
  'sanctus_crystal',
  'umbra_dust',
  'umbra_shard',
  'umbra_crystal',
  'climbers_ration',
};

void main() {
  const zone = 'the_reliquary_deep';
  final all = ReliquaryDeepBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        ReliquaryDeepBestiary.commons,
        hasLength(5),
        reason: 'ENEMIES §2e gives every zone exactly five wandering types',
      );
      expect(
        ReliquaryDeepBestiary.minis,
        hasLength(4),
        reason: 'two drawn of four',
      );
      expect(
        ReliquaryDeepBestiary.bosses,
        hasLength(2),
        reason: 'one drawn of two',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (§7.1) — a bestiary
      // left out of `Bestiary.all` compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'ReliquaryDeepBestiary is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'forZone and the class list disagree about the roster',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(ReliquaryDeepBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so a run can draw a mirror');
    });

    test('the boss pair is a weight and the thing still undoing it, NOT a '
        'mirror', () {
      // ⭐⭐ ENEMIES §2e: the two names come straight out of the arrival line
      // and the elements split on the same seam. What Was Consecrated is a
      // mass (Juggernaut, Sanctus); What Did Not Leave It Alone is a decision
      // that keeps being taken (Tyrant, Umbra).
      expect(
        ReliquaryDeepBestiary.whatWasConsecrated.archetype.id,
        'juggernaut',
      );
      expect(
        ReliquaryDeepBestiary.whatDidNotLeaveItAlone.archetype.id,
        'tyrant',
      );
      expect(
        ReliquaryDeepBestiary.bosses.map((b) => b.archetype.id).toSet(),
        hasLength(2),
        reason: 'the boss pool draws one of two and must not be a mirror',
      );
      // ⚠️ §2g / ETHEREAL §2.4: this zone fields NO Aspect, and ⭐ Sanctus
      // never gets one anywhere in the game.
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('aspect')),
        reason: 'the Reliquary Deep fields no Aspect (ENEMIES §2g)',
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

    test('the five commons are the five archetypes §2e names', () {
      // ⚠️ Three of these are §2f re-assignments away from the original
      // draft — Adept (was Sentinel), Blighter (was Glasswing), Glasswing
      // (was Blighter) — and the Skirmisher replaced a cut Siphon. A mutant
      // that reverts any of them still compiles.
      expect(
        ReliquaryDeepBestiary.commons.map((e) => e.archetype.id).toList(),
        ['adept', 'blighter', 'glasswing', 'bruiser', 'skirmisher'],
      );
      expect(
        ReliquaryDeepBestiary.commons.map((e) => e.archetype.id),
        isNot(contains('siphon')),
        reason: '§2f cut the Siphon from this zone; the Skirmisher replaced it',
      );
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('drudge')),
        reason: 'ENEMIES §2f puts zero Drudges above level 30',
      );
    });

    test('ids and names are unique', () {
      expect(all.map((e) => e.id).toSet(), hasLength(all.length));
      expect(all.map((e) => e.name).toSet(), hasLength(all.length));
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      // An id that drifts from its name is a rename nobody notices. ⭐ Two
      // names here carry a hyphen (Censer-Wraith, Bone-Reliquary), which this
      // derivation flattens to an underscore exactly as it does a space.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('the per-creature element assignment matches §2e exactly', () {
      // ⭐ Hard-coded rather than derived: §2h lets a hybrid assign one
      // element or both per creature, so there is no formula to check
      // against — only the table.
      const sanctus = [MagicElement.sanctus];
      const umbra = [MagicElement.umbra];
      const both = [MagicElement.sanctus, MagicElement.umbra];
      expect(ReliquaryDeepBestiary.reliquaryKeeper.elements, sanctus);
      expect(ReliquaryDeepBestiary.censerWraith.elements, umbra);
      expect(ReliquaryDeepBestiary.theUnleft.elements, umbra);
      expect(ReliquaryDeepBestiary.boneReliquary.elements, sanctus);
      expect(ReliquaryDeepBestiary.corridorCrawler.elements, both);
      expect(ReliquaryDeepBestiary.antechoir.elements, sanctus);
      expect(ReliquaryDeepBestiary.reliquaryColossus.elements, sanctus);
      expect(ReliquaryDeepBestiary.theSecondHand.elements, umbra);
      expect(ReliquaryDeepBestiary.warmMiddle.elements, both);
      // ⭐⭐ The seam: the first hand is Sanctus, the second is Umbra.
      expect(
        ReliquaryDeepBestiary.whatWasConsecrated.elements,
        sanctus,
        reason: 'the boss elements split on the arrival line\'s own seam',
      );
      expect(ReliquaryDeepBestiary.whatDidNotLeaveItAlone.elements, umbra);
    });

    test('⚠️ the zone carries NO off-element creature', () {
      // §2e.2 names four creatures in fifteen zones and none of them is here:
      // The Buried Sky, The Glass Archive, The Sealed Garden and The Collapsed
      // Academy. ⭐ The guardrail is "at most one per zone", and this zone's
      // allowance is unspent — a mutant that spends it still compiles.
      const zoneElements = {MagicElement.sanctus, MagicElement.umbra};
      final offElement = all
          .where((e) => e.elements.any((el) => !zoneElements.contains(el)))
          .toList();
      expect(
        offElement.map((e) => e.id),
        isEmpty,
        reason: '§2e.2 licenses no off-element creature in this zone',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2e: "the yardstick, and the one thing in the corridor still doing
      // the job it was left" — the anchor is the Adept, and §2f moved it off
      // Sentinel to make that true.
      expect(
        ReliquaryDeepBestiary.reliquaryKeeper.archetype.id,
        'adept',
        reason:
            'the anchor is the yardstick the rest of the zone is felt against',
      );
      expect(
        all.where((e) => e.archetype.id == 'adept'),
        hasLength(1),
        reason: 'ENEMIES §2f: exactly one Adept per zone, and it is mandatory',
      );
    });

    test('the zone band is 52–56, a dungeon, Sanctus + Umbra', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 52);
      expect(loc.maxLevel, 56);
      expect(loc.kind, LocationKind.dungeon, reason: '🏰 in ENEMIES §2e');
      expect(loc.elements, [MagicElement.sanctus, MagicElement.umbra]);
      expect(loc.tier, MagicTier.ethereal);
    });

    test('⚠️ the dungeon is entered from the Umbral Wastes ONLY', () {
      // ⭐ The 2026-09-21 ruling, and it is load-bearing for the drop economy:
      // a dead end off the top of the climb, not a stop partway up it. A
      // second edge would put the zone back on the north road.
      final loc = World.byId(zone);
      expect(loc.edges.map((e) => e.to).toList(), [
        'the_umbral_wastes',
      ], reason: 'the Reliquary is a dead end off the ice (WORLD §roads)');
    });
  });

  group('combat stats match ETHEREAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        ReliquaryDeepBestiary.reliquaryKeeper.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        ReliquaryDeepBestiary.censerWraith.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        ReliquaryDeepBestiary.theUnleft.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Bruiser hits like a truck and sometimes whiffs', () {
      expect(
        ReliquaryDeepBestiary.boneReliquary.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
      );
    });

    test('the Skirmisher is quick and hard to pin', () {
      expect(
        ReliquaryDeepBestiary.corridorCrawler.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        ReliquaryDeepBestiary.antechoir.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('⭐ the Redoubt keeps the FULL 35/30 row — §2.3\'s deviation is '
        'conditional and its condition is not met', () {
      // ⚠️⚠️ §2.3 recommends 25/24 (EV 6.0%) for the Redoubt in this zone and
      // The Buried Sky — dungeon walls a player cannot retreat from — but only
      // *"unless the fatigue clock has shipped."* ⭐ It HAS: DuelEngine's
      // sudden-death guarantees every duel terminates, which is precisely the
      // stalemate the deviation was guarding against.
      expect(
        ReliquaryDeepBestiary.reliquaryColossus.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
      expect(
        DuelEngine.fatigueThreshold,
        greaterThan(0),
        reason:
            'if the fatigue clock is ever removed, §2.3\'s 25/24 deviation '
            'becomes live again and this Redoubt must drop with it',
      );
      expect(DuelEngine.fatiguePerTurn, greaterThan(0));
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        ReliquaryDeepBestiary.theSecondHand.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        ReliquaryDeepBestiary.warmMiddle.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut is unstoppable and unsubtle', () {
      expect(
        ReliquaryDeepBestiary.whatWasConsecrated.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('the Tyrant carries a little of everything', () {
      expect(
        ReliquaryDeepBestiary.whatDidNotLeaveItAlone.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 5,
          dodge: 5,
          critChance: 10,
          critDamage: 15,
          deflectChance: 10,
          deflectAmount: 15,
        ),
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

    test('no inert stat: an amount never appears without its chance', () {
      // ⚠️ §2.1's three inert-stat traps — a "buff" with a zero chance to
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
    });
  });

  group('creatures are creatures, not mages', () {
    test('no creature here is a mage', () {
      // ⭐ ENEMIES §3.4 — only the Collapsed Academy's Archmage and the
      // Citadel's Procarius bring a Spellbook loadout. This zone's bosses are
      // a corridor and a thing taking it apart; neither casts.
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

    test('move ids are unique across the WHOLE bestiary, and all rd_', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (§3.5/§7.2). Checked game-wide, not zone-locally, because a
      // collision with a shipped zone is the failure that actually happens.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('rd_'), isTrue, reason: '$id is not zone-tagged');
      }
      // ⭐ Mages cast Spellbook ids by design (EnemyDef.isMage), and two
      // mages may share one — the law is over CREATURE kits only.
      final everything = [
        for (final e in Bestiary.all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(
        everything.toSet(),
        hasLength(everything.length),
        reason: 'an rd_ move id collides with another zone\'s',
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
      // the moves. This is the seam where those two must agree. ⚠️ No mage
      // exemption applies in this zone: the Reliquary fields no mage boss.
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

    test('raw damage stays in the Whispering Woods band', () {
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so a 52–56 band arrives via the ENCOUNTER LEVEL, never
      // bigger raws. §1.3's table is byte-for-byte KINETIC's and does not
      // grow — which a builder authoring a level-56 boss will want to doubt.
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
      // ⚠️ §1.3's per-archetype rule, and it is the whole of what makes the
      // Blighter read differently from a plain attacker: each hit meets the
      // wall on its own. ⭐ A censer pays out in wisps, never in one lump.
      for (final m in ReliquaryDeepBestiary.censerWraith.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: 'censer_wraith\'s "${m.name}" arrives in one piece',
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

    test('the Redoubt\'s wall lands ahead of the player\'s own shield', () {
      final wall = ReliquaryDeepBestiary.reliquaryColossus.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(SpellPriority.shield),
        reason: 'a passage sealed after you shield seals on nothing',
      );
    });

    test('no shield ever sits on the attack rung', () {
      // ⚠️ The priority ladder's one hard "never" (the shipped integer
      // ladder): a shield at 9 goes up after everything it was meant to stop.
      for (final e in all) {
        for (final m in e.moves) {
          if (m.effect is! ShieldEffect) continue;
          expect(
            m.priority,
            lessThanOrEqualTo(SpellPriority.shield),
            reason: '${e.id}\'s "${m.name}" shields too late to matter',
          );
        }
      }
    });

    test('the Skirmisher gets ahead of aux and regular spells, but never a '
        'shield', () {
      // ⭐ §2.5's tempo lean: quick means the 5 rung, not the 1 rung. The
      // Hexer owns instant in this zone and the Skirmisher must not steal it.
      final crawler = ReliquaryDeepBestiary.corridorCrawler;
      expect(crawler.archetype.id, 'skirmisher');
      for (final m in crawler.moves) {
        expect(
          m.priority,
          SpellPriority.quick,
          reason: '"${m.name}" is off the quick rung',
        );
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final middle = ReliquaryDeepBestiary.warmMiddle;
      expect(middle.archetype.id, 'hexer');
      expect(
        middle.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        middle.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays lowered to 4, and it executes', () {
      // ⚠️ §1.3 — at L56 a mini five-charge raw lands far past an 897 HP bar:
      // not a two-cast kill, a one-shot with change. Kills a mutant that
      // restores the archetype's own maxMoveCost of 5.
      final hand = ReliquaryDeepBestiary.theSecondHand;
      expect(hand.archetype.id, 'executioner');
      for (final m in hand.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
      expect(
        hand.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).executeBelowPercent > 0,
        ),
        isTrue,
        reason: 'the second hand finishes nothing it starts',
      );
    });

    test('⭐ nothing in this zone lifesteals — the Siphon was CUT (§2f)', () {
      // §4.6's drop table still calls one row "the Siphon", which is a stale
      // LABEL: §2f turned Corridor Crawler into a Skirmisher because "this
      // zone's idea is unfinished work, not appetite." A lifesteal move
      // anywhere here puts the appetite back.
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('siphon')),
        reason: 'the Siphon archetype is cut from this zone',
      );
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" takes what is yours',
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
  });

  group('drop tables resolve and are honest', () {
    test('every id this zone OWNS resolves against the catalogue', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_parallelLaneIds.contains(id)) continue;
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('the cross-lane ids resolve too', () {
      for (final id in _parallelLaneIds) {
        expect(
          ItemCatalogue.tryById(id),
          isNotNull,
          reason: '$id is named by §4.6\'s tables and must exist',
        );
      }
    });

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the skip above would be hiding a real local failure.
      final mine = ReliquaryDeepItems.all.map((d) => d.id).toSet();
      expect(
        mine.intersection(_parallelLaneIds),
        isEmpty,
        reason: 'the exemption list is excusing an id this lane owns',
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

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in ReliquaryDeepBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...ReliquaryDeepBestiary.minis,
        ...ReliquaryDeepBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in ReliquaryDeepBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          final def = ItemCatalogue.tryById(id);
          if (def == null) continue; // cross-lane; covered by the skip above
          expect(
            def.rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ the hybrid pays BOTH mote ladders and nothing else', () {
      final dropped = ReliquaryDeepBestiary.allDrops;
      for (final id in [
        'sanctus_dust',
        'sanctus_shard',
        'sanctus_crystal',
        'umbra_dust',
        'umbra_shard',
        'umbra_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      final foreign = <String>{
        for (final el in MagicElement.values)
          if (el != MagicElement.sanctus && el != MagicElement.umbra) ...[
            '${el.name}_dust',
            '${el.name}_shard',
            '${el.name}_crystal',
          ],
      };
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the common mote line is the half-chance hybrid shape', () {
      // ⭐ Two ladders at 0.5 each, so a kill hands over about what a pure
      // zone's single 0.75 roll does (the shipped Frostfell/Thornmire shape).
      // ⚠️ Restoring either to chance 1 doubles the zone's mote income.
      for (final e in ReliquaryDeepBestiary.commons) {
        final motes = e.drops.always.where(
          (d) => d.defId == 'sanctus_dust' || d.defId == 'umbra_dust',
        );
        expect(motes, hasLength(2), reason: '${e.id} skips a mote ladder');
        for (final d in motes) {
          expect(
            d.chance,
            0.5,
            reason: '${e.id}\'s ${d.defId} is not at the hybrid half-chance',
          );
        }
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in ReliquaryDeepBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in ReliquaryDeepBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️⚠️ no boss carries a gate part — the Written Third MOVED OUT', () {
      // §3.4's reconciliation: the three Ethereal Thirds fall in the
      // quarter's three PURE zones, and `the_written_third` went to The
      // Collapsed Academy. §4.6's `_bossDrops` block still shows it on the
      // `always` line and its own catalogue table strikes it through — the
      // strike is the current reading. ⭐ This zone is a dead-end dungeon, not
      // a gate zone, so §2e.1's keys-on-both-bosses rule has nothing to apply
      // to.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            id,
            isNot('the_written_third'),
            reason: '${e.id} drops the gate fragment §3.4 moved to the Academy',
          );
          expect(
            id.endsWith('_third'),
            isFalse,
            reason: '${e.id} drops "$id", which reads like a gate part',
          );
        }
      }
      expect(
        ReliquaryDeepItems.all.whereType<KeyDef>(),
        isEmpty,
        reason: 'this zone defines no key; §3.4 moved its fragment out',
      );
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in ReliquaryDeepBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('censer_pendant'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('censer_pendant'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('censer_pendant').rarity, Rarity.rare);
    });

    test('the epic is boss-only, and the boss unique is the zone\'s one', () {
      final epics = ReliquaryDeepItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(epics, [
        'the_unconsecrated',
      ], reason: '§4.6 authors exactly one epic');
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
        }
      }
      // ⭐ §2e.1's `unique` role: bosses only, and BOTH bosses share the one
      // table, so the draw of one boss of two never gates the epic.
      for (final b in ReliquaryDeepBestiary.bosses) {
        expect(b.drops.possibleDrops, contains('the_unconsecrated'));
      }
    });

    test('⭐ the hide role pays in reliquary_gold — §3.5 ruling 1', () {
      // ENEMIES §2e gives Corridor Crawler `mote · hide`, and this zone
      // defines no hide item, so the role resolves to the SECOND gatherable
      // material. ⚠️ §3.1: the Reliquary is the only hybrid in either quarter
      // with three gatherable materials and no hide at all.
      expect(
        ReliquaryDeepBestiary.corridorCrawler.drops.possibleDrops,
        contains('reliquary_gold'),
        reason: 'the hide role has nothing to resolve to',
      );
      final materials = ReliquaryDeepItems.all
          .whereType<MaterialDef>()
          .toList();
      expect(materials, hasLength(3), reason: 'a hybrid gets three materials');
      expect(
        materials[1].id,
        'reliquary_gold',
        reason:
            '§3.5 ruling 1 names the SECOND material, in §3.1\'s order: '
            'censer_resin, reliquary_gold, unleft_linen',
      );
      for (final m in materials) {
        expect(
          m.id.contains('hide') || m.id.contains('pelt'),
          isFalse,
          reason: '${m.id} reads as a hide, which this zone must not have',
        );
      }
    });
  });

  group('the catalogue matches §4.6', () {
    test('12 defs, all resolvable under this zone', () {
      // ⚠️ §7.1's per-zone figure says **13** and counts `the_written_third`,
      // which §3.4 moved to The Collapsed Academy and §4.6's own table strikes
      // through. 12 is the post-reconciliation count: 3 materials + 1
      // consumable + 8 equipment, and no motes (§3.2 puts both families with
      // the pure zones that first yield them).
      expect(ReliquaryDeepItems.all, hasLength(12), reason: '§4.6 minus §3.4');
      for (final def in ReliquaryDeepItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
      expect(
        ReliquaryDeepItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'sanctus_* and umbra_* belong to the pure zones (§3.2)',
      );
    });

    test('the three materials carry §3.1\'s skills, tiers and values', () {
      expect(
        ReliquaryDeepItems.censerResin.skill,
        CraftSkill.potionsAndAlchemy,
      );
      expect(ReliquaryDeepItems.reliquaryGold.skill, CraftSkill.jewelry);
      expect(ReliquaryDeepItems.unleftLinen.skill, CraftSkill.tailoring);
      for (final m in ReliquaryDeepItems.all.whereType<MaterialDef>()) {
        expect(m.tier, 9, reason: '${m.id} is off the band\'s material tier');
      }
      expect(ReliquaryDeepItems.censerResin.value, 53);
      expect(ReliquaryDeepItems.reliquaryGold.value, 340);
      expect(ReliquaryDeepItems.unleftLinen.value, 520);
      // ⚠️ Uncommon is the gem grade and survives nowhere else this quarter.
      expect(ReliquaryDeepItems.reliquaryGold.rarity, Rarity.uncommon);
      expect(ReliquaryDeepItems.censerResin.rarity, Rarity.common);
      expect(ReliquaryDeepItems.unleftLinen.rarity, Rarity.common);
    });

    test(
      'equip levels sit in the band; everything else sits at or below it',
      () {
        final loc = World.byId(zone);
        for (final def in ReliquaryDeepItems.all) {
          if (def is EquipmentDef) {
            expect(
              def.equipLevel,
              inInclusiveRange(loc.minLevel, loc.maxLevel),
              reason: '${def.id} equips outside its own zone\'s band',
            );
          } else {
            expect(
              def.equipLevel,
              lessThanOrEqualTo(loc.minLevel),
              reason:
                  '${def.id} is a material or consumable and must be usable '
                  'the moment it drops',
            );
          }
        }
        // ⚠️ §4.6 pins the two named pieces above the set: the chase at 54 and
        // the epic at the band ceiling.
        expect(ReliquaryDeepItems.censerPendant.equipLevel, 54);
        expect(ReliquaryDeepItems.theUnconsecrated.equipLevel, 56);
      },
    );

    test('⭐ the Unleft Linen set is the last armour set in the game, and its '
        'totals are §4.6\'s', () {
      const set = [
        ReliquaryDeepItems.unleftHood,
        ReliquaryDeepItems.unleftRobe,
        ReliquaryDeepItems.unleftLeggings,
        ReliquaryDeepItems.unleftBoots,
        ReliquaryDeepItems.unleftGloves,
      ];
      expect(set.map((d) => d.slot).toSet(), {
        EquipSlot.hat,
        EquipSlot.robeTop,
        EquipSlot.robeBottom,
        EquipSlot.boots,
        EquipSlot.gloves,
      }, reason: 'the set does not cover five distinct armour slots');
      int sum(int Function(ItemModifiers) f) =>
          set.fold(0, (t, d) => t + f(d.modifiers));
      expect(sum((m) => m.maxHpBonus), 115, reason: '§4.6: 115 HP');
      expect(sum((m) => m.accuracyBonus), 6, reason: '§4.6: 6 acc');
      expect(sum((m) => m.dodge), 7, reason: '§4.6: 7 dodge');
      expect(sum((m) => m.deflectChance), 18, reason: '§4.6: 18/26 deflect');
      expect(sum((m) => m.deflectAmount), 26);
      for (final d in set) {
        expect(
          d.rarity,
          Rarity.common,
          reason:
              '${d.id} is not Common — §3.6 keeps Mythic and Legendary free '
              'for Phase 8 set tiers III and IV',
        );
        expect(d.equipLevel, 53);
        expect(d.material, 'Unleft Linen');
      }
    });

    test('⚠️⚠️ only ONE piece of the set carries a deflect amount, and it is '
        'the game\'s largest', () {
      // §2.1b — deflect *amount* sums across pieces, so the budget is spent
      // once. A second piece carrying any amount at all breaks the proof that
      // the worst legal L60 assembly lands on ITEMS §4.1a's cap of 50.
      final carriers = ReliquaryDeepItems.all
          .whereType<EquipmentDef>()
          .where((d) => d.modifiers.deflectAmount > 0)
          .toList();
      expect(carriers.map((d) => d.id), ['unleft_gloves']);
      expect(ReliquaryDeepItems.unleftGloves.modifiers.deflectAmount, 26);
      expect(ReliquaryDeepItems.unleftGloves.modifiers.deflectChance, 18);
    });

    test(
      'crafted gear composes its name; the two named pieces are written',
      () {
        // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
        // material+form grammar composes the name and cannot drift from it. All
        // six commons here are crafted (§5.1 #15–19 and #29).
        for (final d in ReliquaryDeepItems.all.whereType<EquipmentDef>().where(
          (d) => d.rarity == Rarity.common,
        )) {
          expect(
            d.properName,
            isNull,
            reason: '${d.id}: a written name on crafted gear is the drift',
          );
        }
        expect(ReliquaryDeepItems.censerPendant.properName, 'Censer Pendant');
        expect(
          ReliquaryDeepItems.theUnconsecrated.properName,
          'The Unconsecrated',
        );
        // ⭐ Both named pieces are untradeable drops, not merchandise.
        expect(
          ReliquaryDeepItems.censerPendant.tradability,
          Tradability.untradeable,
        );
        expect(
          ReliquaryDeepItems.theUnconsecrated.tradability,
          Tradability.untradeable,
        );
      },
    );

    test('⭐⭐ censer_pendant is the zone in one item, both halves and a '
        'third stat', () {
      // §2.5a — Sanctus's affinity is shield strength % + healing received %,
      // Umbra's is crit damage. ⚠️ §4.6 flags this as the only piece in either
      // contract carrying both halves of a hybrid AND a third stat, with a 📝
      // to cut the critDamage if that is one too many.
      final m = ReliquaryDeepItems.censerPendant.modifiers;
      expect(m.healingReceivedPercent, 15);
      expect(m.shieldStrengthPercent, 15);
      expect(m.critDamage, 20);
      expect(
        m.deflectAmount,
        0,
        reason: 'the pendant must not also spend §2.1b\'s deflect budget',
      );
      expect(ReliquaryDeepItems.censerPendant.value, 5200);
    });

    test('⭐ aetherglass_locket spends the last Celestial banked gem', () {
      // §5.1 #29: `aetherglass` ×3 (The Glass Archive, Q3) + `reliquary_gold`
      // ×2. ⚠️ The gem is a SHIPPED Celestial id, not a cross-lane one, so it
      // must resolve right now.
      final glass = ItemCatalogue.tryById('aetherglass');
      expect(
        glass,
        isNotNull,
        reason: 'the locket\'s gem is defined in The Glass Archive (§3.2)',
      );
      expect(ItemCatalogue.zoneOf('aetherglass'), 'the_glass_archive');
      expect(ReliquaryDeepItems.aetherglassLocket.material, 'Aetherglass');
      // ⭐ Deliberately no deflection, although Arcane's affinity IS
      // deflection: §2.1b's cap has no room left for a fourth slot.
      expect(
        ReliquaryDeepItems.aetherglassLocket.modifiers.deflectChance,
        0,
        reason: '§4.6: the locket deliberately carries no deflection',
      );
      expect(ReliquaryDeepItems.aetherglassLocket.modifiers.deflectAmount, 0);
      expect(ReliquaryDeepItems.aetherglassLocket.rarity, Rarity.common);
    });

    test('the Draught is a lump, beltable, and worth less than it costs', () {
      final draught = ReliquaryDeepItems.censerDraught;
      expect(draught, isA<Beltable>(), reason: 'a Draught is drunk mid-duel');
      expect(draught.effect.heal, 295);
      expect(
        draught.effect.healPerTurn,
        0,
        reason: 'a Draught is never over-time — that is a Tonic (§3.3)',
      );
      expect(
        draught.value,
        lessThan(4 * ReliquaryDeepItems.censerResin.value),
        reason: 'buy→craft→vendor must not profit (§5.5)',
      );
    });

    test('every equipment piece salvages back into something real', () {
      for (final d in ReliquaryDeepItems.all.whereType<EquipmentDef>()) {
        expect(d.salvage, isNotEmpty, reason: '${d.id} salvages to nothing');
        for (final s in d.salvage) {
          expect(
            ItemCatalogue.tryById(s.defId),
            isNotNull,
            reason: '${d.id} salvages into "${s.defId}", which does not exist',
          );
        }
      }
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('⭐⭐ three nodes, one per material, and no hide anywhere', () {
      // §3.1: the only hybrid in either quarter whose three materials are all
      // gatherable. ⚠️ A fourth node, or a hide, breaks the zone's premise —
      // a corridor someone made, in a mountain, with no animals in it.
      expect(nodes, hasLength(3));
      expect(nodes.map((n) => n.id).toSet(), {
        'rd_censer_run',
        'rd_gilt_fitting',
        'rd_altar_linen',
      });
      expect(
        nodes.map((n) => n.yieldsDefId).toSet(),
        ReliquaryDeepItems.all
            .whereType<MaterialDef>()
            .map((m) => m.id)
            .toSet(),
        reason: 'a material this zone defines has no node, or vice versa',
      );
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} compiles but never spawns',
        );
      }
    });

    test('every node yields a real material THIS zone defines', () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(def, isA<MaterialDef>());
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields a non-stackable',
        );
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} harvests another zone\'s material',
        );
        expect(n.min, greaterThan(1));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('node skill follows the material\'s consuming skill (§6a.1)', () {
      // ⭐ Potions ← Foraging, Tailoring ← Foraging, Jewelry (gems) ← Mining.
      // A node that pays the wrong ledger row levels a skill the material
      // never feeds.
      expect(GatherNodes.rdCenserRun.skill, GatherSkill.foraging);
      expect(GatherNodes.rdGiltFitting.skill, GatherSkill.mining);
      expect(GatherNodes.rdAltarLinen.skill, GatherSkill.foraging);
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 111);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final colossus = ReliquaryDeepBestiary.reliquaryColossus;
      final juggernaut = ReliquaryDeepBestiary.whatWasConsecrated;
      expect(
        colossus.maxHpAt(52),
        (MageState.scaledMaxHp(52) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        colossus.maxHpAt(52),
        1626,
        reason: '§1.2\'s worked table, transcribed rather than invented',
      );
      expect(
        juggernaut.maxHpAt(52),
        (MageState.scaledMaxHp(52) * Archetypes.juggernaut.hpScale).round(),
      );
      expect(juggernaut.maxHpAt(52), 2660, reason: '§1.2\'s worked table');
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 52. Anything that can open with a kill from full
      // health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(52);
      expect(startingHp, 739, reason: '§1.2\'s worked table');
      for (final e in ReliquaryDeepBestiary.commons) {
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
      for (final def in ReliquaryDeepItems.all) {
        expect(
          def.lore.endsWith('.'),
          isTrue,
          reason: '${def.id} lore is not a sentence',
        );
        expect(
          RegExp(r'\d').hasMatch(def.lore),
          isFalse,
          reason: '${def.id} lore leaks a number instead of describing a thing',
        );
        expect(def.lore.length, greaterThan(40), reason: '${def.id} lore thin');
      }
    });
  });
}
