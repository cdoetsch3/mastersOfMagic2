// ZONE BALANCE PROBE — a seeded, headless autoplay harness that measures
// whether a zone's difficulty matches its band, the content equivalent of
// `packages/mom_engine/tool/balance_sim.dart` (docs/IMPLEMENTATION_PLAN.md
// Phase 4), which gated the element-effect balance pass. That sim answers
// "are the twelve elements even with each other"; this one answers "is
// Frostfell Pass, as shipped, roughly as hard as a level-21-26 zone should
// be" — a maintainer reads the report before playtesting new content.
//
// NOT a shipped feature. It lives in test/tool land next to
// `tool/export_content_test.dart` (a test-run tool, not a game feature) and
// is invoked the same way:
//
//   flutter test tool/balance_probe_test.dart            (CI-fast default)
//   BALANCE_PROBE_DEEP=1 flutter test tool/balance_probe_test.dart  (full report)
//
// ⚠️ **Gating note.** Phase 4's own sim (`balance_sim.dart`) isn't wired into
// `flutter test`/`dart test` at all — it is a bare `main()` run by hand via
// `dart run`. This probe has to be a `_test.dart` file instead (like
// `export_content_test.dart`, for the same reason its own doc gives: it
// needs the real Flutter-side game code — Bestiary, ItemCatalogue, World —
// and `flutter test` is the cheapest place that code runs headless). So the
// gate here is a duel-count knob, not an on/off switch: a tiny default N
// keeps the file cheap enough to run on every `flutter test` pass, and
// `BALANCE_PROBE_DEEP=1` unlocks the N the maintainer actually reads
// findings from.
//
// ⭐ **Engine and production code untouched.** Every duel is built through
// the exact campaign seam: `EnemyDef` → `EnemyEncounter` → `LocalAiDriver` →
// `DuelController` (the same chain `test/enemy_combat_stats_test.dart` pins
// field-for-field), so HP/damage scaling and combat-stat application can
// never drift from what a real fight does. The only thing this file adds is
// driving both sides afterward with its own fixed-intelligence `LadderAi`
// instead of a human player and the creature's own archetype intelligence —
// see [_probeIntelligence] for why.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/enemies/whispering_woods.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/recipe_book.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// ⭐ **One fixed intelligence, both sides** — the probe's whole point is to
/// isolate CONTENT (archetype hp/damage scales, a creature's own move set)
/// from BRAIN (how well it's played). The shipped campaign already varies
/// brain skill by archetype (drudge = 1 up to tyrant = 9,
/// `lib/game/enemies/enemy_archetype.dart`) and by roster persona (Wick = 1
/// up to Procarius = 10, `lib/game/ai_personas.dart`) — mixing that into a
/// difficulty probe would make a win-rate swing ambiguous between "this
/// archetype's numbers are off" and "this archetype's brain rung is higher".
/// So both the player and the creature are driven by [LadderAi] at the same
/// rung, and only the LOADOUT differs (a mage's representative kit vs. a
/// creature's own moves — never the skill applying them).
///
/// 7 is docs/IMPLEMENTATION_PLAN.md Phase 4's own ruling for exactly this
/// question ("what intelligence is the balance target measured at?"):
/// "i7 — competent, status-aware, and roughly what a real opponent should
/// feel like." `ai_personas.dart` independently describes 7 the same way
/// ("starts predicting what you are charging toward").
const int _probeIntelligence = 7;

/// Turn cap mirroring `balance_sim.dart` — `DuelEngine.fatigueThreshold`
/// (50) plus escalating unblockable damage already guarantees termination
/// long before this; it exists only as a belt-and-braces stop.
const int _turnCap = 200;

// ---------------------------------------------------------------------
// 📝 First-pass placeholder sanity bands — the maintainer tunes these
// against real playtesting, exactly like Phase 4's element bands. Given
// verbatim from the brief:
//   commons: naked win 45-90%, crafted 65-97%
//   bosses:  naked win 10-60%, crafted 35-85%
// No mini-boss band was specified. Minis sit structurally between commons
// and bosses (one is drawn per section, same as a boss, but there are two
// of them per run rather than one) — 📝 this probe reuses the COMMON band
// for minis as the closer placeholder rather than inventing a third number
// out of nothing, and flags every mini row with that borrowing so it reads
// as "unverified", not as a ruling.
// ---------------------------------------------------------------------
class _Band {
  final double loNaked;
  final double hiNaked;
  final double loCrafted;
  final double hiCrafted;
  const _Band({
    required this.loNaked,
    required this.hiNaked,
    required this.loCrafted,
    required this.hiCrafted,
  });
}

