import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/windward_steppe.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/windward_steppe_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **`hardtack` is a cross-builder dependency, not a windward_steppe id.**
/// KINETIC_CONTRACT §4.3's drop tables name it (Old Quarry's consumable,
/// `old_quarry_items.dart`), but this zone was built in an isolated worktree
/// alongside two parallel builders and Old Quarry's catalogue does not exist
/// here yet. Every "every drop id resolves" check below skips this one id by
/// name — the coordinator's merge is what actually proves it resolves.
const _crossBuilderIds = <String>{}; // hardtack landed with Old Quarry

void main() {
  const zone = 'windward_steppe';
  final all = WindwardSteppeBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(WindwardSteppeBestiary.commons, hasLength(5));
      expect(WindwardSteppeBestiary.minis, hasLength(4));
      expect(WindwardSteppeBestiary.bosses, hasLength(2));
    });

    test('registered in Bestiary.all and reachable via forZone', () {
      // ⚠️ An unlisted zone compiles fine and simply never spawns.
      for (final e in all) {
        expect(Bestiary.byId(e.id), same(e), reason: '${e.id} not in Bestiary.all');
      }
      expect(Bestiary.forZone(zone).length, 11);
      expect(Bestiary.forZone(zone).toSet(), all.toSet());
    });

    test('the four minis are one of each mini archetype', () {
      expect(WindwardSteppeBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('the boss pair is the constant/exception pair the design names', () {
      // ⭐ §4.3: The Unbroken Blow (a force — Juggernaut) is the constant;
      // Tempest Monarch (a will — Tyrant) is the gust, the exception.
      expect(
        WindwardSteppeBestiary.theUnbrokenBlow.archetype.id,
        'juggernaut',
      );
      expect(WindwardSteppeBestiary.tempestMonarch.archetype.id, 'tyrant');
    });

    test('this zone has no Adept', () {
      // ⚠️ §8.4 — thematic absence is legitimate. Old Quarry and Windward
      // Steppe are the two Kinetic zones that stay Adept-less by ruling.
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('adept')),
        reason: 'the Adept-less ruling (§8.4) was reversed for this zone',
      );
    });

    test('exactly two bosses — the empty-arena idea stays dead (§8.3)', () {
      expect(WindwardSteppeBestiary.bosses, hasLength(2));
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

    test('everything belongs to a real zone, and uses that zone element', () {
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(
          e.elements,
          [MagicElement.aero],
          reason: '${e.id} — a pure zone means one element (ENEMIES §2h)',
        );
        expect(loc.elements, contains(e.elements.single));
      }
    });

    test('the zone band is 19–24, per world.dart canon', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 19);
      expect(loc.maxLevel, 24);
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
      );
    });
  });

  group('combat stats match KINETIC_CONTRACT §2.3', () {
    // ⚠️ Mutation-verified: a swapped archetype (e.g. handing the Hexer's
    // stats to the Skirmisher) and a dodge value above the §2.3 cap of 10
    // must both fail these tests.
    test('Skirmisher (Steppe Harrier): acc +5, dodge 8 — under the cap', () {
      final e = WindwardSteppeBestiary.steppeHarrier;
      expect(e.archetype, Archetypes.skirmisher);
      expect(e.combatStats, const EnemyCombatStats(accuracyBonus: 5, dodge: 8));
      expect(e.combatStats.dodge, lessThanOrEqualTo(10));
    });

    test('Sentinel (Leanstone): deflect 25/20, no other stat', () {
      final e = WindwardSteppeBestiary.leanstone;
      expect(e.archetype, Archetypes.sentinel);
      expect(
        e.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('Lasher (Chaff): crit 15 / -20 crit damage', () {
      final e = WindwardSteppeBestiary.chaff;
      expect(e.archetype, Archetypes.lasher);
      expect(
        e.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('Drudge (Tumblehusk): acc -10, nothing else', () {
      final e = WindwardSteppeBestiary.tumblehusk;
      expect(e.archetype, Archetypes.drudge);
      expect(e.combatStats, const EnemyCombatStats(accuracyBonus: -10));
    });

    test('Glasswing (Kitewing): crit 20 / +30 crit damage', () {
      final e = WindwardSteppeBestiary.kitewing;
      expect(e.archetype, Archetypes.glasswing);
      expect(
        e.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('Hexer (Wind Wraith): acc +8, dodge 10 — the cap itself', () {
      // ⚠️ §2.3: "the Hexer at 10 and the Skirmisher at 8 are the only two
      // allowed near it." This is the other of the two.
      final e = WindwardSteppeBestiary.windWraith;
      expect(e.archetype, Archetypes.hexer);
      expect(e.combatStats, const EnemyCombatStats(accuracyBonus: 8, dodge: 10));
      expect(e.combatStats.dodge, lessThanOrEqualTo(10));
    });

    test('every enemy dodge in this zone stays at or under the cap of 10', () {
      // 🚫 Kills a mutant that bumps any dodge value past the §2.3 cap.
      for (final e in all) {
        expect(
          e.combatStats.dodge,
          lessThanOrEqualTo(10),
          reason: '${e.id} exceeds the enemy dodge cap',
        );
      }
    });

    test('critDamage is never carried without critChance (inert-stat trap)', () {
      // ⚠️ §2.1's guard: critChance == 0 makes critDamage a dead stat.
      for (final e in all) {
        if (e.combatStats.critDamage != 0) {
          expect(
            e.combatStats.critChance,
            greaterThan(0),
            reason: '${e.id} carries critDamage with no critChance',
          );
        }
        if (e.combatStats.deflectAmount != 0) {
          expect(
            e.combatStats.deflectChance,
            greaterThan(0),
            reason: '${e.id} carries deflectAmount with no deflectChance',
          );
        }
      }
    });

    test('the archetype determines the stat block — no swaps', () {
      // 🚫 Kills a mutant that hands one archetype's row to another.
      const byArchetype = {
        'drudge': EnemyCombatStats(accuracyBonus: -10),
        'skirmisher': EnemyCombatStats(accuracyBonus: 5, dodge: 8),
        'lasher': EnemyCombatStats(critChance: 15, critDamage: -20),
        'glasswing': EnemyCombatStats(critChance: 20, critDamage: 30),
        'sentinel': EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
        'champion': EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        'redoubt': EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        'executioner': EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        'hexer': EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        'juggernaut': EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
        'tyrant': EnemyCombatStats(
          accuracyBonus: 5,
          dodge: 5,
          critChance: 10,
          critDamage: 15,
          deflectChance: 10,
          deflectAmount: 15,
        ),
      };
      for (final e in all) {
        expect(
          e.combatStats,
          byArchetype[e.archetype.id],
          reason: '${e.id} (${e.archetype.id}) does not match its '
              'archetype\'s KINETIC_CONTRACT §2.3 row',
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

    test('move ids are unique across the whole zone, and all prefixed', () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id.startsWith('ws_'), isTrue, reason: '$id is not zone-tagged');
      }
    });

    test('no move name collides with the game\'s own vocabulary', () {
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          final n = m.name.toLowerCase();
          expect(reservedVerbs.contains(n), isFalse,
              reason: '"${m.name}" is one of the game\'s own verbs');
          expect(elements.contains(n), isFalse,
              reason: '"${m.name}" is an element name');
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

    test('the Executioner cost cap is lowered to 4 this quarter', () {
      // ⚠️ KINETIC_CONTRACT §1.3 — the mini five-charge raw would one-shot a
      // level-24 player; this quarter's cap is 4, not the archetype's usual 5.
      final serpent = WindwardSteppeBestiary.galeSerpent;
      expect(serpent.archetype.id, 'executioner');
      for (final m in serpent.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '${m.name} exceeds the Kinetic-quarter Executioner cap',
        );
      }
    });

    test('raw damage stays within the hard ceiling (§1.3)', () {
      // ⚠️ ≤ 60 raw on any one move, ≤ 12 raw per charge — the worst case,
      // not an average. The engine scales by level and archetype on top.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          final worst = effect.maxAmount * effect.hits;
          expect(
            worst,
            lessThanOrEqualTo(60),
            reason: '${e.id}\'s "${m.name}" is above the shared ceiling',
          );
          expect(
            worst / m.chargeCost,
            lessThanOrEqualTo(12),
            reason: '${e.id}\'s "${m.name}" is too efficient per charge',
          );
        }
      }
    });

    test('the Skirmisher acts in the quick band', () {
      final harrier = WindwardSteppeBestiary.steppeHarrier;
      expect(harrier.archetype.id, 'skirmisher');
      for (final m in harrier.moves) {
        expect(
          m.priority,
          lessThanOrEqualTo(5),
          reason: 'a Skirmisher that resolves at 9 acts AFTER the player',
        );
      }
    });

    test('the Drudge raw is cut ~20% for its own incompetence', () {
      final husk = WindwardSteppeBestiary.tumblehusk;
      expect(husk.archetype.id, 'drudge');
      final effect = husk.moves.single.effect as DamageEffect;
      expect(effect.minAmount, 4);
      expect(effect.maxAmount, 7);
    });

    test('the Lasher is multi-hit only, on both moves', () {
      final chaff = WindwardSteppeBestiary.chaff;
      expect(chaff.archetype.id, 'lasher');
      for (final m in chaff.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect((m.effect as DamageEffect).hits, greaterThan(1));
      }
    });

    test('the wall archetypes actually carry a wall', () {
      for (final e in all) {
        if (!{'sentinel', 'redoubt', 'juggernaut'}.contains(e.archetype.id)) {
          continue;
        }
        expect(
          e.moves.any((m) => m.effect is ShieldEffect),
          isTrue,
          reason: '${e.id} is a ${e.archetype.name} with nothing to hide behind',
        );
      }
    });

    test('the Redoubt carries an attack, a shield, and lifesteal', () {
      final titan = WindwardSteppeBestiary.skyTitan;
      expect(titan.archetype.id, 'redoubt');
      expect(titan.moves.any((m) => m.effect is ShieldEffect), isTrue);
      expect(
        titan.moves.any(
          (m) => m.effect is DamageEffect && (m.effect as DamageEffect).lifesteal > 0,
        ),
        isTrue,
        reason: 'Sky Titan has no lifesteal move',
      );
    });

    test('the Hexer gets ahead of the whole board', () {
      final wraith = WindwardSteppeBestiary.windWraith;
      expect(wraith.archetype.id, 'hexer');
      expect(
        wraith.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
      );
      expect(
        wraith.moves.any(
          (m) => m.effect is DamageEffect && (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Tyrant plays well: a cheap shield and priority over the player', () {
      final monarch = WindwardSteppeBestiary.tempestMonarch;
      expect(monarch.archetype.id, 'tyrant');
      final wall = monarch.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(wall.chargeCost, 1, reason: 'a wall it cannot always afford');
      expect(
        monarch.moves.any((m) => m.isOffensive && m.priority < 3),
        isTrue,
        reason: 'nothing Tempest Monarch throws beats a shield to the board',
      );
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every table is a real item', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_crossBuilderIds.contains(id)) continue;
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
        expect(e.drops.totalWeight, greaterThan(0));
      }
    });

    test('commons can come up empty; minis and bosses never do', () {
      for (final e in WindwardSteppeBestiary.commons) {
        expect(e.drops.main.any((d) => d.defId == null), isTrue,
            reason: '${e.id} always pays out');
      }
      for (final e in [
        ...WindwardSteppeBestiary.minis,
        ...WindwardSteppeBestiary.bosses,
      ]) {
        expect(e.drops.main.any((d) => d.defId == null), isFalse,
            reason: '${e.id} is a fight you sought out; it must pay');
      }
    });

    test('the mote ladder climbs with rank', () {
      for (final e in WindwardSteppeBestiary.commons) {
        expect(e.drops.possibleDrops, isNot(contains('aero_crystal')));
      }
      for (final e in WindwardSteppeBestiary.minis) {
        expect(e.drops.possibleDrops, contains('aero_crystal'));
      }
      for (final e in WindwardSteppeBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'aero_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Crystal',
        );
      }
    });

    test('a pure Aero zone drops only Aero motes', () {
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
        'geo_dust', 'geo_shard', 'geo_crystal',
        'electro_dust', 'electro_shard', 'electro_crystal',
      };
      for (final id in WindwardSteppeBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('no boss drops a Kinetic Sigil essence (§8.6)', () {
      // ⚠️ The collect-three-keys mechanism is rejected; no Kinetic boss may
      // drop `aero_essence`, and no catalogue may define one.
      for (final b in WindwardSteppeBestiary.bosses) {
        expect(b.drops.possibleDrops, isNot(contains('aero_essence')));
      }
      expect(ItemCatalogue.contains('aero_essence'), isFalse);
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in WindwardSteppeBestiary.minis) {
        expect(e.drops.possibleDrops, contains('leanstone_charm'));
        expect(e.drops.mainChanceOf('leanstone_charm'), lessThanOrEqualTo(0.10));
      }
      expect(ItemCatalogue.byId('leanstone_charm').rarity, Rarity.rare);
    });

    test('the Epic chase is boss-only, and rare', () {
      final epics = ItemCatalogue.all
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

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in WindwardSteppeBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          if (_crossBuilderIds.contains(id)) continue;
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final harrier = WindwardSteppeBestiary.steppeHarrier;
      final blow = WindwardSteppeBestiary.theUnbrokenBlow;
      expect(harrier.maxHpAt(19), (MageState.scaledMaxHp(19) * 0.70).round());
      expect(blow.maxHpAt(24), (MageState.scaledMaxHp(24) * 3.60).round());
      expect(blow.maxHpAt(24), greaterThan(harrier.maxHpAt(24)));
    });

    test('the §1.2 worked HP table holds at this zone\'s band edges', () {
      // ⭐ Cross-check against KINETIC_CONTRACT §4.3's roster table.
      expect(WindwardSteppeBestiary.steppeHarrier.maxHpAt(19), 142);
      expect(WindwardSteppeBestiary.steppeHarrier.maxHpAt(24), 172);
      expect(WindwardSteppeBestiary.theUnbrokenBlow.maxHpAt(24), 886);
      expect(WindwardSteppeBestiary.tempestMonarch.maxHpAt(24), 640);
    });

    test('no common one-shots a character who just walked in', () {
      final startingHp = MageState.scaledMaxHp(19);
      for (final e in WindwardSteppeBestiary.commons) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          final worst = effect.maxAmount * effect.hits;
          expect(worst, lessThan(startingHp),
              reason: '${e.id}\'s "${m.name}" can hit for $worst');
        }
      }
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('two nodes, matching §6 — hides and motes get none', () {
      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.id).toSet(), {
        'ws_yew_break',
        'ws_tussock_swale',
      });
    });

    test('registered in GatherNodes.all', () {
      for (final n in nodes) {
        expect(GatherNodes.byId(n.id), same(n));
        expect(GatherNodes.all, contains(n));
      }
    });

    test('every node yields a real, fungible item', () {
      for (final n in nodes) {
        final def = ItemCatalogue.byId(n.yieldsDefId);
        expect(
          def.isFungible,
          isTrue,
          reason: '${n.id} yields ${n.yieldsDefId}, which is not fungible',
        );
        expect(n.min, greaterThan(0));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('node XP matches the §6 formula: 9 + 2 × (zone.minLevel - 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} XP does not match §6');
      }
    });

    test('the two materials each get exactly one node', () {
      expect(
        nodes.map((n) => n.yieldsDefId).toSet(),
        {'yew_log', 'tussock_flax'},
      );
    });
  });

  group('the zone catalogue', () {
    test('15 defs, all registered under this zone', () {
      expect(WindwardSteppeItems.all, hasLength(15));
      for (final d in WindwardSteppeItems.all) {
        expect(ItemCatalogue.zoneOf(d.id), zone);
      }
      expect(ItemCatalogue.byZone[zone], WindwardSteppeItems.all);
    });

    test('crafted equipment leaves properName null', () {
      for (final d in WindwardSteppeItems.all) {
        if (d is! EquipmentDef) continue;
        if (d.rarity == Rarity.common) {
          expect(
            d.properName,
            isNull,
            reason: '${d.id} is Common (crafted) but names itself',
          );
        }
      }
    });

    test('the two drop-only chases carry a properName', () {
      expect(WindwardSteppeItems.leanstoneCharm.properName, isNotNull);
      expect(WindwardSteppeItems.theLongLean.properName, isNotNull);
    });

    test('no crit anywhere in this catalogue (§2.5 — Yew stays crit-free)', () {
      for (final d in WindwardSteppeItems.all) {
        if (d is! EquipmentDef) continue;
        expect(
          d.modifiers.critChance,
          0,
          reason: '${d.id} carries crit; that debuts on Rowan, not Yew',
        );
        expect(d.modifiers.critDamage, 0, reason: '${d.id} carries crit damage');
      }
    });

    test('Yew equips at 20, per the weapon ladder', () {
      for (final id in ['yew_quarterstaff', 'yew_wand', 'yew_knot']) {
        expect(ItemCatalogue.byId(id).equipLevel, 20, reason: id);
      }
    });

    test('no Kinetic Sigil essence is defined (§8.6)', () {
      expect(
        WindwardSteppeItems.all.map((d) => d.id),
        isNot(contains('aero_essence')),
      );
    });
  });

  group('the lore channel is populated', () {
    test('every creature carries a field note, in the right voice', () {
      for (final e in all) {
        expect(e.lore.length, greaterThan(40), reason: '${e.id} lore is thin');
        expect(e.lore.endsWith('.'), isTrue, reason: '${e.id} lore is not a sentence');
        expect(
          RegExp(r'\d+\s*(hp|damage|dmg)', caseSensitive: false).hasMatch(e.lore),
          isFalse,
          reason: '${e.id} lore leaks mechanics',
        );
      }
    });
  });
}
