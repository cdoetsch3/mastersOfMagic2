/// The Sealed Garden's roster LAWS (Lv 49–53, Flora + Sanctus) and its
/// catalogue checks — ENEMIES §2e plus ETHEREAL_CONTRACT §4.4.
///
/// ⚠️ **`sanctus_*` and `climbers_ration` are owned by the parallel
/// Hallowmarch worktree.** Everything this zone DEFINES is asserted normally;
/// the cross-lane ids are asserted in one `skip:`ped test whose skip reason
/// names the dependency, so the merge coordinator has exactly one line to
/// delete once the lanes land together.
///
/// ⭐⭐ **`flora_*` is NOT cross-lane** — it is `whispering_woods_items.dart`,
/// the level 1–5 catalogue, and it resolves today. §7.3 calls it the deepest
/// cross-quarter mote reference in the game.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_sealed_garden.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_sealed_garden_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id the Garden itself authors — that is what
/// the "no local id hides in here" test below proves.
const _parallelLaneIds = <String>{
  'sanctus_dust',
  'sanctus_shard',
  'sanctus_crystal',
  'climbers_ration',
};

void main() {
  const zone = 'the_sealed_garden';
  final all = SealedGardenBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        SealedGardenBestiary.commons,
        hasLength(5),
        reason: 'ENEMIES §2e gives every zone exactly five wandering types',
      );
      expect(
        SealedGardenBestiary.minis,
        hasLength(4),
        reason: 'two drawn of four',
      );
      expect(
        SealedGardenBestiary.bosses,
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
        reason: 'SealedGardenBestiary is not listed in Bestiary.all',
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
      expect(SealedGardenBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so a run can draw a mirror');
    });

    test('the boss pair is the rule and the invitation, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e: the Guardian *"will not let you in"* (Juggernaut,
      // endurance — a wall does not need a plan); the Serpent *"would very
      // much like to"* (Tyrant, §2g's *the intelligence is the threat*).
      // ⚠️ Which one you draw decides whether the garden confronts you or
      // tempts you, so two of a kind would delete the zone's whole shape.
      expect(
        SealedGardenBestiary.guardianOfTheWorldTree.archetype.id,
        'juggernaut',
      );
      expect(
        SealedGardenBestiary.theSerpentInTheBranches.archetype.id,
        'tyrant',
      );
      expect(
        SealedGardenBestiary.bosses.map((b) => b.archetype.id).toSet(),
        hasLength(2),
        reason: 'the two bosses are the same archetype, so neither is a choice',
      );
      expect(
        SealedGardenBestiary.bosses.map((b) => b.archetype.id),
        isNot(contains('aspect')),
        reason:
            '§2g fields no Aspect here — ⭐ Sanctus never gets one anywhere '
            'in the game, and §2.4 says so in both directions',
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
      expect(SealedGardenBestiary.commons.map((e) => e.archetype.id).toList(), [
        'sentinel',
        'siphon',
        'blighter',
        'adept',
        'bruiser',
      ]);
      // ⭐⭐ §2f cut the Siphon from twelve of fifteen zones and KEPT it in
      // three. This is one of the three, and Windfall is the reason: *the
      // temptation, written as a stat block*. A mutant that "tidies" it into
      // a Skirmisher still compiles.
      expect(
        SealedGardenBestiary.windfall.archetype.id,
        'siphon',
        reason: '§2f keeps the Siphon in exactly three zones; this is one',
      );
    });

    test('ids and names are unique', () {
      expect(all.map((e) => e.id).toSet(), hasLength(all.length));
      expect(all.map((e) => e.name).toSet(), hasLength(all.length));
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

    test('the per-creature element assignment matches §2e exactly', () {
      // ⭐ Hard-coded rather than derived: §2h lets a hybrid assign one
      // element or both per creature, so there is no formula to check
      // against — only the table. ⭐ Sanctus is the rule, Flora is the garden
      // doing the asking, and that is what this map encodes.
      const flora = [MagicElement.flora];
      const sanctus = [MagicElement.sanctus];
      const both = [MagicElement.flora, MagicElement.sanctus];
      expect(SealedGardenBestiary.orchardWarden.elements, sanctus);
      expect(SealedGardenBestiary.windfall.elements, flora);
      expect(SealedGardenBestiary.whisperling.elements, flora);
      expect(SealedGardenBestiary.choristerVine.elements, both);
      expect(SealedGardenBestiary.thornpenitent.elements, both);
      expect(SealedGardenBestiary.theLastGardener.elements, both);
      expect(SealedGardenBestiary.rootMatriarch.elements, flora);
      expect(SealedGardenBestiary.theKeptVow.elements, sanctus);
      expect(SealedGardenBestiary.guardianOfTheWorldTree.elements, sanctus);
      expect(SealedGardenBestiary.theSerpentInTheBranches.elements, flora);
      // ⚠️ The Cherub is the exception and gets its own law below.
      expect(SealedGardenBestiary.cherubOfTheTurningBlade.elements, [
        MagicElement.sanctus,
        MagicElement.solar,
      ]);
    });

    test('⚠️ the zone carries exactly ONE off-element creature, and it is '
        'SOLAR rather than pyro', () {
      // §2e.2 names four creatures in fifteen zones. Here it is the Cherub,
      // with one solar move. ⚠️⚠️ **The pyro version of this creature is the
      // single most likely "fix" anyone will make to this file** — a flaming
      // sword is the obvious image — and it is exactly what §2h forbids,
      // because Pyro is Flora's own counter. Every clause is checked, because
      // each one alone still compiles.
      const zoneElements = {MagicElement.flora, MagicElement.sanctus};
      final offElement = all
          .where((e) => e.elements.any((el) => !zoneElements.contains(el)))
          .toList();

      expect(offElement.map((e) => e.id), [
        'cherub_of_the_turning_blade',
      ], reason: '§2e.2 licenses one off-element creature in this zone, named');
      expect(
        offElement.single.rank,
        isNot(EnemyRank.common),
        reason: 'minis and bosses only — a common is the fight you learn on',
      );
      expect(
        offElement.single.elements
            .where((el) => !zoneElements.contains(el))
            .toList(),
        [MagicElement.solar],
        reason: 'at most ONE off-element, and §2e.2 names solar',
      );
      // ⚠️⚠️ The row §2h says never to lose: a creature that carries the
      // thing which beats the player's correct counter-pick punishes
      // preparation, and players who are punished for preparing stop.
      final forbidden = {
        MagicElement.flora.counteredBy,
        MagicElement.sanctus.counteredBy,
      };
      // ⭐ Derived from the shipped wheel, not from memory: tier 1 runs
      // Pyro → Flora → Aqua and tier 4 runs Sanctus → Umbra → Arcane, so the
      // two things that beat this zone are **Pyro** (Flora's) and **Arcane**
      // (Sanctus's — NOT Umbra, which is what Sanctus beats).
      expect(forbidden, {
        MagicElement.pyro,
        MagicElement.arcane,
      }, reason: 'the counter wheel moved; re-derive §2e.2 before trusting it');
      expect(
        forbidden,
        isNot(contains(MagicElement.solar)),
        reason: 'solar would be this zone\'s own counter, which §2h forbids',
      );
      expect(
        offElement.single.elements,
        isNot(contains(MagicElement.pyro)),
        reason:
            '⚠️ pyro is FLORA\'S COUNTER — §2e.2 writes "NOT pyro" in bold '
            'for this exact creature',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2e: the anchor here is the SENTINEL, not the Adept — *rooted and
      // set to guard* is §2b's own definition of the archetype, and the
      // Orchard Warden is the creature it was written for.
      expect(
        SealedGardenBestiary.orchardWarden.archetype.id,
        'sentinel',
        reason: 'the anchor is the zone\'s premise standing in one place',
      );
    });

    test('the zone band is 49–53, a route, Flora + Sanctus', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 49);
      expect(loc.maxLevel, 53);
      expect(
        loc.kind,
        LocationKind.route,
        reason: 'no 🏰 in ENEMIES §2e — the Garden is a dead-end road',
      );
      // ⭐⭐ The game's FIRST element guarded by its LAST, in that order.
      expect(loc.elements, [MagicElement.flora, MagicElement.sanctus]);
    });

    test('🚫 nothing here uses the reserved word', () {
      // ⚠️ WORLD_DESIGN §4c.1a: "Bloom" is reserved and was renamed to
      // Photosynthesis project-wide. A flowering-garden zone is the single
      // most likely place for it to come back.
      for (final e in all) {
        expect(
          e.name.toLowerCase(),
          isNot(contains('bloom')),
          reason: '${e.id} uses the reserved word',
        );
        for (final m in e.moves) {
          expect(
            m.name.toLowerCase(),
            isNot(contains('bloom')),
            reason: '${e.id}\'s "${m.name}" uses the reserved word',
          );
          expect(m.id, isNot(contains('bloom')));
        }
      }
    });
  });

  group('combat stats match ETHEREAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        SealedGardenBestiary.choristerVine.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel deflects', () {
      expect(
        SealedGardenBestiary.orchardWarden.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('⭐ the Siphon connects and survives, and never crits', () {
      // ⚠️ §2.3's own note: a lifesteal crit heals it for the crit too, and a
      // 0.95-HP body that can double-heal off one roll is the stalemate
      // ENEMIES §2.2 already fears.
      expect(
        SealedGardenBestiary.windfall.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, dodge: 6),
      );
      expect(
        SealedGardenBestiary.windfall.combatStats.critChance,
        0,
        reason: 'a crit on a lifesteal body is the stalemate, not a spike',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        SealedGardenBestiary.whisperling.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
      );
    });

    test('the Bruiser is slow, telegraphed and heavy', () {
      expect(
        SealedGardenBestiary.thornpenitent.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        SealedGardenBestiary.theLastGardener.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      // 📝 §2.3 recommends dropping the Redoubt's 35 to ~25 in **The Buried
      // Sky and The Reliquary Deep** — 2.20 bodies inside DUNGEONS a player
      // cannot retreat from. The Sealed Garden is a route, so the row stands.
      expect(
        SealedGardenBestiary.rootMatriarch.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        SealedGardenBestiary.cherubOfTheTurningBlade.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        SealedGardenBestiary.theKeptVow.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut deflects a lot off a very large body', () {
      expect(
        SealedGardenBestiary.guardianOfTheWorldTree.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('the Tyrant carries a little of everything', () {
      expect(
        SealedGardenBestiary.theSerpentInTheBranches.combatStats,
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

    test('move ids are unique across the WHOLE bestiary, and all sg_', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (§3.5/§7.2). Checked game-wide, not zone-locally, because a
      // collision with a shipped zone is the failure that actually happens.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('sg_'), isTrue, reason: '$id is not zone-tagged');
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
        reason: 'a sg_ move id collides with another zone\'s',
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
            reason: '"${m.name}" is a player spell\'s name',
          );
        }
      }
    });

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. ⚠️ No mage exemption applies in this zone: the Garden
      // fields no mage boss, and the two it does field are a wall and a
      // serpent.
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
      // by level, so a 49–53 band arrives via the ENCOUNTER LEVEL, never
      // bigger raws. §1.3's table is byte-for-byte KINETIC's and does not
      // grow — which a builder authoring a level-53 boss will want to doubt
      // more than anywhere else in the game.
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

    test('⚠️ the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️⚠️ **ENEMIES §2e's kit sketch writes "Come Down Once (5 …)" and
      // this lane did NOT take it.** §1.3 carries the standing ruling with
      // the arithmetic: at L53 a mini five-charge raw (46–60) lands 672–876
      // against a 769 HP bar — a one-shot, not the two-cast kill the
      // archetype exists for. At cost 4 it lands 380–497. The contract owns
      // the damage table (§0.1) and all six shipped Celestial Executioners
      // are already 3/4. This test is the thing that stops the sketch coming
      // back.
      final cherub = SealedGardenBestiary.cherubOfTheTurningBlade;
      expect(cherub.archetype.id, 'executioner');
      for (final m in cherub.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
    });

    test('⭐ the Siphon has no safe chip — BOTH its moves heal it', () {
      // §2e: *"chip damage never accumulates; commit to burst."* A Siphon
      // with one honest attack is a Skirmisher with extra steps.
      final windfall = SealedGardenBestiary.windfall;
      for (final m in windfall.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).lifesteal,
          greaterThan(0),
          reason: '${windfall.id}\'s "${m.name}" gives the player a free trade',
        );
      }
    });

    test('⭐ the Blighter lands ONE status at two price points', () {
      // ⚠️ `bank_dots.dart` law 5: two spells granting the same dotId are two
      // price points on ONE status, so the second REPLACES the first. A
      // Suggestion is one idea getting louder, never two ideas at once — and
      // a mutant that gives the moves separate ids turns the common into a
      // stacking-DoT problem at level 49.
      final w = SealedGardenBestiary.whisperling;
      final dots = w.moves.map((m) => m.effect).whereType<DotAttackEffect>();
      expect(dots, hasLength(2), reason: 'a Blighter that does not blight');
      expect(dots.map((d) => d.dotId).toSet(), {
        'sg_suggestion',
      }, reason: 'two dotIds means two Suggestions running at once');
      expect(dots.map((d) => d.damagePerTick).toList(), [
        4,
        5,
      ], reason: 'the dear price point must actually be worth paying');
      expect(dots.map((d) => d.ticks).toList(), [3, 5]);
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

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final vow = SealedGardenBestiary.theKeptVow;
      expect(vow.archetype.id, 'hexer');
      expect(
        vow.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        vow.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: '⭐ a vow that a wall can stop is not a vow that does not lapse',
      );
    });

    test('⭐⭐ the tempter takes your CHARGE, not your health', () {
      // §2e: *"`DischargeEffect` is the mechanical form of «you were saving
      // that for something»."* ⚠️ The first creature move in the game to use
      // it, and the whole reason the Serpent reads differently from the
      // Guardian. A mutant that swaps it for a third attack makes the two
      // bosses the same fight at different sizes.
      final serpent = SealedGardenBestiary.theSerpentInTheBranches;
      final taker = serpent.moves.singleWhere(
        (m) => m.effect is DischargeEffect,
        orElse: () => throw StateError('no Discharge on the tempter'),
      );
      expect(taker.name, 'Name What You Want');
      expect(
        taker.priority,
        SpellPriority.auxOffense,
        reason:
            'aux-offense is where Discharge sits in the player\'s own book; '
            'the creature plays by the same ladder',
      );
      expect(
        taker.isHarmful,
        isTrue,
        reason: 'Blind and Stagger must both see it as an attack',
      );
      expect(
        taker.isOffensive,
        isFalse,
        reason: 'it deals no damage — that is the entire point of it',
      );
    });

    test('⭐ the Guardian is a wall with no plan, and says so', () {
      // §2e: *"Endurance — a wall does not need a plan."* Its dear move is
      // the theme written as a move, and it is the top of the boss band.
      final guardian = SealedGardenBestiary.guardianOfTheWorldTree;
      final dearest = guardian.moves.reduce(
        (a, b) => a.chargeCost >= b.chargeCost ? a : b,
      );
      expect(dearest.name, 'You Are Not Allowed In');
      expect(dearest.chargeCost, 5);
      expect(
        guardian.moves.any(
          (m) =>
              m.effect is DamageEffect && (m.effect as DamageEffect).hits > 1,
        ),
        isFalse,
        reason: 'a Juggernaut arrives in one piece; that is what it is for',
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
          reason: '$id is named by §4.4\'s tables and must exist',
        );
      }
    });

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the skip above would be hiding a real local failure.
      final mine = SealedGardenItems.all.map((d) => d.id).toSet();
      expect(
        mine.intersection(_parallelLaneIds),
        isEmpty,
        reason: 'the exemption list is excusing an id this lane owns',
      );
    });

    test('⭐⭐ flora_* is NOT cross-lane — it resolves to level 1–5 today', () {
      // §7.3's starred row: the deepest cross-quarter mote reference in the
      // game, and the drop table saying out loud what the zone is for. ⚠️ A
      // builder will assume it is a mistake and "fix" it into a new family.
      for (final id in ['flora_dust', 'flora_shard', 'flora_crystal']) {
        expect(
          ItemCatalogue.zoneOf(id),
          'whispering_woods',
          reason: '$id moved out of the zone that first yields it',
        );
        expect(SealedGardenBestiary.allDrops, contains(id));
      }
      expect(
        SealedGardenItems.all.whereType<MoteDef>(),
        isEmpty,
        reason:
            'this zone defines no mote family — both of its ladders are '
            'somebody else\'s, which is the point',
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
      for (final e in SealedGardenBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...SealedGardenBestiary.minis,
        ...SealedGardenBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in SealedGardenBestiary.commons) {
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
      final dropped = SealedGardenBestiary.allDrops;
      for (final id in [
        'flora_dust',
        'flora_shard',
        'flora_crystal',
        'sanctus_dust',
        'sanctus_shard',
        'sanctus_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ Nothing from a third element — the off-element move is a MOVE, and
      // §2e.2 buys no third mote family with it. ⭐ In particular there is no
      // `solar_*` here, although the Cherub is half solar.
      final foreign = <String>{
        for (final el in MagicElement.values)
          if (el != MagicElement.flora && el != MagicElement.sanctus) ...[
            '${el.name}_dust',
            '${el.name}_shard',
            '${el.name}_crystal',
          ],
      };
      for (final id in dropped) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in SealedGardenBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in SealedGardenBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️⚠️ no boss carries a gate part — this is NOT a gate zone', () {
      // §2e.1 puts `key` on both bosses of a gate zone, and §3.5's
      // reconciliation put the three Thirds in the quarter's three PURE
      // zones: Hallowmarch, The Umbral Wastes, The Collapsed Academy.
      // ⚠️ §4.4's own drop block still lists `the_kept_third` on the boss
      // `always` line, so the most likely mutation here is a builder
      // faithfully transcribing the older half of the contract.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            id,
            isNot('the_kept_third'),
            reason: '${e.id} drops the gate fragment §3.5 moved to Hallowmarch',
          );
          expect(
            id,
            isNot(contains('_third')),
            reason: '${e.id} drops something that reads like a gate part',
          );
        }
      }
      expect(
        SealedGardenItems.all.whereType<KeyDef>(),
        isEmpty,
        reason: 'the Garden defines no key either — §3.5, not §4.4\'s table',
      );
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in SealedGardenBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_gardeners_loop'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_gardeners_loop'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('the_gardeners_loop').rarity, Rarity.rare);
    });

    test('the epic is boss-only, and both bosses can pay it', () {
      final epics = SealedGardenItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(epics, [
        'the_season_at_once',
      ], reason: '§4.4 authors exactly one epic');
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
        }
      }
      // ⭐ A run draws ONE boss of two, so splitting the two uniques between
      // them would make which epic exists a coin flip (§2e.1's own argument
      // about keys, applied to uniques).
      for (final b in SealedGardenBestiary.bosses) {
        expect(b.drops.possibleDrops, contains('the_season_at_once'));
        expect(b.drops.possibleDrops, contains('the_gardeners_loop'));
      }
    });

    test('⭐ the Siphon\'s own row is the one that pays the Tonic', () {
      // §4.4's third common row. ⚠️ Unlike the Glass Archive, this zone
      // really does field a Siphon, so the row lands on the creature the
      // contract named rather than by element.
      expect(
        SealedGardenBestiary.windfall.drops.possibleDrops,
        contains('worldroot_tonic'),
      );
      for (final e in all) {
        if (identical(e, SealedGardenBestiary.windfall)) continue;
        expect(
          e.drops.possibleDrops,
          isNot(contains('worldroot_tonic')),
          reason: '${e.id} also pays the Tonic, so the Siphon row is not one',
        );
      }
    });
  });

  group('the catalogue matches §4.4', () {
    test('9 defs, all resolvable under this zone', () {
      // ⚠️ §7.1's per-zone tally says TEN, and it is stale: §3.5's
      // reconciliation moved `the_kept_third` to Hallowmarch and §4.4's own
      // table strikes it through. 3 materials + 1 consumable + 5 equipment.
      expect(SealedGardenItems.all, hasLength(9), reason: '§4.4 minus the key');
      for (final def in SealedGardenItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
      expect(
        SealedGardenItems.all.whereType<MaterialDef>(),
        hasLength(3),
        reason: '§3.1: 3 materials per hybrid, and this one has a hide',
      );
    });

    test('the three materials carry §3.1\'s skills, tiers and values', () {
      expect(SealedGardenItems.worldroot.skill, CraftSkill.potionsAndAlchemy);
      expect(SealedGardenItems.orchardAmber.skill, CraftSkill.jewelry);
      expect(SealedGardenItems.thornpenitentHide.skill, CraftSkill.tailoring);
      for (final m in SealedGardenItems.all.whereType<MaterialDef>()) {
        expect(m.tier, 9, reason: '${m.id} is off §3.1\'s tier-9 row');
      }
      expect(SealedGardenItems.worldroot.value, 55);
      expect(SealedGardenItems.orchardAmber.value, 260);
      expect(SealedGardenItems.thornpenitentHide.value, 950);
      // ⚠️ Uncommon is the gem grade and survives nowhere else in this
      // quarter outside Crystal motes.
      expect(SealedGardenItems.orchardAmber.rarity, Rarity.uncommon);
      expect(SealedGardenItems.worldroot.rarity, Rarity.common);
    });

    test(
      'equip levels sit in the band, with §4.4\'s one documented exception',
      () {
        final loc = World.byId(zone);
        for (final def in SealedGardenItems.all) {
          if (def is EquipmentDef) {
            // ⚠️⚠️ `orchard_loop` equips at 54, one ABOVE the band's 53, and
            // it is the contract's own number. It is a **Jewelry craft**,
            // not a drop, and §5.3's jewelry ladder sets its level rather
            // than the zone does — the same licence §4.2 takes in the other
            // direction for `everice_band` at 45, one BELOW its band. The
            // exception is named here so the next one has to be argued for.
            if (def.id == 'orchard_loop') {
              expect(
                def.equipLevel,
                54,
                reason: '§4.4\'s table says 54; moving it needs a ruling',
              );
              continue;
            }
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
                  '${def.id} is a mote, material or consumable and must be '
                  'usable the moment it drops',
            );
          }
        }
        // §4.4's table, transcribed rather than derived.
        expect(SealedGardenItems.penitentBelt.equipLevel, 52);
        expect(SealedGardenItems.eclipseSignet.equipLevel, 50);
        expect(SealedGardenItems.theGardenersLoop.equipLevel, 51);
        expect(SealedGardenItems.theSeasonAtOnce.equipLevel, 53);
      },
    );

    test('crafted gear composes its name; the two uniques are written', () {
      // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
      // material+form grammar composes the name and cannot drift from it.
      for (final def in [
        SealedGardenItems.penitentBelt,
        SealedGardenItems.eclipseSignet,
        SealedGardenItems.orchardLoop,
      ]) {
        expect(
          def.properName,
          isNull,
          reason: '${def.id} is crafted; a written name reintroduces the drift',
        );
      }
      expect(
        SealedGardenItems.theGardenersLoop.properName,
        "The Gardener's Loop",
      );
      expect(
        SealedGardenItems.theSeasonAtOnce.properName,
        'The Season At Once',
      );
    });

    test('⭐ the belt ladder reaches EIGHT, and carries nothing else', () {
      // §5.3: … Corebiter 7 → Penitent 8. ⚠️ Capacity is the one axis that is
      // deliberately not combat power (ITEMS §6b.2), so a belt with a stat on
      // it breaks the whole argument for the slot.
      final belt = SealedGardenItems.penitentBelt;
      expect(belt.modifiers.beltSlots, 8);
      expect(
        belt.modifiers,
        const ItemModifiers(beltSlots: 8),
        reason: 'the belt has picked up a combat stat',
      );
      expect(belt.slot, EquipSlot.belt);
    });

    test('⭐⭐ the two Loops are the same slot and the same form', () {
      // §4.4: the player chooses between +15%/1% with 25 HP and +18%/2% with
      // 25 HP — a 3-point and 1-point step for a whole rarity tier, which is
      // ITEMS §9b.6a's "Rare ≈ Master, Epic marginally stronger" read
      // literally. 📝 If a Rare should feel bigger, widen it there, not here.
      final common = SealedGardenItems.orchardLoop;
      final rare = SealedGardenItems.theGardenersLoop;
      expect(common.slot, EquipSlot.ring);
      expect(rare.slot, common.slot);
      expect(rare.form, common.form);
      expect(rare.material, common.material);
      expect(rare.modifiers.maxHpBonus, common.modifiers.maxHpBonus);
      expect(
        rare.modifiers.healingReceivedPercent -
            common.modifiers.healingReceivedPercent,
        3,
      );
      expect(rare.modifiers.regrowPercent - common.modifiers.regrowPercent, 1);
    });

    test('⚠️⚠️ this zone triples the game\'s regrowPercent sources', () {
      // §4.4: the shipped game had exactly ONE — The Charlock, at 2 — and
      // this file adds three. 📝 `regrowPercent: 3` on a 1,264 HP bar is 38
      // HP a turn, every turn, forever: the single most tunable number in
      // either contract. ⚠️ ITEMS §4.2 needs it routed through `TurnStatus`.
      final sources = ItemCatalogue.all
          .whereType<EquipmentDef>()
          .where((d) => d.modifiers.regrowPercent > 0)
          .map((d) => d.id)
          .toSet();
      expect(sources, {
        'the_charlock',
        'orchard_loop',
        'the_gardeners_loop',
        'the_season_at_once',
      }, reason: 'a fifth regrow source landed without anyone arguing for it');
      expect(
        SealedGardenItems.theSeasonAtOnce.modifiers.regrowPercent,
        3,
        reason: 'the largest regrow in the game, and it is the tuning knob',
      );
    });

    test('⭐ both of this zone\'s drops carry healing — §2.5a\'s proof', () {
      // ⚠️ "This zone is the proof of the §2.5a affinity structure." Flora's
      // lean is healing and Sanctus's is healing plus shields, and the two
      // uniques carry healing at once. If the structure is rejected, THIS is
      // the file that gets rewritten and nothing else does.
      for (final def in [
        SealedGardenItems.theGardenersLoop,
        SealedGardenItems.theSeasonAtOnce,
      ]) {
        expect(
          def.modifiers.healingReceivedPercent,
          greaterThan(0),
          reason: '${def.id} is a Flora+Sanctus drop that heals nothing',
        );
      }
    });

    test('the Tonic is over-time, beltable, and the ladder\'s last', () {
      final tonic = SealedGardenItems.worldrootTonic;
      expect(tonic, isA<Beltable>(), reason: 'a Tonic is drunk mid-duel');
      expect(tonic.effect.healPerTurn, 53);
      expect(tonic.effect.healTurns, 3);
      expect(
        tonic.effect.heal,
        0,
        reason: 'a Tonic is never a lump — that is what a Draught is (§3.3)',
      );
      expect(
        tonic.effect.healFor(),
        159,
        reason:
            '§3.3: 24.2% of a level-49 bar, and the whole course at once '
            'out of combat',
      );
      expect(tonic.value, 165, reason: '§3.3/§4.4\'s number, verbatim');
    });

    test('⚠️ thornpenitent_hide is a hide, so no node may ever yield it', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('thornpenitent_hide')),
        reason:
            '§3.1 names it kill-only; a node for a hide is a second source '
            'that contradicts its own fiction',
      );
      // ⭐ It is the zone's `hide` drop role, and §3.5.1's second-material
      // fallback therefore does NOT apply here.
      for (final e in [
        SealedGardenBestiary.whisperling,
        SealedGardenBestiary.thornpenitent,
      ]) {
        expect(e.drops.possibleDrops, contains('thornpenitent_hide'));
      }
    });

    test('⚠️ no set, no socket, no gem — the Phase 8 guard', () {
      // §3.6: ITEMS §3.4 puts set Tier III at L45 and Tier IV at L50, both
      // inside this band, so every piece here is a deliberate plain Common
      // that Phase 8 can add sets BESIDE rather than instead of.
      for (final def in SealedGardenItems.all.whereType<EquipmentDef>()) {
        expect(def.setId, isNull, reason: '${def.id} joined a set early');
        expect(def.setTier, isNull);
        expect(def.socketCount, 0, reason: '${def.id} has no wood in it');
        expect(
          def.rarity,
          isNot(Rarity.uncommon),
          reason: '${def.id} — no EquipmentDef in the game is Uncommon',
        );
      }
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('three nodes — and two of them are on the same material', () {
      // ⚠️ §6's throughput exception: worldroot feeds four or more recipes and
      // one node per run section cannot keep a level-50 crafter supplied. ⭐ A
      // second node is a throughput fix, not a second source — both yield the
      // same id, so the fiction rule is untouched.
      expect(nodes, hasLength(3));
      expect(nodes.map((n) => n.id).toSet(), {
        'sg_worldroot_undercut',
        'sg_amber_bough',
        'sg_wallside_root',
      });
      expect(
        nodes.where((n) => n.yieldsDefId == 'worldroot'),
        hasLength(2),
        reason: 'the second root node is the documented throughput fix',
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
      // ⭐ Potions ← Foraging, Jewelry (gems) ← Mining. A node that pays the
      // wrong ledger row levels a skill the material never feeds.
      expect(GatherNodes.sgWorldrootUndercut.skill, GatherSkill.foraging);
      expect(GatherNodes.sgWallsideRoot.skill, GatherSkill.foraging);
      expect(GatherNodes.sgAmberBough.skill, GatherSkill.mining);
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 105);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final matriarch = SealedGardenBestiary.rootMatriarch;
      final guardian = SealedGardenBestiary.guardianOfTheWorldTree;
      expect(
        matriarch.maxHpAt(53),
        (MageState.scaledMaxHp(53) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        guardian.maxHpAt(53),
        (MageState.scaledMaxHp(53) * Archetypes.juggernaut.hpScale).round(),
      );
      // ⭐ §1.2's worked table: the Juggernaut is the largest body in the game
      // and it is worth seeing the number written down.
      expect(
        guardian.maxHpAt(53),
        greaterThan(2000),
        reason:
            'the 2.80 scale (✅ 2026-09-25, was 3.60 and > 2500): 769 × 2.80 '
            '= 2153 — still above a 2.60 Tyrant\'s 1999 at the same level',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 49. Anything that can open with a kill from full
      // health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(49);
      for (final e in SealedGardenBestiary.commons) {
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
      for (final def in SealedGardenItems.all) {
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
