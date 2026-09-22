/// The Mirrormere's roster LAWS — CELESTIAL_CONTRACT §4.2, ENEMIES §2e.
///
/// ⚠️ **`pilgrims_ration` and `glasswort_draught` are a known cross-zone gap
/// in this worktree.** Both are defined in `the_kiln_desert_items.dart`, a
/// sibling Celestial builder's file that does not exist here yet (the
/// quarter's zones are being built in parallel worktrees). CELESTIAL_CONTRACT
/// §7.3 lists them as this zone's only non-local ids; they resolve once the
/// merge coordinator lands the lanes together. ⭐ The exemption is a named
/// set, not a blanket skip — it also asserts those ids are NOT defined here,
/// so a builder who "fixes" the gap by copying them into this catalogue
/// breaks the test instead of silently duplicating another zone's items.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_mirrormere.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_mirrormere_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// Ids this zone's tables reference but another lane defines (see the library
/// note).
const _knownCrossZonePending = <String>{'pilgrims_ration', 'glasswort_draught'};

void main() {
  const zone = 'the_mirrormere';
  final all = MirrormereBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        MirrormereBestiary.commons,
        hasLength(5),
        reason: 'kills a mutant that drops or doubles a common',
      );
      expect(MirrormereBestiary.minis, hasLength(4));
      expect(MirrormereBestiary.bosses, hasLength(2));
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (CELESTIAL_CONTRACT
      // §7.1) — an unlisted zone compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'the bestiary is not listed in Bestiary.all',
      );
      expect(Bestiary.forZone(zone).toSet(), all.toSet());
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(MirrormereBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so the pool repeats a role');
    });

    test('the boss pair is the thing and its reflection, NOT a mirror '
        'match', () {
      // ⭐⭐ ENEMIES §2e: The Moon Below is the reflection and it is LOOKING
      // BACK — §2g gives Tyrant to "a person, a will, something that
      // decided." Luna Plena is the moon itself, so it is the Aspect.
      expect(
        MirrormereBestiary.theMoonBelow.archetype.id,
        'tyrant',
        reason: 'the reflection is the one with a mind',
      );
      expect(
        MirrormereBestiary.lunaPlena.archetype.id,
        'aspect',
        reason: 'the moon above is the element embodied',
      );
      expect(
        MirrormereBestiary.theMoonBelow.archetype.id,
        isNot(MirrormereBestiary.lunaPlena.archetype.id),
        reason: 'a boss pool of two identical archetypes says nothing',
      );
    });

    test('Undershine is a Glasswing — the Siphon was CUT from this zone', () {
      // ⚠️ ENEMIES §2f's rebalance: "nothing in this zone drinks, it only
      // reflects." CELESTIAL_CONTRACT §1.2 still calls Undershine a Siphon;
      // the roster is the later document. Kills the mutant that restores it.
      expect(
        MirrormereBestiary.undershine.archetype.id,
        'glasswing',
        reason: 'the Siphon is cut from The Mirrormere (ENEMIES §2f)',
      );
      expect(
        all.map((e) => e.archetype.id),
        isNot(contains('siphon')),
        reason: 'no creature here may be a Siphon',
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

    test('every archetype in the roster is the one §4.2 names', () {
      // ⚠️ Hard-coded rather than derived: an archetype swap compiles, plays
      // and looks plausible, and nothing else in the suite would say a word.
      const expected = {
        'mirror_wraith': 'adept',
        'stillface': 'blighter',
        'undershine': 'glasswing',
        'ripplecut': 'skirmisher',
        'palefish_shoal': 'lasher',
        'the_second_you': 'champion',
        'herald_of_the_waxing': 'redoubt',
        'stalker_of_the_new_moon': 'executioner',
        'the_waning_wraith': 'hexer',
        'the_moon_below': 'tyrant',
        'luna_plena_the_full_moon': 'aspect',
      };
      expect(
        {for (final e in all) e.id: e.archetype.id},
        expected,
        reason: 'the roster table and the code disagree about an archetype',
      );
    });

    test('ids and names are unique', () {
      expect(
        all.map((e) => e.id).toSet(),
        hasLength(all.length),
        reason: 'two creatures share an id, so one is unreachable',
      );
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

    test('every creature is Lunar and nothing else — this is a PURE zone', () {
      // ⭐ §2.4: the_kiln_desert, the_mirrormere and starfall_basin are the
      // quarter's three pure zones, so each Celestial element keeps exactly
      // one pure region.
      final loc = World.byId(zone);
      expect(loc.elements, [MagicElement.lunar]);
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is tagged to another zone');
        expect(e.elements, [
          MagicElement.lunar,
        ], reason: '${e.id} is not purely Lunar');
      }
    });

    test('no creature carries an off-element move', () {
      // ⚠️ ENEMIES §2e.2 names the FOUR creatures in fifteen zones that may,
      // and none of them is here. A `Spell` has no element field today, so
      // the law is stated on the creature's element list.
      for (final e in all) {
        expect(
          e.elements,
          hasLength(1),
          reason: '${e.id} reaches for a second element',
        );
      }
    });

    test('the anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'World.opponentNameFor promises a creature that is not here',
      );
      // ⭐ ENEMIES §2f — the Adept usually lands on the anchor name, and here
      // the yardstick is your own shape, which is the zone saying it first.
      expect(
        MirrormereBestiary.mirrorWraith.name,
        'Mirror Wraith',
        reason: 'the anchor was renamed',
      );
      expect(MirrormereBestiary.mirrorWraith.archetype.id, 'adept');
    });

    test('the zone band is 32–37, a route, and Celestial', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 32, reason: 'the band floor drifted');
      expect(loc.maxLevel, 37, reason: 'the band ceiling drifted');
      expect(loc.kind, LocationKind.route);
      expect(loc.tier, MagicTier.celestial);
    });
  });

  group('combat stats match CELESTIAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present is checked against its own row.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        MirrormereBestiary.mirrorWraith.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        MirrormereBestiary.stillface.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
        reason: 'the Blighter row is +8 accuracy and nothing else',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        MirrormereBestiary.undershine.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
        reason: 'the Glasswing row is 20 / +30',
      );
    });

    test('the Skirmisher is hard to pin and always first', () {
      expect(
        MirrormereBestiary.ripplecut.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
        reason: 'the Skirmisher row is +5 acc / 8 dodge',
      );
    });

    test('the Lasher bites often and stings rarely', () {
      expect(
        MirrormereBestiary.palefishShoal.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason: 'the Lasher row is 15 / −20 — the minus is the point',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        MirrormereBestiary.theSecondYou.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        MirrormereBestiary.heraldOfTheWaxing.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        MirrormereBestiary.stalkerOfTheNewMoon.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        MirrormereBestiary.theWaningWraith.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
      );
    });

    test('the Tyrant has +everything, modestly', () {
      expect(
        MirrormereBestiary.theMoonBelow.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 5,
          dodge: 5,
          critChance: 10,
          critDamage: 15,
          deflectChance: 10,
          deflectAmount: 15,
        ),
        reason: 'the Tyrant row is no weakness to exploit',
      );
    });

    test('the Aspect is Lunar misdirection — §2.4\'s row, verbatim', () {
      // ⭐ "The moon in the water is not where the moon is." Dodge at the
      // ENEMIES §2.5 cap, and §2.4 says this is the one place to spend it.
      expect(
        MirrormereBestiary.lunaPlena.combatStats,
        const EnemyCombatStats(dodge: 10, deflectChance: 20, deflectAmount: 20),
        reason: 'Luna Plena is dodge 10, defl 20/20, acc 0',
      );
      expect(
        MirrormereBestiary.lunaPlena.combatStats.accuracyBonus,
        0,
        reason: 'an Aspect of misdirection does not also get accuracy',
      );
    });

    test('enemy dodge never exceeds the §2.5 cap of 10', () {
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

    test('crit damage and deflect amount never appear without their '
        'chance', () {
      // ⚠️ §2.1's inert-stat traps: a "buff" with a zero chance to trigger is
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

  group('creatures are creatures, not mages', () {
    test('no creature in this zone is a mage', () {
      // ⚠️ ENEMIES §3.4 — only the Collapsed Academy and Citadel field mages.
      // A lake does not keep a Spellbook.
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

    test('move ids are unique across the WHOLE bestiary, and zone-tagged', () {
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (CELESTIAL_CONTRACT §3.5/§7.2).
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason: 'two moves in this zone share an id',
      );
      for (final id in mine) {
        expect(
          id.startsWith('mm_'),
          isTrue,
          reason: '$id is not zone-tagged with the mm_ prefix',
        );
      }
      final foreign = [
        for (final e in Bestiary.all)
          if (e.zoneId != zone) ...e.moves.map((m) => m.id),
      ];
      for (final id in mine) {
        expect(
          foreign,
          isNot(contains(id)),
          reason: '$id collides with another zone\'s move',
        );
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

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree. ⚠️ No mage
      // exemption is needed here: this zone fields none (§3.4).
      for (final e in all) {
        final a = e.archetype;
        expect(
          e.moves.length,
          a.moveCount,
          reason: '${e.id} is a ${a.name}, which wants ${a.moveCount} moves',
        );
        for (final m in e.moves) {
          expect(
            m.chargeCost,
            greaterThanOrEqualTo(a.minMoveCost),
            reason: '${e.id}\'s "${m.name}" is cheaper than a ${a.name} may be',
          );
          expect(
            m.chargeCost,
            lessThanOrEqualTo(a.maxMoveCost),
            reason: '${e.id}\'s "${m.name}" is dearer than a ${a.name} may be',
          );
        }
      }
    });

    test('raw damage stays in the shared authoring band', () {
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so this zone's 32–37 band arrives via the ENCOUNTER LEVEL,
      // never bigger raws.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.maxAmount * effect.hits,
            lessThanOrEqualTo(60),
            reason: '${e.id}\'s "${m.name}" is above the shared 60 ceiling',
          );
          expect(
            effect.averageTotal / m.chargeCost,
            lessThanOrEqualTo(12),
            reason: '${e.id}\'s "${m.name}" is above 12 raw per charge',
          );
        }
      }
    });

    test('priorities use the shipped integer ladder', () {
      // ⚠️ Shields 3 (or 1–2 for a wall that must beat the player's), quick
      // 5, aux 7/8, attack 9. ⭐ Never a shield at 9 — a wall that lands last
      // is not a wall.
      for (final e in all) {
        for (final m in e.moves) {
          expect(
            m.priority,
            inInclusiveRange(1, 9),
            reason: '${e.id}\'s "${m.name}" is off the ladder',
          );
          if (m.effect is ShieldEffect) {
            expect(
              m.priority,
              lessThanOrEqualTo(3),
              reason: '${e.id}\'s "${m.name}" is a shield that lands too late',
            );
          }
        }
      }
    });

    test('the Blighter is multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule — it wins by out-lasting, not
      // out-hitting.
      final stillface = MirrormereBestiary.stillface;
      expect(stillface.archetype.id, 'blighter');
      for (final m in stillface.moves) {
        expect(m.effect, isA<DamageEffect>());
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} is a single hit on a Blighter',
        );
      }
    });

    test('the Lasher arrives in pieces, so shields chip', () {
      final shoal = MirrormereBestiary.palefishShoal;
      expect(shoal.archetype.id, 'lasher');
      for (final m in shoal.moves) {
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} shatters a shield instead of chipping it',
        );
      }
    });

    test('the Skirmisher is quick, and quick means priority 5', () {
      final ripplecut = MirrormereBestiary.ripplecut;
      expect(ripplecut.archetype.id, 'skirmisher');
      for (final m in ripplecut.moves) {
        expect(
          m.priority,
          5,
          reason: '${m.name} does not cross the surface first',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Without a ShieldEffect a Redoubt is only a bigger HP number.
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
      final herald = MirrormereBestiary.heraldOfTheWaxing;
      final wall = herald.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(
        wall.priority,
        lessThan(3),
        reason: 'the wall goes up after the player\'s, which is no wall at all',
      );
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final wraith = MirrormereBestiary.theWaningWraith;
      expect(wraith.archetype.id, 'hexer');
      expect(
        wraith.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        wraith.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap is 4, not 5', () {
      // ⚠️ §1.3's standing lowering. Kills a mutant that restores cost 5.
      final stalker = MirrormereBestiary.stalkerOfTheNewMoon;
      expect(stalker.archetype.id, 'executioner');
      for (final m in stalker.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '${m.name} at cost 5 is a one-shot with change',
        );
      }
    });

    test('⭐ NOTHING in this zone lifesteals — it reflects, it does not '
        'drink', () {
      // ⭐ ENEMIES §2f cut the Siphon from The Mirrormere for exactly this
      // reason, and §1.3's "one lifesteal move" licence for the Redoubt is
      // declined here rather than let the archetype back in sideways.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" drinks, and this zone reflects',
          );
        }
      }
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every table is a real item, or a known pending one', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_knownCrossZonePending.contains(id)) continue;
          expect(
            ItemCatalogue.contains(id),
            isTrue,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

    test('the pending ids belong to another lane and are NOT redefined '
        'here', () {
      final local = MirrormereItems.all.map((d) => d.id).toSet();
      for (final id in _knownCrossZonePending) {
        expect(
          local,
          isNot(contains(id)),
          reason: '$id is the Kiln Desert\'s; defining it here duplicates it',
        );
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
      for (final e in MirrormereBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...MirrormereBestiary.minis,
        ...MirrormereBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in MirrormereBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          if (_knownCrossZonePending.contains(id)) continue;
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a PURE zone pays ONE mote ladder, and it is its own', () {
      final dropped = MirrormereBestiary.allDrops;
      for (final id in ['lunar_dust', 'lunar_shard', 'lunar_crystal']) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      for (final id in dropped) {
        if (id.startsWith('lunar_')) continue;
        expect(
          RegExp(r'_(dust|shard|crystal)$').hasMatch(id),
          isFalse,
          reason: '$id is a foreign mote in a pure Lunar zone',
        );
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8).
      for (final e in MirrormereBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in MirrormereBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId == 'lunar_crystal'),
          hasLength(1),
          reason: '${b.id} does not guarantee a Crystal',
        );
      }
    });

    test('⭐ the gate essence is on BOTH bosses, always, and never '
        'weighted', () {
      // ⭐ ENEMIES §2e.1's ruling: a run draws one boss of two, so a gate part
      // on only one would make the Celestial Totem a coin flip. ⚠️ And never
      // on `main`, which draws exactly ONE entry.
      for (final b in MirrormereBestiary.bosses) {
        final essence = b.drops.always.where((d) => d.defId == 'lunar_essence');
        expect(
          essence,
          hasLength(1),
          reason: '${b.id} does not guarantee the Lunar Essence',
        );
        expect(
          essence.single.chance,
          1,
          reason: '${b.id} makes a mandatory gate part a roll',
        );
        expect(
          b.drops.main.map((d) => d.defId),
          isNot(contains('lunar_essence')),
          reason: '${b.id} puts the gate part in competition with a log',
        );
      }
      for (final e in [
        ...MirrormereBestiary.commons,
        ...MirrormereBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('lunar_essence')),
          reason: '${e.id} is not a boss and must not drop a gate part',
        );
      }
    });

    test('the hide role resolved to the zone\'s SECOND material', () {
      // ⭐ ETHEREAL_CONTRACT §3.5.1 — The Mirrormere defines no kill-only
      // hide, so "something died" pays in `mirrorflax`. ⚠️ And because it is
      // a gatherable, it keeps its node, unlike a true hide.
      expect(
        MirrormereBestiary.mirrorWraith.drops.possibleDrops,
        contains('mirrorflax'),
      );
      expect(
        MirrormereBestiary.palefishShoal.drops.possibleDrops,
        contains('mirrorflax'),
      );
      expect(
        MirrormereItems.all.whereType<MaterialDef>().map((d) => d.id),
        isNot(contains('mirrormere_hide')),
        reason: 'this zone must not invent a hide the contract does not define',
      );
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in MirrormereBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_waning_charm'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_waning_charm'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('the_waning_charm').rarity, Rarity.rare);
    });

    test('the epic is boss-only, and rare on the boss too', () {
      final epics = MirrormereItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(epics, contains('the_larger_reflection'));
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(
            e.drops.mainChanceOf(id),
            lessThanOrEqualTo(0.15),
            reason: '${e.id} hands the epic out too freely',
          );
        }
      }
    });
  });

  group('the catalogue matches §4.2', () {
    test('16 defs, the quarter\'s largest catalogue', () {
      expect(
        MirrormereItems.all,
        hasLength(16),
        reason: '§7.1 counts Mirrormere at 16 — an item was added or lost',
      );
      expect(
        MirrormereItems.all.map((d) => d.id).toSet(),
        hasLength(16),
        reason: 'two defs share an id',
      );
    });

    test('every item is resolvable under this zone', () {
      // ⚠️ Registration in `ItemCatalogue.byZone` is where the silent failure
      // lives — an unlisted catalogue compiles and never resolves.
      for (final def in MirrormereItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('⭐ the Lunar mote family is DEFINED here, all three tiers', () {
      // ⭐ §3.2 — the mote lives with the zone that first yields it, and this
      // is Lunar's one pure region. Tidewrack and the Sunless Reach import.
      final motes = MirrormereItems.all.whereType<MoteDef>().toList();
      expect(motes, hasLength(3));
      expect(motes.map((m) => m.id).toSet(), {
        'lunar_dust',
        'lunar_shard',
        'lunar_crystal',
      });
      for (final m in motes) {
        expect(
          m.element,
          MagicElement.lunar,
          reason: '${m.id} is not a Lunar mote',
        );
      }
      expect(motes.map((m) => m.tier).toSet(), {
        MoteTier.dust,
        MoteTier.shard,
        MoteTier.crystal,
      }, reason: 'the ladder is missing a rung or doubles one');
      // ✅ ITEMS §8: Dust and Shard are Common, Crystal is Uncommon.
      expect(MirrormereItems.lunarDust.rarity, Rarity.common);
      expect(MirrormereItems.lunarShard.rarity, Rarity.common);
      expect(
        MirrormereItems.lunarCrystal.rarity,
        Rarity.uncommon,
        reason: 'Crystal is the rung the ladder is first felt on',
      );
      // ✅ ECONOMY §14c: 2 / 25 / 150, uniform across elements.
      expect(MirrormereItems.lunarDust.value, 2);
      expect(MirrormereItems.lunarShard.value, 25);
      expect(MirrormereItems.lunarCrystal.value, 150);
    });

    test('the two gatherable materials, and the gate part that is neither', () {
      final materials = MirrormereItems.all.whereType<MaterialDef>().toList();
      expect(materials.map((d) => d.id).toSet(), {
        'bloodwood_log',
        'mirrorflax',
        'lunar_essence',
      }, reason: 'the material set drifted from §3.1/§3.4');
      expect(MirrormereItems.bloodwoodLog.skill, CraftSkill.woodcarving);
      expect(MirrormereItems.bloodwoodLog.tier, 6);
      expect(MirrormereItems.mirrorflax.skill, CraftSkill.tailoring);
      expect(MirrormereItems.mirrorflax.tier, 5);
      // ⚠️ §3.4 — Bound, rare, and worth nothing: a gate part is shown and
      // spent, never sold.
      expect(
        MirrormereItems.lunarEssence.tradability,
        Tradability.bound,
        reason: 'an unbound gate part lets gold buy the Celestial Totem',
      );
      expect(MirrormereItems.lunarEssence.rarity, Rarity.rare);
      expect(MirrormereItems.lunarEssence.value, 0);
      expect(MirrormereItems.lunarEssence.skill, CraftSkill.enchanting);
    });

    test('every equipLevel sits in the band; stock sits at or below it', () {
      final loc = World.byId(zone);
      for (final def in MirrormereItems.all) {
        if (def is EquipmentDef) {
          expect(
            def.equipLevel,
            inInclusiveRange(loc.minLevel, loc.maxLevel),
            reason: '${def.id} cannot be worn anywhere near this zone',
          );
        } else {
          expect(
            def.equipLevel,
            lessThanOrEqualTo(loc.minLevel),
            reason: '${def.id} is stock and must be usable on arrival',
          );
        }
      }
    });

    test('crafted equipment leaves properName null; the drops set it', () {
      // ⚠️ ITEMS §9b.5a — a crafted name is COMPOSED from material + form, so
      // writing one down reintroduces the drift the rule prevents.
      for (final def in MirrormereItems.all.whereType<EquipmentDef>()) {
        final named = def.rarity.index >= Rarity.rare.index;
        expect(
          def.properName != null,
          named,
          reason: '${def.id} is ${def.rarity.name} and its properName is wrong',
        );
      }
    });

    test('Bloodwood spends exactly one socket, per §4.1a', () {
      // ⚠️ §9b.6's range is 1–2; the ruling takes the BOTTOM, floored at the
      // previous tier's count. Gems are Phase 8 and an empty socket is still
      // a promise.
      for (final def in MirrormereItems.all.whereType<EquipmentDef>()) {
        final expected = def.material == 'Bloodwood' ? 1 : 0;
        expect(
          def.socketCount,
          expected,
          reason: '${def.id} promises a socket count §4.1a did not spend',
        );
      }
    });

    test('the staff out-accurates wand and knot combined (§9b.8 ruling 2)', () {
      final staff = MirrorflaxCheck.acc(MirrormereItems.bloodwoodQuarterstaff);
      final wand = MirrorflaxCheck.acc(MirrormereItems.bloodwoodWand);
      final knot = MirrorflaxCheck.acc(MirrormereItems.bloodwoodKnot);
      expect(
        staff,
        greaterThanOrEqualTo(wand + knot),
        reason: '§4.1a restores the rule the shipped Rowan broke',
      );
      expect(
        MirrormereItems.bloodwoodQuarterstaff.twoHanded,
        isTrue,
        reason: 'a quarterstaff that leaves the offhand free is free damage',
      );
    });

    test('⭐ the Mirrorflax set totals 49 HP · 5 acc · 4 dodge · 10/20 '
        'deflect', () {
      const setIds = {
        'mirrorflax_hood',
        'mirrorflax_robe',
        'mirrorflax_leggings',
        'mirrorflax_boots',
        'mirrorflax_gloves',
      };
      final pieces = MirrormereItems.all
          .whereType<EquipmentDef>()
          .where((d) => setIds.contains(d.id))
          .toList();
      expect(pieces, hasLength(5), reason: 'the armour set is incomplete');
      int sum(int Function(ItemModifiers) f) =>
          pieces.fold(0, (a, d) => a + f(d.modifiers));
      expect(sum((m) => m.maxHpBonus), 49, reason: 'the set HP total drifted');
      expect(sum((m) => m.accuracyBonus), 5);
      expect(
        sum((m) => m.dodge),
        4,
        reason: 'Lunar\'s affinity is dodge and the set must carry a taste',
      );
      expect(sum((m) => m.deflectChance), 10);
      expect(sum((m) => m.deflectAmount), 20);
      // ⭐ Every armour piece must sit in a slot that can carry a set (§3.2).
      for (final d in pieces) {
        expect(d.slot.carriesSet, isTrue, reason: '${d.id} is in a bad slot');
      }
    });

    test('the epic fights the set robe for the same slot, deliberately', () {
      expect(
        MirrormereItems.theLargerReflection.slot,
        MirrormereItems.mirrorflaxRobe.slot,
        reason: 'the epic is the reason to BREAK your set',
      );
      expect(
        MirrormereItems.theLargerReflection.tradability,
        Tradability.untradeable,
      );
      expect(
        MirrormereItems.theWaningCharm.tradability,
        Tradability.untradeable,
      );
    });

    test('both drop-only pieces carry Lunar\'s dodge affinity (§2.5a)', () {
      expect(
        MirrormereItems.theWaningCharm.modifiers.dodge,
        9,
        reason: 'the rare chase is how a player learns Lunar is dodge',
      );
      expect(MirrormereItems.theLargerReflection.modifiers.dodge, 6);
    });

    test('every crafted piece salvages back into its own material', () {
      for (final def in MirrormereItems.all.whereType<EquipmentDef>()) {
        if (def.properName != null) continue; // drops do not salvage
        expect(def.salvage, isNotEmpty, reason: '${def.id} cannot be broken');
        for (final y in def.salvage) {
          expect(
            MirrormereItems.all.map((d) => d.id),
            contains(y.defId),
            reason: '${def.id} salvages into a foreign material',
          );
          expect(y.min, greaterThan(0));
          expect(y.max, greaterThanOrEqualTo(y.min));
        }
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final herald = MirrormereBestiary.heraldOfTheWaxing;
      final moon = MirrormereBestiary.theMoonBelow;
      expect(
        herald.maxHpAt(32),
        (MageState.scaledMaxHp(32) * Archetypes.redoubt.hpScale).round(),
        reason: 'a second HP curve has been introduced',
      );
      expect(
        moon.maxHpAt(37),
        (MageState.scaledMaxHp(37) * Archetypes.tyrant.hpScale).round(),
      );
      expect(moon.maxHpAt(37), greaterThan(herald.maxHpAt(32)));
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 32. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(32);
      for (final e in MirrormereBestiary.commons) {
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

    test('two nodes — the wood and the fibre', () {
      expect(
        nodes,
        hasLength(2),
        reason: 'a pure zone authors one node per gatherable material',
      );
      expect(nodes.map((n) => n.id).toSet(), {
        'mm_bloodwood_grove',
        'mm_mirrorflax_shallows',
      });
    });

    test('every node is reachable from GatherNodes.all', () {
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} is defined but not listed, so it never spawns',
        );
      }
    });

    test('every node yields a real, fungible material of THIS zone', () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(def, isA<MaterialDef>());
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields ${n.yieldsDefId}, which is not stackable',
        );
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} yields another zone\'s material',
        );
        expect(n.min, greaterThan(0));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('the node skill is the material\'s consuming skill (§6a.1)', () {
      // ⭐ Woodcarving ← Felling, Tailoring ← Foraging.
      expect(
        GatherNodes.byId('mm_bloodwood_grove')!.skill,
        GatherSkill.felling,
      );
      expect(
        GatherNodes.byId('mm_mirrorflax_shallows')!.skill,
        GatherSkill.foraging,
      );
    });

    test('⚠️ the gate essence has no node', () {
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('lunar_essence')),
        reason: 'a node would turn the Celestial Totem into an errand',
      );
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 71);
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

    test('every item carries lore, and no equipment lore names a stat', () {
      for (final def in MirrormereItems.all) {
        expect(def.lore, isNotEmpty, reason: '${def.id} has no lore');
        expect(
          def.lore.endsWith('.'),
          isTrue,
          reason: '${def.id} lore is not a sentence',
        );
        expect(
          RegExp(
            r'\d+\s*(hp|dodge|accuracy|damage)',
            caseSensitive: false,
          ).hasMatch(def.lore),
          isFalse,
          reason: '${def.id} lore leaks mechanics',
        );
      }
    });
  });
}

/// A one-line reader so the accuracy-ladder assertion reads as the rule it is
/// checking rather than as three field accesses.
abstract final class MirrorflaxCheck {
  static int acc(EquipmentDef d) => d.modifiers.accuracyBonus;
}
