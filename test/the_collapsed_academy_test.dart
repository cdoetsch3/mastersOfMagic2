/// The Collapsed Academy's roster LAWS (Lv 50–54, Arcane) and its catalogue
/// checks — ENEMIES §2e plus ETHEREAL_CONTRACT §4.5.
///
/// ⭐⭐ **This zone fields the game's first MAGE boss**, so three creature laws
/// carry an explicit mage exemption here — move count / cost band, the zone
/// move-id prefix, and §1.3's raw ceiling. ⚠️ Each exemption is written as a
/// `continue` with the reason beside it rather than as a looser assertion, and
/// each is paid for by the mage-only laws in the group below it: the loadout
/// must be in `Spellbook.all` and legal at this band's floor. A mutant that
/// widens an exemption to cover creatures fails those.
///
/// ⚠️ **`climbers_ration` is owned by Hallowmarch**, a parallel Ethereal
/// worktree. Everything this zone DEFINES is asserted normally; the one
/// cross-lane id is asserted in a single `skip:`ped test whose skip reason
/// names the dependency, so the merge coordinator has exactly one line to
/// delete once the lanes land together.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_collapsed_academy.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_collapsed_academy_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/progression.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id the Academy itself authors — that is what
/// the "no local id hides in here" test below proves.
///
/// ⚠️ `arcane_*` is deliberately NOT here: the Glass Archive is shipped, so
/// those resolve today and are asserted normally.
const _parallelLaneIds = <String>{'climbers_ration'};

