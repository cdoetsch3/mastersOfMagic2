import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_archetype.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_combat_stats.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/the_sunless_reach.dart';
import 'package:masters_of_magic_2/game/gathering/gather_node.dart';
import 'package:masters_of_magic_2/game/items/catalogue/the_sunless_reach_items.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/skills.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⚠️ **The parallel-lane exemption, stated once.** `solar_*` is defined in
/// The Kiln Desert's catalogue and `lunar_*` in The Mirrormere's, both of
/// which are being built in sibling worktrees (CELESTIAL_CONTRACT §3.2 — the
/// mote lives with the zone that first yields it); `pilgrims_ration` is the
/// Kiln Desert's too. Until those merge, the full drop-resolution law cannot
/// pass, so it is `skip:`ped by name rather than weakened — and the
/// locally-owned half of it runs today.
const _pendingSiblingZones = {
  'solar_dust',
  'solar_shard',
  'solar_crystal',
  'lunar_dust',
  'lunar_shard',
  'lunar_crystal',
  'pilgrims_ration',
};

void main() {
  const zone = 'the_sunless_reach';
  final all = SunlessReachBestiary.all;

  group('the roster matches the design', () {
    test('5 commons, 4 mini-bosses, 2 bosses', () {
      expect(
        SunlessReachBestiary.commons,
        hasLength(5),
        reason: 'a zone with four commons is a zone missing an encounter slot',
      );
      expect(
        SunlessReachBestiary.minis,
        hasLength(4),
        reason: 'a run draws 2 of 4',
      );
      expect(
        SunlessReachBestiary.bosses,
        hasLength(2),
        reason: 'a run draws 1 of 2',
      );
    });

    test('reachable through Bestiary.forZone', () {
      // ⚠️ Registration is where a silent failure lives (§7.1) — an unlisted
      // zone compiles fine and never appears in an encounter.
      expect(
        Bestiary.forZone(zone),
        hasLength(11),
        reason: 'SunlessReachBestiary.all is not listed in Bestiary.all',
      );
      expect(
        Bestiary.forZone(zone).toSet(),
        all.toSet(),
        reason: 'Bestiary.forZone returns a different set than the class does',
      );
    });

    test('the four minis are one of each mini archetype', () {
      // ⭐ ENEMIES §2g — a run draws 2 of 4, so this is what makes every visit
      // a different pair of tactical ROLES rather than just different names.
      expect(SunlessReachBestiary.minis.map((e) => e.archetype.id).toSet(), {
        'champion',
        'redoubt',
        'executioner',
        'hexer',
      }, reason: 'two minis share an archetype, so a draw can repeat a role');
    });

    test('⭐⭐ the boss pair is TWO Aspects — the one blessed doubling', () {
      // ⭐⭐ ENEMIES §2f/§2g + CELESTIAL §2.4: this is the only zone in the
      // game that fields two Aspects, and the pair IS the theme. Kills the
      // mutant that "fixes" the doubling into a Juggernaut/Tyrant pair.
      expect(
        SunlessReachBestiary.theLastLight.archetype.id,
        'aspect',
        reason: 'the Solar boss stopped being an Aspect',
      );
      expect(
        SunlessReachBestiary.theFirstDark.archetype.id,
        'aspect',
        reason: 'the Lunar boss stopped being an Aspect',
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
        reason: 'two creatures share an id, so one of them is unreachable',
      );
      expect(
        all.map((e) => e.name).toSet(),
        hasLength(all.length),
        reason: 'two creatures share a name',
      );
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

    test('every creature carries only Solar and/or Lunar, and its own zone '
        'holds both', () {
      final loc = World.byId(zone);
      const legal = {MagicElement.solar, MagicElement.lunar};
      for (final e in all) {
        expect(e.zoneId, zone, reason: '${e.id} is tagged to the wrong zone');
        expect(e.elements, isNotEmpty, reason: '${e.id} has no element');
        for (final el in e.elements) {
          expect(
            legal,
            contains(el),
            reason: '${e.id} carries a foreign element',
          );
          expect(
            loc.elements,
            contains(el),
            reason: '${e.id} uses an element world.dart does not give the zone',
          );
        }
      }
    });

    test('the per-creature element assignment matches ENEMIES §2e exactly', () {
      // ⭐ The fusion is a BOUNDARY, not a blend — five creatures are pure and
      // three carry both, and which is which is the whole design. Hard-coded
      // so a "make the hybrid hybrid everywhere" mutant dies here.
      const solar = [MagicElement.solar];
      const lunar = [MagicElement.lunar];
      const both = [MagicElement.solar, MagicElement.lunar];
      expect(SunlessReachBestiary.eclipseHerald.elements, both);
      expect(SunlessReachBestiary.crestlineWarden.elements, solar);
      expect(SunlessReachBestiary.nightglare.elements, solar);
      expect(SunlessReachBestiary.coldlightSwarm.elements, lunar);
      expect(SunlessReachBestiary.shadowpitchStalker.elements, lunar);
      expect(SunlessReachBestiary.solarArchon.elements, solar);
      expect(SunlessReachBestiary.theCrest.elements, both);
      expect(SunlessReachBestiary.bothSidedThing.elements, both);
      expect(SunlessReachBestiary.duskmarch.elements, lunar);
      // ⚠️ Both Aspects MUST be single-element (ENEMIES §2.5) — an Aspect is
      // one element's passive taken to an extreme, and a two-element one is
      // not an extreme of anything.
      expect(
        SunlessReachBestiary.theLastLight.elements,
        solar,
        reason: 'the Solar Aspect is no longer single-element',
      );
      expect(
        SunlessReachBestiary.theFirstDark.elements,
        lunar,
        reason: 'the Lunar Aspect is no longer single-element',
      );
    });

    test('⭐ the two Aspects are opposites, not a copy-paste', () {
      final light = SunlessReachBestiary.theLastLight;
      final dark = SunlessReachBestiary.theFirstDark;
      expect(
        light.elements.toSet().intersection(dark.elements.toSet()),
        isEmpty,
        reason: 'the two Aspects share an element, so the pair says nothing',
      );
      // ⚠️ CELESTIAL §2.4, verbatim: "They must not share a stat block or the
      // doubling says nothing."
      expect(
        light.combatStats,
        isNot(dark.combatStats),
        reason: 'the two Aspects share a stat block (§2.4 forbids it)',
      );
      // ⭐ And the kits differ in kind: the Solar half is all edge and carries
      // no wall at all; the Lunar half is the thing you cannot get through.
      expect(
        light.moves.any((m) => m.effect is ShieldEffect),
        isFalse,
        reason: 'The Last Light took cover; light does not',
      );
      expect(
        dark.moves.any((m) => m.effect is ShieldEffect),
        isTrue,
        reason: 'The First Dark has nothing to close over you with',
      );
    });

    test('the placeholder anchor name survived into the real roster', () {
      expect(
        all.map((e) => e.name),
        contains(World.opponentNameFor(World.byId(zone))),
        reason: 'the zone anchor name is not a creature in this roster',
      );
      // ⭐ ENEMIES §2e — the Eclipse Herald is the Adept and the yardstick,
      // "the only thing here that stands on both sides".
      expect(
        SunlessReachBestiary.eclipseHerald.archetype.id,
        'adept',
        reason: 'the anchor stopped being the zone yardstick',
      );
    });

    test('the zone band is 38–42, and nothing else', () {
      final loc = World.byId(zone);
      expect(loc.minLevel, 38, reason: 'the band floor moved');
      expect(loc.maxLevel, 42, reason: 'the band ceiling moved');
    });
  });

  group('combat stats match CELESTIAL_CONTRACT §2.3', () {
    // ⚠️ Kills the swapped-archetype mutant: a def whose combatStats were
    // copied from the WRONG archetype row still compiles and still looks
    // "reasonable," so every archetype present in this zone is checked
    // against its own row rather than sampling a few.
    test('the Adept is deliberately blank — the yardstick, unmodified', () {
      expect(
        SunlessReachBestiary.eclipseHerald.combatStats,
        EnemyCombatStats.none,
        reason: 'a yardstick with a thumb on the scale stops being one (§2.3)',
      );
    });

    test('the Bruiser hits like a truck and sometimes whiffs entirely', () {
      expect(
        SunlessReachBestiary.crestlineWarden.combatStats,
        const EnemyCombatStats(
          accuracyBonus: -8,
          critChance: 8,
          critDamage: 25,
        ),
        reason: 'the Crestline Warden is not on the Bruiser row',
      );
    });

    test('the Blighter\'s statuses always land', () {
      expect(
        SunlessReachBestiary.nightglare.combatStats,
        const EnemyCombatStats(accuracyBonus: 8),
        reason: 'Nightglare is not on the Blighter row',
      );
    });

    test('the Lasher is lots of small bites, one occasionally stinging', () {
      expect(
        SunlessReachBestiary.coldlightSwarm.combatStats,
        const EnemyCombatStats(critChance: 15, critDamage: -20),
        reason: 'the Coldlight Swarm is not on the Lasher row',
      );
    });

    test('the Skirmisher is hard to pin, always first', () {
      expect(
        SunlessReachBestiary.shadowpitchStalker.combatStats,
        const EnemyCombatStats(accuracyBonus: 5, dodge: 8),
        reason: 'the Shadowpitch Stalker is not on the Skirmisher row',
      );
    });

    test('the Champion is simply good at everything', () {
      expect(
        SunlessReachBestiary.solarArchon.combatStats,
        const EnemyCombatStats(accuracyBonus: 6, critChance: 10),
        reason: 'the Solar Archon is not on the Champion row',
      );
    });

    test('the Redoubt is a wall that erodes you', () {
      expect(
        SunlessReachBestiary.theCrest.combatStats,
        const EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
        reason: 'The Crest is not on the Redoubt row',
      );
    });

    test('the Executioner is one mistake ends you', () {
      expect(
        SunlessReachBestiary.bothSidedThing.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 8,
          critChance: 12,
          critDamage: 40,
        ),
        reason: 'the Both-Sided Thing is not on the Executioner row',
      );
    });

    test('the Hexer is slippery and always connecting', () {
      expect(
        SunlessReachBestiary.duskmarch.combatStats,
        const EnemyCombatStats(accuracyBonus: 8, dodge: 10),
        reason: 'the Duskmarch is not on the Hexer row',
      );
    });

    test('the Solar Aspect is the bright, accurate, spiky half — §2.4\'s row, '
        'verbatim', () {
      expect(
        SunlessReachBestiary.theLastLight.combatStats,
        const EnemyCombatStats(
          accuracyBonus: 20,
          critChance: 20,
          critDamage: 25,
        ),
        reason: 'The Last Light drifted off §2.4 (acc +20, crit 20 / +25)',
      );
    });

    test('the Lunar Aspect is the half you cannot find or hurt — §2.4\'s row, '
        'verbatim', () {
      expect(
        SunlessReachBestiary.theFirstDark.combatStats,
        const EnemyCombatStats(dodge: 10, deflectChance: 25, deflectAmount: 25),
        reason: 'The First Dark drifted off §2.4 (dodge 10, defl 25 / 25)',
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

    test('move ids are unique across the WHOLE bestiary, and all prefixed', () {
      // ⚠️ The prefix is what keeps 28 zones' move ids from colliding
      // (CELESTIAL §3.5/§7.2). Checked game-wide, not just in-zone: a
      // collision with a shipped zone is the failure that actually happens.
      final mine = [for (final e in all) ...e.moves.map((m) => m.id)];
      expect(
        mine.toSet(),
        hasLength(mine.length),
        reason: 'two moves in this zone share an id',
      );
      for (final id in mine) {
        expect(id.startsWith('sr_'), isTrue, reason: '$id is not zone-tagged');
      }
      // ⭐ Mages cast Spellbook ids by design (EnemyDef.isMage) — the law is
      // over CREATURE kits only.
      final everyone = [
        for (final e in Bestiary.all)
          if (!e.isMage) ...e.moves.map((m) => m.id),
      ];
      expect(
        everyone.toSet(),
        hasLength(everyone.length),
        reason: 'a move id collides with another zone\'s',
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
      // the moves. This is the seam where those two must agree. 📝 No mage in
      // this zone, so nothing is exempt from the move-count law here.
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

    test('raw damage stays in the shared authoring band', () {
      // ⚠️ CELESTIAL §1.1/§1.3's double-scaling trap. The engine already
      // scales damage by level, so this zone's 38–42 band arrives via the
      // ENCOUNTER LEVEL, never bigger raws.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.maxAmount * effect.hits,
            lessThanOrEqualTo(60),
            reason: '${e.id}\'s "${m.name}" is above the shared ceiling of 60',
          );
          expect(
            effect.averageTotal / m.chargeCost,
            lessThanOrEqualTo(12),
            reason: '${e.id}\'s "${m.name}" is above 12 raw per charge',
          );
        }
      }
    });

    test('⚠️ no off-element move anywhere in this zone', () {
      // ⚠️ ENEMIES §2e.2 names the four creatures in the whole game that carry
      // one, and none is here. Nothing in the Reach may reach for a third
      // element, and the boundary theme is the reason.
      const legal = {MagicElement.solar, MagicElement.lunar};
      for (final e in all) {
        expect(
          e.elements.toSet().difference(legal),
          isEmpty,
          reason: '${e.id} picked up an off-element §2e.2 never granted it',
        );
      }
    });

    test('the Blighter is multi-hit only', () {
      // ⚠️ §1.3's per-archetype rule — a Blighter wins by out-lasting.
      final nightglare = SunlessReachBestiary.nightglare;
      expect(nightglare.archetype.id, 'blighter');
      for (final m in nightglare.moves) {
        expect(
          m.effect,
          isA<DamageEffect>(),
          reason: '${m.name} is not damage',
        );
        expect(
          (m.effect as DamageEffect).hits,
          greaterThan(1),
          reason: '${m.name} is a single big hit, which is not a Blighter',
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
      final crest = SunlessReachBestiary.theCrest;
      final wall = crest.moves.firstWhere((m) => m.effect is ShieldEffect);
      expect(
        wall.priority,
        lessThan(3),
        reason: 'a wall that goes up after the hit lands is not a wall',
      );
    });

    test('no shield in the zone resolves at the attack rung', () {
      // ⚠️ The shipped priority ladder: shields 3, quick 5, aux 7/8, attack 9.
      // A shield at 9 goes up after everything it was meant to stop.
      for (final e in all) {
        for (final m in e.moves) {
          if (m.effect is! ShieldEffect) continue;
          expect(
            m.priority,
            lessThanOrEqualTo(3),
            reason: '${e.id}\'s "${m.name}" is a shield at priority 9',
          );
        }
      }
    });

    test('the Hexer gets ahead of the whole board, and bypasses a shield', () {
      final duskmarch = SunlessReachBestiary.duskmarch;
      expect(duskmarch.archetype.id, 'hexer');
      expect(
        duskmarch.moves.map((m) => m.priority).reduce((a, b) => a < b ? a : b),
        1,
        reason: 'the Hexer has no move that beats a shield to the board',
      );
      expect(
        duskmarch.moves.any(
          (m) =>
              m.effect is DamageEffect &&
              (m.effect as DamageEffect).ignoresShields,
        ),
        isTrue,
        reason: 'nothing the Hexer throws goes through a wall',
      );
    });

    test('priority 1–2 is spent only where the design asks for it', () {
      // ⚠️ The ladder's own rule: 1–2 are for genuinely Quickened strikes.
      // Here that is the Hexer (its whole signature) and the Redoubt's wall.
      for (final e in all) {
        for (final m in e.moves) {
          if (m.priority > 2) continue;
          expect(
            e.archetype.id == 'hexer' || m.effect is ShieldEffect,
            isTrue,
            reason:
                '${e.id}\'s "${m.name}" sits at priority ${m.priority} '
                'without being a Hexer strike or a pre-emptive wall',
          );
        }
      }
    });

    test('the Executioner\'s cost cap is lowered to 4, this quarter', () {
      // ⚠️ CELESTIAL §1.3 — at L42 a five-charge mini raw would be a one-shot
      // with change. Kills a mutant that reverts to the archetype's own 5.
      final thing = SunlessReachBestiary.bothSidedThing;
      expect(thing.archetype.id, 'executioner');
      for (final m in thing.moves) {
        expect(
          m.chargeCost,
          lessThanOrEqualTo(4),
          reason: '${m.name} is back at cost 5',
        );
      }
    });

    test('nothing in this zone lifesteals', () {
      // ⭐ ENEMIES §2.6 / §2f — the Siphon is cut from this zone, and casual
      // lifesteal is what made it stop being a shock.
      for (final e in all) {
        for (final m in e.moves) {
          final effect = m.effect;
          if (effect is! DamageEffect) continue;
          expect(
            effect.lifesteal,
            0,
            reason: '${e.id}\'s "${m.name}" leeches, which is not this zone',
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
    test('every id this zone OWNS is a real item', () {
      // ⭐ The half of the resolution law that can run today — it still kills
      // a typo in ebony_log, duskcap, eclipse_opal, duskcap_tonic,
      // crestline_ring or the_dividing_line.
      for (final e in all) {
        for (final id in e.drops.possibleDrops) {
          if (_pendingSiblingZones.contains(id)) continue;
          expect(
            ItemCatalogue.tryById(id),
            isNotNull,
            reason: '${e.id} drops "$id", which no catalogue defines',
          );
        }
      }
    });

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

    test('⭐ each common draws the §4.5 row its ROLE calls for', () {
      // ⭐⭐ The join between the roster lane and the item lane, pinned. §4.5
      // gives three common rows — material-A ×2, material-B ×2 and "the
      // Sentinel" — and ENEMIES §2e gives each creature a role. ⚠️ The two
      // `hide` commons resolve to `duskcap`, the zone's SECOND gatherable
      // material, because the Reach defines no hide (ETHEREAL §3.5.1); the
      // was-Sentinel keeps the eclipse-opal row. A mutant that swaps two of
      // these tables still compiles, still drops real items of the right
      // rarity, and silently rewrites what the zone is farmed for.
      const materialA = {'ebony_log', 'lunar_shard', 'lunar_dust'};
      const materialB = {'duskcap', 'solar_shard', 'solar_dust'};
      const sentinelRow = {
        'eclipse_opal',
        'solar_shard',
        'solar_dust',
        'duskcap_tonic',
      };
      Set<String> mainOf(EnemyDef e) => {
        for (final d in e.drops.main)
          if (d.defId != null) d.defId!,
      };

      // hide ×2 → material-B, the second gatherable material.
      expect(
        mainOf(SunlessReachBestiary.eclipseHerald),
        materialB,
        reason: 'the Eclipse Herald\'s hide role stopped paying in duskcap',
      );
      expect(
        mainOf(SunlessReachBestiary.shadowpitchStalker),
        materialB,
        reason:
            'the Shadowpitch Stalker\'s hide role stopped paying in duskcap',
      );
      // mote-only ×2 → material-A, and they carry the zone's one bonus roll.
      expect(
        mainOf(SunlessReachBestiary.nightglare),
        materialA,
        reason: 'Nightglare is off the ebony row',
      );
      expect(
        mainOf(SunlessReachBestiary.coldlightSwarm),
        materialA,
        reason: 'the Coldlight Swarm is off the ebony row',
      );
      // material → "the Sentinel" row, which is where the opal lives.
      expect(
        mainOf(SunlessReachBestiary.crestlineWarden),
        sentinelRow,
        reason: 'the Crestline Warden is off the eclipse-opal row',
      );

      // ⚠️ The ration rides material-A and nothing else (§4.5's bonus column).
      const onMaterialA = {'nightglare', 'coldlight_swarm'};
      for (final e in SunlessReachBestiary.commons) {
        expect(
          e.drops.bonus.any((d) => d.defId == 'pilgrims_ration'),
          onMaterialA.contains(e.id),
          reason:
              '${e.id} disagrees with §4.5 about whether it carries the '
              'ration bonus',
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
      for (final e in SunlessReachBestiary.commons) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isTrue,
          reason: '${e.id} always pays out',
        );
      }
      for (final e in [
        ...SunlessReachBestiary.minis,
        ...SunlessReachBestiary.bosses,
      ]) {
        expect(
          e.drops.main.any((d) => d.defId == null),
          isFalse,
          reason: '${e.id} is a fight you sought out; it must pay',
        );
      }
    });

    test('rarity climbs with rank — commons never drop Rare or better', () {
      for (final e in SunlessReachBestiary.commons) {
        for (final id in e.drops.possibleDrops) {
          final def = ItemCatalogue.tryById(id);
          if (def == null) continue; // covered by the skipped law above
          expect(
            def.rarity.index,
            lessThanOrEqualTo(Rarity.uncommon.index),
            reason: '${e.id} drops "$id", which is above its station',
          );
        }
      }
    });

    test('⭐ a hybrid drops BOTH parents\' mote ladders, and no third', () {
      // ⭐ CELESTIAL §3.2 — this zone defines NO motes of its own; it pays in
      // solar_* (The Kiln Desert) and lunar_* (The Mirrormere).
      final dropped = SunlessReachBestiary.allDrops;
      for (final id in [
        'solar_dust',
        'solar_shard',
        'solar_crystal',
        'lunar_dust',
        'lunar_shard',
        'lunar_crystal',
      ]) {
        expect(dropped, contains(id), reason: '$id is missing from the zone');
      }
      for (final id in dropped) {
        if (!id.endsWith('_dust') &&
            !id.endsWith('_shard') &&
            !id.endsWith('_crystal')) {
          continue;
        }
        expect(
          id.startsWith('solar_') || id.startsWith('lunar_'),
          isTrue,
          reason: '$id is a mote from a third element',
        );
      }
    });

    test('this zone defines no mote of its own', () {
      expect(
        SunlessReachItems.all.whereType<MoteDef>(),
        isEmpty,
        reason:
            'the mote lives with the zone that first yields it (§3.2) — '
            'solar_* is the Kiln Desert\'s and lunar_* the Mirrormere\'s',
      );
    });

    test('the mote ladder climbs with rank', () {
      // ⭐ Crystal is where the ladder is first FELT, so it must be a fight the
      // player chose (ITEMS §8).
      for (final e in SunlessReachBestiary.commons) {
        expect(
          e.drops.possibleDrops.where((id) => id.endsWith('_crystal')),
          isEmpty,
          reason: '${e.id} hands out Crystal',
        );
      }
      for (final b in SunlessReachBestiary.bosses) {
        expect(
          b.drops.always.where((d) => d.defId?.endsWith('_crystal') ?? false),
          hasLength(2),
          reason: '${b.id} does not guarantee both Crystals',
        );
      }
    });

    test('⚠️ no boss here carries a gate part — a hybrid never does', () {
      // ⚠️ ENEMIES §2e.1: the Celestial Totem's three essences ride the boss
      // pools of the three PURE zones (Kiln Desert, Mirrormere, Starfall
      // Basin). A key on a hybrid would be a fourth source for a three-part
      // gate.
      for (final b in SunlessReachBestiary.bosses) {
        for (final id in b.drops.possibleDrops) {
          expect(
            id,
            isNot(contains('essence')),
            reason: '${b.id} drops something that reads like a gate part',
          );
          expect(
            id,
            isNot(contains('totem')),
            reason: '${b.id} drops something that reads like a gate part',
          );
        }
      }
    });

    test('both bosses share one table, so the draw never changes the prize', () {
      // ⭐ A run draws one boss of two (§3d). Two boss tables that differ would
      // make the reward a coin flip on top of the fight.
      expect(
        SunlessReachBestiary.theLastLight.drops.possibleDrops,
        SunlessReachBestiary.theFirstDark.drops.possibleDrops,
        reason: 'the two Aspects pay differently',
      );
    });

    test('the Rare chase hangs off the mini pool, and stays rare', () {
      for (final e in SunlessReachBestiary.minis) {
        expect(
          e.drops.possibleDrops,
          contains('crestline_ring'),
          reason: '${e.id} cannot drop the zone chase',
        );
        expect(
          e.drops.mainChanceOf('crestline_ring'),
          lessThanOrEqualTo(0.10),
          reason: '${e.id} hands the chase out too freely',
        );
      }
      expect(
        ItemCatalogue.byId('crestline_ring').rarity,
        Rarity.rare,
        reason: 'the zone chase is no longer Rare',
      );
    });

    test('the epic is boss-only and stays a chase', () {
      final epics = SunlessReachItems.all
          .where((d) => d.rarity == Rarity.epic)
          .map((d) => d.id);
      expect(
        epics,
        contains('the_dividing_line'),
        reason: 'the quarter\'s wand epic left this catalogue',
      );
      for (final id in epics) {
        for (final e in all) {
          if (!e.drops.possibleDrops.contains(id)) continue;
          expect(e.rank, EnemyRank.boss, reason: '$id drops from ${e.id}');
          expect(
            e.drops.mainChanceOf(id),
            lessThanOrEqualTo(0.15),
            reason: '${e.id} hands $id out too freely',
          );
        }
      }
    });
  });

  group('the catalogue matches CELESTIAL_CONTRACT §4.5', () {
    test('eleven defs, and every one resolvable under this zone', () {
      expect(
        SunlessReachItems.all,
        hasLength(11),
        reason:
            '§7.1 counts the Sunless Reach at 9 item definitions; 📝 +2 on '
            '2026-10-01 — the opal ring and pendant, the Jewelry ladder\'s '
            'Jewelry-24 rung (ENCHANTING §5.3)',
      );
      for (final def in SunlessReachItems.all) {
        expect(
          ItemCatalogue.zoneOf(def.id),
          zone,
          reason: '${def.id} is not resolvable under $zone',
        );
      }
    });

    test('every equipLevel sits inside the band; nothing else gates', () {
      final loc = World.byId(zone);
      for (final def in SunlessReachItems.all) {
        if (def is EquipmentDef) {
          expect(
            def.equipLevel,
            inInclusiveRange(loc.minLevel, loc.maxLevel),
            reason: '${def.id} equips at ${def.equipLevel}, outside 38–42',
          );
        } else {
          // ⚠️ Materials, motes and consumables must be usable the moment a
          // player walks in — a material you cannot carry yet is a drop that
          // vanishes.
          expect(
            def.equipLevel,
            lessThanOrEqualTo(loc.minLevel),
            reason: '${def.id} gates above the band floor',
          );
        }
      }
    });

    test('crafted equipment leaves properName null; drops set it', () {
      // ⚠️ ITEMS §9b.5a — a crafted name composes from material + form, and a
      // written one would let the name drift from the facts.
      const crafted = {'ebony_quarterstaff', 'ebony_wand', 'ebony_knot'};
      const named = {'crestline_ring', 'the_dividing_line'};
      for (final def in SunlessReachItems.all.whereType<EquipmentDef>()) {
        if (crafted.contains(def.id)) {
          expect(
            def.properName,
            isNull,
            reason: '${def.id} is crafted and must compose its own name',
          );
        }
        if (named.contains(def.id)) {
          expect(
            def.properName,
            isNotNull,
            reason: '${def.id} is a named drop and needs its own name',
          );
          expect(
            def.tradability,
            Tradability.untradeable,
            reason: '${def.id} should not be buyable',
          );
        }
      }
    });

    test('the Ebony line spends exactly one socket apiece', () {
      // ⭐ §4.1a: Ebony's §9b.6 range is 1–2 sockets and this contract spends
      // 1. ⚠️ The quarterstaff is the two-hander; the knot is not.
      for (final id in [
        'ebony_quarterstaff',
        'ebony_wand',
        'ebony_knot',
        'the_dividing_line',
      ]) {
        final def = ItemCatalogue.byId(id) as EquipmentDef;
        expect(def.socketCount, 1, reason: '$id does not carry one socket');
      }
      expect(
        (ItemCatalogue.byId('ebony_quarterstaff') as EquipmentDef).twoHanded,
        isTrue,
        reason: 'the quarterstaff stopped being a two-hander',
      );
      expect(
        (ItemCatalogue.byId('ebony_wand') as EquipmentDef).twoHanded,
        isFalse,
        reason: 'a wand is not a two-hander',
      );
    });

    test('⭐ the crestline ring carries BOTH sides of the affinity pair', () {
      // ⭐ §4.5 — Solar's accuracy and Lunar's dodge, equal and opposed, is
      // the zone stated as an item. Kills the mutant that "tidies" it into
      // one stat.
      final ring = ItemCatalogue.byId('crestline_ring') as EquipmentDef;
      expect(
        ring.modifiers.accuracyBonus,
        ring.modifiers.dodge,
        reason: 'the two halves of the band no longer match',
      );
      expect(
        ring.modifiers.accuracyBonus,
        5,
        reason: 'the ring drifted off §4.5\'s acc 5 / dodge 5 / +20 HP',
      );
      expect(ring.modifiers.maxHpBonus, 20);
    });

    test('the tonic is a Tonic — over time, on the belt', () {
      final tonic = ItemCatalogue.byId('duskcap_tonic');
      expect(
        tonic,
        isA<BeltableDef>(),
        reason: 'a tonic is drunk mid-duel, so it must be Beltable (§6b.3)',
      );
      expect((tonic as BeltableDef).effect.healPerTurn, 34);
      expect(tonic.effect.healTurns, 3);
      expect(
        tonic.effect.heal,
        0,
        reason: 'a Tonic heals over time, not in a lump (§3.3)',
      );
    });

    test('⏳ eclipse_opal banks — no Celestial recipe spends it here', () {
      // ⚠️ §3.1/§7.4 — Jewelry's station stays at Rimeholt (L45), so the opal
      // is gatherable at 38 and spendable at 45. This zone must not sneak a
      // consumer in.
      final opal = ItemCatalogue.byId('eclipse_opal') as MaterialDef;
      expect(opal.skill, CraftSkill.jewelry);
      expect(opal.rarity, Rarity.uncommon);
      expect(opal.tier, 7);
    });
  });

  group('gather nodes', () {
    final nodes = GatherNodes.forZone(zone);

    test('three nodes — nothing here is kill-only', () {
      // ⭐ The first hybrid in the game whose three materials are ALL
      // world-held, which is also why the `hide` role resolves to duskcap
      // (ETHEREAL_CONTRACT §3.5.1) instead of to a pelt.
      expect(nodes, hasLength(3), reason: 'a node was dropped or duplicated');
      expect(nodes.map((n) => n.id).toSet(), {
        'sr_ebony_stand',
        'sr_duskcap_shelf',
        'sr_opal_seam',
      }, reason: 'a node id drifted');
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

    test('every node yields a real material this zone defines', () {
      final mine = SunlessReachItems.all.map((d) => d.id).toSet();
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
          reason: '${n.id} yields something that is not a material',
        );
        expect(
          mine,
          contains(n.yieldsDefId),
          reason: '${n.id} yields a material this zone does not define',
        );
        expect(n.min, greaterThan(0), reason: '${n.id} can yield nothing');
        expect(
          n.max,
          greaterThanOrEqualTo(n.min),
          reason: '${n.id} has an inverted range',
        );
      }
    });

    test('the node skill follows the material\'s consuming skill (§6a.1)', () {
      const expected = {
        'sr_ebony_stand': GatherSkill.felling,
        'sr_duskcap_shelf': GatherSkill.foraging,
        'sr_opal_seam': GatherSkill.mining,
      };
      for (final n in nodes) {
        expect(
          n.skill,
          expected[n.id],
          reason: '${n.id} is on the wrong skill',
        );
      }
    });

    test('node XP matches the shared formula: 9 + 2 × (minLevel − 1)', () {
      final expectedXp = 9 + 2 * (World.byId(zone).minLevel - 1);
      expect(expectedXp, 83, reason: 'the formula or the band moved');
      for (final n in nodes) {
        expect(n.xp, expectedXp, reason: '${n.id} has a stale XP value');
      }
    });
  });

  group('the level band is survivable', () {
    test('HP scales off the shared baseline, not a second curve', () {
      final crest = SunlessReachBestiary.theCrest;
      final dark = SunlessReachBestiary.theFirstDark;
      expect(
        crest.maxHpAt(38),
        (MageState.scaledMaxHp(38) * Archetypes.redoubt.hpScale).round(),
        reason: 'The Crest grew a second HP curve',
      );
      expect(
        dark.maxHpAt(42),
        (MageState.scaledMaxHp(42) * Archetypes.aspect.hpScale).round(),
        reason: 'The First Dark grew a second HP curve',
      );
    });

    test('no common one-shots a character who just walked in', () {
      // ⚠️ The zone opens at level 38. Anything that can open with a kill from
      // full health is a difficulty spike disguised as a wandering monster.
      final startingHp = MageState.scaledMaxHp(38);
      for (final e in SunlessReachBestiary.commons) {
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

    test('every item carries lore, and no equipment leaks a number', () {
      for (final def in SunlessReachItems.all) {
        expect(
          def.lore.length,
          greaterThan(20),
          reason: '${def.id} lore is thin',
        );
        expect(
          def.lore.endsWith('.'),
          isTrue,
          reason: '${def.id} lore is not a sentence',
        );
      }
    });
  });
}