const _commonBand = _Band(loNaked: 0.45, hiNaked: 0.90, loCrafted: 0.65, hiCrafted: 0.97);
const _bossBand = _Band(loNaked: 0.10, hiNaked: 0.60, loCrafted: 0.35, hiCrafted: 0.85);

_Band _bandFor(EnemyRank rank) =>
    rank == EnemyRank.boss ? _bossBand : _commonBand;

/// Two loadout scenarios (the brief's "naked" / "crafted").
enum _Scenario { naked, crafted }

// ---------------------------------------------------------------------
// Crafted-only loadout derivation
// ---------------------------------------------------------------------

/// The band's crafted-only gear at [level]: for every equip slot, the best
/// CRAFTED item (a [RecipeBook] output, never a bestiary drop) a player
/// could actually be wearing at that level, summed.
///
/// ⭐ **Mechanical "best" rule, documented rather than eyeballed:** among the
/// crafted items unlocked for a slot (`equipLevel <= level`), pick the
/// highest `equipLevel` (the latest tier a player could have upgraded into);
/// ties broken by the larger raw stat total (every [ItemModifiers] field is
/// a player benefit, so summing them is a monotonic "more is better" proxy —
/// it does not need to be a *correct* power ranking, only a stable one);
/// final tie broken by item id for full determinism. This is exactly how
/// `oak_quarterstaff` vs. `oak_wand` (same equip level 1, different stat
/// shapes) resolves without a fight.
///
/// 📝 Two deliberate simplifications:
///  - **No set bonuses.** [Equipping.totals] — the real seam every other
///    reader goes through — doesn't model one either; there is no bonus
///    mechanic wired up in the shipped game to reproduce.
///  - **Always [Quality.standard].** A craft's quality is a roll
///    (Rough/Standard/Ornate/Master), not a guarantee; Standard is the ruled
///    ×1.00 baseline (`ItemModifiers.scaledBy`), so this reads as "a
///    competent crafter, not a lucky one" rather than either extreme.
ItemModifiers craftedGearAt(int level) {
  var total = ItemModifiers.none;
  for (final slot in EquipSlot.values) {
    final best = bestCraftedItemFor(slot, level);
    if (best == null) continue;
    // ⭐ Reuses THE resolution seam (Equipping.modifiersOf) rather than
    // reading `.modifiers` directly, so a quality-scaling rule change is
    // picked up here automatically, exactly like every other reader.
    total = total + Equipping.modifiersOf(best);
  }
  return total;
}

/// The single best CRAFTED item for [slot] unlocked at [level] (or null if
/// nothing crafted fills that slot yet) — the per-slot pick [craftedGearAt]
/// sums. Exposed on its own so the "best" rule (see [craftedGearAt]'s doc)
/// can be pinned directly, rather than only inferred from an aggregate sum
/// that several slots feed into.
EquipmentDef? bestCraftedItemFor(EquipSlot slot, int level) {
  final craftedIds = {for (final r in RecipeBook.all) r.outputId};
  final candidates = <EquipmentDef>[];
  for (final id in craftedIds) {
    final def = ItemCatalogue.tryById(id);
    if (def is EquipmentDef && def.slot == slot && def.equipLevel <= level) {
      candidates.add(def);
    }
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final byLevel = b.equipLevel.compareTo(a.equipLevel);
    if (byLevel != 0) return byLevel;
    final byPower = _statTotal(b.modifiers).compareTo(_statTotal(a.modifiers));
    if (byPower != 0) return byPower;
    return a.id.compareTo(b.id);
  });
  return candidates.first;
}

/// Sums every combat-relevant field — deliberately excludes [beltSlots]
/// (ITEMS §6b.2's non-combat axis) so a belt-heavy item never wins a
/// combat-stat tiebreak it has no business winning.
int _statTotal(ItemModifiers m) =>
    m.accuracyBonus +
    m.dodge +
    m.critChance +
    m.critDamage +
    m.deflectChance +
    m.deflectAmount +
    m.maxHpBonus +
    m.damagePerCast +
    m.damagePerCharge +
    m.shieldStrengthPercent +
    m.healingReceivedPercent +
    m.regrowPercent;

