import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_kiln_desert.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_kiln_desert_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

void main() {
  const zone = 'the_kiln_desert';
  final all = KilnDesertBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        KilnDesertBestiary.commons,
        hasLength(5),
        reason:
            'a sixth or fourth common silently changes every encounter '
            'slot in the zone',
      );
      expect(
        KilnDesertBestiary.minis,
        hasLength(4),
        reason:
            'a run draws 2 '
            'of 4 minis; any other count changes the draw',
      );
      expect(
        KilnDesertBestiary.bosses,
        hasLength(2),
        reason:
            'the gate '
            'ruling assumes exactly two bosses, both carrying the key',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (CELESTIAL_CONTRACT
      // §7.1) — an unlisted zone compiles fine and never appears.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'the bestiary is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'a creature is defined but missing from the zone lists',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(KilnDesertBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so some draws repeat a role');
    });

    test('the boss pair is a mass and the sun, NOT a mirror', () {
      // ⭐⭐ ENEMIES §2e — The Cold Shadow is what the sun cannot reach, a
      // MASS, so a Juggernaut: §2g reserves Tyrant for "a person, a will,
      // something that decided," and nothing decided this. The Solar Deity is
      // the element itself, so an Aspect. No Tyrant in this zone.
      expect(
        KilnDesertBestiary.theColdShadow.archetype.id,
        'juggernaut',
        reason: 'reverting The Cold Shadow to Tyrant gives a shadow a mind',
      );
      expect(
        KilnDesertBestiary.solarDeity.archetype.id,
        'aspect',
        reason: 'the Aspect is what makes this a gate zone pair, not a rematch',
      );
      expect(
        KilnDesertBestiary.bosses.map((e) => e.archetype.id).toSet(),
        hasLength(2),
        reason: 'a mirrored boss pair teaches the same fight twice',
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
      expect(
        all.map((e) => e.id).toSet(),
        hasLength(all.length),
        reason: 'two creatures share an id, so one is unreachable by lookup',
      );
      expect(
        all.map((e) => e.name).toSet(),
        hasLength(all.length),
        reason: 'two creatures share a display name',
      );
    });

    test('every id is the snake_case of its own name', () {
      // ⚠️ The export, the art pipeline and the achievement log all key on id.
      // An id that drifts from its name is a rename nobody notices.
      for (final e in all) {
        final derived = e.name.toLowerCase().replaceAll(
          RegExp(r"[^a-z0-9]+"),
          '_',
        );
        expect(e.id, derived, reason: '${e.name} should be id "$derived"');
      }
    });

    test('no creature id collides with the rest of the game', () {
      final ids = Bestiary.all.map((e) => e.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'a Kiln Desert id shadows a creature from another zone',
      );
    });

    test('every creature is pure Solar — this is one of the three pure '
        'zones', () {
      // ⭐ CELESTIAL_CONTRACT §2.4: the_kiln_desert, the_mirrormere and
      // starfall_basin are the quarter's three pure zones, so each Celestial
      // element keeps exactly one pure region.
      final loc = World.byId(zone);
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is tagged to another zone');
        expect(e.elements, const [
          MagicElement.solar,
        ], reason: '${e.id} is not pure Solar, which breaks the §2.4 audit');
        expect(
          loc.elements,
          contains(MagicElement.solar),
          reason: 'world.dart no longer calls this a Solar zone',
        );
      }
    });

    test('the per-creature element assignment matches the roster table '
        'exactly', () {
      // ⚠️ Hard-coded rather than derived: a mutant that flips one creature
      // to lunar must fail here, not pass a "they all match each other" loop.
      const solar = [MagicElement.solar];
      expect(KilnDesertBestiary.shadeless.elements, solar);
      expect(KilnDesertBestiary.sunstruckPilgrim.elements, solar);
      expect(KilnDesertBestiary.glasspanCrawler.elements, solar);
      expect(KilnDesertBestiary.mirage.elements, solar);
      expect(KilnDesertBestiary.kilnMoth.elements, solar);
      expect(KilnDesertBestiary.sunTemplar.elements, solar);
      expect(KilnDesertBestiary.prismSentinel.elements, solar);
      expect(KilnDesertBestiary.saltmarchWraith.elements, solar);
      expect(KilnDesertBestiary.theShadelessHour.elements, solar);
      expect(KilnDesertBestiary.theColdShadow.elements, solar);
      // ⚠️ The Aspect MUST be single-element (ENEMIES §2.5).
      expect(
        KilnDesertBestiary.solarDeity.elements,
        solar,
        reason: 'an Aspect with two elements leans on neither passive',
      );
    });

    test('the archetype re-band of 2026-09-22 survived', () {
      // ⭐ ENEMIES §2e's roster table: Shadeless was Skirmisher, Sunstruck
      // Pilgrim was Drudge, Glasspan Crawler was Sentinel. Kills a mutant
      // that reverts any of the three.
      expect(
        KilnDesertBestiary.shadeless.archetype.id,
        'adept',
        reason: 'the Shadeless is the zone yardstick, not a Skirmisher',
      );
      expect(
        KilnDesertBestiary.sunstruckPilgrim.archetype.id,
        'blighter',
        reason: 'the Pilgrim is the Blind tutor; a Drudge teaches nothing',
      );
      expect(
        KilnDesertBestiary.glasspanCrawler.archetype.id,
        'bruiser',
        reason: 'the Crawler reads the charge bar; a Sentinel does not',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'world.dart advertises a creature this zone does not field',
      );
      expect(
        World.opponentNameFor(World.byId(zone)),
        'Sunstruck Pilgrim',
        reason: 'the anchor moved away from the roster table\'s creature',
      );
    });

    test('the zone band is 30–34, and nothing else', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 30, reason: 'the band floor moved under the items');
      expect(loc.maxLevel, 34, reason: 'the band ceiling moved');
      expect(
        loc.kind,
        LocationKind.route,
        reason: 'a dungeon here would re-open the §0.3 descending-run ruling',
      );
    });
  });

  group('combat stats match CELESTIAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present in this zone is checked
    // against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        KilnDesertBestiary.shadeless.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        KilnDesertBestiary.sunstruckPilgrim.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
        reason: 'the Pilgrim is off its §2.3 row',
      );
    });

    test('the Bruiser hits like a truck and sometimes whiffs', () {
      expect(
        KilnDesertBestiary.glasspanCrawler.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
        reason: 'the Crawler is off its §2.3 row',
      );
    });

    test('the Glasswing is spiky and hot', () {
      expect(
        KilnDesertBestiary.mirage.combatStats,
        const EnemyCombatStats(critChance: 20, critDamage: 30),
        reason: 'the Mirage is off its §2.3 row',
      );
    });

    test('the Lasher bites often and stings rarely', () {
      expect(
        KilnDesertBestiary.kilnMoth.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason:
            'the Kiln Moth is off its §2.3 row — note the NEGATIVE crit '
            'damage, which is the whole archetype',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        KilnDesertBestiary.sunTemplar.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Sun Templar is off its §2.3 row',
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        KilnDesertBestiary.prismSentinel.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason: 'the Prism Sentinel is off its §2.3 row',
      );
    });

    test('the Executioner keeps the FULL §2.3 row at this band', () {
      // ⚠️ Old Quarry trimmed its Executioner to 8/25 by the 2026-08-20
      // entry-band ruling. That ruling was about level 15–19; at 30–34 the
      // archetype carries its published numbers, as Frostfell's Coldsnap
      // already does.
      expect(
        KilnDesertBestiary.saltmarchWraith.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason: 'the Saltmarch Wraith was trimmed as if it were entry band',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        KilnDesertBestiary.theShadelessHour.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'The Shadeless Hour is off its §2.3 row',
      );
    });

    test('the Juggernaut is unstoppable, unsubtle', () {
      expect(
        KilnDesertBestiary.theColdShadow.combatStats,
        const EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
        reason: 'The Cold Shadow is off its §2.3 row',
      );
    });

    test('the Aspect is §2.4\'s Solar row, verbatim — it does not miss, and '
        'it takes your sight while it does not', () {
      expect(
        KilnDesertBestiary.solarDeity.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 25,
          critChance: 10,
          critDamage: 10,
        ),
        reason: 'the Solar Deity is off §2.4 — accuracy IS Solar\'s affinity',
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

    test(
      'crit damage and deflect amount never appear without their chance',
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
      },
    );
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

    test('move ids are unique across the WHOLE bestiary, and all prefixed '
        'kd_', () {
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason: 'two Kiln Desert moves share an id',
      );
      for (final id in mine) {
        expect(id.startsWith('kd_'), isTrue, reason: '$id is not zone-tagged');
      }
      // ⚠️ The prefix is what keeps 26 zones' move ids from colliding
      // (CELESTIAL_CONTRACT §3.5/§7.1) — proved against every shipped zone,
      // not just this one.
      final everything = [
        for (final e in Bestiary.all) ...e.moves.map((m) => m.id),
      ];
      expect(
        everything.toSet(),
        hasLength(everything.length),
        reason: 'a kd_ move id collides with another zone\'s',
      );
    });

    test('no move name collides with the game\'s own vocabulary', () {
      const reservedVerbs = {'charge', 'cast', 'focus'};
      final elements = MagicElement.values.map((e) => e.name).toSet();
      final spellNames = Spellbook.all.map((s) => s.name.toLowerCase()).toSet();
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
          expect(
            spellNames.contains(n),
            isFalse,
            reason: '"${m.name}" is a player spell name (ENEMIES §3.3)',
          );
        }
      }
    });

    test('move count and cost band respect the archetype shape', () {
      // ⭐ ENEMIES §3.2 — archetype supplies the SHAPE, the creature supplies
      // the moves. This is the seam where those two must agree.
      // 📝 No mage in this zone, so nothing is exempt from the move-count law
      // (the Collapsed Academy and Citadel lanes own `isMage`).
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
            reason:
                '${e.id}\'s "${m.name}" is cheaper than a ${a.name} '
                'should have',
          );
          expect(
            m.chargeCost,
            lessThanOrEqualTo(a.maxMoveCost),
            reason:
                '${e.id}\'s "${m.name}" is dearer than a ${a.name} '
                'should have',
          );
        }
      }
    });

    test('raw damage stays in the Whispering Woods band', () {
      // ⚠️ §1.1/§1.3's double-scaling trap. The engine already scales damage
      // by level, so this zone's 30–34 band arrives via the ENCOUNTER LEVEL,
      // never bigger raws. Hard ceilings: ≤ 60 raw on a move, ≤ 12 per charge.
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

    test('priorities use the shipped integer ladder', () {
      // ⚠️ Shields 3 (2 or less only to beat the player's own), quick 5,
      // aux 7/8, attack 9; 1–2 reserved for genuinely Quickened strikes.
      // ⚠️ A shield at 9 is the specific mutant: it would go up AFTER the
      // hit it was meant to absorb.
      for (final e in all) {
        for (final m in e.moves) {
          expect(
            m.priority,
            inInclusiveRange(1, 9),
            reason: '${e.id}\'s "${m.name}" is off the ladder entirely',
          );
          if (m.effect is ShieldEffect) {
            expect(
              m.priority,
              lessThanOrEqualTo(3),
              reason: '${e.id}\'s "${m.name}" is a wall that goes up last',
            );
          }
        }
      }
    });

    test('the Blighter is multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule — a Blighter out-lasts rather than
      // out-hits. ⭐ It is also how the zone teaches Blind: the engine rolls
      // the status per charge spent, so a cheap constant kit blinds steadily.
      final pilgrim = KilnDesertBestiary.sunstruckPilgrim;
      expect(pilgrim.archetype.id, 'blighter');
      for (final m in pilgrim.moves) {
        expect(
          m.effect,
          isA<DamageEffect>(),
          reason: '${m.name} is not an attack at all',
        );
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} landed as one big hit, which is a Bruiser',
        );
      }
    });

    test('the Lasher is multi-hit only — why a big shield is not the '
        'answer', () {
      final moth = KilnDesertBestiary.kilnMoth;
      expect(moth.archetype.id, 'lasher');
      for (final m in moth.moves) {
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} shatters a shield instead of chipping it',
        );
      }
    });

    test('the wall archetypes actually carry a wall', () {
      // ⚠️ Redoubt/Juggernaut are defined partly by attrition. Without a
      // ShieldEffect the archetype is only a bigger HP number.
      for (final e in all) {
        if (!{'sentinel', 'redoubt', 'juggernaut'}.contains(e.archetype.id)) {
          continue;
        }
        expect(
          e.moves.any((m) => m.effect is ShieldEffect),
          isTrue,
          reason:
              '${e.id} is a ${e.archetype.name} with nothing to hide '
              'behind',
        );
      }
    });

    test('the Redoubt\'s wall lands ahead of the player\'s own shield', () {
      final wall = KilnDesertBestiary.prismSentinel.moves.firstWhere(
        (m) => m.effect is ShieldEffect,
      );
      expect(
        wall.priority,
        lessThan(3),
        reason: 'the Prism Sentinel\'s wall resolves after the player\'s',
      );
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final hour = KilnDesertBestiary.theShadelessHour;
      expect(hour.archetype.id, 'hexer');
      expect(
        hour.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        hour.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing The Shadeless Hour throws goes through a wall',
      );
    });

    test('the Executioner\'s cost cap is lowered to 4, this quarter', () {
      // ⚠️ §1.3 — at the mini five-charge raw a level-47 Executioner lands
      // 884–1153 against a 607 HP bar. Kills a mutant that restores cost 5.
      final wraith = KilnDesertBestiary.saltmarchWraith;
      expect(wraith.archetype.id, 'executioner');
      for (final m in wraith.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '"${m.name}" is a one-shot with change at the band top',
        );
      }
    });

    test('nothing lifesteals except the Redoubt\'s one move', () {
      // ⭐ ENEMIES §2.6 — casual lifesteal is the Siphon's, and this zone
      // fields none. §1.3 allows the Redoubt exactly one.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          if (e.archetype.id == 'redoubt' && effect.lifesteal > 0) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" drinks, which is not this zone',
          );
        }
      }
      expect(
        KilnDesertBestiary.prismSentinel.moves.where(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).lifesteal > 0,
        ),
        hasLength(1),
        reason:
            'the Redoubt should have exactly ONE lifesteal move (§1.3) — '
            'zero makes it a plain wall, two make it a Siphon',
      );
    });

    test('the Aspect\'s dear move is cost 4 — Blind, taken further', () {
      // ⭐ The engine rolls Blind at 10% per charge spent on a landed Solar
      // attack, so charge cost IS the status magnitude. A cheaper finisher
      // would make the Aspect's whole premise quieter than a common's.
      final deity = KilnDesertBestiary.solarDeity;
      expect(
        deity.moves.map((m) => m.chargeCost).reduce((a, b) => a > b ? a : b),
        4,
        reason: 'the Solar Deity blinds less than the Sun Templar does',
      );
    });

    test('no off-element move — §2e.2 names none in this zone', () {
      // ⚠️ Off-element is licensed for four creatures in fifteen zones and
      // the Kiln Desert is not one of them.
      for (final e in all) {
        expect(
          e.elements,
          hasLength(1),
          reason: '${e.id} carries a second element',
        );
      }
    });
  });

  group('drop tables resolve and are honest', () {
    test('every id in every table is a real item', () {
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
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
      for (final e in KilnDesertBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...KilnDesertBestiary.minis,
        ...KilnDesertBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in KilnDesertBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          expect(
            ItemCatalogue.byId(id).rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a pure zone pays ONE mote ladder, and it is Solar', () {
      final dropped = KilnDesertBestiary.allDrops;
      for (final id in ['solar_dust', 'solar_shard', 'solar_crystal']) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      for (final id in dropped) {
        if (!id.endsWith('_dust') &&
            !id.endsWith('_shard') &&
            !id.endsWith('_crystal')) {
          continue;
        }
        expect(
          id.startsWith('solar_'),
          isTrue,
          reason: '$id is a foreign mote in one of the three PURE zones',
        );
      }
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight
      // the player chose (ITEMS §8; §4.1's "mini and boss and nowhere else").
      for (final e in KilnDesertBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in KilnDesertBestiary.bosses) {
        expect(
          b.drops.always.any((d) => d.defId == 'solar_crystal'),
          isTrue,
          reason: '${b.id} does not guarantee a Crystal',
        );
      }
    });

    test('⭐ the gate essence drops from BOTH bosses, on the always line', () {
      // ⚠️ ENEMIES §2e.1 / CELESTIAL_CONTRACT §4.1 — a run draws one boss of
      // two. A key on the weighted table, or on only one boss, turns a
      // mandatory progression item into a coin flip.
      for (final b in KilnDesertBestiary.bosses) {
        final entry = b.drops.always.where((d) => d.defId == 'solar_essence');
        expect(
          entry,
          hasLength(1),
          reason: '${b.id} does not guarantee the Solar Essence',
        );
        expect(
          entry.single.chance,
          1,
          reason: '${b.id} rolls for a tier gate part',
        );
        expect(
          b.drops.main.any((d) => d.defId == 'solar_essence'),
          isFalse,
          reason: '${b.id} also weights the essence, which double-counts it',
        );
      }
      for (final e in [
        ...KilnDesertBestiary.commons,
        ...KilnDesertBestiary.minis,
      ]) {
        expect(
          e.drops.possibleDrops,
          isNot(contains('solar_essence')),
          reason: '${e.id} is not a boss and must not carry the gate part',
        );
      }
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in KilnDesertBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('the_shadeless_band'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('the_shadeless_band'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(ItemCatalogue.byId('the_shadeless_band').rarity, Rarity.rare);
    });

    test('the epic is boss-only', () {
      final epics = KilnDesertItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(
        epics,
        contains('the_hardest_edge'),
        reason: 'the zone lost its epic',
      );
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(
            e.drops.mainChanceOf(id),
            lessThanOrEqualTo(0.15),
            reason: '${e.id} hands out $id too freely',
          );
        }
      }
    });

    test('the hide role resolves to glasswort — the zone\'s SECOND '
        'material', () {
      // ⭐ ETHEREAL_CONTRACT §3.5.1: the Kiln Desert defines no hide, so
      // "something died" pays in the zone's own stuff. ⚠️ Kills a mutant
      // that invents a `kiln_hide` or drops the role silently.
      for (final e in [
        KilnDesertBestiary.shadeless,
        KilnDesertBestiary.sunstruckPilgrim,
        KilnDesertBestiary.kilnMoth,
      ]) {
        expect(
          e.drops.possibleDrops,
          contains('glasswort'),
          reason: '${e.id} carries the hide role and pays nothing for it',
        );
      }
      for (final id in KilnDesertBestiary.allDrops) {
        expect(
          id,
          isNot(contains('hide')),
          reason: '$id looks like an invented hide; this zone has none',
        );
      }
    });

    test('every zone item is a real ItemDef owned by this zone', () {
      for (final def in KilnDesertItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
      expect(
        KilnDesertItems.all,
        hasLength(13),
        reason: 'CELESTIAL_CONTRACT §4.1 authors exactly 13 defs',
      );
    });
  });

  group('the catalogue obeys the contract', () {
    test('equipment sits inside the band; stock sits at or below its '
        'floor', () {
      final loc = World.byId(zone);
      for (final def in KitchenSink.equipment) {
        expect(
          def.equipLevel,
          inInclusiveRange(loc.minLevel, loc.maxLevel),
          reason: '${def.id} cannot be worn anywhere in its own zone',
        );
      }
      for (final def in KitchenSink.notEquipment) {
        expect(
          def.equipLevel,
          lessThanOrEqualTo(loc.minLevel),
          reason: '${def.id} is stock and must be usable from the band floor',
        );
      }
    });

    test('crafted equipment leaves properName null; drops set it', () {
      // ⚠️ §3.5 — a crafted name composes from material + form (ITEMS
      // §9b.5a). A properName on a crafted piece freezes it.
      for (final id in [
        'ironwood_quarterstaff',
        'ironwood_wand',
        'ironwood_knot',
      ]) {
        expect(
          ItemCatalogue.byId(id).properName,
          isNull,
          reason: '$id is crafted and must compose its own name',
        );
      }
      for (final id in ['the_shadeless_band', 'the_hardest_edge']) {
        expect(
          ItemCatalogue.byId(id).properName,
          isNotNull,
          reason: '$id is a named drop and must carry its name',
        );
      }
    });

    test('the Woodcarving ladder is §4.1a\'s Ironwood row, verbatim', () {
      // ⚠️ The accuracy column STOPS climbing and the knot's goes DOWN
      // (Rowan 6 → Ironwood 5) because hitChance caps at 100 (§2.1a). A
      // mutant that "fixes" the knot back up to 6 breaks §9b.8 ruling 2:
      // staff (9) ≥ wand (4) + knot (5).
      final staff = ItemCatalogue.byId('ironwood_quarterstaff') as EquipmentDef;
      final wand = ItemCatalogue.byId('ironwood_wand') as EquipmentDef;
      final knot = ItemCatalogue.byId('ironwood_knot') as EquipmentDef;
      expect(staff.modifiers.damagePerCharge, 5);
      expect(staff.modifiers.accuracyBonus, 9);
      expect(wand.modifiers.damagePerCast, 6);
      expect(wand.modifiers.accuracyBonus, 4);
      expect(
        knot.modifiers.accuracyBonus,
        5,
        reason:
            'the knot climbed back '
            'to Rowan\'s 6 and broke staff ≥ wand + knot',
      );
      expect(
        staff.modifiers.accuracyBonus,
        greaterThanOrEqualTo(
          wand.modifiers.accuracyBonus + knot.modifiers.accuracyBonus,
        ),
        reason: 'the staff no longer out-accurates wand + knot combined',
      );
    });

    test('every socketed piece promises exactly one socket', () {
      // ⚠️ §4.1a: the BOTTOM of §9b.6's 0–1 range, floored at Rowan's count.
      // An empty socket is a promise and gems are still Phase 8.
      for (final id in [
        'ironwood_quarterstaff',
        'ironwood_wand',
        'ironwood_knot',
        'the_hardest_edge',
      ]) {
        expect(
          (ItemCatalogue.byId(id) as EquipmentDef).socketCount,
          1,
          reason: '$id promises a different number of empty sockets',
        );
      }
    });

    test('the two-handers say so, and nothing else does', () {
      for (final def in KitchenSink.equipment) {
        final expected =
            def.form == 'Quarterstaff' && def.slot == EquipSlot.mainHand;
        expect(
          def.twoHanded,
          expected,
          reason: '${def.id}\'s two-handedness disagrees with its form',
        );
      }
    });

    test('the mote ladder is ECONOMY §14c\'s values, uniform by tier', () {
      expect(ItemCatalogue.byId('solar_dust').value, 2);
      expect(ItemCatalogue.byId('solar_shard').value, 25);
      expect(
        ItemCatalogue.byId('solar_crystal').value,
        150,
        reason: 'mote values are per TIER and uniform across elements',
      );
      expect(
        ItemCatalogue.byId('solar_crystal').rarity,
        Rarity.uncommon,
        reason: 'Crystal is the one uncommon rung (ITEMS §8)',
      );
    });

    test('the gate essence is Bound, valueless and kill-only', () {
      final essence = ItemCatalogue.byId('solar_essence');
      expect(essence.tradability, Tradability.bound);
      expect(essence.value, 0, reason: 'a gate part must not be vendorable');
      expect(essence.rarity, Rarity.rare);
      expect(
        GatherNodes.all.map((n) => n.yieldsDefId),
        isNot(contains('solar_essence')),
        reason: 'a node for the gate part is a second source (§3.4)',
      );
    });

    test('the consumable forms are §3.3\'s, and the Ration is NOT '
        'beltable', () {
      // ⚠️ ITEMS §9b.8 ruling 6 — Rations are not usable in a fight.
      expect(
        ItemCatalogue.byId('pilgrims_ration'),
        isA<ConsumableDef>(),
        reason: 'the Ration became belt-legal, which breaks the vocabulary',
      );
      expect(
        ItemCatalogue.byId('pilgrims_ration'),
        isNot(isA<BeltableDef>()),
        reason: 'the Ration must not reach the belt',
      );
      expect(
        ItemCatalogue.byId('glasswort_draught'),
        isA<BeltableDef>(),
        reason: 'the Draught must be belt-legal — it costs your turn',
      );
      expect((KilnDesertItems.pilgrimsRation).effect.heal, 110);
      expect(
        (KilnDesertItems.glasswortDraught).effect.heal,
        125,
        reason: '§3.3\'s ordering: a Draught beats a Ration',
      );
      expect(
        KilnDesertItems.glasswortDraught.effect.healPerTurn,
        0,
        reason: 'a Draught is a FLAT heal; over-time is a Tonic',
      );
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final crawler = KilnDesertBestiary.glasspanCrawler;
      final shadow = KilnDesertBestiary.theColdShadow;
      expect(
        crawler.maxHpAt(30),
        (MageState.scaledMaxHp(30) * Archetypes.bruiser.hpScale).round(),
        reason: 'a second HP curve crept in',
      );
      expect(
        shadow.maxHpAt(34),
        (MageState.scaledMaxHp(34) * Archetypes.juggernaut.hpScale).round(),
        reason: 'a second HP curve crept in',
      );
      expect(
        shadow.maxHpAt(34),
        greaterThan(crawler.maxHpAt(34)),
        reason: 'the boss no longer out-bulks a common',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 30. Anything that can open with a kill
      // from full health is a difficulty spike disguised as a wandering
      // monster.
      final startingHp = MageState.scaledMaxHp(30);
      for (final e in KilnDesertBestiary.commons) {
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

    test('two nodes — and for once both materials get one', () {
      // ⭐ The Kiln Desert has no hide and no cloth (§4.1), so nothing here
      // is kill-only and the whole 2-per-pure budget goes to the world.
      expect(nodes, hasLength(2), reason: 'a node is missing or duplicated');
      expect(nodes.map((n) => n.id).toSet(), {
        'kd_ironwood_stand',
        'kd_glasspan_flat',
      }, reason: 'a node id drifted from CELESTIAL_CONTRACT §6');
    });

    test('every node is reachable from GatherNodes.all', () {
      // ⚠️ An unlisted node compiles fine and simply never spawns.
      for (final n in nodes) {
        expect(
          GatherNodes.byId(n.id),
          same(n),
          reason: '${n.id} is defined but not in GatherNodes.all',
        );
      }
    });

    test('every node yields a real material of THIS zone', () {
      for (final n in nodes) {
        final def = ItemCatalogue.tryById(n.yieldsDefId);
        expect(def, isNotNull, reason: '${n.id} yields nothing real');
        expect(
          def!.isFungible,
          isTrue,
          reason: '${n.id} yields ${n.yieldsDefId}, which is not stackable',
        );
        expect(
          def,
          isA<MaterialDef>(),
          reason: '${n.id} gathers something that is not a material',
        );
        expect(
          ItemCatalogue.zoneOf(n.yieldsDefId),
          zone,
          reason: '${n.id} gathers another zone\'s material',
        );
        expect(n.min, greaterThan(0));
        expect(n.max, greaterThanOrEqualTo(n.min));
      }
    });

    test('node skill matches the material\'s consuming skill (§6a.1)', () {
      // ⭐ Woodcarving ← Felling, Potions ← Foraging.
      expect(
        GatherNodes.byId('kd_ironwood_stand')!.skill,
        GatherSkill.felling,
        reason: 'ironwood is Woodcarving stock and Felling is its half',
      );
      expect(
        GatherNodes.byId('kd_glasspan_flat')!.skill,
        GatherSkill.foraging,
        reason: 'glasswort is a herb and herbs are foraged',
      );
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 67, reason: 'the band floor moved under the formula');
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });

    test('no node id collides with the rest of the game', () {
      final ids = GatherNodes.all.map((n) => n.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'a kd_ node id shadows another zone\'s',
      );
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

    test('every item carries lore too', () {
      for (final def in KilnDesertItems.all) {
        expect(
          def.lore.length,
          greaterThan(20),
          reason: '${def.id} has no lore line',
        );
      }
    });
  });
}

/// Small split of the zone catalogue, so the equip-level law can say two
/// different things about gear and about stock without repeating the filter.
abstract final class KitchenSink {
  static final equipment = KilnDesertItems.all.whereType<EquipmentDef>();
  static final notEquipment = KilnDesertItems.all.where(
    (d) => d is! EquipmentDef,
  );
}
