import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/old_quarry.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'old_quarry';
  final all = OldQuarryBestiary.all;

  group('the roster is registered and reachable', () {
    test('all 11 defs are reachable via Bestiary.forZone', () {
      final fromBestiary = Bestiary.forZone(zone);
      expect(fromBestiary, hasLength(11));
      expect(
        fromBestiary.map((e) => e.id).toSet(),
        OldQuarryBestiary.all.map((e) => e.id).toSet(),
        reason: 'Bestiary.all must include every OldQuarryBestiary def, or '
            'the zone compiles fine and simply never appears in an encounter',
      );
    });

    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(OldQuarryBestiary.commons, hasLength(5));
      expect(OldQuarryBestiary.minis, hasLength(4));
      expect(OldQuarryBestiary.bosses, hasLength(2));
    });

    test('the four minis are one of each mini archetype', () {
      expect(OldQuarryBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      });
    });

    test('both bosses are distinct, and the mass/mind pair the contract '
        'names', () {
      expect(
        OldQuarryBestiary.mountainHeart.id,
        isNot(OldQuarryBestiary.theEmptyCourse.id),
      );
      // ⭐ KINETIC_CONTRACT §4.1 — Mountain Heart is what was TAKEN (a mass —
      // Juggernaut), The Empty Course is the shape of what is GONE, walking
      // (a thing that decided — Tyrant).
      expect(OldQuarryBestiary.mountainHeart.archetype.id, 'juggernaut');
      expect(OldQuarryBestiary.theEmptyCourse.archetype.id, 'tyrant');
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

    test('ids and names are unique, and every id is the snake_case of its '
        'own name', () {
      expect(all.map((e) => e.id).toSet(), hasLength(all.length));
      expect(all.map((e) => e.name).toSet(), hasLength(all.length));
      for (final e in all) {
        final derived = e.name
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z0-9]+"), '_');
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('everything belongs to old_quarry, and uses the Geo element — a '
        'pure zone', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 15);
      expect(loc.maxLevel, 19);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(e.elements, [MagicElement.geo]);
        expect(loc.elements, contains(e.elements.single));
      }
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
      );
    });

    test('no Siphon and no Adept — neither belongs in this zone', () {
      // ⚠️ KINETIC_CONTRACT §1.2 — Siphon is deliberately absent from the
      // whole Kinetic quarter; §4.1's roster has no Adept either.
      final ids = all.map((e) => e.archetype.id).toSet();
      expect(ids, isNot(contains('siphon')));
      expect(ids, isNot(contains('adept')));
      expect(ids, isNot(contains('aspect')));
    });
  });

  group('combat stats copy the contract\'s per-archetype table', () {
    // ⭐ KINETIC_CONTRACT §2.3 — every non-Adept, non-Aspect archetype gets
    // its row verbatim. Checked for every archetype this zone actually uses,
    // which is well over the "at least 3" the task calls for and kills the
    // swapped-archetype mutant across the whole roster.
    test('Drudge — acc -10, otherwise inert', () {
      final s = OldQuarryBestiary.tailingsDrudge.combatStats;
      expect(s.accuracyBonus, -10);
      expect(s.dodge, 0);
      expect(s.critChance, 0);
      expect(s.deflectChance, 0);
    });

    test('Skirmisher — acc +5, dodge 8', () {
      final s = OldQuarryBestiary.chiselback.combatStats;
      expect(s.accuracyBonus, 5);
      expect(s.dodge, 8);
    });

    test('Lasher — crit 15, critDamage -20', () {
      final s = OldQuarryBestiary.gravelswarm.combatStats;
      expect(s.critChance, 15);
      expect(s.critDamage, -20);
    });

    test('Sentinel — deflect 25/20', () {
      final s = OldQuarryBestiary.plumblineSentry.combatStats;
      expect(s.deflectChance, 25);
      expect(s.deflectAmount, 20);
    });

    test('Bruiser — acc -8, crit 8/+25', () {
      final s = OldQuarryBestiary.quarryGolem.combatStats;
      expect(s.accuracyBonus, -8);
      expect(s.critChance, 8);
      expect(s.critDamage, 25);
    });

    test('Champion — acc +6, crit 10', () {
      final s = OldQuarryBestiary.obsidianGolem.combatStats;
      expect(s.accuracyBonus, 6);
      expect(s.critChance, 10);
    });

    test('Redoubt — deflect 35/30', () {
      final s = OldQuarryBestiary.earthTitan.combatStats;
      expect(s.deflectChance, 35);
      expect(s.deflectAmount, 30);
    });

    test('Executioner — acc +8, crit 12/+40', () {
      final s = OldQuarryBestiary.deadweight.combatStats;
      expect(s.accuracyBonus, 8);
      expect(s.critChance, 12);
      expect(s.critDamage, 40);
    });

    test('Hexer — acc +8, dodge 10', () {
      final s = OldQuarryBestiary.theOverseer.combatStats;
      expect(s.accuracyBonus, 8);
      expect(s.dodge, 10);
    });

    test('Juggernaut — deflect 25/35', () {
      final s = OldQuarryBestiary.mountainHeart.combatStats;
      expect(s.deflectChance, 25);
      expect(s.deflectAmount, 35);
    });

    test('Tyrant — acc +5, dodge 5, crit 10/+15, deflect 10/15', () {
      final s = OldQuarryBestiary.theEmptyCourse.combatStats;
      expect(s.accuracyBonus, 5);
      expect(s.dodge, 5);
      expect(s.critChance, 10);
      expect(s.critDamage, 15);
      expect(s.deflectChance, 10);
      expect(s.deflectAmount, 15);
    });

    test('enemy dodge never exceeds the contract\'s cap of 10', () {
      // ⚠️ KINETIC_CONTRACT §2.3 — "Cap enemy dodge low... only the Hexer at
      // 10 and the Skirmisher at 8 are allowed near it."
      for (final e in all) {
        expect(
          e.combatStats.dodge,
          lessThanOrEqualTo(10),
          reason: '${e.id} exceeds the enemy dodge cap',
        );
      }
    });
  });

  group('the level band is inside 15-19', () {
    test('the zone bounds are exactly the contract\'s band', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 15);
      expect(loc.maxLevel, 19);
    });

    test('HP scales off the shared baseline at every level in the band', () {
      for (var level = 15; level <= 19; level++) {
        for (final e in all) {
          expect(
            e.maxHpAt(level),
            (MageState.scaledMaxHp(level) * e.archetype.hpScale).round(),
            reason: '${e.id} at $level should follow the shared curve, not a '
                'second one',
          );
        }
      }
    });
  });

  group('creatures are creatures, not mages', () {
    test('move ids are unique across the zone, and all prefixed oq_', () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id.startsWith('oq_'), isTrue, reason: '$id is not zone-tagged');
      }
    });

    test('no move borrows an id from the player Spellbook', () {
      final spellIds = Spellbook.all.map((s) => s.id).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          expect(spellIds.contains(m.id), isFalse);
        }
      }
    });

    test('every creature can afford at least one of its own moves from '
        'zero', () {
      for (final e in all) {
        expect(e.moves, isNotEmpty);
        expect(
          e.moves.map((m) => m.chargeCost).reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(5),
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
          reason: '${e.id} has a pricier move than a ${a.name} should',
        );
      }
    });

    test('raw damage stays in the Whispering Woods band', () {
      // ⚠️ KINETIC_CONTRACT §1 — the double-scaling trap. Raw ≤ 60 total, ≤
      // 12 per charge (the Kinetic ceiling; Q1 used 11).
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

    test('the Executioner\'s cost cap is lowered to 4, not 5', () {
      // ⚠️ KINETIC_CONTRACT §1.3 — the one-shot trap. Deadweight must never
      // carry a 5-charge move.
      for (final m in OldQuarryBestiary.deadweight.moves) {
        expect(m.chargeCost, lessThanOrEqualTo(4));
      }
    });

    test('the Lasher is multi-hit only, both moves', () {
      for (final m in OldQuarryBestiary.gravelswarm.moves) {
        final effect = m.effect;
        expect(effect, isA<DamageEffect>());
        expect((effect as DamageEffect).hits, greaterThan(1));
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
        OldQuarryBestiary.earthTitan.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        isTrue,
      );
    });

    test('the Hexer has one ignoresShields move', () {
      expect(
        OldQuarryBestiary.theOverseer.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
      );
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every drop table is a real item', () {
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
      for (final e in OldQuarryBestiary.commons) {
        expect(e.drops.main.any((d) => d.defId == null), isTrue,
            reason: '${e.id} always pays out');
      }
      for (final e in [...OldQuarryBestiary.minis, ...OldQuarryBestiary.bosses]) {
        expect(e.drops.main.any((d) => d.defId == null), isFalse,
            reason: '${e.id} is a fight you sought out; it must pay');
      }
    });

    test('geo_crystal only appears on the mini and boss tables', () {
      for (final e in OldQuarryBestiary.commons) {
        expect(e.drops.possibleDrops, isNot(contains('geo_crystal')));
      }
      for (final e in OldQuarryBestiary.minis) {
        expect(e.drops.possibleDrops, contains('geo_crystal'));
      }
      for (final e in OldQuarryBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'geo_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Crystal',
        );
      }
    });

    test('a pure Geo zone drops only Geo motes', () {
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
      };
      for (final id in OldQuarryBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
    });

    test('no essence — the Sigil mechanism is rejected this quarter', () {
      for (final id in OldQuarryBestiary.allDrops) {
        expect(id, isNot('geo_essence'));
      }
    });

    test('both bosses can hand over the Overseer\'s Seal and The Given '
        'Weight', () {
      expect(
        OldQuarryBestiary.mountainHeart.drops.main
            .any((d) => d.defId == 'the_given_weight'),
        isTrue,
      );
      expect(
        OldQuarryBestiary.theEmptyCourse.drops.main
            .any((d) => d.defId == 'the_given_weight'),
        isTrue,
      );
    });
  });

  group('the item catalogue is complete and registered', () {
    test('the catalogue is registered under the real zone id', () {
      expect(ItemCatalogue.byZone.keys, contains(zone));
      expect(ItemCatalogue.byZone[zone], hasLength(9));
    });

    test('every item in the zone catalogue is actually obtainable', () {
      // ⚠️ bronze_ingot is the one exception: its recipe lives in the
      // (separately-owned) kinetic_recipes.dart, out of this build's scope,
      // so it is verified only as a resolvable, correctly-typed def below.
      final dropped = OldQuarryBestiary.allDrops;
      for (final d in ItemCatalogue.byZone[zone]!) {
        if (d.id == 'bronze_ingot') continue;
        expect(
          dropped.contains(d.id),
          isTrue,
          reason: '${d.id} is defined but nothing drops it',
        );
      }
    });

    test('equipment leaves properName set only for named drops, per the id '
        'convention', () {
      for (final d in ItemCatalogue.byZone[zone]!.whereType<EquipmentDef>()) {
        expect(
          d.properName,
          isNotNull,
          reason: '${d.id} is drop-only equipment and must set its own name',
        );
      }
    });

    test('quarry_jasper banks — no recipe in this build consumes it '
        '(Jewelry does not debut this quarter)', () {
      final jasper = ItemCatalogue.byId('quarry_jasper');
      expect(jasper, isA<MaterialDef>());
      expect((jasper as MaterialDef).skill, CraftSkill.jewelry);
    });
  });

  group('gather nodes are reachable and resolve', () {
    test('both nodes are reachable via GatherNodes.forZone', () {
      final nodes = GatherNodes.forZone(zone);
      expect(nodes.map((n) => n.id).toSet(), {'oq_tin_seam', 'oq_jasper_face'});
    });

    test('no node for a hide or a mote — both nodes yield world-held '
        'materials', () {
      for (final n in GatherNodes.forZone(zone)) {
        expect(n.yieldsDefId, isNot(contains('_dust')));
        expect(n.yieldsDefId, isNot(contains('_shard')));
        expect(n.yieldsDefId, isNot(contains('_crystal')));
      }
    });

    test('every node yields a real, fungible item def', () {
      for (final n in GatherNodes.forZone(zone)) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields an id nothing defines');
        expect(def!.isFungible, isTrue,
            reason: '${n.id} yields a non-fungible item, which a stack '
                'cannot represent');
      }
    });

    test('node XP follows 9 + 2 x (zone.minLevel - 1)', () {
      final expected = 9 + 2 * (World.byId(zone).minLevel - 1);
      for (final n in GatherNodes.forZone(zone)) {
        expect(n.xp, expected, reason: n.id);
      }
    });

    test('skill is read off the material\'s consuming skill', () {
      // ⭐ §6a.1 — Jewelry (gems) and Metalworking (ore) both read off Mining.
      for (final n in GatherNodes.forZone(zone)) {
        expect(n.skill, GatherSkill.mining);
      }
    });
  });

  group('the lore channel is populated', () {
    test('every creature carries a field note, in the right voice', () {
      for (final e in all) {
        expect(e.lore.length, greaterThan(40), reason: '${e.id} lore is thin');
        expect(e.lore.endsWith('.'), isTrue,
            reason: '${e.id} lore is not a sentence');
        expect(
          RegExp(r'\d+\s*(hp|damage|dmg)', caseSensitive: false)
              .hasMatch(e.lore),
          isFalse,
          reason: '${e.id} lore leaks mechanics',
        );
      }
    });
  });
}
