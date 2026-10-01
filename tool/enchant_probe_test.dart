// ENCHANT PROBE — the ENCHANTING_DESIGN §8.4 re-sim gate on the Greater
// enchant and gem numbers. A seeded, headless sibling of
// `tool/balance_probe_test.dart`: same seam, same fixed brain, same turn cap;
// it measures what the enchant layer (§4.1 affinity, §4.1a gear proc, §5.1
// gems) is worth ON TOP of the best shipped kit at level 50, and converts
// that worth into character levels — ITEMS §9b.4a's governing ratio ("gear is
// worth about ten levels, no more").
//
//   flutter test tool/enchant_probe_test.dart              (CI default: the pinned kits)
//   ENCHANT_PROBE_DEEP=1 flutter test tool/enchant_probe_test.dart   (all twelve elements, deeper N)
//
// ⭐ **Engine and production code untouched.** Every mage is built by
// `DuelController._buildMage` — a creature through `EnemyEncounter` →
// `LocalAiDriver(enemy:)`, a geared rival through the ladder-bot door
// `LocalAiDriver(gear:)` — and every kit's stats come out of
// `Equipping.totals` over real `ItemInstance`s carrying `withEnchant` /
// `withSocket`, so the overlay, the halved repeat gems and the gear-proc set
// union are the shipped code's, not this file's arithmetic.
//
// ⚠️ **What the pinned bounds mean.** They are the MEASURED numbers plus a
// margin (a regression fence), not the §9b.4a budget: the probe found the
// draft Greater numbers OVER budget (see ENCHANTING_DESIGN §8.4), and the
// retune is a ❓ for Christian. When a retune lands, re-run deep and tighten
// the bounds down to the new measurement.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/ai_personas.dart';
import 'package:masters_of_magic_2/game/duel_controller.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_def.dart';
import 'package:masters_of_magic_2/game/enemies/enemy_encounter.dart';
import 'package:masters_of_magic_2/game/items/catalogue/gems.dart';
import 'package:masters_of_magic_2/game/items/enchants.dart';
import 'package:masters_of_magic_2/game/items/equipping.dart';
import 'package:masters_of_magic_2/game/items/item_catalogue.dart';
import 'package:masters_of_magic_2/game/items/item_def.dart';
import 'package:masters_of_magic_2/game/items/item_instance.dart';
import 'package:masters_of_magic_2/game/loadout.dart';
import 'package:masters_of_magic_2/game/mage_apparel.dart';
import 'package:masters_of_magic_2/game/opponent_driver.dart';
import 'package:masters_of_magic_2/game/world.dart';
import 'package:mom_engine/mom_engine.dart';

/// The level the gate is measured at — the top of the shipped equip ladder
/// (the Aetherwood weapons are equip level 50) and Greater's home band.
const int _level = 50;

/// The balance probe's rung, for the balance probe's reason: isolate the
/// LOADOUT from the brain (`balance_probe_test.dart` `_probeIntelligence`).
const int _probeIntelligence = 7;

/// The balance probe's belt-and-braces stop.
const int _turnCap = 200;

// ---------------------------------------------------------------------
// The kit
// ---------------------------------------------------------------------

/// The balance probe's monotonic "more is better" proxy, verbatim — every
/// combat field summed, belt slots and potency left out (a belt never wins a
/// combat tiebreak).
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

/// The best SHIPPED piece for [slot] a level-[level] mage can wear —
/// crafted or dropped, since the gate asks what the strongest real kit
/// becomes, not the median one.
///
/// ⭐ **Mechanical, not eyeballed**: the highest [_statTotal] among every
/// catalogue [EquipmentDef] with `equipLevel <= level`, ties to the higher
/// equip level, then the id. 📝 Unlike the balance probe's crafted rule this
/// does NOT prefer the newest tier first — an epic drop ten levels old (the
/// Noon Hour, +55 HP / +20 crit damage / Divert) honestly beats this tier's
/// +6-accuracy hood.
///
/// ⚠️ **No set exclusion is needed today** — no shipped piece carries a
/// `setId` (pinned below), so "best non-set" is "best". A set landing makes
/// that test fail and this rule need its filter.
///
/// [twoHandedOnly] restricts a main hand to two-handers — see [bestKit].
EquipmentDef? bestShippedFor(
  EquipSlot slot,
  int level, {
  bool twoHandedOnly = false,
}) {
  final candidates = [
    for (final d in ItemCatalogue.all)
      if (d is EquipmentDef &&
          d.slot == slot &&
          d.equipLevel <= level &&
          d.setId == null &&
          (!twoHandedOnly || d.twoHanded))
        d,
  ];
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final byPower = _statTotal(b.modifiers).compareTo(_statTotal(a.modifiers));
    if (byPower != 0) return byPower;
    final byLevel = b.equipLevel.compareTo(a.equipLevel);
    if (byLevel != 0) return byLevel;
    return a.id.compareTo(b.id);
  });
  return candidates.first;
}

