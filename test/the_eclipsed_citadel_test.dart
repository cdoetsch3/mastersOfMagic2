/// The Eclipsed Citadel's roster LAWS (Lv 58–60, all twelve) and its catalogue
/// checks — ENEMIES §2e plus ETHEREAL_CONTRACT §4.8.
///
/// ⚠️ **`sanctus_*` (Hallowmarch), `umbra_*` (The Umbral Wastes),
/// `climbers_ration` (Hallowmarch) and `nightink_draught` (The Unwritten
/// Library) are owned by parallel Ethereal worktrees.** Everything this zone
/// DEFINES is asserted normally; the cross-lane ids are asserted in one
/// `skip:`ped test whose skip reason names the lanes, so the merge coordinator
/// has exactly one line to delete once they land together.
///
/// ⭐ **Two engine seams are exercised here and nowhere else**, because they
/// exist for this zone:
///
/// 1. `EnemyDef.isMage` + `EnemyDef.intelligenceOverride` — Procarius fields a
///    `Spellbook` loadout instead of a creature kit, so the move-count law is
///    exempted for him and replaced with "his loadout IS the persona's".
/// 2. `Bestiary.bossSequenceFor` + `AdventureRun.atFinalBoss` — the Citadel
///    fights both bosses in order and only banks the clear after the second.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/adventure.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/enemies/the_eclipsed_citadel.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_eclipsed_citadel_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ Ids this zone's tables name but a **sibling worktree** defines. Nothing
/// in this list may ever be an id the Citadel itself authors — that is what the
/// "no local id hides in here" test below proves.
const _parallelLaneIds = <String>{
  'sanctus_dust',
  'sanctus_shard',
  'sanctus_crystal',
  'umbra_dust',
  'umbra_shard',
  'umbra_crystal',
  'climbers_ration',
  'nightink_draught',
};