// ---------------------------------------------------------------------
// Level selection
// ---------------------------------------------------------------------

/// The level a creature of [rank] is met at, for a zone spanning
/// [minLevel]–[maxLevel].
///
/// ⭐ Mirrors `AdventureRun.roll`/`_rampedLevel` in `lib/game/adventure.dart`:
/// minis and bosses always fight at the top of the band
/// (`zone.maxLevel` — "elevated ranks fight at the top of the band, not on
/// the ramp"), while commons ramp across the whole band as the run
/// progresses. A single representative level for a common encounter is the
/// ramp's midpoint, rounded the same way `_rampedLevel` rounds.
int _levelFor(EnemyRank rank, int minLevel, int maxLevel) =>
    rank == EnemyRank.common ? ((minLevel + maxLevel) / 2).round() : maxLevel;

// ---------------------------------------------------------------------
// One duel, built exactly as the campaign builds it
// ---------------------------------------------------------------------

/// Builds one duel through the real seam and hands back the pieces the
/// probe needs to drive it — `DuelController` itself stays untouched;
/// nothing here reimplements HP/damage/combat-stat arithmetic by hand.
class _DuelRig {
  final MageState player;
  final MageState enemy;
  final DuelEngine engine;
  const _DuelRig(this.player, this.enemy, this.engine);

  factory _DuelRig.build({
    required EnemyDef def,
    required int level,
    required ItemModifiers playerGear,
    required int seed,
  }) {
    final controller = DuelController(
      // ⭐ A representative kit, not the naked/crafted axis under test — the
      // starter loadout is the shipped default ("a rounded five elements and
      // ten spells", `lib/game/loadout.dart`), so the probe's AI has a real
      // hand to play rather than an empty or hand-picked one.
      loadout: Loadout.starter,
      driver: LocalAiDriver(
        persona: EnemyEncounter(def: def, level: level).toPersona(),
        enemy: def,
        // Unused: the probe never calls `driver.exchangeTurn` (that would
        // hand the enemy its own archetype intelligence instead of the
        // probe's fixed rung) — it drives `engine` directly below.
        rng: Random(seed),
      ),
      playerLevel: level,
      playerGear: playerGear,
      rng: ReseedableRandom(seed),
    );
    return _DuelRig(controller.player, controller.enemy, controller.engine);
  }
}

class _Outcome {
  final bool decided; // engine.isOver — false only if the turn cap was hit
  final bool playerWon;
  final bool isDraw;
  final int turns;
  final int playerHp;
  final int playerMaxHp;
  const _Outcome({
    required this.decided,
    required this.playerWon,
    required this.isDraw,
    required this.turns,
    required this.playerHp,
    required this.playerMaxHp,
  });
}

_Outcome _playOne({
  required EnemyDef def,
  required int level,
  required ItemModifiers playerGear,
  required int seed,
}) {
  final rig = _DuelRig.build(
    def: def,
    level: level,
    playerGear: playerGear,
    seed: seed,
  );
  // ⭐ One shared rng stream for engine resolution AND both AIs' decisions —
  // the same convention `balance_sim.dart` uses, and the reason two probe
  // runs at the same seed reproduce the same duel bit-for-bit.
  final rng = rig.engine.rng;
  final playerAi = LadderAi(
    _probeIntelligence,
    spells: Loadout.starter.spells,
    elements: Loadout.starter.elements,
  );
  // ⭐ The creature's own moves and elements — never a Spellbook entry
  // (`enemy_def.dart`'s own rule) — with the SAME fixed rung as the player,
  // not `def.archetype.intelligence`. See [_probeIntelligence].
  final enemyAi = LadderAi(
    _probeIntelligence,
    spells: def.moves,
    elements: def.elements,
  );
  while (!rig.engine.isOver && rig.engine.turnNumber < _turnCap) {
    rig.engine.resolveTurn(
      playerAi.chooseAction(rig.player, rig.enemy, rng),
      enemyAi.chooseAction(rig.enemy, rig.player, rng),
    );
  }
  return _Outcome(
    decided: rig.engine.isOver,
    playerWon: rig.engine.isOver && identical(rig.engine.winner, rig.player),
    isDraw: rig.engine.isOver && rig.engine.isDraw,
    turns: rig.engine.turnNumber,
    playerHp: rig.player.hp,
    playerMaxHp: rig.player.maxHp,
  );
}