/// The nine-piece kit the gate enchants: the best two-hander plus the best
/// piece in every other non-hand slot.
///
/// ⭐ **Nine, by the two-hander.** §4.1's own worry is "nine Greater enchants
/// on a full kit"; a two-hander is what makes a kit nine pieces (ten slots,
/// the off hand displaced), and the Aetherwood Quarterstaff — the top-tier
/// crafted weapon AT level 50 — carries three sockets, the most any
/// two-hander at this level has. 📝 The one-hand route (the Dividing Line or
/// Aetherwood Wand + Aetherwood Knot) is ten pieces with four or six sockets:
/// one more enchant and a few more gem points than measured here, flagged in
/// §8.4 rather than run.
List<EquipmentDef> bestKit(int level) => [
  for (final slot in EquipSlot.values)
    if (slot != EquipSlot.offHand)
      ?bestShippedFor(slot, level, twoHandedOnly: slot == EquipSlot.mainHand),
];

/// One kit as it would sit in a save: the defs as [ItemInstance]s (Standard
/// quality — the probe's ×1.00 baseline), with enchants and gems applied by
/// the shipped instance verbs.
class Kit {
  final String name;
  final List<(EquipmentDef, ItemInstance)> pieces;
  final ItemModifiers? _whatIf;
  Kit(this.name, this.pieces) : _whatIf = null;

  /// ⚠️ **A hypothetical** — totals written by hand for a retune that is NOT
  /// shipped (the §8.4 ❓ candidates). Only [whatIfEnchants] builds one, and
  /// the 'what-if path reproduces the shipped overlay' test pins that, fed
  /// the shipped table, it lands on exactly the real [gear].
  Kit.whatIf(this.name, ItemModifiers gear) : pieces = const [], _whatIf = gear;

  /// ⭐ Read through [Equipping.totals] — THE seam the duel reads — so the
  /// set union of procs and the per-piece repeat-gem halving are the
  /// shipped rules, not a re-derivation.
  late final ItemModifiers gear =
      _whatIf ??
      Equipping.totals(
        equipped: {for (final (def, inst) in pieces) def.slot: inst.instanceId},
        instances: {for (final (_, inst) in pieces) inst.instanceId: inst},
      );

  /// This kit's totals with piece i enchanted in `elements[i % length]` at
  /// [amount] affinity points (instead of the shipped table's), carrying
  /// the procs only when [procs] — the retune lever the shipped data cannot
  /// express. Read by the deep run's WHAT-IF section only.
  Kit whatIfEnchants(
    String name,
    List<MagicElement> elements,
    int Function(MagicElement) amount, {
    required bool procs,
  }) {
    var g = gear;
    for (var i = 0; i < pieces.length; i++) {
      final e = elements[i % elements.length];
      g = g + Affinity.of(e, amount(e));
      if (procs) g = g + ItemModifiers(gearProcs: {e});
    }
    return Kit.whatIf(name, g);
  }

  int get socketCount => pieces.fold(0, (s, p) => s + p.$1.socketCount);

  static Kit bare(List<EquipmentDef> defs) => Kit('Bare', [
    for (final d in defs)
      (
        d,
        ItemInstance(
          instanceId: 'probe_${d.id}',
          defId: d.id,
          quality: Quality.standard,
        ),
      ),
  ]);

  /// Every piece enchanted — piece i with `elements[i % elements.length]`.
  Kit enchanted(String name, List<MagicElement> elements, EnchantTier tier) =>
      Kit(name, [
        for (var i = 0; i < pieces.length; i++)
          (
            pieces[i].$1,
            pieces[i].$2.withEnchant(
              Enchants.idFor(elements[i % elements.length], tier),
            ),
          ),
      ]);

  /// Every socket on every piece filled with [element]'s gem at [tier].
  Kit socketed(String name, MagicElement element, EnchantTier tier) =>
      Kit(name, [
        for (final (def, inst) in pieces)
          (
            def,
            [
              for (var s = 0; s < def.socketCount; s++) s,
            ].fold(inst, (i, s) => i.withSocket(s, Gems.idFor(element, tier))),
          ),
      ]);
}

// ---------------------------------------------------------------------
// Opponents
// ---------------------------------------------------------------------

/// The balance probe's opponent set narrowed to the gate's level: every
/// bestiary creature from a zone whose band holds [_level], all fought AT
/// [_level] (so the comparison is gear, not a level gap).
List<EnemyDef> _opponentsAt(int level, EnemyRank rank) => [
  for (final e in Bestiary.all)
    if (e.rank == rank &&
        World.byId(e.zoneId).minLevel <= level &&
        level <= World.byId(e.zoneId).maxLevel)
      e,
];

/// A geared rival's body for the mirror duels — the ladder-bot door
/// (`LocalAiDriver(gear:)`, LADDER §4), the same one a human's wardrobe
/// rides, so the rival is built by the same `_buildMage` as the player.
AiPersona _rival(int level) => AiPersona(
  id: 'enchant_probe_rival',
  name: 'Rival',
  title: 'Probe',
  level: level,
  intelligence: _probeIntelligence,
  apparel: MageApparel.apprenticeBlue,
  loadout: Loadout.starter,
);