void main() {
  const zone = 'the_eclipsed_citadel';
  final all = EclipsedCitadelBestiary.all;
  final procarius = EclipsedCitadelBestiary.procariusTheEclipsed;
  final persona = AiRoster.byId('procarius');

  /// ⭐ Every law that talks about *creature kits* has to skip the mage — his
  /// moves are the player's own spellbook (§3.4). One helper, so a new law
  /// cannot forget.
  final creatures = all.where((e) => !e.isMage).toList();

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        EclipsedCitadelBestiary.commons,
        hasLength(5),
        reason:
            'ENEMIES §2e REVERSED its own proposal to abandon the template '
            'for the finale — the Citadel keeps 5/4/2 and carries the twelve '
            'inside it',
      );
      expect(EclipsedCitadelBestiary.minis, hasLength(4));
      expect(
        EclipsedCitadelBestiary.bosses,
        hasLength(2),
        reason: 'the COUNT of two is honoured; only the draw is not',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives — a bestiary left out
      // of `Bestiary.all` compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'EclipsedCitadelBestiary is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'forZone and the class list disagree about the roster',
      );
    });

    test('the four minis are one of each mini archetype', () {
      expect(EclipsedCitadelBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so a run can draw a mirror');
    });

    test('the five commons are the five archetypes §2e names', () {
      // ⚠️ Exactly one Adept — the yardstick — and no Drudge: §1.2 flags the
      // Drudge at this band as a wasted encounter slot, and the Citadel has
      // none to waste.
      expect(
        EclipsedCitadelBestiary.commons.map((e) => e.archetype.id).toList(),
        ['sentinel', 'blighter', 'bruiser', 'lasher', 'adept'],
      );
      expect(
        EclipsedCitadelBestiary.commons.where((e) => e.archetype.id == 'adept'),
        hasLength(1),
        reason: 'a zone has exactly one yardstick',
      );
    });

    test('the boss pair is the covering and the covered, NOT a mirror', () {
      // ⭐⭐ §2e: Totality is the body covering (mass — Juggernaut); Procarius
      // is the light covered (mind — Tyrant). Two masses or two minds would
      // make the sequence one fight played twice.
      expect(EclipsedCitadelBestiary.totality.archetype.id, 'juggernaut');
      expect(procarius.archetype.id, 'tyrant');
      expect(
        EclipsedCitadelBestiary.bosses.map((b) => b.archetype.id).toSet(),
        hasLength(2),
        reason: 'the sequence must be two different fights, not one twice',
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
      expect(all.map((e) => e.id).toSet(), hasLength(all.length));
      expect(all.map((e) => e.name).toSet(), hasLength(all.length));
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      // ⭐ Procarius is the interesting one: "Procarius, the Eclipsed" must
      // collapse the comma AND the space into a single underscore.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
      expect(procarius.id, 'procarius_the_eclipsed');
    });

    test('the per-creature element assignment matches §2e exactly', () {
      // ⭐ Hard-coded rather than derived: §2e spends the twelve a different
      // way at each rank, so there is no formula to check against — only the
      // table.
      expect(EclipsedCitadelBestiary.theHeldDoor.elements, [
        MagicElement.geo,
        MagicElement.flora,
      ]);
      expect(EclipsedCitadelBestiary.ashlight.elements, [
        MagicElement.pyro,
        MagicElement.umbra,
      ]);
      expect(EclipsedCitadelBestiary.theKeptWatch.elements, [
        MagicElement.sanctus,
        MagicElement.solar,
      ]);
      expect(EclipsedCitadelBestiary.nightcurrent.elements, [
        MagicElement.lunar,
        MagicElement.electro,
      ]);
      expect(EclipsedCitadelBestiary.theLastApplicant.elements, [
        MagicElement.aqua,
        MagicElement.aero,
        MagicElement.astral,
        MagicElement.arcane,
      ]);
      expect(EclipsedCitadelBestiary.theBasin.elements, [
        MagicElement.flora,
        MagicElement.aqua,
        MagicElement.pyro,
      ]);
      expect(EclipsedCitadelBestiary.theRange.elements, [
        MagicElement.geo,
        MagicElement.electro,
        MagicElement.aero,
      ]);
      expect(EclipsedCitadelBestiary.theShelf.elements, [
        MagicElement.solar,
        MagicElement.lunar,
        MagicElement.astral,
      ]);
      expect(EclipsedCitadelBestiary.theClimb.elements, [
        MagicElement.sanctus,
        MagicElement.umbra,
        MagicElement.arcane,
      ]);
      expect(
        EclipsedCitadelBestiary.totality.elements,
        MagicElement.values,
        reason: 'the Juggernaut IS the "all twelve at once" statement',
      );
      expect(procarius.elements, [
        MagicElement.arcane,
        MagicElement.umbra,
        MagicElement.lunar,
        MagicElement.electro,
        MagicElement.pyro,
      ]);
    });

    test('⭐⭐ each rank spends the twelve exactly once', () {
      // ⚠️ THE structural law of this zone, and the reason §2e withdrew its
      // own proposal to abandon the template. A mutant that duplicates one
      // element and drops another still compiles, still looks plausible, and
      // silently costs the Citadel the only thing that makes it the finale.
      const twelve = MagicElement.values;

      final commons = [
        for (final e in EclipsedCitadelBestiary.commons) ...e.elements,
      ];
      expect(
        commons.toSet(),
        twelve.toSet(),
        reason:
            'the commons must walk the macro-tier loop once — four edges of '
            'two, plus the Adept\'s one-from-each-tier remainder',
      );
      expect(
        commons,
        hasLength(12),
        reason: 'an element appears twice across the commons',
      );

      final minis = [
        for (final e in EclipsedCitadelBestiary.minis) ...e.elements,
      ];
      expect(
        minis.toSet(),
        twelve.toSet(),
        reason: 'the four minis are the four quarters, three elements each',
      );
      expect(minis, hasLength(12));
      for (final m in EclipsedCitadelBestiary.minis) {
        expect(
          m.elements.map((e) => e.tier).toSet(),
          hasLength(1),
          reason: '${m.id} mixes quarters; a mini IS one quarter',
        );
      }

      // ⭐ The bosses are the third twelve, carried by ONE of them.
      expect(EclipsedCitadelBestiary.totality.elements, hasLength(12));
    });

    test('⚠️ the zone has no off-element creature, because it cannot', () {
      // §2e.2 licenses at most one off-element creature per zone. The Citadel
      // fields all twelve, so "off-element" is not a thing that exists here —
      // and a test that says so out loud stops a builder importing the
      // Archive's exception into the one zone where it is meaningless.
      for (final e in all) {
        for (final el in e.elements) {
          expect(
            MagicElement.values,
            contains(el),
            reason: '${e.id} carries something outside the twelve',
          );
        }
      }
    });

    test('the anchor name is the BOSS, which no other zone does', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor points at a creature that is not here',
      );
      // ⭐ §2e: "the map names the Citadel after the man, not after a common."
      expect(
        World.opponentNameFor(World.byId(zone)),
        procarius.name,
        reason: 'the anchor moved off the game\'s named antagonist',
      );
    });

    test('the zone band is 58–60, a dungeon, all twelve', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 58);
      expect(loc.maxLevel, 60);
      expect(loc.kind, LocationKind.dungeon, reason: '🏰 in ENEMIES §2e');
      expect(loc.elements, MagicElement.values);
      expect(loc.tier, MagicTier.ethereal);
    });
  });

  group('combat stats match ETHEREAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        EclipsedCitadelBestiary.theLastApplicant.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel hides behind a deflection', () {
      expect(
        EclipsedCitadelBestiary.theHeldDoor.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        EclipsedCitadelBestiary.ashlight.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
      );
    });

    test('the Bruiser is telegraphed, inaccurate and heavy', () {
      expect(
        EclipsedCitadelBestiary.theKeptWatch.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
      );
    });

    test('the Lasher trades crit damage for crit frequency', () {
      expect(
        EclipsedCitadelBestiary.nightcurrent.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        EclipsedCitadelBestiary.theBasin.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        EclipsedCitadelBestiary.theRange.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        EclipsedCitadelBestiary.theShelf.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        EclipsedCitadelBestiary.theClimb.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut deflects hard and rarely', () {
      expect(
        EclipsedCitadelBestiary.totality.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('the Tyrant carries a little of everything', () {
      // ⚠️ Procarius takes the archetype's STAT BLOCK even though he overrides
      // its intelligence and its move count — the two exceptions §2e names are
      // the only two.
      expect(
        procarius.combatStats,
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
          reason: '${e.id} — slippery, never unhittable',
        );
      }
    });

    test('no inert stat: an amount never appears without its chance', () {
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

  group('⭐⭐ Procarius is a MAGE — the §3.4 exemption', () {
    test('he is the zone\'s only mage, and the flag is what says so', () {
      expect(
        all.where((e) => e.isMage).map((e) => e.id),
        ['procarius_the_eclipsed'],
        reason:
            'the creatures act and the mage casts (§3.3a) — a second mage '
            'here would make that split a coincidence',
      );
      expect(
        procarius.isMage,
        isTrue,
        reason:
            'without the flag every zone suite in the game applies the '
            'move-count law to him',
      );
    });

    test('his loadout IS the persona\'s, spell for spell', () {
      // ⭐⭐ The whole point of the exemption. §2e: "ai_personas.dart is canon
      // for him and the roster honours it verbatim." The EnemyDef writes the
      // ten spells out (a const EnemyDef cannot reach a non-const Loadout), so
      // THIS is the assertion that keeps the copy from drifting.
      expect(
        procarius.moves.map((s) => s.id).toList(),
        persona.loadout.spells.map((s) => s.id).toList(),
        reason:
            'the roster and ai_personas.dart disagree about Procarius\'s '
            'spellbook — the persona is the older, shipped record and wins',
      );
      expect(procarius.moves, hasLength(10));
      expect(procarius.moves.map((s) => s.id).toSet(), {
        'jolt',
        'blast',
        'ruin',
        'cataclysm',
        'barrage',
        'drain',
        'sanctuary',
        'barrier',
        'overload',
        'discharge',
      });
      expect(
        procarius.elements,
        persona.loadout.elements,
        reason: 'his elements are the persona\'s five, in the persona\'s order',
      );
    });

    test('the loadout is level-legal, and he is the game\'s only L60', () {
      expect(persona.level, 60);
      expect(
        persona.level,
        World.byId(zone).maxLevel,
        reason: 'the only persona above the player cap, in this zone\'s band',
      );
      expect(
        procarius.moves.length,
        lessThanOrEqualTo(Loadout.maxSpellSlots),
        reason: 'a mage cannot bring more spells than a loadout holds',
      );
      // ⭐ Ethereal magic unlocks at 45 and every element he owns is legal at
      // 60 — spelled out because "level-legal" is the clause the exemption
      // trades the move-count law for.
      for (final el in procarius.elements) {
        expect(
          MagicTier.values,
          contains(el.tier),
          reason: '${el.name} sits outside the four tiers',
        );
      }
    });

    test('⚠️ intelligence 10 overrides the Tyrant\'s 9, and reaches the AI', () {
      // ⭐ §2e's first deliberate exception: "a finale antagonist demoted by a
      // table is a bug, not a balance decision." Three assertions, because the
      // field, the getter and the encounter adapter are three separate places
      // a mutant can drop the override on the floor.
      expect(Archetypes.tyrant.intelligence, 9);
      expect(procarius.intelligenceOverride, 10);
      expect(
        procarius.intelligence,
        10,
        reason: 'EnemyDef.intelligence is not reading the override',
      );
      expect(
        persona.intelligence,
        10,
        reason: 'the override must equal the persona it exists to honour',
      );
      expect(
        EnemyEncounter(def: procarius, level: 60).toPersona().intelligence,
        10,
        reason:
            'enemy_encounter.dart is still reading '
            'def.archetype.intelligence, so he fights at 9',
      );
    });

    test('⭐ every OTHER creature in the game takes its archetype\'s rung', () {
      // ⚠️ The override is an exception; a second one anywhere would make it a
      // pattern, and nothing else in the game is a shipped persona.
      for (final e in Bestiary.all) {
        if (identical(e, procarius)) continue;
        expect(
          e.intelligenceOverride,
          isNull,
          reason: '${e.id} overrides its archetype\'s intelligence',
        );
        expect(e.intelligence, e.archetype.intelligence);
      }
    });

    test('he is exempt from the move-count law, and visibly so', () {
      // ⚠️ Stated as an inequality rather than skipped silently: if a future
      // edit ever made his loadout three spells long, the exemption would stop
      // being load-bearing and this test would say so.
      expect(Archetypes.tyrant.moveCount, 3);
      expect(
        procarius.moves.length,
        isNot(Archetypes.tyrant.moveCount),
        reason:
            'the exemption is only justified while a loadout and a creature '
            'kit are genuinely different shapes',
      );
    });
  });

  group('⭐⭐ the two-stage boss is a SEQUENCE, not a pool', () {
    test('the sequence is Totality then Procarius, and both resolve', () {
      expect(
        EclipsedCitadelBestiary.bossSequence,
        ['totality', 'procarius_the_eclipsed'],
        reason: 'the order IS the zone\'s name: the covering, then the covered',
      );
      for (final id in EclipsedCitadelBestiary.bossSequence) {
        final def = Bestiary.byId(id);
        expect(def, isNotNull, reason: '$id names no creature');
        expect(
          def!.rank,
          EnemyRank.boss,
          reason: '$id is in the sequence but is not a boss',
        );
      }
      expect(
        EclipsedCitadelBestiary.bossSequence.toSet(),
        EclipsedCitadelBestiary.bosses.map((b) => b.id).toSet(),
        reason: 'the sequence and the boss list are different rosters',
      );
    });

    test('Bestiary.bossSequenceFor answers for this zone and NO other', () {
      expect(Bestiary.bossSequenceFor(zone), [
        'totality',
        'procarius_the_eclipsed',
      ]);
      for (final loc in World.locations) {
        if (loc.id == zone) continue;
        expect(
          Bestiary.bossSequenceFor(loc.id),
          isEmpty,
          reason:
              '${loc.id} has a boss sequence, which deletes the one-of-two '
              'draw that makes a zone worth running twice (§3d)',
        );
      }
      expect(
        Bestiary.bossSequenceFor('a_zone_that_does_not_exist'),
        isEmpty,
        reason: 'an unknown zone must answer empty, never throw',
      );
    });

    test('a Citadel run lines up BOTH bosses, in order, at the end', () {
      for (var seed = 0; seed < 20; seed++) {
        final run = AdventureRun.roll(
          zone: World.byId(zone),
          roster: Bestiary.forZone(zone),
          playerHp: 100,
          rng: Random(seed),
        );
        final bossLine = run.encounters
            .where((e) => e.def.rank == EnemyRank.boss)
            .map((e) => e.def.id)
            .toList();
        expect(bossLine, [
          'totality',
          'procarius_the_eclipsed',
        ], reason: 'seed $seed drew a boss instead of running the sequence');
        expect(
          run.encounters.last.def.id,
          'procarius_the_eclipsed',
          reason: 'seed $seed does not END on the named antagonist',
        );
        // ⚠️ Elevated ranks fight at the top of the band, sequence included.
        for (final e in run.encounters) {
          if (e.def.rank == EnemyRank.common) continue;
          expect(e.level, 60, reason: 'seed $seed: ${e.def.id} is off-band');
        }
      }
    });

    test('the clear is banked ONLY after the second boss falls', () {
      final run = AdventureRun.roll(
        zone: World.byId(zone),
        roster: Bestiary.forZone(zone),
        playerHp: 100,
        rng: Random(4),
      );
      var sawTotality = false;
      while (!run.isOver && !run.isFinished) {
        final id = run.current!.def.id;
        if (id == 'totality') {
          sawTotality = true;
          expect(
            run.atBoss,
            isTrue,
            reason: 'Totality is a boss fight and must read as one',
          );
          expect(
            run.atFinalBoss,
            isFalse,
            reason:
                'atFinalBoss on Totality banks the zone clear and leaves '
                'Procarius standing in a run that already ended',
          );
        }
        if (id == 'procarius_the_eclipsed') {
          expect(
            sawTotality,
            isTrue,
            reason: 'Procarius was reached without fighting the Citadel first',
          );
          expect(run.atFinalBoss, isTrue);
        }
        run.recordVictory(
          loot: const [],
          instances: const {},
          remainingHp: 100,
        );
        if (id == 'totality') {
          expect(
            run.outcome,
            RunOutcome.running,
            reason: 'beating the covering ended the run',
          );
          expect(run.current?.def.id, 'procarius_the_eclipsed');
        }
      }
      expect(
        run.outcome,
        RunOutcome.cleared,
        reason: 'the sequence completed and the zone did not count as cleared',
      );
    });

    test('⚠️ every other zone still draws exactly ONE boss', () {
      // ⭐ The byte-identical-behaviour promise. Checked across every zone with
      // a roster, not just one, because the seam lives in shared code.
      for (final loc in World.locations) {
        final roster = Bestiary.forZone(loc.id);
        if (roster.where((e) => e.rank == EnemyRank.boss).length != 2) continue;
        if (loc.id == zone) continue;
        for (var seed = 0; seed < 5; seed++) {
          final run = AdventureRun.roll(
            zone: loc,
            roster: roster,
            playerHp: 100,
            rng: Random(seed),
          );
          final bosses = run.encounters.where(
            (e) => e.def.rank == EnemyRank.boss,
          );
          expect(
            bosses,
            hasLength(1),
            reason: '${loc.id} seed $seed now fights more than one boss',
          );
          expect(
            run.atFinalBoss,
            isFalse,
            reason: '${loc.id} opens on its boss',
          );
        }
      }
    });
  });

  group('creatures are creatures (and one of them is not)', () {
    test('no CREATURE move borrows an id from the player Spellbook', () {
      // ⚠️ ENEMIES §3 — a boar does not cast Bolt. ⭐ Procarius is excluded
      // because borrowing the Spellbook is precisely what he does.
      final spellIds = Spellbook.all.map((s) => s.id).toSet();
      for (final e in creatures) {
        for (final m in e.moves) {
          expect(
            spellIds.contains(m.id),
            isFalse,
            reason: '${e.id}\'s "${m.name}" reuses a Spellbook id',
          );
        }
      }
      // …and the mage's are ALL Spellbook ids, which is the other half.
      for (final m in procarius.moves) {
        expect(spellIds, contains(m.id));
      }
    });

    test('move ids are unique across the WHOLE bestiary, and all ec_', () {
      final mine = [for (final e in creatures) ...e.moves.map((m) => m.id)];
      expect(mine.toSet(), hasLength(mine.length), reason: 'duplicate in-zone');
      for (final id in mine) {
        expect(id.startsWith('ec_'), isTrue, reason: '$id is not zone-tagged');
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
        reason: 'an ec_ move id collides with another zone\'s',
      );
    });

    test('no move name collides with the game\'s own vocabulary', () {
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      for (final e in creatures) {
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
      // the moves. ⚠️ **Mages are exempt** (§3.4): a loadout is not a kit, and
      // the exemption is tested on its own above.
      for (final e in creatures) {
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
      // ⚠️ §1.1/§1.3's double-scaling trap, and §1.3 warns this zone by name:
      // "its authors will be tempted to give it bigger raws to feel final. It
      // does not need them." The engine scales by LEVEL; the table does not
      // grow.
      for (final e in creatures) {
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

    test('the Lasher arrives in pieces, never in one', () {
      // ⚠️ §1.3's per-archetype rule — it is the whole of why a Lasher reads
      // differently from a plain attacker: each strand meets the wall alone,
      // which is the "a big shield is not always the answer" lesson.
      for (final m in EclipsedCitadelBestiary.nightcurrent.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '"${m.name}" arrives in one piece',
        );
      }
    });

    test('⭐ the Blighter is the game\'s first creature DoT', () {
      // ⭐⭐ §2e: the only creature in the game stacking Ignite and Creeping
      // Dark together. Both moves carry the burn, and both carry the SAME
      // burn — two dot ids would be two statuses, not one creature.
      final ashlight = EclipsedCitadelBestiary.ashlight;
      for (final m in ashlight.moves) {
        expect(
          m.effect,
          isA<DotAttackEffect>(),
          reason: '"${m.name}" is a plain hit; the burn is the payload',
        );
        final dot = m.effect as DotAttackEffect;
        expect(dot.dotId, 'ec_afterburn');
        expect(dot.dotName, 'Afterburn');
        expect(dot.ticks, greaterThan(0));
        expect(dot.damagePerTick, greaterThan(0));
      }
      expect(
        ashlight.elements,
        containsAll([MagicElement.pyro, MagicElement.umbra]),
        reason: 'Ignite is pyro and Creeping Dark is umbra; it needs both',
      );
    });

    test('the wall archetypes actually carry a wall', () {
      for (final e in creatures) {
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
      // ⚠️ The priority ladder's one hard "never": a shield at 9 goes up after
      // everything it was meant to stop.
      for (final e in creatures) {
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
      final climb = EclipsedCitadelBestiary.theClimb;
      expect(climb.archetype.id, 'hexer');
      expect(
        climb.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        SpellPriority.instant,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        climb.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: '"Nothing You Brought Is Enough" no longer goes through a wall',
      );
    });

    test('⚠️ the Executioner\'s cost cap stays lowered to 4', () {
      // §1.3, and it contradicts §2e's own kit sketch (which writes cost 5).
      // At L60 a mini five-charge raw lands 884–1153 against a 1,012 HP bar:
      // not a two-cast kill, a one-shot with change. Kills the mutant that
      // restores the archetype's own maxMoveCost of 5.
      final shelf = EclipsedCitadelBestiary.theShelf;
      expect(shelf.archetype.id, 'executioner');
      expect(Archetypes.executioner.maxMoveCost, 5);
      for (final m in shelf.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" reaches cost ${m.chargeCost}',
        );
      }
      expect(
        shelf.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).executeBelowPercent > 0,
        ),
        isTrue,
        reason: 'the Shelf without its drop is just a hard hit',
      );
    });

    test(
      'exactly one move in the zone lifesteals, and it is the Redoubt\'s',
      () {
        // ⭐ "Grind It Out" is attrition said in one move: the wall that heals is
        // what makes the Kinetic quarter's weight a fight rather than a wait.
        final stealers = [
          for (final e in creatures)
            for (final m in e.moves)
              if (m.effect is DamageEffect &&
                  (m.effect as DamageEffect).lifesteal > 0)
                '${e.id}/${m.id}',
        ];
        expect(stealers, ['the_range/ec_grinditout']);
      },
    );

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
          reason: '$id is named by §4.8\'s tables and must exist',
        );
      }
    });

    test('⚠️ no id in the cross-lane list is one this zone authors', () {
      // Otherwise the skip above would be hiding a real local failure.
      final mine = EclipsedCitadelItems.all.map((d) => d.id).toSet();
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
      for (final e in EclipsedCitadelBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...EclipsedCitadelBestiary.minis,
        ...EclipsedCitadelBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in EclipsedCitadelBestiary.commons) {
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

    test('⭐⭐ every common pays in ALL TWELVE mote families, at 0.12', () {
      // §3.5.2 and §8.4's chosen option: twelve rows, not a DropEntry.oneOf.
      // ⚠️ The single most distinctive fact about this zone's loot, and a
      // mutant that drops one family still compiles and still looks fine in a
      // loot log. ~1.4 dusts a kill across a random spread.
      for (final e in EclipsedCitadelBestiary.commons) {
        final dusts = e.drops.always
            .where((d) => d.defId!.endsWith('_dust'))
            .toList();
        expect(dusts.map((d) => d.defId).toSet(), {
          for (final el in MagicElement.values) '${el.name}_dust',
        }, reason: '${e.id} does not pay in all twelve');
        for (final d in dusts) {
          expect(d.chance, 0.12, reason: '${e.id}/${d.defId} is off-rate');
          expect(d.min, 1);
          expect(d.max, 2);
        }
      }
    });

    test('the zone defines no mote family of its own', () {
      // ⭐ §3.5.2 — "no mote family, and the drop tables pay in all twelve."
      expect(
        EclipsedCitadelItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'a citadel_dust would make "all twelve" thirteen',
      );
    });

    test('the mote ladder climbs with rank', () {
      for (final e in EclipsedCitadelBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_shard')),
          isEmpty,
          reason: '${e.id} hands out Shard',
        );
      }
      for (final m in EclipsedCitadelBestiary.minis) {
        expect(
          m.drops.always.where((d) => d.defId!.endsWith('_shard')),
          hasLength(2),
          reason: '${m.id} does not pay §4.8\'s two shards',
        );
        expect(
          m.drops.always.where((d) => d.defId!.endsWith('_crystal')),
          hasLength(1),
          reason: '${m.id} does not pay one matching crystal',
        );
      }
      for (final b in EclipsedCitadelBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId!.endsWith('_crystal')),
          hasLength(3),
          reason:
              '${b.id} does not guarantee three Crystals — the richest '
              'always-line in the game (§4.8)',
        );
      }
    });

    test('⭐ a mini pays in what it is MADE of', () {
      // "Any 2 of the twelve" (§4.8) is resolved as the first two of the
      // mini's own three elements, so the four minis between them cover eight
      // distinct families instead of rolling the same two every run.
      for (final m in EclipsedCitadelBestiary.minis) {
        final own = m.elements.map((e) => e.name).toSet();
        for (final d in m.drops.always) {
          final family = d.defId!.split('_').first;
          expect(
            own,
            contains(family),
            reason: '${m.id} pays $family, which it is not made of',
          );
        }
      }
      final families = <String>{
        for (final m in EclipsedCitadelBestiary.minis)
          for (final d in m.drops.always) d.defId!.split('_').first,
      };
      expect(
        families,
        hasLength(8),
        reason: 'two minis pay the same family; §4.8 wants the spread',
      );
    });

    test('⚠️ no key drops here, and no gate item', () {
      // 📝 §3.5.2: Procarius's `key` role is the Concordant Crown FRAME, which
      // has no item yet (§3.4a — the Crown is blocked on Core/Heart motes), so
      // this lane drops nothing for it. ⚠️ §4.8: "No gate item drops here" —
      // the Citadel is the gate's destination.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          final def = ItemCatalogue.tryById(id);
          expect(def, isNot(isA<KeyDef>()), reason: '${e.id} drops a key');
          expect(
            id,
            isNot(contains('fragment')),
            reason: '${e.id} drops something that reads like a gate part',
          );
          expect(id, isNot(contains('crown')));
        }
      }
      expect(
        EclipsedCitadelItems.all.whereType<KeyDef>(),
        isEmpty,
        reason:
            'the Crown frame cannot be authored until Core/Heart motes ship',
      );
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in EclipsedCitadelBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_eclipsed_band'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_eclipsed_band'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('the_eclipsed_band').rarity, Rarity.rare);
    });

    test('⭐ TWO epics, boss-only, and one clear in five pays one', () {
      // §4.8's third ruling: every other zone in four quarters gets one epic;
      // the Citadel gets two because its two materials are each the headline
      // of one. 📝 20 combined weight is deliberate and is the knob.
      final epics = EclipsedCitadelItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id)
          .toList();
      expect(epics, [
        'the_last_thing_in_the_way',
        'the_corona',
      ], reason: '§4.8 authors exactly two epics — offence and defence');
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.10));
        }
      }
      for (final b in EclipsedCitadelBestiary.bosses) {
        final combined = epics
            .map(b.drops.mainChanceOf)
            .reduce((a, x) => a + x);
        expect(
          combined,
          closeTo(0.20, 1e-9),
          reason: '${b.id} no longer pays an epic one clear in five',
        );
      }
    });
  });

  group('the catalogue matches §4.8', () {
    test('7 defs, all resolvable under this zone', () {
      expect(EclipsedCitadelItems.all, hasLength(7), reason: '§4.8\'s count');
      for (final def in EclipsedCitadelItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⚠️ two materials, both kill-only, and the zone has NO node', () {
      // ⭐⭐ §3.1's ruling: the Citadel is not ground, so ruling 7's "hybrid
      // gets three" does not apply and neither does a seam to work. This is
      // the only zone in the game with a material and no node at all.
      final materials = EclipsedCitadelItems.all.whereType<MaterialDef>();
      expect(materials.map((m) => m.id).toList(), [
        'eclipse_iron',
        'corona_pearl',
      ]);
      for (final m in materials) {
        expect(
          m.skill,
          CraftSkill.jewelry,
          reason: '${m.id} feeds the wrong ledger',
        );
        expect(m.tier, 10);
        expect(m.rarity, Rarity.uncommon, reason: '${m.id} is gem-grade');
        expect(
          GatherNodes.all.map((n) => n.yieldsDefId),
          isNot(contains(m.id)),
          reason:
              '${m.id} has a gather node — nothing grows on an obstruction, '
              'and a node would be a second source contradicting its fiction',
        );
      }
      expect(
        GatherNodes.forZone(zone),
        isEmpty,
        reason: '§6 gives the Citadel zero nodes; §1.6 depends on it',
      );
    });

    test('⭐ the drop ROLES land on the two materials (§3.5.2)', () {
      // `material` → eclipse_iron, `hide` → corona_pearl, and both on the one
      // shared common pool §4.8 authors for the whole zone.
      for (final e in EclipsedCitadelBestiary.commons) {
        expect(
          e.drops.possibleDrops,
          containsAll(['eclipse_iron', 'corona_pearl']),
          reason: '${e.id} is missing one of the zone\'s two roles',
        );
      }
    });

    test(
      'equip levels sit in the band; everything else sits at or below it',
      () {
        final loc = World.byId(zone);
        for (final def in EclipsedCitadelItems.all) {
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
                  '${def.id} is a material and must be usable the moment it '
                  'drops',
            );
          }
        }
      },
    );

    test('⭐ the game\'s only three equipLevel-60 items are here', () {
      final atCap = EclipsedCitadelItems.all
          .whereType<EquipmentDef>()
          .where((d) => d.equipLevel == 60)
          .map((d) => d.id)
          .toList();
      expect(atCap, [
        'eclipse_ring',
        'the_last_thing_in_the_way',
        'the_corona',
      ], reason: 'everything else a L60 mage wears was found lower down');
      final elsewhere = ItemCatalogue.all
          .whereType<EquipmentDef>()
          .where(
            (d) => d.equipLevel == 60 && ItemCatalogue.zoneOf(d.id) != zone,
          )
          .map((d) => d.id);
      expect(
        elsewhere,
        isEmpty,
        reason: 'another zone now requires the cap itself',
      );
    });

    test(
      'the crafted two compose their names; the three uniques are written',
      () {
        // ⚠️ ITEMS §9b.5a — crafted equipment must leave properName null so the
        // material+form grammar composes the name and cannot drift from it. ⭐
        // corona_torc and eclipse_ring are the only two pieces here that appear
        // on no drop table, which is what makes them the crafted ones.
        for (final def in [
          EclipsedCitadelItems.coronaTorc,
          EclipsedCitadelItems.eclipseRing,
        ]) {
          expect(
            def.properName,
            isNull,
            reason:
                '${def.id} is crafted; a written name reintroduces the drift',
          );
          expect(
            EclipsedCitadelBestiary.allDrops,
            isNot(contains(def.id)),
            reason: '${def.id} is crafted and must not also drop',
          );
        }
        expect(
          EclipsedCitadelItems.theEclipsedBand.properName,
          'The Eclipsed Band',
        );
        expect(
          EclipsedCitadelItems.theLastThingInTheWay.properName,
          'The Last Thing in the Way',
        );
        expect(EclipsedCitadelItems.theCorona.properName, 'The Corona');
        for (final def in [
          EclipsedCitadelItems.theEclipsedBand,
          EclipsedCitadelItems.theLastThingInTheWay,
          EclipsedCitadelItems.theCorona,
        ]) {
          expect(
            def.tradability,
            Tradability.untradeable,
            reason: '${def.id} is a chase and must stay off the market',
          );
        }
      },
    );

    test('⚠️⚠️ the_corona\'s deflectAmount is 14, and 14 is a proof', () {
      // §2.1b: `unleft_gloves` 26 + a deflect hat 14 + `bedrock_greaves` 10 =
      // exactly 50, which is ITEMS §4.1a's player cap. Raising this by one
      // breaks a design invariant thirty levels away.
      final hat = EclipsedCitadelItems.theCorona;
      expect(hat.modifiers.deflectAmount, 14);
      expect(hat.modifiers.deflectChance, 16);
      expect(26 + hat.modifiers.deflectAmount + 10, 50);
    });

    test('⭐ the two epics are a real choice, not a ladder', () {
      // §4.8: one is the whole offensive budget of the fight, the other the
      // whole defensive one, and they occupy different slots.
      final offence = EclipsedCitadelItems.theLastThingInTheWay;
      final defence = EclipsedCitadelItems.theCorona;
      expect(offence.slot, EquipSlot.gloves);
      expect(defence.slot, EquipSlot.hat);
      expect(offence.slot, isNot(defence.slot));
      expect(offence.modifiers.damagePerCast, 14);
      expect(offence.modifiers.maxHpBonus, 0, reason: 'offence pays no HP');
      expect(defence.modifiers.maxHpBonus, 70);
      expect(
        defence.modifiers.damagePerCast,
        0,
        reason: 'defence pays no damage',
      );
    });

    test('⭐ the Jewelry ladder ends on two Commons that carry no modifier', () {
      // ITEMS §9b.6a's lattice at its clearest: maxed flat stats, and
      // structurally unable to carry a modifier (§8).
      for (final def in [
        EclipsedCitadelItems.coronaTorc,
        EclipsedCitadelItems.eclipseRing,
      ]) {
        expect(def.rarity, Rarity.common, reason: '${def.id} climbed a rung');
        expect(def.modifiers.beltSlots, 0);
        expect(def.modifiers.regrowPercent, 0);
        expect(def.modifiers.healingReceivedPercent, 0);
        expect(def.modifiers.shieldStrengthPercent, 0);
      }
    });

    test('values are §4.8\'s, verbatim', () {
      expect(EclipsedCitadelItems.eclipseIron.value, 1000);
      expect(EclipsedCitadelItems.coronaPearl.value, 900);
      expect(EclipsedCitadelItems.coronaTorc.value, 3400);
      expect(EclipsedCitadelItems.eclipseRing.value, 3950);
      expect(EclipsedCitadelItems.theEclipsedBand.value, 7800);
      expect(EclipsedCitadelItems.theLastThingInTheWay.value, 22000);
      expect(EclipsedCitadelItems.theCorona.value, 24000);
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final totality = EclipsedCitadelBestiary.totality;
      expect(
        totality.maxHpAt(60),
        (MageState.scaledMaxHp(60) * Archetypes.juggernaut.hpScale).round(),
        reason: 'a second HP curve has crept in',
      );
      expect(
        totality.maxHpAt(60),
        3643,
        reason: '§1.2\'s worked table, transcribed rather than invented',
      );
      expect(
        procarius.maxHpAt(60),
        2631,
        reason: '§1.2\'s Tyrant row at the cap',
      );
      expect(
        EclipsedCitadelBestiary.theRange.maxHpAt(60),
        2226,
        reason: '§1.2\'s Redoubt row — the game\'s third-largest number',
      );
    });

    test('no common one-shots a character who just walked in', () {
      final startingHp = MageState.scaledMaxHp(58);
      for (final e in EclipsedCitadelBestiary.commons) {
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
      for (final def in EclipsedCitadelItems.all) {
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
      }
    });
  });
}