// ---------------------------------------------------------------------
// Aggregation + report
// ---------------------------------------------------------------------

class _Agg {
  int duels = 0;
  int wins = 0;
  int unfinished = 0;
  int draws = 0;
  int turnsSum = 0;
  int hpPctSumOnWins = 0; // percent of max HP, summed only over wins

  void add(_Outcome o) {
    duels++;
    turnsSum += o.turns;
    if (!o.decided) {
      unfinished++;
      return;
    }
    if (o.isDraw) {
      draws++;
    } else if (o.playerWon) {
      wins++;
      hpPctSumOnWins += (o.playerHp * 100 / o.playerMaxHp).round();
    }
  }

  double get winRate => duels == 0 ? 0 : wins / duels;
  double get meanTurns => duels == 0 ? 0 : turnsSum / duels;
  double get meanHpPctOnWins => wins == 0 ? 0 : hpPctSumOnWins / wins;
}

class ProbeReport {
  final String table;
  final List<String> warnings;
  const ProbeReport(this.table, this.warnings);
}

/// Zone ids with a bestiary, in the same order `Bestiary.all` concatenates
/// them — derived, never hand-copied, so a 12th zone landing in
/// `bestiary.dart` appears here for free.
List<String> _zoneOrder() {
  final seen = <String>{};
  final order = <String>[];
  for (final e in Bestiary.all) {
    if (seen.add(e.zoneId)) order.add(e.zoneId);
  }
  return order;
}

/// Runs the probe and renders the report.
///
/// [zoneIds] restricts which zones run (defaults to every zone with a
/// bestiary) — used by the determinism companion test to stay tiny.
/// [duelsPerCreature] is K in the brief: seeded duels run per creature per
/// scenario, then rolled up to one row per zone × rank × scenario.
ProbeReport runZoneBalanceProbe({
  List<String>? zoneIds,
  required int duelsPerCreature,
}) {
  final zones = zoneIds ?? _zoneOrder();
  final buf = StringBuffer();
  final warnings = <String>[];
  var seed = 1; // ⭐ one incrementing counter, walked in a fixed nested
  // loop order below — this (not wall-clock, not hashCode) is what makes
  // two runs of this function byte-identical.

  buf.writeln(
    'ZONE BALANCE PROBE — $duelsPerCreature duels/creature/scenario, '
    'intelligence $_probeIntelligence both sides, cap $_turnCap turns',
  );
  buf.writeln(
    '${'zone'.padRight(22)}${'rank'.padRight(7)}${'scenario'.padRight(9)}'
    '${'n'.padRight(7)}${'win%'.padRight(8)}${'avgT'.padRight(7)}'
    '${'hp%win'.padRight(8)}flag',
  );

  for (final zoneId in zones) {
    final zone = World.byId(zoneId);
    final creatures = Bestiary.forZone(zoneId);
    for (final rank in EnemyRank.values) {
      final ofRank = creatures.where((c) => c.rank == rank).toList();
      if (ofRank.isEmpty) continue;
      final level = _levelFor(rank, zone.minLevel, zone.maxLevel);
      for (final scenario in _Scenario.values) {
        final gear = scenario == _Scenario.naked
            ? ItemModifiers.none
            : craftedGearAt(level);
        final agg = _Agg();
        for (final def in ofRank) {
          for (var i = 0; i < duelsPerCreature; i++) {
            agg.add(
              _playOne(def: def, level: level, playerGear: gear, seed: seed++),
            );
          }
        }
        final band = _bandFor(rank);
        final lo = scenario == _Scenario.naked ? band.loNaked : band.loCrafted;
        final hi = scenario == _Scenario.naked ? band.hiNaked : band.hiCrafted;
        final outside = agg.winRate < lo || agg.winRate > hi;
        var flag = '';
        if (outside) flag = 'WARN';
        if (rank == EnemyRank.mini) flag = flag.isEmpty ? '(mini~common)' : '$flag (mini~common)';

        buf.writeln(
          zone.name.padRight(22) +
              rank.name.padRight(7) +
              scenario.name.padRight(9) +
              '${agg.duels}'.padRight(7) +
              '${(agg.winRate * 100).toStringAsFixed(1)}%'.padRight(8) +
              agg.meanTurns.toStringAsFixed(1).padRight(7) +
              '${agg.meanHpPctOnWins.toStringAsFixed(0)}%'.padRight(8) +
              flag,
        );

        if (outside) {
          warnings.add(
            '${zone.name} / ${rank.name} / ${scenario.name} (Lv $level): '
            'win rate ${(agg.winRate * 100).toStringAsFixed(1)}% is outside '
            'the ${(lo * 100).toStringAsFixed(0)}-${(hi * 100).toStringAsFixed(0)}% '
            'placeholder band'
            '${rank == EnemyRank.mini ? ' (borrowed from commons — no mini band specified)' : ''}',
          );
        }
        if (agg.unfinished > 0) {
          warnings.add(
            '${zone.name} / ${rank.name} / ${scenario.name}: '
            '${agg.unfinished}/${agg.duels} duels hit the $_turnCap-turn cap '
            'without deciding — investigate before trusting this row',
          );
        }
        if (agg.draws > 0) {
          warnings.add(
            '${zone.name} / ${rank.name} / ${scenario.name}: '
            '${agg.draws}/${agg.duels} duels ended in a draw (both mages at '
            '0 HP the same tick) — excluded from win% and hp%win',
          );
        }
      }
    }
  }
  return ProbeReport(buf.toString(), warnings);
}