// ---------------------------------------------------------------------
// Tally
// ---------------------------------------------------------------------

/// Per-element effect landings the SUBJECT caused, keyed for the §4.1a table.
/// Solar and Lunar share one bucket (both Blind).
enum ProcFx {
  ignite,
  waterlogged,
  photosynthesis,
  staticFeedback,
  tailwind,
  stagger,
  blind,
  alignment,
  grace,
  creepingDark,
  arcaneKnowledge,
}

ProcFx procFxOf(MagicElement e) => switch (e) {
  MagicElement.pyro => ProcFx.ignite,
  MagicElement.aqua => ProcFx.waterlogged,
  MagicElement.flora => ProcFx.photosynthesis,
  MagicElement.electro => ProcFx.staticFeedback,
  MagicElement.aero => ProcFx.tailwind,
  MagicElement.geo => ProcFx.stagger,
  MagicElement.solar || MagicElement.lunar => ProcFx.blind,
  MagicElement.astral => ProcFx.alignment,
  MagicElement.sanctus => ProcFx.grace,
  MagicElement.umbra => ProcFx.creepingDark,
  MagicElement.arcane => ProcFx.arcaneKnowledge,
};

class Tally {
  int n = 0;
  int wins = 0;
  int draws = 0;
  int unfinished = 0;
  int turns = 0;

  /// The subject's damaging casts — each one is one gear-proc roll per
  /// element it wears (§4.1a), so this is the proc OPPORTUNITY count.
  int hits = 0;
  final fx = List<int>.filled(ProcFx.values.length, 0);

  double get score => n == 0 ? 0 : (wins + draws / 2) / n;
  double get hitsPerDuel => n == 0 ? 0 : hits / n;
  double fxPerDuel(ProcFx f) => n == 0 ? 0 : fx[f.index] / n;
}

/// Plays one already-built duel to the end with the fixed brains, tallying
/// it for [subject] against [other].
void _drive(
  DuelEngine engine,
  MageState player,
  MageState enemy,
  DuelAi playerAi,
  DuelAi enemyAi,
  MageState subject,
  Tally t,
) {
  final other = identical(subject, player) ? enemy : player;
  final rng = engine.rng;
  while (!engine.isOver && engine.turnNumber < _turnCap) {
    final r = engine.resolveTurn(
      playerAi.chooseAction(player, enemy, rng),
      enemyAi.chooseAction(enemy, player, rng),
    );
    MageState? caster;
    var counted = false;
    for (final e in r.events) {
      switch (e) {
        case SpellCastEvent(caster: final c):
          caster = c;
          counted = false;
        case DamageEvent(:final target):
          if (!counted &&
              identical(caster, subject) &&
              identical(target, other)) {
            t.hits++;
            counted = true;
          }
        case BuffAppliedEvent(:final mage, :final statusId):
          final onOther = identical(mage, other);
          final onSelf = identical(mage, subject);
          final f = switch (statusId) {
            'ignite' when onOther => ProcFx.ignite,
            'waterlogged' when onOther => ProcFx.waterlogged,
            'stagger' when onOther => ProcFx.stagger,
            'blind' when onOther => ProcFx.blind,
            'photosynthesis' when onSelf => ProcFx.photosynthesis,
            'astralAlignment' when onSelf => ProcFx.alignment,
            'grace' when onSelf => ProcFx.grace,
            'creepingDark' when onSelf => ProcFx.creepingDark,
            'arcaneKnowledge' when onSelf => ProcFx.arcaneKnowledge,
            _ => null,
          };
          if (f != null) t.fx[f.index]++;
        case ChargeDrainedEvent(:final mage) when identical(mage, other):
          t.fx[ProcFx.staticFeedback.index]++;
        case HasteChangedEvent(:final holder) when identical(holder, subject):
          t.fx[ProcFx.tailwind.index]++;
        default:
          break;
      }
    }
  }
  t.n++;
  t.turns += engine.turnNumber;
  if (!engine.isOver) {
    t.unfinished++;
  } else if (engine.isDraw) {
    t.draws++;
  } else if (identical(engine.winner, subject)) {
    t.wins++;
  }
}

LadderAi _starterBrain() => LadderAi(
  _probeIntelligence,
  spells: Loadout.starter.spells,
  elements: Loadout.starter.elements,
);

/// [n] duels of [kit] at [playerLevel] against [foes] (round robin) at
/// [_level]. Seeds `seed0 .. seed0+n-1` — the SAME block for every kit, so
/// two kits face identical draws wherever their duels have not diverged
/// (common random numbers: kit-vs-kit deltas are far less noisy than N
/// alone suggests).
Tally vsCreatures(
  ItemModifiers gear,
  List<EnemyDef> foes, {
  required int n,
  required int seed0,
  int playerLevel = _level,
}) {
  final t = Tally();
  for (var i = 0; i < n; i++) {
    final def = foes[i % foes.length];
    final seed = seed0 + i;
    final c = DuelController(
      loadout: Loadout.starter,
      driver: LocalAiDriver(
        persona: EnemyEncounter(def: def, level: _level).toPersona(),
        enemy: def,
        rng: Random(seed),
      ),
      playerLevel: playerLevel,
      playerGear: gear,
      rng: ReseedableRandom(seed),
    );
    _drive(
      c.engine,
      c.player,
      c.enemy,
      _starterBrain(),
      LadderAi(_probeIntelligence, spells: def.moves, elements: def.elements),
      c.player,
      t,
    );
  }
  return t;
}

