import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_molten_deep.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_molten_deep_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'the_molten_deep';
  final all = TheMoltenDeepBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(TheMoltenDeepBestiary.commons, hasLength(5));
      expect(TheMoltenDeepBestiary.minis, hasLength(4));
      expect(TheMoltenDeepBestiary.bosses, hasLength(2));
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (KINETIC_CONTRACT
      // §7.1) — an unlisted zone compiles fine and never appears.
      expect(Bestiary.forZone(zone), hasLength(11));
      expect(Bestiary.forZone(zone).toSet(), all.toSet());
    });

    test('the four minis are one of each mini archetype', () {
      expect(TheMoltenDeepBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('the boss pair is the mass/mind pair the contract names', () {
      // ⭐⭐ KINETIC_CONTRACT §4.6: Efreet is what BURNS (a will — Tyrant),
      // The Slow Stone is what has NOT melted yet (a mass — Juggernaut).
      expect(TheMoltenDeepBestiary.theSlowStone.archetype.id, 'juggernaut');
      expect(TheMoltenDeepBestiary.efreet.archetype.id, 'tyrant');
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
      for (final e in all) {
        final derived = e.name
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z0-9]+"), '_');
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('everything belongs to the zone, and every element it uses is one '
        'of the zone\'s two (a hybrid, not a pure zone)', () {
      final loc = World.byId(zone);
      expect(loc.elements, [MagicElement.pyro, MagicElement.geo]);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(e.elements, isNotEmpty);
        for (final el in e.elements) {
          expect(
            loc.elements,
            contains(el),
            reason: '${e.id} uses $el, which is not one of this hybrid\'s '
                'two elements',
          );
        }
      }
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
      );
    });

    test('the zone band is 25–29, and nothing else', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 25);
      expect(loc.maxLevel, 29);
    });
  });

  group('combat stats match KINETIC_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: every archetype present in this
    // zone is checked against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        TheMoltenDeepBestiary.slagswimmer.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Sentinel reads as "everything lands softer"', () {
      expect(
        TheMoltenDeepBestiary.moltenWarden.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('the Bruiser hits like a truck, sometimes whiffs entirely', () {
      expect(
        TheMoltenDeepBestiary.crustwalker.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        TheMoltenDeepBestiary.emberVent.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        TheMoltenDeepBestiary.coolingThing.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        TheMoltenDeepBestiary.theFloor.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        TheMoltenDeepBestiary.magmaBehemoth.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        TheMoltenDeepBestiary.pyroclast.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        TheMoltenDeepBestiary.firstmelt.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        TheMoltenDeepBestiary.theSlowStone.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('the Tyrant has no weakness to exploit', () {
      expect(
        TheMoltenDeepBestiary.efreet.combatStats,
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
          reason: '${e.id} — enemy dodge should read as slippery, never '
              'unhittable',
        );
      }
    });

    test('crit damage and deflect amount never appear without their chance',
        () {
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

    test('move ids are unique across the whole zone, and all prefixed md_',
        () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id.startsWith('md_'), isTrue, reason: '$id is not zone-tagged');
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
      // already scales damage by level, so this zone's 25–29 band arrives
      // via the ENCOUNTER LEVEL, never bigger raws.
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

    test('the Blighter is multi-hit only, both moves', () {
      final vent = TheMoltenDeepBestiary.emberVent;
      expect(vent.archetype.id, 'blighter');
      for (final m in vent.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect((m.effect as DamageEffect).hits, greaterThan(1));
      }
    });

    test('the wall archetypes actually carry a wall', () {
      for (final e in all) {
        if (!{
          'sentinel',
          'redoubt',
          'juggernaut',
          'tyrant',
        }.contains(e.archetype.id)) {
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

    test('the Redoubt carries its lifesteal move', () {
      expect(
        TheMoltenDeepBestiary.magmaBehemoth.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        isTrue,
      );
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield',
        () {
      final firstmelt = TheMoltenDeepBestiary.firstmelt;
      expect(firstmelt.archetype.id, 'hexer');
      expect(
        firstmelt.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        firstmelt.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap is lowered to 4, this quarter', () {
      // ⚠️ KINETIC_CONTRACT §1.3 — kills a mutant that reverts to Q1's
      // cost-5 cap, which would one-shot a level-29 shielded player.
      final pyroclast = TheMoltenDeepBestiary.pyroclast;
      expect(pyroclast.archetype.id, 'executioner');
      for (final m in pyroclast.moves) {
        expect(m.chargeCost, lessThanOrEqualTo(4));
      }
    });

    test('the Tyrant plays well: a cheap wall ahead of its own big hit', () {
      final efreet = TheMoltenDeepBestiary.efreet;
      expect(efreet.archetype.id, 'tyrant');
      final wall = efreet.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(wall.chargeCost, 1, reason: 'a wall it cannot always afford');
      expect(
        efreet.moves.any((m) => m.isOffensive && m.priority < 3),
        isTrue,
        reason: 'nothing Efreet throws beats a shield to the board',
      );
    });

    test('nothing in this zone lifesteals except the Redoubt\'s finisher',
        () {
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
    test('every id in every table is a real item', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('every main table draws exactly one entry, by weight, summing to '
        '100', () {
      for (final e in all) {
        if (e.drops.main.isEmpty) continue;
        expect(e.drops.totalWeight, 100, reason: '${e.id}\'s main table');
      }
    });

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in TheMoltenDeepBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...TheMoltenDeepBestiary.minis,
        ...TheMoltenDeepBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in TheMoltenDeepBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('both crystal families only appear on the mini and boss tables',
        () {
      for (final e in TheMoltenDeepBestiary.commons) {
        expect(e.drops.possibleDrops, isNot(contains('pyro_crystal')));
        expect(e.drops.possibleDrops, isNot(contains('geo_crystal')));
      }
      for (final e in TheMoltenDeepBestiary.minis) {
        expect(e.drops.possibleDrops, contains('pyro_crystal'));
        expect(e.drops.possibleDrops, contains('geo_crystal'));
      }
      for (final e in TheMoltenDeepBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'pyro_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Pyro Crystal',
        );
        expect(
          e.drops.always.any((d) => d.defId == 'geo_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Geo Crystal',
        );
      }
    });

    test('a Pyro + Geo hybrid drops only Pyro and Geo motes — no motes of '
        'its own (§3.2)', () {
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'electro_dust', 'electro_shard', 'electro_crystal',
        'aero_dust', 'aero_shard', 'aero_crystal',
      };
      for (final id in TheMoltenDeepBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
      // ⭐ No mote definitions of its own — none of the item ids this zone's
      // own catalogue defines are motes.
      expect(TheMoltenDeepItems.all.whereType<MoteDef>(), isEmpty);
    });

    test('no boss table carries a Sigil essence item', () {
      // ⚠️ KINETIC_CONTRACT §3.3/§8.6 — the collect-three-keys mechanism is
      // rejected. Kills a mutant that reintroduces an essence item.
      for (final b in TheMoltenDeepBestiary.bosses) {
        expect(b.drops.possibleDrops, isNot(contains('pyro_essence')));
        expect(b.drops.possibleDrops, isNot(contains('geo_essence')));
      }
    });

    test('the Rare chase hangs off both the mini and boss pools', () {
      for (final e in TheMoltenDeepBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('firstmelt_loop'),
          reason: '${e.id} cannot drop the zone chase',
        );
      }
      for (final e in TheMoltenDeepBestiary.bosses) {
        expect(e.drops.possibleDrops, contains('firstmelt_loop'));
      }
      expect(ItemCatalogue.byId('firstmelt_loop').rarity, Rarity.rare);
    });

    test('the Epic chase is boss-only, and rare', () {
      final epics = TheMoltenDeepItems.all
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
      for (final def in TheMoltenDeepItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('the catalogue is registered under the real zone id, with 6 defs',
        () {
      expect(ItemCatalogue.byZone.keys, contains(zone));
      expect(ItemCatalogue.byZone[zone], hasLength(6));
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ `emberhide_belt` is the one exception: it is a Tailoring-crafted
      // output of the kill-only `emberhide` hide, not a drop itself. Its
      // recipe lives outside this build's scope (the recipe ladder file),
      // so it is verified only as a resolvable, correctly-typed def below —
      // the same shape old_quarry_test.dart carves out for `bronze_ingot`.
      final dropped = TheMoltenDeepBestiary.allDrops;
      for (final d in ItemCatalogue.byZone[zone]!) {
        if (d.id == 'emberhide_belt') continue;
        expect(
          dropped.contains(d.id),
          isTrue,
          reason: '${d.id} is defined but nothing drops it',
        );
      }
    });

    test('crafted equipment leaves properName null; drop-only chases carry '
        'one (§3.4)', () {
      for (final d in ItemCatalogue.byZone[zone]!.whereType<EquipmentDef>()) {
        if (d.rarity == Rarity.common) {
          expect(
            d.properName,
            isNull,
            reason: '${d.id} is Common (crafted) but names itself',
          );
        } else {
          expect(
            d.properName,
            isNotNull,
            reason: '${d.id} is drop-only equipment and must set its own '
                'name',
          );
        }
      }
    });

    test('obsidian and firesalt bank — no recipe in this build consumes '
        'them', () {
      final obsidian = ItemCatalogue.byId('obsidian');
      expect(obsidian, isA<MaterialDef>());
      expect((obsidian as MaterialDef).skill, CraftSkill.jewelry);

      final firesalt = ItemCatalogue.byId('firesalt');
      expect(firesalt, isA<MaterialDef>());
      expect((firesalt as MaterialDef).skill, CraftSkill.potionsAndAlchemy);
    });

    test('emberhide is kill-only — a hide with no node', () {
      final emberhide = ItemCatalogue.byId('emberhide');
      expect(emberhide, isA<MaterialDef>());
      expect((emberhide as MaterialDef).skill, CraftSkill.tailoring);
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('emberhide')),
      );
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final warden = TheMoltenDeepBestiary.moltenWarden;
      final stone = TheMoltenDeepBestiary.theSlowStone;
      expect(
        warden.maxHpAt(25),
        (MageState.scaledMaxHp(25) * Archetypes.sentinel.hpScale).round(),
      );
      expect(
        stone.maxHpAt(29),
        (MageState.scaledMaxHp(29) * Archetypes.juggernaut.hpScale).round(),
      );
      expect(stone.maxHpAt(29), greaterThan(warden.maxHpAt(29)));
    });

    test('The Slow Stone is 1080 HP at L29 — the largest number in the '
        'quarter (KINETIC_CONTRACT §1.2/§4.6), pinned through the statline '
        'math so a coefficient drift is caught, not just the literal', () {
      final expected =
          (MageState.scaledMaxHp(29) * Archetypes.juggernaut.hpScale).round();
      expect(expected, 1080);
      expect(TheMoltenDeepBestiary.theSlowStone.maxHpAt(29), 1080);
    });

    test('no common one-shots a character who just walked in', () {
      final startingHp = MageState.scaledMaxHp(25);
      for (final e in TheMoltenDeepBestiary.commons) {
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

    test('two nodes, both world-held — the hide has no node', () {
      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.id).toSet(), {
        'md_obsidian_flow',
        'md_firesalt_crust',
      });
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(GatherNodes.byId(n.id), same(n));
      }
    });

    test('every node yields a real, fungible item from this zone\'s '
        'catalogue', () {
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

    test('skill matches each material\'s consuming skill via §6a.1', () {
      // ⭐ Jewelry (gems) ← Mining, Potions ← Foraging — a hybrid zone's two
      // world-held materials do not have to share one skill.
      final obsidianNode = GatherNodes.byId('md_obsidian_flow')!;
      expect(obsidianNode.skill, GatherSkill.mining);
      expect(obsidianNode.yieldsDefId, 'obsidian');

      final firesaltNode = GatherNodes.byId('md_firesalt_crust')!;
      expect(firesaltNode.skill, GatherSkill.foraging);
      expect(firesaltNode.yieldsDefId, 'firesalt');
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 57);
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