void main() {
  final deep = Platform.environment['BALANCE_PROBE_DEEP'] == '1';
  // 📝 CI-fast default: ~2,900 duels (11 zones × ~11 creatures × 2 scenarios
  // × 12), which is seconds. The deep run — what the maintainer actually
  // reads the Kinetic curve from — is ~60,000 duels and takes minutes; it is
  // opt-in via BALANCE_PROBE_DEEP=1 rather than the file's default because
  // nothing in this repo's `flutter test` gate should take minutes.
  final duelsPerCreature = deep ? 250 : 12;

  test(
    'zone balance probe',
    () {
      final report = runZoneBalanceProbe(duelsPerCreature: duelsPerCreature);
      print(report.table);
      if (report.warnings.isEmpty) {
        print('\nNo zones outside the placeholder sanity bands.');
      } else {
        print('\nWARN — outside first-pass placeholder sanity bands:');
        for (final w in report.warnings) {
          print('  - $w');
        }
      }
    },
    timeout: Timeout(Duration(minutes: deep ? 15 : 2)),
  );

  test('deterministic: two runs at a tiny N print byte-identical reports', () {
    final a = runZoneBalanceProbe(
      zoneIds: const ['whispering_woods', 'the_molten_deep'],
      duelsPerCreature: 3,
    );
    final b = runZoneBalanceProbe(
      zoneIds: const ['whispering_woods', 'the_molten_deep'],
      duelsPerCreature: 3,
    );
    expect(a.table, b.table, reason: 'the report must be a pure function of its seeds');
    expect(a.warnings, b.warnings);
  });

  group('probe machinery', () {
    test(
      'crafted loadout derivation picks only crafted-obtainable gear',
      () {
        // Every Primal recipe is unlocked well before level 12 (the highest
        // `skillLevel` in `PrimalRecipes` is 10; equip levels top out at 11),
        // so this is the full Primal crafted wardrobe, hand-verified against
        // `primal_recipes.dart` + the Whispering Woods/Ashfall Vale/Cinderpeak
        // catalogues:
        //   mainHand  birch_quarterstaff (eq10): +2 dmg/charge, +6 accuracy
        //   offHand   birch_knot         (eq10): +4 accuracy
        //   hat       bogflax_hood       (eq10): +2 accuracy
        //   robeTop   bogflax_robe       (eq10): +10 max HP
        //   robeBottom bogflax_leggings  (eq10): +7 max HP
        //   boots     bogflax_boots      (eq10): +2 max HP
        //   gloves    bogflax_gloves     (eq10): +2 max HP
        //   belt      tuskhide_belt      (eq11): +2 belt slots
        // totals: accuracy 6+4+2=12, dmg/charge 2, max HP 10+7+2+2=21, belt 2
        final gear = craftedGearAt(12);
        expect(gear.accuracyBonus, 12, reason: 'crafted mainHand+offHand+hat accuracy');
        expect(gear.damagePerCharge, 2, reason: 'crafted mainHand damage/charge');
        expect(gear.maxHpBonus, 21, reason: 'crafted robe set max HP');
        expect(gear.beltSlots, 2, reason: 'crafted belt slots');
        expect(gear.damagePerCast, 0, reason: 'the wand lost the mainHand tiebreak — must not also contribute');
        expect(gear.critChance, 0);
        expect(gear.dodge, 0);
        expect(gear.deflectChance, 0);

        // ⭐ The negative check, isolated to ONE slot via [bestCraftedItemFor]
        // rather than inferred from an aggregate sum several slots feed into
        // (a mistake this test itself made on its first draft — the naive
        // "robeTop should read 6" assumption ignored that bindweed_leggings/
        // boots/gloves also contribute maxHpBonus at level 4, netting 12
        // there by coincidence, which would have silently passed even if
        // robeTop had wrongly resolved to something else entirely).
        //
        // `sporecap_mantle` (Whispering Woods, robeTop, +12 max HP, +2
        // accuracy, equip level 4) is DROP-ONLY — no recipe makes it — and by
        // its own doc comment "beats the Standard crafted robe (+6 HP)
        // outright". If the derivation ever started pulling from
        // `ItemCatalogue` instead of `RecipeBook` outputs, robeTop at level 4
        // would resolve to `sporecap_mantle` instead of `bindweed_robe` and
        // this fails immediately.
        final robeTopPick = bestCraftedItemFor(EquipSlot.robeTop, 4);
        expect(robeTopPick?.id, 'bindweed_robe', reason: 'the only CRAFTED robeTop item unlocked by level 4');
        expect(robeTopPick?.modifiers.maxHpBonus, 6);

        // And the aggregate at level 4, for completeness — everything the
        // Bindweed set (all equip level 1) plus the Fawnhide belt (equip
        // level 4) grants, nothing bogflax/birch/tuskhide (equip level
        // 10-11) or drop-only yet.
        final low = craftedGearAt(4);
        expect(
          low.maxHpBonus,
          6 + 4 + 1 + 1, // robe + leggings + boots + gloves
          reason: 'the whole Bindweed set\'s max HP, summed — NOT sporecap_mantle\'s +12 alone',
        );
        expect(
          low.accuracyBonus,
          5 + 3 + 1, // oak_quarterstaff + oak_knot + bindweed_hood
          reason: 'oak_quarterstaff(+5) + oak_knot(+3) + bindweed_hood(+1) — sporecap_mantle\'s +2 must not appear',
        );
        expect(low.beltSlots, 1, reason: 'fawnhide_belt unlocks at equip level 4');
      },
    );

    test(
      'enemy construction matches the campaign path field-for-field '
      '(kills the probe-drifts-from-campaign mutant)',
      () {
        // Same fixture `test/enemy_combat_stats_test.dart` pins its own
        // invariance test against: a real, stat-free Q1 creature.
        final fawn = WhisperingWoodsBestiary.listeningFawn;
        const level = 5;

        final rig = _DuelRig.build(
          def: fawn,
          level: level,
          playerGear: ItemModifiers.none,
          seed: 1,
        );

        // Independently hand-computed from the documented formula
        // (`DuelController._buildMage`'s own doc, and
        // `enemy_combat_stats_test.dart`'s `preSeamEnemy`) — NOT read back
        // off the rig, so a rig that quietly stopped going through
        // `EnemyEncounter`/`LocalAiDriver`/`DuelController` (e.g. someone
        // "simplifies" `_DuelRig.build` into hand-rolled arithmetic that
        // drifts from a future campaign change) fails this test even if
        // their arithmetic looks plausible.
        final expectedMaxHp =
            (MageState.scaledMaxHp(level) * fawn.archetype.hpScale).round();
        expect(rig.enemy.maxHp, expectedMaxHp, reason: 'enemy HP must be the level baseline × archetype hpScale');
        expect(rig.enemy.powerScale, fawn.archetype.damageScale, reason: 'enemy damage must carry the archetype scale');
        expect(rig.enemy.accuracyBonus, 0, reason: 'a stat-free Q1 EnemyDef must build at the engine baseline');
        expect(rig.enemy.dodge, 0);
        expect(rig.enemy.critChance, 0);
        expect(rig.enemy.critDamage, 50, reason: 'the engine\'s own inert default');
        expect(rig.enemy.deflectChance, 0);
        expect(rig.enemy.deflectAmount, 0);

        // The player side of the same rig: naked gear must build at exactly
        // the level baseline, nothing more.
        expect(rig.player.maxHp, MageState.scaledMaxHp(level), reason: 'naked player must be the bare level baseline');
        expect(rig.player.accuracyBonus, 0);
      },
    );
  });
}
