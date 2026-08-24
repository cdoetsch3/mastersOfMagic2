import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/crafting/gesture.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/thunderspire_peaks.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/thunderspire_peaks_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'thunderspire_peaks';
  final all = ThunderspirePeaksBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(ThunderspirePeaksBestiary.commons, hasLength(5));
      expect(ThunderspirePeaksBestiary.minis, hasLength(4));
      expect(ThunderspirePeaksBestiary.bosses, hasLength(2));
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (KINETIC_CONTRACT
      // §7.1) — an unlisted zone compiles fine and never appears.
      expect(Bestiary.forZone(zone), hasLength(11));
      expect(Bestiary.forZone(zone).toSet(), all.toSet());
    });

    test('the four minis are one of each mini archetype', () {
      expect(
        ThunderspirePeaksBestiary.minis.map((e) => e.archetype.id).toSet(),
        {'champion', 'redoubt', 'executioner', 'hexer'},
      );
    });

    test('the boss pair is the constant/arrival pair the contract names', () {
      // ⭐⭐ KINETIC_CONTRACT §4.5: The Storm That Passes is the mass that
      // simply keeps going (Juggernaut); The Strike That Lands is the
      // arrival the countdown was building to (Aspect).
      expect(
        ThunderspirePeaksBestiary.theStormThatPasses.archetype.id,
        'juggernaut',
      );
      expect(
        ThunderspirePeaksBestiary.theStrikeThatLands.archetype.id,
        'aspect',
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
      for (final e in all) {
        final derived = e.name
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z0-9]+"), '_');
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('everything belongs to a real zone, and every element it uses is '
        'one the zone actually carries', () {
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone);
        expect(
          e.elements,
          isNotEmpty,
          reason: '${e.id} names no element at all',
        );
        for (final el in e.elements) {
          expect(
            loc.elements,
            contains(el),
            reason: '${e.id} uses $el, which ${loc.name} does not carry',
          );
        }
      }
    });

    test('a hybrid roster actually uses both elements somewhere, not just '
        'one', () {
      // ⚠️ §4.5's roster mixes single-element creatures (aero/electro) with
      // a few genuinely-both ones — a hybrid that only ever assigns one
      // element per creature everywhere is a pure zone wearing two names.
      expect(all.any((e) => e.elements.contains(MagicElement.electro)), isTrue);
      expect(all.any((e) => e.elements.contains(MagicElement.aero)), isTrue);
      expect(
        all.any((e) => e.elements.length == 2),
        isTrue,
        reason: 'no creature carries both elements at once',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
      );
    });

    test('the zone band is 23–28, and nothing else', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 23);
      expect(loc.maxLevel, 28);
    });

    test('the Adept is the ruled swap, and it is the zone\'s only Adept', () {
      // ✅ §8.4 — ionwake is Skirmisher → Adept, the cheapest of the swaps
      // the draft offered for this zone.
      expect(ThunderspirePeaksBestiary.ionwake.archetype.id, 'adept');
      expect(
        all.where((e) => e.archetype.id == 'adept'),
        hasLength(1),
        reason: 'the swap replaces a Skirmisher, it does not add a second '
            'yardstick',
      );
      expect(
        all.any((e) => e.archetype.id == 'skirmisher'),
        isFalse,
        reason: 'the swap must REPLACE the Skirmisher slot, per §8.4',
      );
    });

    test('Thunder Roc keeps its Electro assignment, per ruling §8.8', () {
      expect(ThunderspirePeaksBestiary.thunderRoc.elements, [MagicElement.electro]);
      expect(
        ThunderspirePeaksBestiary.stormcrestRoc.elements,
        [MagicElement.aero],
        reason: 'the two rocs must stay different elements or they read as '
            'one species at two sizes',
      );
    });
  });

  group('combat stats match KINETIC_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present in this zone is checked
    // against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        ThunderspirePeaksBestiary.ionwake.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Bruiser hits like a truck, sometimes whiffs entirely', () {
      expect(
        ThunderspirePeaksBestiary.stormcrestRoc.combatStats,
        const EnemyCombatStats(accuracyBonus: -8, critChance: 8, critDamage: 25),
      );
    });

    test('the Sentinel reads as "everything lands softer"', () {
      expect(
        ThunderspirePeaksBestiary.hummingOre.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
      );
    });

    test('the Lasher stings, and its sting is deliberately weak', () {
      expect(
        ThunderspirePeaksBestiary.flashcount.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        ThunderspirePeaksBestiary.updraftWisp.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        ThunderspirePeaksBestiary.crownFire.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        ThunderspirePeaksBestiary.anvilhead.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        ThunderspirePeaksBestiary.thunderRoc.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        ThunderspirePeaksBestiary.theShortening.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        ThunderspirePeaksBestiary.theStormThatPasses.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
      );
    });

    test('the Aspect is THE STRIKE THAT LANDS\' own zone-specific block, not '
        'a generic Aspect row', () {
      // ⚠️ §2.4/§2.5: crit 30 / critDmg +50, acc +10 — the strongest crit
      // block in the zone, distinct from the generic Aspect row (§2.3 leaves
      // that row "per zone").
      expect(
        ThunderspirePeaksBestiary.theStrikeThatLands.combatStats,
        const EnemyCombatStats(accuracyBonus: 10, critChance: 30, critDamage: 50),
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

    test('move ids are unique across the whole zone, and all prefixed', () {
      final ids = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id.startsWith('tp_'), isTrue, reason: '$id is not zone-tagged');
      }
    });

    test('no move name collides with the game\'s own vocabulary', () {
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      for (final e in all) {
        for (final m in e.moves) {
          final n = m.name.toLowerCase();
          expect(reservedVerbs.contains(n), isFalse);
          expect(elements.contains(n), isFalse);
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

    test('raw damage stays in the Whispering Woods band', () {
      // ⚠️ KINETIC_CONTRACT §1.1/§1.3's double-scaling trap. The engine
      // already scales damage by level, so this zone's 23–28 band arrives via
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

    test('the Lasher is multi-hit only', () {
      final fc = ThunderspirePeaksBestiary.flashcount;
      expect(fc.archetype.id, 'lasher');
      for (final m in fc.moves) {
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
          reason: '${e.id} is a ${e.archetype.name} with nothing to hide '
              'behind',
        );
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield '
        '— the zone\'s premise made mechanical', () {
      final shortening = ThunderspirePeaksBestiary.theShortening;
      expect(shortening.archetype.id, 'hexer');
      expect(
        shortening.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        shortening.moves.any(
          (m) => m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap is lowered to 4, this quarter', () {
      final roc = ThunderspirePeaksBestiary.thunderRoc;
      expect(roc.archetype.id, 'executioner');
      for (final m in roc.moves) {
        expect(m.chargeCost, lessThanOrEqualTo(4));
      }
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
      // ⚠️ No cross-zone gap here: unlike Stormcliff's `hardtack` — this
      // worktree already carries Old Quarry (hardtack), Stormcliff and
      // Windward Steppe, so every id this zone's tables name resolves today.
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
      for (final e in ThunderspirePeaksBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...ThunderspirePeaksBestiary.minis,
        ...ThunderspirePeaksBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in ThunderspirePeaksBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('the mote ladder climbs with rank, in BOTH element families', () {
      for (final e in ThunderspirePeaksBestiary.commons) {
        expect(e.drops.possibleDrops, isNot(contains('electro_crystal')));
        expect(e.drops.possibleDrops, isNot(contains('aero_crystal')));
      }
      for (final e in ThunderspirePeaksBestiary.minis) {
        expect(e.drops.possibleDrops, contains('electro_crystal'));
        expect(e.drops.possibleDrops, contains('aero_crystal'));
      }
      for (final e in ThunderspirePeaksBestiary.bosses) {
        expect(
          e.drops.always.any((d) => d.defId == 'electro_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Electro Crystal',
        );
        expect(
          e.drops.always.any((d) => d.defId == 'aero_crystal'),
          isTrue,
          reason: '${e.id} does not guarantee Aero Crystal',
        );
      }
    });

    test('a hybrid zone drops only its two parent elements\' motes, and '
        'DEFINES none of them', () {
      const foreign = {
        'flora_dust', 'flora_shard', 'flora_crystal',
        'aqua_dust', 'aqua_shard', 'aqua_crystal',
        'pyro_dust', 'pyro_shard', 'pyro_crystal',
        'geo_dust', 'geo_shard', 'geo_crystal',
      };
      for (final id in ThunderspirePeaksBestiary.allDrops) {
        expect(foreign, isNot(contains(id)), reason: '$id is off-element');
      }
      // ⭐ §3.2 — hybrids define no motes; every electro_*/aero_* id here
      // resolves against the pure zones that first yielded them.
      expect(
        ThunderspirePeaksItems.all.whereType<MoteDef>(),
        isEmpty,
        reason: 'a hybrid must not define its own copy of a pure zone\'s mote',
      );
      expect(ItemCatalogue.zoneOf('electro_dust'), 'stormcliff_coast');
      expect(ItemCatalogue.zoneOf('aero_dust'), 'windward_steppe');
    });

    test('no boss table carries a Sigil essence item', () {
      for (final b in ThunderspirePeaksBestiary.bosses) {
        for (final essence in [
          'geo_essence',
          'electro_essence',
          'aero_essence',
        ]) {
          expect(
            b.drops.possibleDrops,
            isNot(contains(essence)),
            reason: '${b.id} drops the rejected Sigil key',
          );
        }
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in ThunderspirePeaksBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('countstone_pendant'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('countstone_pendant'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('countstone_pendant').rarity, Rarity.rare);
    });

    test('the Epic chase (groundfault_grips) is boss-only, ruled §8.7, and '
        'at its ruled stats', () {
      final epics = ThunderspirePeaksItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(epics, contains('groundfault_grips'));
      for (final id in epics) {
        for (final e in all) {
          if (e.drops.possibleDrops.contains(id)) {
            expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
            expect(e.drops.mainChanceOf(id), lessThanOrEqualTo(0.15));
          }
        }
      }
      final grips = ItemCatalogue.byId('groundfault_grips') as EquipmentDef;
      expect(grips.slot, EquipSlot.gloves);
      expect(grips.equipLevel, 28);
      expect(
        grips.modifiers,
        const ItemModifiers(accuracyBonus: 5, damagePerCast: 4),
        reason: '§8.7\'s ruled stats for Groundfault Grips',
      );
    });

    test('every item in the zone catalogue is a real ItemDef with a real '
        'zone', () {
      for (final def in ThunderspirePeaksItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });
  });

  group('Rowan is where crafted crit debuts (§2.5, §9b.6)', () {
    test('the Rowan trio and the rare chase carry crit; the epic does not '
        '(§2.5, §8.7)', () {
      // ⭐ §2.5 puts crit on Rowan weapons and the Electro/Pyro jewelry;
      // Groundfault Grips carries the Electro epic's OWN lane instead
      // (on-hit damage plus the accuracy to land it, §8.7) — it must not
      // silently pick up a crit line that was never ruled for it.
      const critSources = {
        'rowan_quarterstaff',
        'rowan_wand',
        'rowan_knot',
        'countstone_pendant',
      };
      for (final id in critSources) {
        final def = ItemCatalogue.byId(id) as EquipmentDef;
        expect(
          def.modifiers.critChance,
          greaterThan(0),
          reason: '$id should carry crit chance',
        );
      }
      final grips = ItemCatalogue.byId('groundfault_grips') as EquipmentDef;
      expect(
        grips.modifiers.critChance,
        0,
        reason: 'Groundfault Grips carries the accuracy/on-hit-damage lane '
            'ruled for it, not crit',
      );
    });

    test('all three Rowan weapons equip at 25, carry a crit pair and a '
        'socket', () {
      // ⚠️ Kills the crit-left-off-crafted mutant: a Rowan piece with a
      // zero crit line silently reverts the quarter's whole "crit debuts on
      // crafted gear here" premise.
      for (final id in ['rowan_quarterstaff', 'rowan_wand', 'rowan_knot']) {
        final def = ItemCatalogue.byId(id) as EquipmentDef;
        expect(def.equipLevel, 25, reason: '$id should equip at 25 (§9b.6)');
        expect(
          def.modifiers.critChance,
          greaterThan(0),
          reason: '$id carries no crit chance — the whole point of Rowan',
        );
        expect(
          def.socketCount,
          1,
          reason: '$id should carry the wood ladder\'s first gem socket',
        );
        expect(def.material, 'Rowan');
        expect(
          def.properName,
          isNull,
          reason: 'crafted equipment must leave properName null (§3.4)',
        );
      }
    });

    test('Yew (Windward Steppe) still carries no crit at all', () {
      // ⭐ §2.5 — crit stays off the crafted tier-3 entirely; Rowan (tier 4)
      // is where it debuts. This is the other half of that claim.
      for (final id in ['yew_quarterstaff', 'yew_wand', 'yew_knot']) {
        final def = ItemCatalogue.byId(id) as EquipmentDef;
        expect(def.modifiers.critChance, 0, reason: '$id should carry no crit');
        expect(def.modifiers.critDamage, 0);
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final ore = ThunderspirePeaksBestiary.hummingOre;
      final storm = ThunderspirePeaksBestiary.theStormThatPasses;
      expect(
        ore.maxHpAt(23),
        (MageState.scaledMaxHp(23) * Archetypes.sentinel.hpScale).round(),
      );
      expect(
        storm.maxHpAt(28),
        (MageState.scaledMaxHp(28) * Archetypes.juggernaut.hpScale).round(),
      );
      expect(storm.maxHpAt(28), greaterThan(ore.maxHpAt(28)));
    });

    test('no common one-shots a character who just walked in', () {
      final startingHp = MageState.scaledMaxHp(23);
      for (final e in ThunderspirePeaksBestiary.commons) {
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

    test('three nodes, all world-held — a hybrid\'s rule (§3.1/§6)', () {
      expect(nodes, hasLength(3));
      expect(nodes.map((n) => n.id).toSet(), {
        'tp_rowan_stand',
        'tp_iron_seam',
        'tp_humming_face',
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

    test('the humming quartz node uses bandKeeper, a fiction that names its '
        'own engine', () {
      final face = GatherNodes.byId('tp_humming_face')!;
      expect(face.step.engine, GestureEngine.bandKeeper);
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
