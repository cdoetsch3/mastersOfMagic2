/// Hallowmarch's roster LAWS (Lv 45–49, Sanctus) and its catalogue checks —
/// ENEMIES §2e plus ETHEREAL_CONTRACT §4.1.
///
/// ⭐ **Mutation-verified**: every `expect` carries a `reason:` naming the
/// wrong implementation it kills. Introduce the bug, watch this test fail,
/// per `testing-conventions.md`.
///
/// ⚠️ **`deepstratum_ore` is owned by a parallel Ethereal worktree** (The
/// Buried Sky). Hallowmarch's third gather node is the game's only cross-zone
/// node and names it; everything this zone DEFINES is asserted normally, and
/// the cross-lane id is asserted in one `skip:`ped test whose skip reason
/// names the dependency, so the merge coordinator has exactly one line to
/// delete once the lanes land together.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/hallowmarch.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/hallowmarch_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id Hallowmarch itself authors — that is what
/// the "no local id hides in here" test below proves.
///
/// ⭐ Exactly one entry, and §7.3 is the reason: Hallowmarch's drop tables are
/// *"all local"*. The single outside reference is the cross-zone gather node.
const _parallelLaneIds = <String>{'deepstratum_ore'};

/// ⭐ The id a creature's name must produce. ⚠️ **The possessive apostrophe is
/// DROPPED, not turned into `_s_`** — the shipped catalogue is unanimous
/// (`pilgrims_ration`, `climbers_ration`, `the_gardeners_loop`), and
/// `pilgrim_s_remnant` would be a permanent asset filename that reads as a
/// typo. This is the first creature in the game whose name has an apostrophe.
String _idFor(String name) => name
    .toLowerCase()
    .replaceAll("'", '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_');

