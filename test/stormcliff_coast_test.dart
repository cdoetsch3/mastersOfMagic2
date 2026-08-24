import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/stormcliff_coast.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/stormcliff_coast_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'stormcliff_coast';
  final all = StormcliffCoastBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(StormcliffCoastBestiary.commons, hasLength(5));
      expect(StormcliffCoastBestiary.minis, hasLength(4));
      expect(StormcliffCoastBestiary.bosses, hasLength(2));
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (KINETIC_CONTRACT
      // §7.1) — an unlisted zone compiles fine and never appears.
      expect(Bestiary.forZone(zone), hasLength(11));
      expect(Bestiary.forZone(zone).toSet(), all.toSet());
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(StormcliffCoastBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('the boss pair is the mind/element pair the contract names', () {
      // ⭐⭐ KINETIC_CONTRACT §4.2: Storm Lord is what comes DOWN (a mind —
      // Tyrant), The Return Stroke is what goes back UP (the element itself,
      // taken to an extreme — Aspect).
      expect(StormcliffCoastBestiary.stormLord.archetype.id, 'tyrant');
      expect(StormcliffCoastBestiary.theReturnStroke.archetype.id, 'aspect');
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
      // An id that drifts from its name is a rename nobody notices.
      for (final e in all) {
        final derived = e.name
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z0-9]+"), '_');
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('everything belongs to a real zone, and uses that zone element', () {
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(
          e.elements,
          [MagicElement.electro],
          reason: '${e.id} — a pure zone means one element (ENEMIES §2h)',
        );
        expect(loc.elements, contains(e.elements.single));
      }
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
      );
      // ✅ KINETIC_CONTRACT §4.2 — the anchor is specifically the Adept, the
      // only one this quarter.
      expect(
        StormcliffCoastBestiary.stormcliffTidecaller.archetype.id,
        'adept',
      );
    });

    test('the zone band is 17–22, and nothing else', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 17);
      expect(loc.maxLevel, 22);
    });
  });

  group('combat stats match KINETIC_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present in this zone is checked
    // against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        StormcliffCoastBestiary.stormcliffTidecaller.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel reads as "everything lands softer"', () {
      expect(
        StormcliffCoastBestiary.fulguriteCrawler.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        StormcliffCoastBestiary.sparkwing.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Lasher stings, and its sting is deliberately weak', () {
      // ⭐ §2.3: negative crit damage on purpose — the surprise is that it
      // lands at all, never that it hurts.
      expect(
        StormcliffCoastBestiary.staticShoal.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('the Skirmisher is hard to pin, always first', () {
      expect(
        StormcliffCoastBestiary.groundling.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        StormcliffCoastBestiary.brinecharge.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        StormcliffCoastBestiary.theLongLine.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        StormcliffCoastBestiary.voltgeist.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        StormcliffCoastBestiary.stormShaman.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Tyrant has no weakness to exploit', () {
      expect(
        StormcliffCoastBestiary.stormLord.combatStats,
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

    test('the Aspect leans on Electro\'s own affinity — crit', () {
      // ⭐ §2.4: Electro's affinity is crit chance, so the Aspect is one
      // enormous flash — a stronger crit block than even the Tyrant's.
      expect(
        StormcliffCoastBestiary.theReturnStroke.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, critChance: 25, critDamage: 45),
      );
    });

    test('enemy dodge never exceeds the §2.3 cap of 10', () {
      for (final e in all) {
        expect(
          e.combatStats.dodge,
          lessThanOrEqualTo(10),
          reason: '${e.id} — enemy dodge should read as slippery, never '
              'unhittable',
        );
      }
    });

    test('crit damage and deflect amount never appear without their chance',
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

    test('move ids are unique across the whole zone, and all prefixed', () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (KINETIC_CONTRACT §3.4/§7.1).
      for (final id in ids) {
        expect(id.startsWith('sc_'), isTrue, reason: '$id is not zone-tagged');
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
      // ⚠️ KINETIC_CONTRACT §1.1/§1.3's double-scaling trap. The engine
      // already scales damage by level, so this zone's 17–22 band arrives via
      // the ENCOUNTER LEVEL, never bigger raws.
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

    test('the Skirmisher and the Hexer\'s cheapest move act in the quick '
        'band', () {
      // ⭐ ENEMIES §2.5 — tempo is expressed in PRIORITY, not in prose.
      final groundling = StormcliffCoastBestiary.groundling;
      expect(groundling.archetype.id, 'skirmisher');
      for (final m in groundling.moves) {
        expect(
          m.priority,
          lessThanOrEqualTo(5),
          reason: 'a Skirmisher that resolves at 9 acts AFTER the player',
        );
      }
    });

    test('the Lasher and the Blighter equivalent are multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule.
      final shoal = StormcliffCoastBestiary.staticShoal;
      expect(shoal.archetype.id, 'lasher');
      for (final m in shoal.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect((m.effect as DamageEffect).hits, greaterThan(1));
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Sentinel/Redoubt/Tyrant are defined partly by attrition. Without a
      // ShieldEffect the archetype is only a bigger HP number.
      for (final e in all) {
        if (!{'sentinel', 'redoubt', 'tyrant'}.contains(e.archetype.id)) {
          continue;
        }
        expect(
          e.moves.any((m) => m.effect is ShieldEffect),
          isTrue,
          reason: '${e.id} is a ${e.archetype.name} with nothing to hide '
              'behind',
        );
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield',
        () {
      final shaman = StormcliffCoastBestiary.stormShaman;
      expect(shaman.archetype.id, 'hexer');
      expect(
        shaman.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        shaman.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap is lowered to 4, this quarter', () {
      // ⚠️ KINETIC_CONTRACT §1.3 — the ruling that keeps a level-29 finisher
      // from one-shotting a shielded player. Kills a mutant that reverts to
      // Q1's cost-5 cap.
      final ghost = StormcliffCoastBestiary.voltgeist;
      expect(ghost.archetype.id, 'executioner');
      for (final m in ghost.moves) {
        expect(m.chargeCost, lessThanOrEqualTo(4));
      }
    });

    test('the Tyrant plays well: a cheap wall ahead of its own big hit', () {
      final lord = StormcliffCoastBestiary.stormLord;
      expect(lord.archetype.id, 'tyrant');
      final wall = lord.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(wall.chargeCost, 1, reason: 'a wall it cannot always afford');
      expect(
        lord.moves.any((m) => m.isOffensive && m.priority < 3),
        isTrue,
        reason: 'nothing Storm Lord throws beats a shield to the board',
      );
    });

    test('nothing in this zone lifesteals except the Redoubt\'s finisher',
        () {
      // ⭐ ENEMIES §2.6 — the Siphon (and casual lifesteal) is Thornmire's
      // lesson; a Redoubt's "one lifesteal" move (§1.3) is the sole exception.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          if (e.archetype.id == 'redoubt' && effect.lifesteal > 0) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" spoils Thornmire\'s reveal',
          );
        }
      }
    });
  });

  group('drop tables resolve and are honest', () {
    // ⚠️ **`hardtack` is a known cross-zone gap in this worktree.** It is
    // defined in `old_quarry_items.dart`, a sibling Kinetic zone builder's
    // file that does not exist here yet (three zones are being built in
    // parallel worktrees). It resolves once the merge coordinator lands all
    // three. Every other id in this zone's tables is defined locally and
    // must resolve today.
    const knownCrossZonePending = <String>{}; // hardtack landed with Old Quarry

    test('every id in every table is a real item, or a known pending one',
        () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (knownCrossZonePending.contains(id)) continue;
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
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
      for (final e in StormcliffCoastBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...StormcliffCoastBestiary.minis,
        ...StormcliffCoastBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in StormcliffCoastBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          if (knownCrossZonePending.contains(id)) continue;
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ ITEMS §8 — Crystal is where the ladder is first FELT, so it must be
      // a fight the player chose.
      for (final e in StormcliffCoastBestiary.commons) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('electro_crystal')),
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final e in StormcliffCoastBestiary.minis) {
        expect(e.drops.possibleDrops, contains('electro_crystal'));
      }
      for (final e in StormcliffCoastBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'electro_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Crystal',
        );
      }
    });

    test('a pure Electro zone drops only Electro motes', () {
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
        'geo_dust', 'geo_shard', 'geo_crystal',
        'aero_dust', 'aero_shard', 'aero_crystal',
      };
      for (final id in StormcliffCoastBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('no boss table carries a Sigil essence item', () {
      // ⚠️ KINETIC_CONTRACT §3.3/§8.6 — the collect-three-keys mechanism is
      // rejected. Kills a mutant that reintroduces `electro_essence`.
      for (final b in StormcliffCoastBestiary.bosses) {
        expect(
          b.drops.possibleDrops,
          isNot(contains('electro_essence')),
          reason: '${b.id} drops the rejected Sigil key',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in StormcliffCoastBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('fulgurite_pendant'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('fulgurite_pendant'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('fulgurite_pendant').rarity, Rarity.rare);
    });

    test('the Epic chase is boss-only, and rare', () {
      final epics = StormcliffCoastItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      for (final id in epics) {
        for (final e in all) {
          if (e.drops.possibleDrops.contains(id)) {
            expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
            expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
          }
        }
      }
    });

    test('every item in the zone catalogue is a real ItemDef with a real '
        'zone', () {
      for (final def in StormcliffCoastItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final crawler = StormcliffCoastBestiary.fulguriteCrawler;
      final lord = StormcliffCoastBestiary.stormLord;
      expect(
        crawler.maxHpAt(17),
        (MageState.scaledMaxHp(17) * Archetypes.sentinel.hpScale).round(),
      );
      expect(
        lord.maxHpAt(22),
        (MageState.scaledMaxHp(22) * Archetypes.tyrant.hpScale).round(),
      );
      expect(lord.maxHpAt(22), greaterThan(crawler.maxHpAt(22)));
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 17. Anything that can open with a kill
      // from full health is a difficulty spike disguised as a wandering
      // monster.
      final startingHp = MageState.scaledMaxHp(17);
      for (final e in StormcliffCoastBestiary.commons) {
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

    test('two nodes, both world-held — neither material is a hide', () {
      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.id).toSet(), {
        'sc_wrackline',
        'sc_saltwort_ledge',
      });
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(GatherNodes.byId(n.id), same(n));
      }
    });

    test('every node yields a real, fungible item from this zone\'s skill',
        () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields ${n.yieldsDefId}, which is not stackable',
        );
        expect(def, isA<MaterialDef>());
        expect(n.min, greaterThan(0));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
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
  });
}