/// [n] mirror duels: kit [a] at [levelA] vs kit [b] at [levelB], both on the
/// starter loadout at the probe rung, tallied for [a]. ⭐ Sides alternate by
/// seed parity (even: [a] is the host/player) so the engine's host/guest
/// order cannot leak into the score.
Tally mirror(
  ItemModifiers a,
  ItemModifiers b, {
  required int n,
  required int seed0,
  int levelA = _level,
  int levelB = _level,
}) {
  final t = Tally();
  for (var i = 0; i < n; i++) {
    final seed = seed0 + i;
    final aIsPlayer = i.isEven;
    final c = DuelController(
      loadout: Loadout.starter,
      driver: LocalAiDriver(
        persona: _rival(aIsPlayer ? levelB : levelA),
        gear: aIsPlayer ? b : a,
        rng: Random(seed),
      ),
      playerLevel: aIsPlayer ? levelA : levelB,
      playerGear: aIsPlayer ? a : b,
      rng: ReseedableRandom(seed),
    );
    _drive(
      c.engine,
      c.player,
      c.enemy,
      _starterBrain(),
      _starterBrain(),
      aIsPlayer ? c.player : c.enemy,
      t,
    );
  }
  return t;
}

/// How many levels [base] must gain to stand even with [kit] — the §9b.4a
/// currency. Searches integer d in [-15, 40] for the smallest d where
/// `[base] at L50+d` scores ≥ [target] (mirror: ≥ 0.5 against [kit] at L50;
/// creatures: ≥ [kit]'s own win rate), then interpolates linearly between
/// d-1 and d. Same seed block at every d (common random numbers keep the
/// curve monotone in practice).
double levelEquivalent(double Function(int d) scoreAt, double target) {
  var lo = -15; // assumed below target
  var hi = 40; // assumed at/above target
  final cache = <int, double>{};
  double s(int d) => cache[d] ??= scoreAt(d);
  if (s(lo) >= target) return lo.toDouble();
  if (s(hi) < target) return hi.toDouble();
  while (hi - lo > 1) {
    final mid = (lo + hi) ~/ 2;
    if (s(mid) >= target) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  final sLo = s(lo);
  final sHi = s(hi);
  if (sHi == sLo) return hi.toDouble();
  return lo + (target - sLo) / (sHi - sLo);
}

// ---------------------------------------------------------------------
// The measured row
// ---------------------------------------------------------------------

class KitRow {
  final Kit kit;
  final Tally common;
  final Tally mini;
  final Tally boss;
  final Tally vsBare;

  /// Levels Bare needs to tie this kit, mirror (PvP) and vs elites (minis +
  /// bosses at L50).
  final double levelsMirror;
  final double levelsElite;

  KitRow(
    this.kit,
    this.common,
    this.mini,
    this.boss,
    this.vsBare,
    this.levelsMirror,
    this.levelsElite,
  );

  double get elite =>
      (mini.wins + boss.wins + (mini.draws + boss.draws) / 2) /
      (mini.n + boss.n);
}

class EnchantProbe {
  final int n;
  final List<EquipmentDef> defs;
  final Kit bare;
  late final List<EnemyDef> commons = _opponentsAt(_level, EnemyRank.common);
  late final List<EnemyDef> minis = _opponentsAt(_level, EnemyRank.mini);
  late final List<EnemyDef> bosses = _opponentsAt(_level, EnemyRank.boss);

  EnchantProbe(this.n)
    : defs = bestKit(_level),
      bare = Kit.bare(bestKit(_level));

  // Seed blocks — fixed offsets, so a row is a pure function of (kit, n).
  static const _seedCommon = 1000000;
  static const _seedMini = 2000000;
  static const _seedBoss = 3000000;
  static const _seedMirror = 4000000;

  Tally _elite(ItemModifiers gear, int playerLevel) {
    final m = vsCreatures(
      gear,
      minis,
      n: n,
      seed0: _seedMini,
      playerLevel: playerLevel,
    );
    final b = vsCreatures(
      gear,
      bosses,
      n: n,
      seed0: _seedBoss,
      playerLevel: playerLevel,
    );
    return Tally()
      ..n = m.n + b.n
      ..wins = m.wins + b.wins
      ..draws = m.draws + b.draws;
  }

  late final double _bareEliteAt50 = _elite(bare.gear, _level).score;
  final _bareEliteCache = <int, double>{};
  double _bareElite(int d) =>
      _bareEliteCache[d] ??= _elite(bare.gear, _level + d).score;

  KitRow measure(Kit kit, {Kit? against}) {
    final base = against ?? bare;
    final gear = kit.gear;
    final common = vsCreatures(gear, commons, n: n, seed0: _seedCommon);
    final mini = vsCreatures(gear, minis, n: n, seed0: _seedMini);
    final boss = vsCreatures(gear, bosses, n: n, seed0: _seedBoss);
    final vsBase = mirror(gear, base.gear, n: n, seed0: _seedMirror);
    final levelsMirror = levelEquivalent(
      (d) => mirror(
        base.gear,
        gear,
        n: n,
        seed0: _seedMirror,
        levelA: _level + d,
      ).score,
      0.5,
    );
    final eliteScore =
        (mini.wins + boss.wins + (mini.draws + boss.draws) / 2) /
        (mini.n + boss.n);
    final levelsElite = identical(base, bare)
        ? levelEquivalent(_bareElite, eliteScore)
        : double.nan;
    return KitRow(kit, common, mini, boss, vsBase, levelsMirror, levelsElite);
  }

  double get bareEliteAt50 => _bareEliteAt50;
}

// ---------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

/// The stat totals a kit reaches and which output clamps bite, as the duel
/// assembles them (base + gear; `DuelController._buildMage`).
String statLine(ItemModifiers g) {
  final crit = MageState.baseCritChance + g.critChance;
  final critDmg = MageState.baseCritDamage + g.critDamage;
  // Hit chance of a 100-accuracy spell against a target with no dodge — the
  // most the accuracy stat can buy before the cap wastes it.
  final hitRaw = 100 - ElementTuning.baseMissPercent + g.accuracyBonus;
  final caps = [
    if (hitRaw > CombatClamps.hitChanceCapPercent) 'hit>${hitRaw - 100}',
    if (g.deflectChance > CombatClamps.deflectActivationCapPercent)
      'defl>${g.deflectChance - CombatClamps.deflectActivationCapPercent}',
    if (g.deflectAmount > CombatClamps.deflectFractionCapPercent) 'deflAmt',
    if (crit >= 100) 'crit≥100',
  ];
  return 'HP+${g.maxHpBonus} acc+${g.accuracyBonus}(hit ${min(hitRaw, 100)}) '
      'crit $crit% x${100 + critDmg}% dodge ${g.dodge} '
      'defl ${g.deflectChance}%/${g.deflectAmount}% '
      'shield+${g.shieldStrengthPercent}% heal+${g.healingReceivedPercent}% '
      'dpc+${g.damagePerCharge} procs ${g.gearProcs.length}'
      '${caps.isEmpty ? '' : '  CAPS: ${caps.join(' ')}'}';
}

String renderRows(List<KitRow> rows, double bareElite) {
  final b = StringBuffer()
    ..writeln(
      '${'kit'.padRight(26)}${'common'.padRight(8)}${'mini'.padRight(8)}'
      '${'boss'.padRight(8)}${'elite'.padRight(8)}${'vsBare'.padRight(8)}'
      '${'lv(PvP)'.padRight(9)}${'lv(elite)'.padRight(10)}hits/duel',
    );
  for (final r in rows) {
    b.writeln(
      r.kit.name.padRight(26) +
          _pct(r.common.score).padRight(8) +
          _pct(r.mini.score).padRight(8) +
          _pct(r.boss.score).padRight(8) +
          _pct(r.elite).padRight(8) +
          _pct(r.vsBare.score).padRight(8) +
          r.levelsMirror.toStringAsFixed(1).padRight(9) +
          r.levelsElite.toStringAsFixed(1).padRight(10) +
          r.vsBare.hitsPerDuel.toStringAsFixed(1),
    );
  }
  b.writeln('(Bare elite win rate at L50: ${_pct(bareElite)})');
  return b.toString();
}

/// The proc table: the element's effect landings per duel for the Standard
/// and Greater kit (vs Bare, mirror), the difference (≈ procs that landed),
/// and that difference per damaging hit (the roll is 15%; a gap below it is
/// Grace eating debuffs, a proc landing on an already-applied status, etc.).
String renderProcs(Map<MagicElement, (KitRow, KitRow)> pairs) {
  final b = StringBuffer()
    ..writeln(
      '${'element'.padRight(9)}${'effect'.padRight(18)}${'std/duel'.padRight(10)}'
      '${'grt/duel'.padRight(10)}${'Δ/duel'.padRight(9)}Δ/hit',
    );
  for (final MapEntry(key: e, value: (std, grt)) in pairs.entries) {
    final f = procFxOf(e);
    final s = std.vsBare.fxPerDuel(f);
    final g = grt.vsBare.fxPerDuel(f);
    final hits = grt.vsBare.hitsPerDuel;
    b.writeln(
      e.name.padRight(9) +
          Enchants.procEffectName(e).padRight(18) +
          s.toStringAsFixed(2).padRight(10) +
          g.toStringAsFixed(2).padRight(10) +
          (g - s).toStringAsFixed(2).padRight(9) +
          (hits == 0 ? '-' : _pct((g - s) / hits)),
    );
  }
  return b.toString();
}

// ---------------------------------------------------------------------
// The gate
// ---------------------------------------------------------------------

/// The elements the CI run measures and pins: one per affinity stat that
/// moves a duel — crit damage, crit chance, deflect, accuracy, shield — plus
/// ⚠️ **Aero, the dodge row**, the worst offender the deep run found (Greater
/// ×9 is worth ~19 levels). Healing (Flora) and the twins (Umbra, Astral,
/// Lunar, Arcane, Sanctus share a stat with one of these) run deep only.
const _gateElements = [
  MagicElement.pyro,
  MagicElement.electro,
  MagicElement.aero,
  MagicElement.geo,
  MagicElement.solar,
  MagicElement.aqua,
];

/// Mixed Greater: nine DIFFERENT elements, one per piece, nine procs live.
/// 📝 The twelve minus Lunar (its proc is Solar's Blind, so it adds no tenth
/// effect), Flora (the weakest Greater ×9 in the deep run, 0.6 levels) and
/// Sanctus (Grace only blocks one debuff; 2.4 levels, a hair above Umbra's
/// 2.1) — the strongest nine the catalogue can field, near enough.
const mixedNine = [
  MagicElement.aqua,
  MagicElement.pyro,
  MagicElement.electro,
  MagicElement.aero,
  MagicElement.geo,
  MagicElement.solar,
  MagicElement.astral,
  MagicElement.umbra,
  MagicElement.arcane,
];

/// Everything the gate measured, keyed for the pins.
class GateReport {
  final Map<String, KitRow> rows;
  final Map<MagicElement, (KitRow, KitRow)> procs;
  final String text;
  GateReport(this.rows, this.procs, this.text);
}

GateReport runGate({required int n, required bool deep}) {
  final probe = EnchantProbe(n);
  final rows = <String, KitRow>{};
  final procs = <MagicElement, (KitRow, KitRow)>{};
  final out = StringBuffer();

  final elements = deep ? MagicElement.values : _gateElements;
  rows['bare'] = probe.measure(probe.bare);
  for (final e in elements) {
    final std = probe.measure(
      probe.bare.enchanted('Standard ×9 ${e.name}', [e], EnchantTier.standard),
    );
    final grt = probe.measure(
      probe.bare.enchanted('Greater ×9 ${e.name}', [e], EnchantTier.greater),
    );
    rows['std_${e.name}'] = std;
    rows['grt_${e.name}'] = grt;
    procs[e] = (std, grt);
  }
  rows['mixed_std'] = probe.measure(
    probe.bare.enchanted('Mixed Standard ×9', mixedNine, EnchantTier.standard),
  );
  rows['mixed_grt'] = probe.measure(
    probe.bare.enchanted('Mixed Greater ×9', mixedNine, EnchantTier.greater),
  );
  for (final e in _gateElements) {
    rows['gems_${e.name}'] = probe.measure(
      probe.bare
          .enchanted('x', [e], EnchantTier.greater)
          .socketed('Greater ×9+gems ${e.name}', e, EnchantTier.greater),
    );
  }
  // ⭐ The whole wardrobe's worth, for §9b.4a's ceiling read as a TOTAL:
  // how many levels a NAKED mage needs to tie the Bare kit (the "lv(PvP)"
  // column of this row is naked → Bare, not Bare → kit).
  final naked = Kit('Naked', const []);
  rows['bare_vs_naked'] = probe.measure(
    Kit('Bare (vs Naked)', probe.bare.pieces),
    against: naked,
  );
  rows['grt_electro_vs_naked'] = probe.measure(
    Kit('Gr×9 electro (vs Naked)', rows['grt_electro']!.kit.pieces),
    against: naked,
  );
  rows['mixed_grt_vs_naked'] = probe.measure(
    Kit('Mixed Gr×9 (vs Naked)', rows['mixed_grt']!.kit.pieces),
    against: naked,
  );

  out
    ..writeln(
      'ENCHANT PROBE — L$_level, $n duels per kit per opponent group, '
      'intelligence $_probeIntelligence both sides, cap $_turnCap turns',
    )
    ..writeln(
      'Kit (${probe.defs.length} pieces, ${probe.bare.socketCount} '
      'sockets): ${probe.defs.map((d) => d.id).join(', ')}',
    )
    ..writeln(
      'Opponents at L$_level: ${probe.commons.length} commons, '
      '${probe.minis.length} minis, ${probe.bosses.length} bosses '
      '(zones whose band holds $_level)',
    )
    ..writeln()
    ..writeln('STAT TOTALS (base + gear; CAPS = output clamp or saturation)');
  for (final r in rows.values) {
    out.writeln('${r.kit.name.padRight(26)}${statLine(r.kit.gear)}');
  }
  out
    ..writeln()
    ..writeln(
      'WIN RATES (creatures at L$_level; vsBare = mirror; lv = levels Bare '
      'must gain to tie)',
    )
    ..write(renderRows(rows.values.toList(), probe.bareEliteAt50))
    ..writeln()
    ..writeln('PROCS (mirror vs Bare; effect landings by the kit wearer)')
    ..write(renderProcs(procs));

  if (deep) {
    final keys = [for (final e in _gateElements) 'grt_${e.name}', 'mixed_grt'];
    out
      ..writeln()
      ..writeln("KIT VS KIT (row kit's score, mirror at L$_level)");
    for (final a in keys) {
      final line = StringBuffer(rows[a]!.kit.name.padRight(26));
      for (final b in keys) {
        line.write(
          a == b
              ? '—'.padRight(7)
              : _pct(
                  mirror(
                    rows[a]!.kit.gear,
                    rows[b]!.kit.gear,
                    n: n,
                    seed0: 5000000,
                  ).score,
                ).padRight(7),
        );
      }
      out.writeln(line);
    }

    // ⚠️ WHAT-IF — hypothetical totals, NOT the shipped tables. (1) The
    // Greater stat with its proc stripped, so the proc's own worth is the
    // gap to the real Greater row; (2) the §8.4 ❓ retune candidate.
    final whatIf = <KitRow>[];
    int draft(MagicElement e) => Affinity.enchantAmount(e, EnchantTier.greater);
    for (final e in _gateElements) {
      whatIf.add(
        probe.measure(
          probe.bare.whatIfEnchants(
            'Gr stat, no proc ${e.name}',
            [e],
            draft,
            procs: false,
          ),
        ),
      );
    }
    whatIf.add(
      probe.measure(
        probe.bare.whatIfEnchants(
          'Mixed Gr stat, no procs',
          mixedNine,
          draft,
          procs: false,
        ),
      ),
    );
    for (final e in MagicElement.values) {
      whatIf.add(
        probe.measure(
          probe.bare.whatIfEnchants(
            '❓ Gr×9 ${e.name}',
            [e],
            proposedGreaterAmount,
            procs: true,
          ),
        ),
      );
    }
    whatIf.add(
      probe.measure(
        probe.bare.whatIfEnchants(
          '❓ Mixed Gr×9',
          mixedNine,
          proposedGreaterAmount,
          procs: true,
        ),
      ),
    );
    out
      ..writeln()
      ..writeln(
        'WHAT-IF (hypothetical totals; ❓ = proposed Greater amounts, procs '
        'at the shipped ${ElementTuning.gearProcPercent}%)',
      );
    for (final r in whatIf) {
      out.writeln('${r.kit.name.padRight(26)}${statLine(r.kit.gear)}');
    }
    out.write(renderRows(whatIf, probe.bareEliteAt50));
  }
  return GateReport(rows, procs, out.toString());
}

/// ❓ **The §8.4 retune candidate — NOT shipped** (Christian's call): the
/// Greater affinity per piece the deep run's WHAT-IF section measures.
/// See ENCHANTING_DESIGN §8.4 for why each row moved.
/// 📝 Dodge and crit chance cut hardest (7 → 2, 7 → 3: per point they are
/// the strongest stats in the duel — dodge subtracts straight off the
/// attacker's hit roll and nothing clamps it short of the 10% floor); every
/// other row to two thirds of the draft, §4.1's own expectation.
int proposedGreaterAmount(MagicElement e) => switch (e) {
  MagicElement.aero || MagicElement.lunar => 2,
  MagicElement.electro || MagicElement.astral => 3,
  MagicElement.pyro ||
  MagicElement.umbra ||
  MagicElement.aqua ||
  MagicElement.flora => 9,
  MagicElement.geo || MagicElement.arcane || MagicElement.solar => 7,
  MagicElement.sanctus => 5,
};

/// ⚠️ **The fence, not the budget** — the CI run's (N = 300) measured
/// numbers, 2026-10-01, on the shipped draft: (mirror score vs Bare, levels
/// Bare must gain to tie in the mirror, win rate vs L50 minis + bosses).
/// Each bound is that measurement plus a margin ([_scoreMargin],
/// [_levelMargin]) — about two standard errors at N = 300 — so seed noise
/// from an unrelated engine change does not trip it but a change that makes
/// an enchanted kit STRONGER does. Several of these are already past ITEMS
/// §9b.4a (ENCHANTING §8.4); the fence stops them getting worse until the ❓
/// retune lands, and then it tightens to the new measurement.
const Map<String, (double, double, double)> _measured = {
  'grt_pyro': (0.620, 1.9, 0.738),
  'grt_electro': (0.803, 8.6, 0.882),
  'grt_aero': (0.927, 18.4, 0.937),
  'grt_geo': (0.673, 4.7, 0.842),
  'grt_solar': (0.677, 3.4, 0.767),
  'grt_aqua': (0.643, 4.4, 0.808),
  'mixed_grt': (0.887, 11.7, 0.947),
  'gems_electro': (0.827, 9.8, 0.900),
  'gems_aero': (0.977, 21.2, 0.937),
};
const double _scoreMargin = 0.05;
const double _levelMargin = 1.5;

void main() {
  final deep = Platform.environment['ENCHANT_PROBE_DEEP'] == '1';
  final n = deep ? 1200 : 300;
  late final report = runGate(n: n, deep: deep);
  final timeout = Timeout(Duration(minutes: deep ? 90 : 15));

  test('enchant probe report', () {
    print(report.text);
  }, timeout: timeout);

  group('kit and harness', () {
    test('the gate kit is nine pieces with three sockets, and no shipped '
        'piece belongs to a set', () {
      final kit = bestKit(_level);
      expect(
        kit.map((d) => d.id).toList(),
        [
          'the_noon_hour',
          'the_larger_reflection',
          'bedrock_greaves',
          'lowwater_tread',
          'umbralweave_gloves',
          'the_maintained_road',
          'stonefall_signet',
          'aetherwood_quarterstaff',
          'corebiter_belt',
        ],
        reason:
            'the best-shipped rule at L50 (stat total, two-hander) — a new '
            'piece that out-totals one of these moves every row of §8.4, so '
            'the table must be re-run, not silently drift',
      );
      expect(
        Kit.bare(kit).socketCount,
        3,
        reason: 'the Aetherwood Quarterstaff is the only socketed piece',
      );
      expect(
        [
          for (final d in ItemCatalogue.all)
            if (d is EquipmentDef && d.setId != null) d.id,
        ],
        isEmpty,
        reason:
            '"best NON-SET kit" filters nothing today; a set landing needs '
            'this probe to decide whether its bonus belongs in the gate',
      );
    });

    test('the what-if path reproduces the shipped overlay exactly', () {
      // ⭐ Kills a WHAT-IF section that drifts from Equipping: fed the shipped
      // table, the hand-summed totals must equal what withEnchant +
      // Equipping.totals produce, field for field and proc for proc.
      final bare = Kit.bare(bestKit(_level));
      for (final els in [
        [MagicElement.electro],
        [MagicElement.geo],
        mixedNine,
      ]) {
        final real = bare.enchanted('real', els, EnchantTier.greater).gear;
        final hypo = bare
            .whatIfEnchants(
              'hypo',
              els,
              (e) => Affinity.enchantAmount(e, EnchantTier.greater),
              procs: true,
            )
            .gear;
        expect(statLine(hypo), statLine(real), reason: '$els stats');
        expect(hypo.gearProcs, real.gearProcs, reason: '$els procs');
      }
    });
  });

  group('the §8.4 fence', () {
    test('Greater procs land at about the 10% roll per damaging hit', () {
      // ⭐ Kills both wiring mutants: procs not reaching the duel (Δ ≈ 0) and
      // procs rolled once PER PIECE instead of once per element (nine rolls
      // at 10% would land on most hits). Measured 13.6–15.7% at the draft's
      // 15 for these four — the band tracks the retuned 10;
      // Electro (no charge to strip), Aero (Haste already held) and the
      // self-buffs sit lower for board reasons, not wiring ones.
      for (final e in [
        MagicElement.pyro,
        MagicElement.geo,
        MagicElement.solar,
        MagicElement.aqua,
      ]) {
        final (std, grt) = report.procs[e]!;
        final f = procFxOf(e);
        final perHit =
            (grt.vsBare.fxPerDuel(f) - std.vsBare.fxPerDuel(f)) /
            grt.vsBare.hitsPerDuel;
        expect(
          perHit,
          inInclusiveRange(0.06, 0.14),
          reason:
              '${e.name}: ${Enchants.procEffectName(e)} landings per hit '
              'over Standard',
        );
      }
    }, timeout: timeout);

    test('no enchanted kit gets stronger than measured', () {
      if (deep) return; // the fence is the CI run's numbers (N = 300)
      for (final MapEntry(key: k, value: (score, levels, elite))
          in _measured.entries) {
        final r = report.rows[k]!;
        expect(
          r.vsBare.score,
          lessThanOrEqualTo(score + _scoreMargin),
          reason: '$k: mirror score vs Bare (ENCHANTING §8.4)',
        );
        expect(
          r.levelsMirror,
          lessThanOrEqualTo(levels + _levelMargin),
          reason: '$k: levels Bare must gain to tie (ITEMS §9b.4a)',
        );
        expect(
          r.elite,
          lessThanOrEqualTo(elite + _scoreMargin),
          reason: '$k: win rate vs L50 minis + bosses',
        );
      }
    }, timeout: timeout);

    test('the worst enchant layer stays fenced at its measured worth', () {
      // The §9b.4a line, as it stands: Bare is worth ~15 levels over naked
      // (the whole gear axis), and the worst enchant layer (Greater ×9 +
      // gems, Aero) measured ~21 on TOP of it — ⚠️ the enchant layer is
      // worth MORE than the kit it sits on. A retune must bring this inside
      // and the bound then tightens; today it fences the worst case.
      if (deep) return;
      final naked = report.rows['bare_vs_naked']!.levelsMirror;
      expect(naked, inInclusiveRange(13.0, 18.0), reason: 'naked → Bare');
      final worst = report.rows.entries
          .where((e) => e.key.startsWith('grt_') || e.key.startsWith('gems_'))
          .map((e) => e.value.levelsMirror)
          .reduce(max);
      expect(
        worst,
        lessThanOrEqualTo(21.2 + _levelMargin),
        reason: 'the strongest single-element enchant layer, in levels',
      );
    }, timeout: timeout);
  });
}