void main() {
  const zone = 'hallowmarch';
  final all = HallowmarchBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        HallowmarchBestiary.commons,
        hasLength(5),
        reason: 'ENEMIES §2e gives every zone exactly five wandering types',
      );
      expect(
        HallowmarchBestiary.minis,
        hasLength(4),
        reason: 'two drawn of four',
      );
      expect(
        HallowmarchBestiary.bosses,
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
        reason: 'HallowmarchBestiary is not listed in Bestiary.all',
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
      expect(HallowmarchBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so a run can draw a mirror');
    });

    test('the boss pair is a force and a will, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e: The Keeper of the Road is *who still does it*
      // (Juggernaut); The Hierophant Eternal is *who ordered it* (Tyrant).
      expect(HallowmarchBestiary.theKeeperOfTheRoad.archetype.id, 'juggernaut');
      expect(HallowmarchBestiary.theHierophantEternal.archetype.id, 'tyrant');
      expect(
        HallowmarchBestiary.bosses.map((b) => b.archetype.id).toSet(),
        hasLength(2),
        reason: 'the two bosses are the same archetype, which is a mirror',
      );
      // ⚠️ **Sanctus never gets an Aspect anywhere in the game** (§2.4,
      // ENEMIES §2g) — the one fact about this zone most likely to be
      // "fixed" by a later builder reaching for the quarter's default pair.
      expect(
        HallowmarchBestiary.bosses.map((b) => b.archetype.id),
        isNot(contains('aspect')),
        reason:
            'Sanctus fields no Aspect anywhere; §2.4 records that as the '
            'ruling, not an omission',
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
      expect(HallowmarchBestiary.commons.map((e) => e.archetype.id).toList(), [
        'sentinel',
        'adept',
        'lasher',
        'glasswing',
        'bruiser',
      ]);
    });

    test('⚠️ Pilgrim\'s Remnant is a Bruiser — the Drudge was CUT (§2f)', () {
      // §2f called a 0.80/0.70 body at level 47 "the clearest waste in the
      // audit". ⚠️ ETHEREAL §1.2 still warns about "a Drudge at 45–54" and
      // §4.1's drop table still calls this row "the Drudge", because the two
      // docs were written in parallel; §0.1/§0.3 give the ROSTER the creature.
      // A mutant that reverts the archetype still compiles and still reads
      // reasonably.
      expect(
        HallowmarchBestiary.pilgrimsRemnant.archetype.id,
        'bruiser',
        reason: '§2f re-assigned this slot; a Drudge here teaches nothing',
      );
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('drudge')),
        reason: 'no Drudge survives anywhere in this roster',
      );
      // ⭐ But the contract's drop row DOES survive the change: §1.2 —
      // "the drop tables put the zone's consumable on the Drudge, so a slot
      // that teaches nothing at least pays something."
      expect(
        HallowmarchBestiary.pilgrimsRemnant.drops.mainChanceOf(
          'climbers_ration',
        ),
        0.15,
        reason: 'the Drudge row\'s 15% Ration did not come along with it',
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
        expect(
          e.id,
          _idFor(e.name),
          reason: '${e.name} should be id "${_idFor(e.name)}"',
        );
      }
      // ⭐ The apostrophe case, pinned by hand so the helper above cannot be
      // quietly relaxed into agreeing with whatever the id happens to be.
      expect(
        HallowmarchBestiary.pilgrimsRemnant.id,
        'pilgrims_remnant',
        reason: 'the possessive is dropped, never rendered as "_s_"',
      );
      expect(HallowmarchBestiary.pilgrimsRemnant.name, "Pilgrim's Remnant");
    });

    test('the per-creature element assignment matches §2e exactly', () {
      // ⭐ Hard-coded rather than derived: §2h lets a zone assign elements per
      // creature, so there is no formula to check against — only the table.
      // ⚠️ Hallowmarch is PURE, so the table is eleven identical rows, and
      // that uniformity is itself the fact worth pinning.
      const sanctus = [MagicElement.sanctus];
      expect(HallowmarchBestiary.causewayWarden.elements, sanctus);
      expect(HallowmarchBestiary.markerSworn.elements, sanctus);
      expect(HallowmarchBestiary.meltwaterChoir.elements, sanctus);
      expect(HallowmarchBestiary.votive.elements, sanctus);
      expect(HallowmarchBestiary.pilgrimsRemnant.elements, sanctus);
      expect(HallowmarchBestiary.milestone.elements, sanctus);
      expect(HallowmarchBestiary.vestalWarden.elements, sanctus);
      expect(HallowmarchBestiary.seraphJudicant.elements, sanctus);
      expect(HallowmarchBestiary.theUpkeep.elements, sanctus);
      expect(HallowmarchBestiary.theKeeperOfTheRoad.elements, sanctus);
      expect(HallowmarchBestiary.theHierophantEternal.elements, sanctus);
    });

    test('⚠️ the zone carries NO off-element creature at all', () {
      // §2e.2 names exactly four creatures in fifteen zones — The Long Count,
      // Burnt Index, the Cherub of the Turning Blade and The Fourth Item —
      // and none of them is here. ⭐ An off-element move added to this zone
      // would be a rule change, not a flourish, so the law is written as a
      // zero rather than as a count.
      for (final e in all) {
        expect(e.elements, [
          MagicElement.sanctus,
        ], reason: '${e.id} carries an element §2e.2 does not license here');
      }
      // ⚠️⚠️ The row §2h says never to lose, stated even though this zone
      // spends no off-element: a creature carrying the player's correct
      // counter-pick punishes preparation.
      //
      // ⚠️ **Sanctus is countered by ARCANE, not by Umbra.** The tier-4
      // triangle is Sanctus → Umbra → Arcane → Sanctus, and `A → B` reads
      // *"A counters B"* — so the element Sanctus beats is Umbra and the one
      // that beats Sanctus is Arcane. §3.4's own note ("dark given a shape")
      // makes Umbra the easy wrong answer here, and the two ETHEREAL zones
      // either side of this one field exactly those two elements.
      expect(
        MagicElement.sanctus.counteredBy,
        MagicElement.arcane,
        reason: 'the counter wheel moved; re-derive §2e.2 before trusting it',
      );
      for (final e in all) {
        expect(
          e.elements,
          isNot(contains(MagicElement.arcane)),
          reason: '${e.id} carries this zone\'s own counter, which §2h forbids',
        );
      }
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2e: "a warden on a road **is** a barrier" — the anchor is one of
      // the seven Sentinels the §2f audit KEPT, and the noun and the
      // archetype are the same statement.
      expect(
        HallowmarchBestiary.causewayWarden.archetype.id,
        'sentinel',
        reason: 'the anchor is the zone\'s barrier, which means the Sentinel',
      );
    });

    test('the zone band is 45–49, a route, pure Sanctus', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 45);
      expect(loc.maxLevel, 49);
      expect(
        loc.kind,
        LocationKind.route,
        reason: 'no 🏰 in ENEMIES §2e — Hallowmarch is a road, not a dungeon',
      );
      expect(loc.elements, [MagicElement.sanctus]);
      expect(
        loc.tier,
        MagicTier.ethereal,
        reason: 'Sanctus is a tier-4 element (§3.2)',
      );
    });
  });

  group('combat stats match §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        HallowmarchBestiary.markerSworn.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel deflects', () {
      expect(
        HallowmarchBestiary.causewayWarden.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('the Lasher trades crit damage for crit frequency', () {
      expect(
        HallowmarchBestiary.meltwaterChoir.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        HallowmarchBestiary.votive.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Bruiser is inaccurate and hits hard when it lands', () {
      expect(
        HallowmarchBestiary.pilgrimsRemnant.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
        reason:
            'the −8 is the archetype\'s own row; a Drudge\'s −10 would be the '
            'pre-§2f block coming back with the archetype',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        HallowmarchBestiary.milestone.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        HallowmarchBestiary.vestalWarden.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason:
            '§2.3 recommends 25 for the two DUNGEON Redoubts only; '
            'Hallowmarch is a route and keeps the archetype row',
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        HallowmarchBestiary.seraphJudicant.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        HallowmarchBestiary.theUpkeep.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut deflects a great deal at a time', () {
      expect(
        HallowmarchBestiary.theKeeperOfTheRoad.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('the Tyrant carries a little of everything', () {
      expect(
        HallowmarchBestiary.theHierophantEternal.combatStats,
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

    test('move ids are unique across the WHOLE bestiary, and all hm_', () {
      // ⚠️ The prefix is what keeps the game's zones' move ids from colliding
      // (§3.5/§7.2). Checked game-wide, not zone-locally, because a collision
      // with a shipped zone is the failure that actually happens.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('hm_'), isTrue, reason: '$id is not zone-tagged');
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
        reason: 'an hm_ move id collides with another zone\'s',
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
      // exemption applies in this zone: Hallowmarch fields no mage boss, and
      // the two that exist are the Archmage and Procarius.
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
      // by level, so a 45–49 band arrives via the ENCOUNTER LEVEL, never
      // bigger raws. §1.3's table is byte-for-byte KINETIC's and CELESTIAL's
      // and does not grow — which a builder authoring a level-49 boss will
      // want to doubt harder here than anywhere before it.
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

    test('the Lasher is multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule, and it is the whole of what makes a
      // Lasher read differently from a plain attacker: each voice meets the
      // wall on its own, which is why a big shield is not the answer.
      for (final m in HallowmarchBestiary.meltwaterChoir.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '"${m.name}" arrives in one piece',
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
      final wall = HallowmarchBestiary.vestalWarden.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(SpellPriority.shield),
        reason: 'a watch that is tended after you shield is tended too late',
      );
    });

    test('⭐ the Redoubt heals with the lever the engine has', () {
      // 📝 There is no creature heal effect, so attrition is written as
      // lifesteal. Without it a 2.20-HP wall is only a long fight.
      final drink = HallowmarchBestiary.vestalWarden.moves
          .map((m) => m.effect)
          .whereType<DamageEffect>()
          .where((d) => d.lifesteal > 0);
      expect(
        drink,
        hasLength(1),
        reason: 'the Redoubt has no way to undo the damage it takes',
      );
      expect(drink.single.lifesteal, 0.4);
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
      final upkeep = HallowmarchBestiary.theUpkeep;
      expect(upkeep.archetype.id, 'hexer');
      expect(
        upkeep.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        upkeep.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️ §1.3 — at L49 a mini five-charge raw lands past the whole player
      // bar: not a two-cast kill, a one-shot. Kills a mutant that restores
      // the archetype's own maxMoveCost of 5.
      final judicant = HallowmarchBestiary.seraphJudicant;
      expect(judicant.archetype.id, 'executioner');
      for (final m in judicant.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
      // ⭐ The archetype's lesson written into the EFFECT rather than into a
      // bigger number — it finishes what is already finished.
      expect(
        judicant.moves
            .map((m) => m.effect)
            .whereType<DamageEffect>()
            .any((d) => d.executeBelowPercent > 0),
        isTrue,
        reason: 'the Executioner cannot execute',
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
    test('every drop id resolves against the catalogue', () {
      // ⭐ §7.3: Hallowmarch is "all local" — no entry in this loop is ever
      // excused, which is why there is no cross-lane skip here.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
      expect(
        HallowmarchBestiary.allDrops.intersection(_parallelLaneIds),
        isEmpty,
        reason:
            'a drop table reached outside the zone; §7.3 says every '
            'Hallowmarch drop id is local',
      );
    });

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the node skip below would be hiding a real local failure.
      final mine = HallowmarchItems.all.map((d) => d.id).toSet();
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
          100,
          reason:
              '${e.id}\'s main weights do not sum to 100, so §4.1\'s '
              'percentages are no longer percentages',
        );
      }
    });

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in HallowmarchBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...HallowmarchBestiary.minis,
        ...HallowmarchBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in HallowmarchBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          final def = ItemCatalogue.byId(id);
          expect(
            def.rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ the pure zone pays ONE mote ladder, at the full rate', () {
      // ⚠️ A hybrid is what pays two families at half chance each; copying
      // the Frostfell `_commonAlways` here would halve the zone's whole mote
      // income with nothing else failing to say so.
      for (final e in HallowmarchBestiary.commons) {
        final dust = e.drops.always.where((d) => d.defId == 'sanctus_dust');
        expect(
          dust,
          hasLength(1),
          reason: '${e.id} does not pay the zone\'s dust exactly once',
        );
        expect(
          dust.single.chance,
          0.75,
          reason: '${e.id} pays a hybrid\'s halved dust rate',
        );
      }
      final dropped = HallowmarchBestiary.allDrops;
      for (final id in ['sanctus_dust', 'sanctus_shard', 'sanctus_crystal']) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ Nothing from a second element — a pure zone buys no other family.
      final foreign = <String>{
        for (final el in MagicElement.values)
          if (el != MagicElement.sanctus) ...[
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
      for (final e in HallowmarchBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final e in HallowmarchBestiary.minis) {
        final crystal = e.drops.always.singleWhere(
          (d) => d.defId == 'sanctus_crystal',
        );
        expect(
          crystal.chance,
          0.15,
          reason:
              '${e.id}\'s Crystal is not 15% — the 2026-09-30 lean took it '
              'from 0.25 to 0.15; kills a zone the lean missed',
        );
      }
      for (final b in HallowmarchBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId == 'sanctus_crystal'),
          hasLength(1),
          reason: '${b.id} does not guarantee its Crystal',
        );
      }
    });

    test('⭐⭐ BOTH bosses drop the gate fragment, always, unweighted', () {
      // ⚠️⚠️ The single most load-bearing law in this file (§3.4, ENEMIES
      // §2e.1). A run draws one boss of two, so a `key` on a `main` table —
      // or on only one boss — turns a mandatory progression item into a coin
      // flip. Every clause is checked, because each one alone still compiles.
      for (final b in HallowmarchBestiary.bosses) {
        final key = b.drops.always.where((d) => d.defId == 'the_kept_third');
        expect(
          key,
          hasLength(1),
          reason: '${b.id} does not carry the_kept_third on its always line',
        );
        expect(
          key.single.chance,
          1,
          reason: '${b.id} makes a mandatory part a coin flip',
        );
        expect(
          b.drops.main.map((d) => d.defId),
          isNot(contains('the_kept_third')),
          reason: '${b.id} weights the gate fragment into its main draw',
        );
      }
      // ⚠️ And nothing below boss rank may hand it over.
      for (final e in [
        ...HallowmarchBestiary.commons,
        ...HallowmarchBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('the_kept_third')),
          reason: '${e.id} gives away the gate fragment',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in HallowmarchBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('votive_pendant'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('votive_pendant'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('votive_pendant').rarity, Rarity.rare);
    });

    test('the epic is boss-only', () {
      final epics = HallowmarchItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(epics, [
        'the_maintained_road',
      ], reason: '§4.1 authors exactly one epic');
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
        }
      }
    });

    test('⚠️ the hide role pays in goldenrood, the SECOND material', () {
      // ⭐ §3.5.1 — Hallowmarch defines no kill-only hide, so "something
      // died" pays in the zone's own stuff. The two commons and the one mini
      // the roster gives a `hide` must each be able to hand it over.
      for (final e in [
        HallowmarchBestiary.markerSworn,
        HallowmarchBestiary.pilgrimsRemnant,
        HallowmarchBestiary.seraphJudicant,
      ]) {
        expect(
          e.drops.possibleDrops,
          contains('goldenrood'),
          reason: '${e.id} carries a hide role with nothing to pay it with',
        );
      }
      // ⚠️ And no hide item was invented to dodge the ruling.
      expect(
        HallowmarchItems.all
            .map((d) => d.id)
            .where((id) => id.endsWith('hide')),
        isEmpty,
        reason: 'a hide item here re-opens §3.5.1 and the node rule with it',
      );
    });
  });

  group('the catalogue matches §4.1', () {
    test('13 defs, all resolvable under this zone', () {
      // ⚠️ §4.1's table and §7.1's count both say **12**: they were written
      // before §3.4's reconciliation moved `the_kept_third` here from The
      // Sealed Garden, whose own table still carries the struck-through row.
      // ⭐ 2 materials + 3 motes + 2 consumables + 1 key + 5 equipment.
      expect(
        HallowmarchItems.all,
        hasLength(13),
        reason: '§4.1\'s twelve rows plus the key §3.4 moved here',
      );
      for (final def in HallowmarchItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⭐⭐ the Sanctus mote family is DEFINED HERE', () {
      // §3.2 — the mote lives with the zone that first yields it, and
      // Hallowmarch is the quarter's (and the game's) first Sanctus zone.
      // ⚠️ The Sealed Garden and The Reliquary Deep both drop `sanctus_*`
      // and must import it rather than author a second copy.
      for (final id in ['sanctus_dust', 'sanctus_shard', 'sanctus_crystal']) {
        expect(
          ItemCatalogue.zoneOf(id),
          zone,
          reason: '$id moved out of the zone that first yields it',
        );
        final def = ItemCatalogue.byId(id);
        expect(def, isA<MoteDef>());
        expect((def as MoteDef).element, MagicElement.sanctus);
      }
      // ✅ ECONOMY §14c: one value per TIER, uniform across every element.
      expect(HallowmarchItems.sanctusDust.value, 2);
      expect(HallowmarchItems.sanctusShard.value, 25);
      expect(HallowmarchItems.sanctusCrystal.value, 150);
      // ⚠️ Crystal alone is uncommon — §0.2 ruling 2 keeps `uncommon` off
      // equipment and on Crystal motes and gem-grade materials.
      expect(HallowmarchItems.sanctusDust.rarity, Rarity.common);
      expect(HallowmarchItems.sanctusShard.rarity, Rarity.common);
      expect(HallowmarchItems.sanctusCrystal.rarity, Rarity.uncommon);
      // ⚠️ No Core, no Heart in this quarter (§3.2) — and `world.dart` gates
      // Zenith on twelve Cores, so this is a known gap, not an oversight.
      expect(HallowmarchItems.all.whereType<MoteDef>().map((m) => m.tier), {
        MoteTier.dust,
        MoteTier.shard,
        MoteTier.crystal,
      }, reason: 'a Core that buys nothing is noise, not a ladder rung');
    });

    test(
      'equip levels sit in the band; everything else sits at or below it',
      () {
        final loc = World.byId(zone);
        for (final def in HallowmarchItems.all) {
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
                  '${def.id} is a key, mote, material or consumable and must '
                  'be usable the moment it drops',
            );
          }
        }
        // ⚠️ §4.1 pins the ladder: the three crafted Spiritwood pieces at the
        // band floor, the rare at 47, the epic at the band ceiling.
        expect(HallowmarchItems.spiritwoodQuarterstaff.equipLevel, 45);
        expect(HallowmarchItems.spiritwoodWand.equipLevel, 45);
        expect(HallowmarchItems.spiritwoodKnot.equipLevel, 45);
        expect(HallowmarchItems.votivePendant.equipLevel, 47);
        expect(HallowmarchItems.theMaintainedRoad.equipLevel, 49);
      },
    );

    test('⭐⭐ Spiritwood is the first two-socket LADDER rung', () {
      // §4.1a of CELESTIAL claims Spiritwood is "the first two-socket item in
      // the game". ⚠️ **Measured against the shipped catalogue that is not
      // true**: `heartwood_stave` — the Whispering Woods' level-5 epic boss
      // unique — has carried two sockets since Q1. ⭐ What IS true, and what
      // this test pins, is the claim the contract was reaching for: every
      // *crafted* wood before Spiritwood carries 0 or 1 (ITEMS §9b.6's
      // range), and Spiritwood is the first rung of that ladder to spend the
      // top of it — and the first whole weapon SET to do so.
      for (final def in [
        HallowmarchItems.spiritwoodQuarterstaff,
        HallowmarchItems.spiritwoodWand,
        HallowmarchItems.spiritwoodKnot,
      ]) {
        expect(
          def.socketCount,
          2,
          reason: '${def.id} lost the quarter\'s Phase 8 surface',
        );
      }
      // ⭐ §4.1a's real claim: Spiritwood is the LOWEST-LEVEL crafted rung to
      // reach two sockets. Aetherwood (the Collapsed Academy, 50–54) sits
      // above it with three, and the Heartwood Staff is a named boss unique,
      // not a rung — so the law is about ordering, never an exact set.
      final craftedSocketed = ItemCatalogue.all
          .whereType<EquipmentDef>()
          .where((d) => d.socketCount > 1 && d.properName == null)
          .toList();
      final lowest = craftedSocketed
          .map((d) => d.equipLevel)
          .reduce((a, b) => a < b ? a : b);
      expect(
        craftedSocketed
            .where((d) => d.equipLevel == lowest)
            .map((d) => d.material)
            .toSet(),
        {'Spiritwood'},
        reason:
            'another crafted wood reached two sockets first — §4.1a\'s '
            'claim moves with it',
      );
    });

    test('the crafted gear composes its name; the two uniques are written', () {
      // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
      // material+form grammar composes the name and cannot drift from it.
      for (final def in [
        HallowmarchItems.spiritwoodQuarterstaff,
        HallowmarchItems.spiritwoodWand,
        HallowmarchItems.spiritwoodKnot,
      ]) {
        expect(
          def.properName,
          isNull,
          reason:
              '${def.id} has a written name, which reintroduces the drift '
              'the grammar exists to prevent',
        );
      }
      expect(HallowmarchItems.votivePendant.properName, 'Votive Pendant');
      expect(
        HallowmarchItems.theMaintainedRoad.properName,
        'The Maintained Road',
      );
      // ⚠️ Only the main hand may be two-handed, and only the staff is.
      expect(HallowmarchItems.spiritwoodQuarterstaff.twoHanded, isTrue);
      expect(HallowmarchItems.spiritwoodWand.twoHanded, isFalse);
    });

    test('⭐ Sanctus\'s affinity arrives COMPLETE, on both drops', () {
      // §2.5a — shield strength % **and** healing received %, the support
      // pair no element owned alone (Aqua's lean and Flora's at once).
      // ⚠️ A mutant that keeps one half still compiles and still reads as a
      // support piece.
      for (final def in [
        HallowmarchItems.votivePendant,
        HallowmarchItems.theMaintainedRoad,
      ]) {
        expect(
          def.modifiers.shieldStrengthPercent,
          greaterThan(0),
          reason: '${def.id} dropped half of Sanctus\'s affinity',
        );
        expect(
          def.modifiers.healingReceivedPercent,
          greaterThan(0),
          reason: '${def.id} dropped the other half',
        );
      }
      expect(
        HallowmarchItems.votivePendant.modifiers.shieldStrengthPercent,
        18,
      );
      expect(
        HallowmarchItems.votivePendant.modifiers.healingReceivedPercent,
        12,
      );
      expect(
        HallowmarchItems.theMaintainedRoad.modifiers.shieldStrengthPercent,
        20,
      );
      expect(
        HallowmarchItems.theMaintainedRoad.modifiers.healingReceivedPercent,
        15,
      );
      expect(HallowmarchItems.theMaintainedRoad.modifiers.maxHpBonus, 45);
      // ⚠️ Both are the same slot — a rare→epic ladder inside one zone
      // (§4.1's own ⚠️, with a 📝 offering `ring` for the rare instead).
      expect(HallowmarchItems.votivePendant.slot, EquipSlot.neck);
      expect(HallowmarchItems.theMaintainedRoad.slot, EquipSlot.neck);
      // ⭐ 20 is the largest shieldStrengthPercent a player can wear.
      final biggest = ItemCatalogue.all
          .whereType<EquipmentDef>()
          .map((d) => d.modifiers.shieldStrengthPercent)
          .reduce((a, b) => a > b ? a : b);
      expect(
        biggest,
        20,
        reason: 'something out-shields the epic; §2.5 counts the sources',
      );
    });

    test('the Ration is out-of-combat and the Draught is not', () {
      // §3.3's vocabulary ruling: Ration = ConsumableDef, Draught =
      // BeltableDef. ⚠️ A beltable Ration would put an out-of-combat heal
      // into a duel, which is the whole distinction.
      expect(HallowmarchItems.climbersRation, isA<ConsumableDef>());
      expect(
        HallowmarchItems.climbersRation,
        isNot(isA<Beltable>()),
        reason: 'a Ration is not drunk mid-duel (ITEMS §9b.8 ruling 6)',
      );
      expect(HallowmarchItems.climbersRation.effect.heal, 195);
      expect(HallowmarchItems.goldenroodDraught, isA<Beltable>());
      expect(HallowmarchItems.goldenroodDraught.effect.heal, 225);
      expect(
        HallowmarchItems.goldenroodDraught.effect.healPerTurn,
        0,
        reason: 'a Draught is a lump — over-time is what a Tonic is (§3.3)',
      );
      // ⭐ §3.3's magnitudes: Ration 35% of the band floor's health, Draught
      // 40%. A level-45 bar is 562.
      expect(MageState.scaledMaxHp(45), 562);
    });

    test('the Kept Third is a bound, worthless, Citadel-gating Key', () {
      final third = ItemCatalogue.byId('the_kept_third');
      expect(third, isA<KeyDef>());
      expect(
        (third as KeyDef).gates,
        'the_eclipsed_citadel',
        reason: '§3.4 — the three Thirds open the last door in the game',
      );
      expect(third.tradability, Tradability.bound);
      expect(third.value, 0, reason: 'KeyDef forces it; §5.4 exempts it');
      expect(third.rarity, Rarity.rare);
      expect(
        third.equipLevel,
        lessThanOrEqualTo(45),
        reason: 'a gate part must be carryable the moment it drops',
      );
    });

    test('the two materials feed the two skills §3.1 assigns', () {
      expect(HallowmarchItems.spiritwoodLog.skill, CraftSkill.woodcarving);
      expect(HallowmarchItems.goldenrood.skill, CraftSkill.potionsAndAlchemy);
      expect(HallowmarchItems.spiritwoodLog.tier, 8);
      expect(HallowmarchItems.goldenrood.tier, 8);
      expect(
        HallowmarchItems.all.whereType<MaterialDef>(),
        hasLength(2),
        reason: 'a pure zone gets exactly two materials (ITEMS §9b.8 rule 7)',
      );
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('three nodes, and the third is the cross-zone one', () {
      expect(nodes, hasLength(3));
      expect(nodes.map((n) => n.id).toSet(), {
        'hm_spiritwood_stand',
        'hm_goldenrood_verge',
        'hm_causeway_quarry',
      });
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

    test('the two LOCAL nodes yield a real material this zone defines', () {
      for (final n in nodes) {
        if (_parallelLaneIds.contains(n.yieldsDefId)) continue;
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

    test('⚠️ the causeway quarry yields The Buried Sky\'s ore', () {
      // ⭐ §6 — the ONLY cross-zone node in the game, and deliberate: the
      // causeway's stone came from further down than the causeway is, so a
      // player who has not yet found the shaft can still start the
      // Metalworking ladder.
      final def = ItemCatalogue.tryById('deepstratum_ore');
      expect(
        def,
        isNotNull,
        reason:
            'deepstratum_ore is named by §6 and must exist once the '
            'Buried Sky lane lands',
      );
      expect(def, isA<MaterialDef>());
      expect(
        ItemCatalogue.zoneOf('deepstratum_ore'),
        'the_buried_sky',
        reason: 'the one node in the game that harvests another zone',
      );
    });

    test('node skill follows the material\'s consuming skill (§6a.1)', () {
      // ⭐ Woodcarving ← Felling, Potions ← Foraging, Metalworking (ore) ←
      // Mining. A node that pays the wrong ledger row levels a skill the
      // material never feeds.
      expect(GatherNodes.hmSpiritwoodStand.skill, GatherSkill.felling);
      expect(GatherNodes.hmGoldenroodVerge.skill, GatherSkill.foraging);
      expect(GatherNodes.hmCausewayQuarry.skill, GatherSkill.mining);
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 97);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });

    test('⚠️ no node yields a mote or a gate part', () {
      // Motes and keys are kill-only by fiction (the node file's own library
      // comment): a node for either is a second source that contradicts
      // itself, and for the key it would also un-gate the Citadel.
      final yielded = GatherNodes.all.map((n) => n.yieldsDefId).toSet();
      for (final id in [
        'sanctus_dust',
        'sanctus_shard',
        'sanctus_crystal',
        'the_kept_third',
      ]) {
        expect(yielded, isNot(contains(id)), reason: '$id has grown a node');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final warden = HallowmarchBestiary.vestalWarden;
      final keeper = HallowmarchBestiary.theKeeperOfTheRoad;
      expect(
        warden.maxHpAt(45),
        (MageState.scaledMaxHp(45) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        warden.maxHpAt(45),
        1236,
        reason: '§1.2\'s worked table, transcribed rather than invented',
      );
      expect(
        keeper.maxHpAt(45),
        (MageState.scaledMaxHp(45) * Archetypes.juggernaut.hpScale).round(),
      );
      expect(
        keeper.maxHpAt(45),
        1574,
        reason:
            'the Juggernaut row at HP× 2.80 (✅ 2026-09-25; was 2023 at 3.60)',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 45. Anything that can open with a kill from full
      // health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(45);
      for (final e in HallowmarchBestiary.commons) {
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
      for (final def in HallowmarchItems.all) {
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
        // ⭐ Motes are deliberately one-line epigrams (§4.1's lore block —
        // *"Dust that was kept."*); everything else is a field note.
        if (def is MoteDef) continue;
        expect(def.lore.length, greaterThan(40), reason: '${def.id} lore thin');
      }
    });
  });
}
