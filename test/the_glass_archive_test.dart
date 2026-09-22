/// The Glass Archive's roster LAWS (Lv 43–47, Solar + Arcane) and its
/// catalogue checks — ENEMIES §2e plus CELESTIAL_CONTRACT §4.7.
///
/// ⚠️ **`solar_*`, `pilgrims_ration` and `arcsalt_draught` are owned by
/// parallel Celestial worktrees** (The Kiln Desert and The Shattered Orrery).
/// Everything this zone DEFINES is asserted normally; the cross-lane ids are
/// asserted in one `skip:`ped test whose skip reason names the dependency, so
/// the merge coordinator has exactly one line to delete once the lanes land
/// together.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_glass_archive.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_glass_archive_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id the Archive itself authors — that is what
/// the "no local id hides in here" test below proves.
const _parallelLaneIds = <String>{
  'solar_dust',
  'solar_shard',
  'solar_crystal',
  'pilgrims_ration',
  'arcsalt_draught',
};

void main() {
  const zone = 'the_glass_archive';
  final all = GlassArchiveBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        GlassArchiveBestiary.commons,
        hasLength(5),
        reason: 'ENEMIES §2e gives every zone exactly five wandering types',
      );
      expect(
        GlassArchiveBestiary.minis,
        hasLength(4),
        reason: 'two drawn of four',
      );
      expect(
        GlassArchiveBestiary.bosses,
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
        reason: 'GlassArchiveBestiary is not listed in Bestiary.all',
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
      expect(GlassArchiveBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so a run can draw a mirror');
    });

    test('the boss pair is a mind and its erasure, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e: What Was Written is the mind that recorded this
      // (Tyrant); What Is Left Of It is the light that unmakes the reading
      // (Aspect). ⚠️ No Juggernaut in this zone — kills a mutant that
      // reaches for the quarter's default boss pair.
      expect(GlassArchiveBestiary.whatWasWritten.archetype.id, 'tyrant');
      expect(GlassArchiveBestiary.whatIsLeftOfIt.archetype.id, 'aspect');
      expect(
        GlassArchiveBestiary.bosses.map((b) => b.archetype.id),
        isNot(contains('juggernaut')),
        reason: 'the Archive keeps nothing; a mass boss says the opposite',
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
      // draft — Adept (was Sentinel), Blighter (was Siphon), Lasher (was
      // Drudge). A mutant that reverts any of them still compiles.
      expect(GlassArchiveBestiary.commons.map((e) => e.archetype.id).toList(), [
        'adept',
        'glasswing',
        'blighter',
        'lasher',
        'skirmisher',
      ]);
      expect(
        GlassArchiveBestiary.commons.map((e) => e.archetype.id),
        isNot(contains('siphon')),
        reason: '§2f cut the Siphon from this zone; the Blighter replaced it',
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
      // against — only the table.
      const solar = [MagicElement.solar];
      const arcane = [MagicElement.arcane];
      const both = [MagicElement.solar, MagicElement.arcane];
      expect(GlassArchiveBestiary.glasswright.elements, both);
      expect(GlassArchiveBestiary.noonmark.elements, solar);
      expect(GlassArchiveBestiary.palimpsest.elements, arcane);
      expect(GlassArchiveBestiary.readerless.elements, arcane);
      expect(GlassArchiveBestiary.lensfly.elements, solar);
      expect(GlassArchiveBestiary.theLastReader.elements, both);
      expect(GlassArchiveBestiary.aperture.elements, solar);
      expect(GlassArchiveBestiary.theMarginalia.elements, arcane);
      expect(GlassArchiveBestiary.whatWasWritten.elements, arcane);
      // ⚠️ The Aspect MUST be single-element (ENEMIES §2.5). ⚠️⚠️ SOLAR, and
      // the two source docs disagree: ENEMIES §2e says solar ("Blind taken to
      // an extreme… too bright to read by"), CELESTIAL §2.4's table says
      // arcane. The contract defers creature facts to the roster (§0.1, §0.3),
      // so the roster wins the element and the contract still wins the stat
      // block below.
      expect(
        GlassArchiveBestiary.whatIsLeftOfIt.elements,
        solar,
        reason:
            'the Aspect is Solar per ENEMIES §2e, and single-element per §2.5',
      );
      // ⚠️ Burnt Index is the exception and gets its own law below.
      expect(GlassArchiveBestiary.burntIndex.elements, [
        MagicElement.solar,
        MagicElement.pyro,
      ]);
    });

    test('⚠️ the zone carries exactly ONE off-element creature, and it is '
        'legal', () {
      // §2e.2 names four creatures in fifteen zones. Here it is Burnt Index,
      // with one pyro move. Every clause of §2h's guardrail is checked,
      // because each one alone still compiles.
      const zoneElements = {MagicElement.solar, MagicElement.arcane};
      final offElement = all
          .where((e) => e.elements.any((el) => !zoneElements.contains(el)))
          .toList();

      expect(offElement.map((e) => e.id), [
        'burnt_index',
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
        [MagicElement.pyro],
        reason: 'at most ONE off-element, and §2e.2 names pyro',
      );
      // ⚠️⚠️ The row §2h says never to lose: a boss that carries the thing
      // which beats the player's correct counter-pick punishes preparation.
      final forbidden = {
        MagicElement.solar.counteredBy,
        MagicElement.arcane.counteredBy,
      };
      expect(forbidden, {
        MagicElement.astral,
        MagicElement.umbra,
      }, reason: 'the counter wheel moved; re-derive §2e.2 before trusting it');
      expect(
        forbidden,
        isNot(contains(MagicElement.pyro)),
        reason: 'pyro would be this zone\'s own counter, which §2h forbids',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2e: "a wright is a maker, and a maker fights you straight" — the
      // anchor is the zone's yardstick, which means the Adept.
      expect(
        GlassArchiveBestiary.glasswright.archetype.id,
        'adept',
        reason:
            'the anchor is the yardstick the rest of the zone is felt '
            'against',
      );
    });

    test('the zone band is 43–47, a dungeon, Solar + Arcane', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 43);
      expect(loc.maxLevel, 47);
      expect(loc.kind, LocationKind.dungeon, reason: '🏰 in ENEMIES §2e');
      expect(loc.elements, [MagicElement.solar, MagicElement.arcane]);
    });
  });

  group('combat stats match CELESTIAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        GlassArchiveBestiary.glasswright.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        GlassArchiveBestiary.noonmark.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        GlassArchiveBestiary.palimpsest.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
      );
    });

    test('the Lasher trades crit damage for crit frequency', () {
      expect(
        GlassArchiveBestiary.readerless.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('the Skirmisher is quick and hard to pin', () {
      expect(
        GlassArchiveBestiary.lensfly.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        GlassArchiveBestiary.theLastReader.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        GlassArchiveBestiary.aperture.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        GlassArchiveBestiary.burntIndex.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        GlassArchiveBestiary.theMarginalia.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Tyrant carries a little of everything', () {
      expect(
        GlassArchiveBestiary.whatWasWritten.combatStats,
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
      // ⚠️ defl 30/25 (EV 7.5%), acc +8 — the contract's own numbers, kept
      // even though this lane took the ELEMENT from ENEMIES §2e instead.
      // ⭐ They land compatibly: accuracy is Solar's gear affinity (§2.5a).
      expect(
        GlassArchiveBestiary.whatIsLeftOfIt.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          deflectChance: 30,
          deflectAmount: 25,
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

    test('move ids are unique across the WHOLE bestiary, and all ga_', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (§3.5/§7.2). Checked game-wide, not zone-locally, because a
      // collision with a shipped zone is the failure that actually happens.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('ga_'), isTrue, reason: '$id is not zone-tagged');
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
        reason: 'a ga_ move id collides with another zone\'s',
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
      // exemption applies in this zone: the Archive fields no mage boss.
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
      // by level, so a 43–47 band arrives via the ENCOUNTER LEVEL, never
      // bigger raws. §1.3's table is byte-for-byte KINETIC's and does not
      // grow — which a builder authoring a level-47 boss will want to doubt.
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

    test('the Blighter and the Lasher are multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule, and it is the whole of what makes the
      // two read differently from a plain attacker: each hit meets the wall
      // on its own.
      for (final e in [
        GlassArchiveBestiary.palimpsest,
        GlassArchiveBestiary.readerless,
      ]) {
        for (final m in e.moves) {
          expect(m.effect, isA<DamageEffect>());
          expect(
            (m.effect as DamageEffect).hits,
            greaterThan(1),
            reason: '${e.id}\'s "${m.name}" arrives in one piece',
          );
        }
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
      final wall = GlassArchiveBestiary.aperture.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(SpellPriority.shield),
        reason: 'an aperture that closes after you shield closes on nothing',
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
      final marginalia = GlassArchiveBestiary.theMarginalia;
      expect(marginalia.archetype.id, 'hexer');
      expect(
        marginalia.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        marginalia.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap stays lowered to 4', () {
      // ⚠️ §1.3 — at L47 a mini five-charge raw lands 884–1153 against a 607
      // HP bar: not a two-cast kill, a one-shot with change. Kills a mutant
      // that restores the archetype's own maxMoveCost of 5.
      final index = GlassArchiveBestiary.burntIndex;
      expect(index.archetype.id, 'executioner');
      for (final m in index.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
    });

    test('⭐ nothing in this zone lifesteals — the Siphon was CUT (§2f)', () {
      // §2e's roster turned Palimpsest from a Siphon into a Blighter: "a page
      // scraped clean writes over you — that is a status, not a drink." A
      // lifesteal move anywhere here puts the drink back.
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
          reason: '$id is named by §4.7\'s tables and must exist',
        );
      }
    });

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the skip above would be hiding a real local failure.
      final mine = GlassArchiveItems.all.map((d) => d.id).toSet();
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
      for (final e in GlassArchiveBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...GlassArchiveBestiary.minis,
        ...GlassArchiveBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in GlassArchiveBestiary.commons) {
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
      final dropped = GlassArchiveBestiary.allDrops;
      for (final id in [
        'solar_dust',
        'solar_shard',
        'solar_crystal',
        'arcane_dust',
        'arcane_shard',
        'arcane_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      // ⚠️ Nothing from a third element — the off-element move is a MOVE, and
      // §2e.2 buys no third mote family with it.
      final foreign = <String>{
        for (final el in MagicElement.values)
          if (el != MagicElement.solar && el != MagicElement.arcane) ...[
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
      for (final e in GlassArchiveBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in GlassArchiveBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️ no boss carries a gate part — the Totem is CRAFTED', () {
      // §2e.1 puts `key` on both bosses of a gate zone, and the Celestial
      // gate's three essences fall in the quarter's three PURE zones (§3.4).
      // The Archive defines `celestial_totem` and must never drop it.
      for (final b in GlassArchiveBestiary.bosses) {
        for (final id in b.drops.possibleDrops) {
          expect(
            id,
            isNot(contains('essence')),
            reason: '${b.id} drops something that reads like a gate part',
          );
          expect(
            id,
            isNot('celestial_totem'),
            reason:
                '${b.id} hands over the gate item, which re-opens §3.4 and '
                'KINETIC §8.6 both',
          );
        }
      }
      for (final e in all) {
        expect(e.drops.possibleDrops, isNot(contains('celestial_totem')));
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in GlassArchiveBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_last_reading'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_last_reading'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('the_last_reading').rarity, Rarity.rare);
    });

    test(
      'the epic is boss-only, and it is the quarter\'s one deflect drop',
      () {
        final epics = GlassArchiveItems.all
            .where((d) => d.rarity == Rarity.epic)
            .map((d) => d.id)
            .toList();
        expect(epics, [
          'the_noon_hour',
        ], reason: '§4.7 authors exactly one epic');
        for (final id in epics) {
          for (final e in all) {
            if (!e.drops.possibleDrops.contains(id)) continue;
            expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
            expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
          }
        }
        // ⚠️ §2.1b — no other Celestial drop carries deflectAmount, and the 14
        // is what makes the worst legal level-60 assembly land on exactly 50.
        final hat = GlassArchiveItems.theNoonHour;
        expect(hat.modifiers.deflectAmount, 14);
        expect(hat.modifiers.deflectChance, 12);
      },
    );
  });

  group('the catalogue matches §4.7', () {
    test('11 defs, all resolvable under this zone', () {
      expect(GlassArchiveItems.all, hasLength(11), reason: '§7.1\'s count');
      for (final def in GlassArchiveItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⭐⭐ the Arcane mote family is DEFINED HERE, not in the Ethereal '
        'quarter', () {
      // §3.2 — the mote lives with the zone that first yields it, and the
      // Glass Archive (43–47) is seven levels below The Collapsed Academy.
      // ⚠️ The single most surprising fact in this file: a builder looking
      // for arcane_dust in the Ethereal quarter will not find it.
      for (final id in ['arcane_dust', 'arcane_shard', 'arcane_crystal']) {
        expect(
          ItemCatalogue.zoneOf(id),
          zone,
          reason: '$id moved out of the zone that first yields it',
        );
        final def = ItemCatalogue.byId(id);
        expect(def, isA<MoteDef>());
        expect((def as MoteDef).element, MagicElement.arcane);
      }
      // ✅ ECONOMY §14c: one value per TIER, uniform across every element.
      expect(GlassArchiveItems.arcaneDust.value, 2);
      expect(GlassArchiveItems.arcaneShard.value, 25);
      expect(GlassArchiveItems.arcaneCrystal.value, 150);
      // ⚠️ No Core, no Heart in this quarter (§3.2).
      expect(GlassArchiveItems.all.whereType<MoteDef>().map((m) => m.tier), {
        MoteTier.dust,
        MoteTier.shard,
        MoteTier.crystal,
      }, reason: 'a Core that buys nothing is noise, not a ladder rung');
    });

    test(
      'equip levels sit in the band; everything else sits at or below it',
      () {
        final loc = World.byId(zone);
        for (final def in GlassArchiveItems.all) {
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
        // ⚠️ §4.7 pins the belt at 45 specifically — the top of this band and
        // the floor of the Ethereal one, the last Celestial item a player wears.
        expect(GlassArchiveItems.palimpsestBelt.equipLevel, 45);
        expect(GlassArchiveItems.theNoonHour.equipLevel, 47);
      },
    );

    test('the crafted belt composes its name; the two uniques are written', () {
      // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
      // material+form grammar composes the name and cannot drift from it.
      expect(
        GlassArchiveItems.palimpsestBelt.properName,
        isNull,
        reason: 'a written name on crafted gear reintroduces the drift',
      );
      expect(GlassArchiveItems.palimpsestBelt.modifiers.beltSlots, 6);
      expect(GlassArchiveItems.theLastReading.properName, 'The Last Reading');
      expect(GlassArchiveItems.theNoonHour.properName, 'The Noon Hour');
    });

    test('the Totem is a bound, worthless, Rimeholt-gating Key', () {
      final totem = ItemCatalogue.byId('celestial_totem');
      expect(totem, isA<KeyDef>());
      expect((totem as KeyDef).gates, 'rimeholt');
      expect(totem.tradability, Tradability.bound);
      expect(totem.value, 0, reason: 'KeyDef forces it; §5.5 exempts it');
      expect(totem.rarity, Rarity.rare);
    });

    test('the Tonic is over-time, beltable, and worth less than it costs', () {
      final tonic = GlassArchiveItems.sunbleachTonic;
      expect(tonic, isA<Beltable>(), reason: 'a Tonic is drunk mid-duel');
      expect(tonic.effect.healPerTurn, 42);
      expect(tonic.effect.healTurns, 3);
      expect(
        tonic.effect.heal,
        0,
        reason: 'a Tonic is never a lump — that is what a Draught is (§3.3)',
      );
      expect(
        tonic.value,
        lessThan(3 * GlassArchiveItems.sunbleachLichen.value),
        reason: 'buy→craft→vendor must not profit (§5.5)',
      );
    });

    test('⚠️ palimpsest_vellum is a hide, so no node may ever yield it', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('palimpsest_vellum')),
        reason:
            'a palimpsest is a hide (§3.1); a node for it would be a second '
            'source that contradicts its own fiction',
      );
      // ⭐ It is the zone's `hide` drop role, and §3.5.1's second-material
      // fallback therefore does NOT apply here.
      for (final e in [
        GlassArchiveBestiary.palimpsest,
        GlassArchiveBestiary.readerless,
      ]) {
        expect(e.drops.possibleDrops, contains('palimpsest_vellum'));
      }
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('three nodes — and two of them are on the same material', () {
      // ⚠️ §6's one deliberate break of its own shape: the hybrid's third
      // material is a kill-only hide, and aetherglass is the one material
      // whose fiction supports two acts (annealed off a roof, or chosen out
      // of the noon writing).
      expect(nodes, hasLength(3));
      expect(nodes.map((n) => n.id).toSet(), {
        'ga_shadeline_lichen',
        'ga_roof_spoil',
        'ga_noon_shelf',
      });
      expect(
        nodes.where((n) => n.yieldsDefId == 'aetherglass'),
        hasLength(2),
        reason: 'the second glass node is the documented exception',
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
      expect(GatherNodes.gaShadelineLichen.skill, GatherSkill.foraging);
      expect(GatherNodes.gaRoofSpoil.skill, GatherSkill.mining);
      expect(GatherNodes.gaNoonShelf.skill, GatherSkill.mining);
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 93);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final aperture = GlassArchiveBestiary.aperture;
      final tyrant = GlassArchiveBestiary.whatWasWritten;
      expect(
        aperture.maxHpAt(47),
        (MageState.scaledMaxHp(47) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        aperture.maxHpAt(47),
        1335,
        reason: '§1.2\'s worked table, transcribed rather than invented',
      );
      expect(
        tyrant.maxHpAt(47),
        (MageState.scaledMaxHp(47) * Archetypes.tyrant.hpScale).round(),
      );
      expect(tyrant.maxHpAt(47), 1578);
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at 43. Anything that can open with a kill from full
      // health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(43);
      for (final e in GlassArchiveBestiary.commons) {
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
      for (final def in GlassArchiveItems.all) {
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
        // ⭐ Motes are deliberately one-line epigrams (§4.7's lore block —
        // *"Dust that made up its mind."*); everything else is a field note.
        if (def is MoteDef) continue;
        expect(def.lore.length, greaterThan(40), reason: '${def.id} lore thin');
      }
    });
  });
}