void main() {
  const zone = 'the_collapsed_academy';
  final all = CollapsedAcademyBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        CollapsedAcademyBestiary.commons,
        hasLength(5),
        reason: 'ENEMIES §2e gives every zone exactly five wandering types',
      );
      expect(
        CollapsedAcademyBestiary.minis,
        hasLength(4),
        reason: 'two drawn of four',
      );
      expect(
        CollapsedAcademyBestiary.bosses,
        hasLength(2),
        reason: 'one drawn of two',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives — a bestiary left out
      // of `Bestiary.all` compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'CollapsedAcademyBestiary is not listed in Bestiary.all',
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
      expect(
        CollapsedAcademyBestiary.minis.map((e) => e.archetype.id).toSet(),
        {'champion', 'redoubt', 'executioner', 'hexer'},
        reason: 'two minis share an archetype, so a run can draw a mirror',
      );
    });

    test('the boss pair is a mind and what it read, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e: The Archmage is *who* read too far (Tyrant); The Last
      // Three Items is *what they read* (Aspect). ⚠️ No Juggernaut — a mass
      // boss says the zone is rubble, which is the one reading §2e forbids.
      expect(CollapsedAcademyBestiary.theArchmage.archetype.id, 'tyrant');
      expect(CollapsedAcademyBestiary.theLastThreeItems.archetype.id, 'aspect');
      expect(
        CollapsedAcademyBestiary.bosses.map((b) => b.archetype.id),
        isNot(contains('juggernaut')),
        reason: 'over-completion, not ruin — a mass boss inverts the theme',
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
      // ⚠️ Two of these are §2f re-assignments away from the original draft —
      // Stairhead is a Bruiser (was Sentinel) and Emeritus is a Glasswing
      // (was Drudge). A mutant that reverts either still compiles, and
      // ETHEREAL §1.2 still prints Emeritus as a Drudge, so the revert has a
      // document to point at.
      expect(
        CollapsedAcademyBestiary.commons.map((e) => e.archetype.id).toList(),
        ['adept', 'bruiser', 'skirmisher', 'blighter', 'glasswing'],
      );
      expect(
        CollapsedAcademyBestiary.commons.map((e) => e.archetype.id),
        isNot(contains('drudge')),
        reason:
            '§2f puts zero Drudges above level 30 — a 0.80/0.70 body at L52 '
            'is a wasted encounter slot',
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
      // ⭐ Hard-coded rather than derived: a pure zone has no formula to check
      // against either, and the one exception below is exactly why.
      const arcane = [MagicElement.arcane];
      expect(CollapsedAcademyBestiary.unfinishedScholar.elements, arcane);
      expect(CollapsedAcademyBestiary.stairhead.elements, arcane);
      expect(CollapsedAcademyBestiary.chalkwraith.elements, arcane);
      expect(CollapsedAcademyBestiary.marginalNote.elements, arcane);
      expect(CollapsedAcademyBestiary.emeritus.elements, arcane);
      expect(CollapsedAcademyBestiary.manaGolem.elements, arcane);
      expect(CollapsedAcademyBestiary.arcaneChimera.elements, arcane);
      expect(CollapsedAcademyBestiary.spellWeaver.elements, arcane);
      expect(CollapsedAcademyBestiary.theArchmage.elements, arcane);
      // ⚠️ The Aspect MUST be single-element (ENEMIES §2.5), which costs
      // nothing in a pure zone but is still the law being satisfied.
      expect(
        CollapsedAcademyBestiary.theLastThreeItems.elements,
        arcane,
        reason: 'the Aspect is one element taken to an extreme, never two',
      );
      // ⚠️ The Fourth Item is the exception and gets its own law below.
      expect(CollapsedAcademyBestiary.theFourthItem.elements, [
        MagicElement.arcane,
        MagicElement.astral,
      ]);
    });

    test('⚠️ the zone carries exactly ONE off-element creature, and it is '
        'legal', () {
      // §2e.2 names four creatures in fifteen zones. Here it is The Fourth
      // Item, with one astral move. Every clause of §2h's guardrail is
      // checked, because each one alone still compiles.
      const zoneElements = {MagicElement.arcane};
      final offElement = all
          .where((e) => e.elements.any((el) => !zoneElements.contains(el)))
          .toList();

      expect(offElement.map((e) => e.id), [
        'the_fourth_item',
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
        [MagicElement.astral],
        reason: 'at most ONE off-element, and §2e.2 names astral',
      );
      // ⚠️⚠️ The row §2h says never to lose: a creature that carries the thing
      // which beats the player's correct counter-pick punishes preparation.
      final forbidden = {MagicElement.arcane.counteredBy};
      expect(forbidden, {
        MagicElement.umbra,
      }, reason: 'the counter wheel moved; re-derive §2e.2 before trusting it');
      expect(
        forbidden,
        isNot(contains(MagicElement.astral)),
        reason: 'astral would be this zone\'s own counter, which §2h forbids',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2e calls the Unfinished Scholar "the yardstick", which means the
      // Adept — and §2f.1's rule that the Adept usually lands on the anchor.
      expect(
        CollapsedAcademyBestiary.unfinishedScholar.archetype.id,
        'adept',
        reason:
            'the anchor is the yardstick the rest of the zone is felt '
            'against',
      );
    });

    test('the zone band is 50–54, a dungeon, pure Arcane', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 50);
      expect(loc.maxLevel, 54);
      expect(loc.kind, LocationKind.dungeon, reason: '🏰 in ENEMIES §2e');
      expect(loc.elements, [MagicElement.arcane]);
    });
  });

  group('combat stats match ETHEREAL §2.3 (CELESTIAL §2.3\'s table)', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        CollapsedAcademyBestiary.unfinishedScholar.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Bruiser hits like a truck and sometimes whiffs', () {
      expect(
        CollapsedAcademyBestiary.stairhead.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
      );
    });

    test('the Skirmisher is quick and hard to pin', () {
      expect(
        CollapsedAcademyBestiary.chalkwraith.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        CollapsedAcademyBestiary.marginalNote.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        CollapsedAcademyBestiary.emeritus.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        CollapsedAcademyBestiary.theFourthItem.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        CollapsedAcademyBestiary.manaGolem.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        CollapsedAcademyBestiary.arcaneChimera.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        CollapsedAcademyBestiary.spellWeaver.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Tyrant carries a little of everything', () {
      expect(
        CollapsedAcademyBestiary.theArchmage.combatStats,
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

    test('the Aspect is §2.4\'s row, verbatim', () {
      // ⚠️ defl 35/28 (EV 9.8%), acc +10 — a hair under the Redoubt's 10.5%
      // on purpose, and deflection because Arcane's lean IS deflection:
      // knowing what is coming is how you take less of it.
      expect(
        CollapsedAcademyBestiary.theLastThreeItems.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 10,
          deflectChance: 35,
          deflectAmount: 28,
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
      // ⚠️ §2.1's inert-stat traps — a "buff" with a zero chance to trigger is
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

  group('⭐⭐ the Archmage is a mage, and the only one', () {
    final archmage = CollapsedAcademyBestiary.theArchmage;

    test('exactly one creature in the zone sets isMage', () {
      // ⚠️ ENEMIES §3.4 — the flag is a licence off three creature laws, so a
      // second one appearing quietly is three laws quietly switched off.
      expect(all.where((e) => e.isMage).map((e) => e.id), [
        'the_archmage',
      ], reason: 'isMage spread to a creature that fights with verbs');
    });

    test('every spell in the loadout is a real Spellbook entry', () {
      // ⭐ The law a mage owes in exchange for its exemptions: a mage does not
      // get to invent moves and call them spells.
      final book = {for (final s in Spellbook.all) s.id: s};
      for (final m in archmage.moves) {
        expect(
          book[m.id],
          same(m),
          reason: '"${m.name}" is not the Spellbook\'s own object',
        );
      }
    });

    test('the loadout is level-legal at the band FLOOR, not the ceiling', () {
      // ⚠️ §2.7's ruling: an enemy may only bring spells a PLAYER of its level
      // could. Checked at 50 rather than 54, because a player walks in at 50.
      final floor = World.byId(zone).minLevel;
      for (final m in archmage.moves) {
        expect(
          Progression.plannedUnlockLevelOf(m),
          lessThanOrEqualTo(floor),
          reason:
              '"${m.name}" unlocks at '
              '${Progression.plannedUnlockLevelOf(m)}, above the band floor '
              'of $floor',
        );
      }
    });

    test('the loadout fits a real loadout: 8–10 slots, and 10 is the cap', () {
      expect(archmage.moves, hasLength(10));
      expect(
        archmage.moves.length,
        lessThanOrEqualTo(Loadout.maxSpellSlots),
        reason: 'a mage may not carry more slots than a player has',
      );
      expect(
        Progression.spellsAtLevel(World.byId(zone).minLevel),
        greaterThanOrEqualTo(archmage.moves.length),
        reason:
            'the unlock schedule does not reach this many slots by level '
            '${World.byId(zone).minLevel}',
      );
      expect(
        archmage.moves.map((m) => m.id).toSet(),
        hasLength(archmage.moves.length),
        reason: 'the same spell is in two slots',
      );
    });

    test('⭐ the loadout is Arcane-leaning: knowledge, not just a damage '
        'ladder', () {
      // ⭐ §4.5/ITEMS §2.2 — Arcane's identity is knowing what is coming.
      // Discharge, Overload and Dispel are what makes this a fight against a
      // reader rather than against a bigger Tyrant.
      final ids = archmage.moves.map((m) => m.id).toSet();
      expect(
        ids,
        containsAll(['discharge', 'overload', 'dispel']),
        reason: 'without these it is a stat block, not an archmage',
      );
      expect(
        ids,
        containsAll(['bolt', 'blast', 'surge', 'ruin', 'cataclysm']),
        reason: 'the five-rung ladder is what makes its charge bar readable',
      );
      expect(
        archmage.moves.where((m) => m.effect is ShieldEffect),
        hasLength(2),
        reason: 'nothing to turtle a five-charge telegraph behind',
      );
    });

    test('the mage still obeys the laws that are NOT exempted', () {
      // ⚠️ The exemptions are three, named on EnemyDef.isMage — not "all of
      // them". Drops, stats, rank and affordability are untouched.
      expect(archmage.rank, EnemyRank.boss);
      expect(
        archmage.moves.map((m) => m.chargeCost).reduce((a, b) => a < b ? a : b),
        lessThanOrEqualTo(5),
        reason: 'the Archmage cannot reach any of its own spells',
      );
      expect(
        archmage.drops.possibleDrops,
        contains('the_written_third'),
        reason: 'a mage boss of a gate zone still owes the fragment',
      );
    });
  });

  group('creatures are creatures, not mages', () {
    test('no CREATURE move borrows an id from the player Spellbook', () {
      // ⚠️ ENEMIES §3 — a boar does not cast Bolt. Sharing an id would also
      // make the two catalogues collide in the battle log. ⭐ The mage is
      // exempt because its ids ARE the Spellbook's, which is the point of it.
      final spellIds = Spellbook.all.map((s) => s.id).toSet();
      for (final e in all) {
        if (e.isMage) continue;
        for (final m in e.moves) {
          expect(
            spellIds.contains(m.id),
            isFalse,
            reason: '${e.id}\'s "${m.name}" reuses a Spellbook id',
          );
        }
      }
    });

    test('creature move ids are unique across the WHOLE bestiary, and all '
        'ca_', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (§3.5/§7.2). Checked game-wide, not zone-locally, because a collision
      // with a shipped zone is the failure that actually happens.
      final mine = [
        for (final e in all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('ca_'), isTrue, reason: '$id is not zone-tagged');
      }
      final everything = [
        for (final e in Bestiary.all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(
        everything.toSet(),
        hasLength(everything.length),
        reason: 'a ca_ move id collides with another zone\'s',
      );
    });

    test('no move name collides with the game\'s own vocabulary', () {
      // ⚠️ Applies to the mage too — a Spellbook name that were an element
      // name would be just as ambiguous in the log.
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
      // the moves. ⚠️ The mage is exempt: a loadout is ten slots, and the
      // Tyrant's shape asks for three.
      for (final e in all) {
        if (e.isMage) continue;
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
      // by level, so a 50–54 band arrives via the ENCOUNTER LEVEL, never
      // bigger raws. §1.3's table is byte-for-byte KINETIC's and does not
      // grow — which a builder authoring a level-54 boss will want to doubt.
      // ⚠️ The mage is exempt: the Spellbook is priced for PLAYERS, and
      // Cataclysm's 59–72 is over the creature ceiling by construction.
      for (final e in all) {
        if (e.isMage) continue;
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
      // ⚠️ §1.3's per-archetype rule, and it is the whole of what makes a
      // Blighter read differently from a plain attacker: each hit meets the
      // wall on its own.
      for (final m in CollapsedAcademyBestiary.marginalNote.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: 'marginal_note\'s "${m.name}" arrives in one piece',
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
      final wall = CollapsedAcademyBestiary.manaGolem.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(SpellPriority.shield),
        reason: 'a wall raised after you shield is a delay, not a wall',
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

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final weaver = CollapsedAcademyBestiary.spellWeaver;
      expect(weaver.archetype.id, 'hexer');
      expect(
        weaver.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        weaver.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️ §1.3 — at L54 a mini five-charge raw lands well past a one-shot,
      // and the archetype is for a two-cast kill. Kills a mutant that
      // restores the archetype's own maxMoveCost of 5.
      final chimera = CollapsedAcademyBestiary.arcaneChimera;
      expect(chimera.archetype.id, 'executioner');
      for (final m in chimera.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
    });

    test('⭐ the Aspect escalates — its finisher executes', () {
      // ⭐ §2e: "it gets stronger every turn you let it live." With no
      // creature-side ramp in the engine, the execute rider is what carries
      // that: an ordinary big hit until you are low, and the end of the fight
      // after. A mutant that drops the rider leaves a plain cost-4 attack.
      final finisher = CollapsedAcademyBestiary.theLastThreeItems.moves
          .firstWhere((m) => m.chargeCost == 4);
      expect(finisher.effect, isA<DamageEffect>());
      expect(
        (finisher.effect as DamageEffect).executeBelowPercent,
        30,
        reason: 'the Aspect\'s premise is carried by this number alone',
      );
    });

    test('⭐ nothing in this zone lifesteals — there is no Siphon here', () {
      // §2e's roster fields no Siphon in the Academy; a lifesteal move
      // anywhere here smuggles the archetype back in through the move set.
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

    test(
      'the cross-lane ids resolve too',
      () {
        for (final id in _parallelLaneIds) {
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
            reason: '$id is named by §4.5\'s tables and must exist',
          );
        }
      },
      skip:
          '`climbers_ration` is defined by hallowmarch_items.dart, a parallel '
          'Ethereal worktree. Delete this skip when the lanes merge.',
    );

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the skip above would be hiding a real local failure.
      final mine = CollapsedAcademyItems.all.map((d) => d.id).toSet();
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
      for (final e in CollapsedAcademyBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...CollapsedAcademyBestiary.minis,
        ...CollapsedAcademyBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in CollapsedAcademyBestiary.commons) {
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

    test('⭐ a PURE zone pays ONE mote ladder, and it is the Archive\'s', () {
      final dropped = CollapsedAcademyBestiary.allDrops;
      for (final id in ['arcane_dust', 'arcane_shard', 'arcane_crystal']) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ Nothing from a second element — the off-element move is a MOVE, and
      // §2e.2 buys no second mote family with it. Astral especially.
      final foreign = <String>{
        for (final el in MagicElement.values)
          if (el != MagicElement.arcane) ...[
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
      for (final e in CollapsedAcademyBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in CollapsedAcademyBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(1),
          reason: '${b.id} does not guarantee the Crystal',
        );
      }
    });

    test('⭐⭐ the gate fragment drops from BOTH bosses, always, unweighted', () {
      // ⚠️ §2e.1 / §3.4 / §3.5 rule 3, and the reason is stated there: a run
      // draws one boss of two, so a weighted fragment — or one on a single
      // boss — turns a mandatory progression item into a coin flip. Three
      // separate mutants are killed here: moving it to `main`, giving it a
      // `chance`, and dropping it from one boss only.
      for (final b in CollapsedAcademyBestiary.bosses) {
        final entries = b.drops.always.where(
          (d) => d.defId == 'the_written_third',
        );
        expect(
          entries,
          hasLength(1),
          reason: '${b.id} does not carry the fragment on its always line',
        );
        expect(
          entries.single.chance,
          1,
          reason: '${b.id} weights a mandatory gate part',
        );
        expect(
          b.drops.main.map((d) => d.defId),
          isNot(contains('the_written_third')),
          reason: '${b.id} moved the fragment onto the weighted table',
        );
      }
      // ⚠️ And nothing below boss rank may ever carry it.
      for (final e in [
        ...CollapsedAcademyBestiary.commons,
        ...CollapsedAcademyBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('the_written_third')),
          reason: '${e.id} hands out a tier gate',
        );
      }
    });

    test('⭐ the `hide` role settles into mana_slag, the SECOND material', () {
      // §3.5 rule 1 — the Academy defines no kill-only hide, so "something
      // died" pays in the zone's own stuff. §2e gives the role to the
      // Unfinished Scholar and Emeritus.
      for (final e in [
        CollapsedAcademyBestiary.unfinishedScholar,
        CollapsedAcademyBestiary.emeritus,
      ]) {
        expect(
          e.drops.possibleDrops,
          contains('mana_slag'),
          reason: '${e.id} carries the hide role and pays nothing for it',
        );
      }
      // ⚠️ And no hide-shaped id exists here to be "restored" later.
      for (final def in CollapsedAcademyItems.all) {
        expect(
          def.id,
          isNot(contains('hide')),
          reason: '${def.id} re-invents a hide §3.1 does not give this zone',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in CollapsedAcademyBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('chalkline_signet'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('chalkline_signet'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('chalkline_signet').rarity, Rarity.rare);
    });

    test('the epic is boss-only, and it is the best main hand in the game', () {
      final epics = CollapsedAcademyItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(epics, [
        'the_unbuilt_stair',
      ], reason: '§4.5 authors exactly one epic');
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
        }
      }
      // ⚠️ §4.5 — only marginally ahead of the crafted staff, and deliberately
      // so: +1 dpc, +1 acc, −2 critDamage. Kills a mutant that "fixes" the
      // Epic into a clear upgrade and re-opens §2.6 finding 2.
      final epic = CollapsedAcademyItems.theUnbuiltStair.modifiers;
      final crafted = CollapsedAcademyItems.aetherwoodQuarterstaff.modifiers;
      expect(epic.damagePerCharge - crafted.damagePerCharge, 1);
      expect(epic.accuracyBonus - crafted.accuracyBonus, 1);
      expect(epic.critDamage - crafted.critDamage, -2);
    });
  });

  group('the catalogue matches §4.5', () {
    test('9 defs, all resolvable under this zone', () {
      // ⚠️ §7.1's per-zone count still reads **8**, because it was written
      // before §3.4's reconciliation moved `the_written_third` here from The
      // Reliquary Deep's list. The quarter total of 79 is unchanged.
      expect(CollapsedAcademyItems.all, hasLength(9));
      for (final def in CollapsedAcademyItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⭐⭐ the Arcane mote family is NOT defined here', () {
      // §3.2 / §4.5 — the mote lives with the zone that first yields it, and
      // the Glass Archive (43–47) is seven levels below this one. ⚠️ The
      // single most surprising fact about this file: this is the only PURE
      // zone in the game that defines no mote family, and a builder who
      // "fixes" that ships three duplicate ids.
      expect(
        CollapsedAcademyItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'the Academy re-defined a mote family the Archive owns',
      );
      for (final id in ['arcane_dust', 'arcane_shard', 'arcane_crystal']) {
        expect(
          ItemCatalogue.zoneOf(id),
          'the_glass_archive',
          reason: '$id moved out of the zone that first yields it',
        );
      }
    });

    test(
      'equip levels sit in the band; everything else sits at or below it',
      () {
        final loc = World.byId(zone);
        for (final def in CollapsedAcademyItems.all) {
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
                  '${def.id} is a key, material or consumable and must be '
                  'usable the moment it drops',
            );
          }
        }
        // ⚠️ §4.5 pins the three Aetherwood commons at the band floor, the
        // signet two levels up and the Epic at the ceiling.
        expect(CollapsedAcademyItems.aetherwoodQuarterstaff.equipLevel, 50);
        expect(CollapsedAcademyItems.chalklineSignet.equipLevel, 52);
        expect(CollapsedAcademyItems.theUnbuiltStair.equipLevel, 54);
      },
    );

    test('the crafted wood composes its name; the two uniques are written', () {
      // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
      // material+form grammar composes the name and cannot drift from it.
      for (final def in [
        CollapsedAcademyItems.aetherwoodQuarterstaff,
        CollapsedAcademyItems.aetherwoodWand,
        CollapsedAcademyItems.aetherwoodKnot,
      ]) {
        expect(
          def.properName,
          isNull,
          reason:
              '${def.id} — a written name on crafted gear reintroduces the '
              'drift',
        );
      }
      expect(
        CollapsedAcademyItems.chalklineSignet.properName,
        'Chalkline Signet',
      );
      expect(
        CollapsedAcademyItems.theUnbuiltStair.properName,
        'The Unbuilt Stair',
      );
    });

    test('⭐ three sockets on every Aetherwood piece — the ladder\'s last '
        'rung', () {
      // §4.5 / ITEMS §9b.6 — the full count the tier allows, and the widest
      // Phase 8 surface any zone offers. ⚠️ No setId, setTier or gem appears,
      // so Phase 8 can add sets BESIDE these rather than instead of them.
      for (final def in CollapsedAcademyItems.all.whereType<EquipmentDef>()) {
        if (def.material != 'Aetherwood') continue;
        expect(
          def.socketCount,
          3,
          reason: '${def.id} lost a socket its tier pays for',
        );
        expect(def.setId, isNull, reason: '${def.id} claims a Phase 8 set');
        expect(def.setTier, isNull);
      }
      // ⚠️ Only a main hand may be two-handed, and both staves are.
      for (final def in [
        CollapsedAcademyItems.aetherwoodQuarterstaff,
        CollapsedAcademyItems.theUnbuiltStair,
      ]) {
        expect(def.twoHanded, isTrue, reason: '${def.id} is a Quarterstaff');
        expect(def.slot, EquipSlot.mainHand);
      }
      expect(CollapsedAcademyItems.aetherwoodWand.twoHanded, isFalse);
    });

    test('the fragment is a bound, worthless, Citadel-gating Key', () {
      final third = ItemCatalogue.byId('the_written_third');
      expect(third, isA<KeyDef>());
      expect((third as KeyDef).gates, 'the_eclipsed_citadel');
      expect(third.tradability, Tradability.bound);
      expect(third.value, 0, reason: 'KeyDef forces it; §5.4 exempts it');
      expect(third.rarity, Rarity.rare, reason: '§3.4: each fragment is rare');
      expect(third.equipLevel, 1);
    });

    test('⚠️ chalkline_signet\'s tiny deflectAmount is deliberate', () {
      // §2.1b — amount is the scarce resource, and this is a CHANCE-heavy
      // ring meant to be worn with the Unleft gloves (26 + 8 = 34), not
      // instead of them. 📝 Moving the 8 moves that proof; the test is here so
      // the move is a deliberate one.
      final ring = CollapsedAcademyItems.chalklineSignet.modifiers;
      expect(ring.deflectChance, 18);
      expect(ring.deflectAmount, 8);
      expect(
        ring.deflectChance,
        greaterThan(ring.deflectAmount),
        reason: 'the ring stopped being the chance-heavy half of the pair',
      );
    });

    test('⚠️ aethersteel_ingot is a crafted OUTPUT: no node, no drop', () {
      // §4.5 — it is Metalworking's output and feeds four recipes. A node or
      // a drop table entry would make the smelting step optional.
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('aethersteel_ingot')),
        reason: 'a node for an ingot skips the forge',
      );
      expect(
        CollapsedAcademyBestiary.allDrops,
        isNot(contains('aethersteel_ingot')),
        reason: 'something in the Academy is dropping finished stock',
      );
      expect(
        CollapsedAcademyItems.aethersteelIngot.skill,
        CraftSkill.metalworking,
      );
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('two nodes — one per gatherable material, and no more', () {
      // ⚠️ ITEMS §9b.8: two materials per pure zone. The third def in the
      // catalogue is a crafted ingot, which is why there is no third node.
      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.id).toSet(), {
        'ca_aetherwood_stair',
        'ca_slag_vault',
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
      // ⭐ Woodcarving ← Felling, Metalworking (ore and slag) ← Mining. A node
      // that pays the wrong ledger row levels a skill the material never
      // feeds.
      expect(GatherNodes.caAetherwoodStair.skill, GatherSkill.felling);
      expect(CollapsedAcademyItems.aetherwoodLog.skill, CraftSkill.woodcarving);
      expect(GatherNodes.caSlagVault.skill, GatherSkill.mining);
      expect(CollapsedAcademyItems.manaSlag.skill, CraftSkill.metalworking);
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 107);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final golem = CollapsedAcademyBestiary.manaGolem;
      final archmage = CollapsedAcademyBestiary.theArchmage;
      expect(
        golem.maxHpAt(52),
        (MageState.scaledMaxHp(52) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        golem.maxHpAt(52),
        1626,
        reason: '§1.2\'s worked table, transcribed rather than invented',
      );
      expect(
        archmage.maxHpAt(52),
        (MageState.scaledMaxHp(52) * Archetypes.tyrant.hpScale).round(),
      );
      expect(archmage.maxHpAt(52), 1921);
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 50. Anything that can open with a kill from full
      // health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(50);
      for (final e in CollapsedAcademyBestiary.commons) {
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
      for (final def in CollapsedAcademyItems.all) {
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
