/// Rolling a kill into actual things.
///
/// ⚠️ **Not lockstep-critical.** Loot is PvE and resolves on one client, so it
/// draws from an ordinary `Random` rather than the duel's shared per-turn seed.
/// ⭐ Keep it that way — routing loot through the duel seed would make every
/// drop a netcode concern for no benefit.
library;

import 'dart:math';

import '../items/item_catalogue.dart';
import '../items/item_def.dart';
import '../items/item_instance.dart';
import 'drop_table.dart';
import 'enemy_def.dart';

/// **The one generator every production loot roll draws from.**
///
/// ⭐ One long-lived stream rather than a fresh `Random()` per kill. Both are
/// sound on both backends — see below — but a single stream is the version
/// that stays sound no matter what a future SDK does with unseeded seeding,
/// and it removes the need to reason about the question at all. Tests keep
/// passing their own seeded `Random`; only the unseeded production path lands
/// here.
///
/// 📝 **The web-seeding audit (2026-08-17), so nobody has to redo it.** The
/// reported "boss Epic three runs running" was suspected to be a dart2js
/// seeding artefact — many `Random()` built inside one millisecond sharing a
/// clock-derived seed. That cannot happen on either backend we ship:
///
/// - **dart2js**: `Random()` with no seed returns `const _JSRandom()` — a
///   *const* singleton with no state and no seed at all, delegating every draw
///   straight to JS `Math.random()`. There is nothing to correlate: every
///   `Random()` in the program is literally the same object, and the clock is
///   never consulted. `nextInt(max)` is `(Math.random() * max) >>> 0`, an exact
///   floor for every `max` these tables use (all ≤ 100, and `_mintId`'s 16), so
///   ⚠️ the 32-bit `>>> 0` truncation is not a bias source either — it only
///   becomes one above 2^32, which `nextInt` rejects outright.
/// - **Dart VM**: `Random()` with no seed takes `_setupSeed(_nextSeed())`, and
///   `_nextSeed()` *advances a global PRNG* seeded from the VM entropy source.
///   No clock in that path either, so same-millisecond construction still
///   yields decorrelated streams.
///
/// So the streak was luck (0.1³ = 1 in 1000 per three-boss window, and the
/// player has killed many bosses). The weight stays 10 by ruling; this shared
/// stream is hygiene, not a fix.
final Random lootRng = Random();

/// What one kill produced.
class Loot {
  /// One entry per unit rolled — ⭐ three logs are three entries (ITEMS
  /// §10.3a). ⚠️ Dust and Shards stack in the backpack since 2026-09-25, so
  /// seven Dust here are seven entries that `AdventureRun.recordVictory`
  /// folds into one picker row ('Pyro Dust ×7').
  final List<InventorySlot> slots;

  /// Instances minted for the non-fungibles above, by id.
  final Map<String, ItemInstance> instances;

  const Loot(this.slots, this.instances);

  static const empty = Loot([], {});

  bool get isEmpty => slots.isEmpty;
  int get count => slots.length;
}

/// Rolls [table] into items.
///
/// The three tiers behave differently on purpose (see `DropTable`):
/// - `always` — every entry gets a roll every kill, subject to its own
///   `chance` (which defaults to 1, i.e. genuinely guaranteed).
/// - `main` — ⭐ **exactly one** entry, by weight. This is what bounds what a
///   kill can be worth and makes drop rates readable as percentages.
/// - `bonus` — each rolled independently, on top.
///
/// ⚠️ **Omitting [rng] is the production call** — it draws from [lootRng], the
/// one shared stream. Pass a seeded `Random` only to pin a test; a caller that
/// hands over a fresh `Random()` per kill re-creates exactly the per-kill
/// construction [lootRng] exists to retire.
Loot rollDrops(DropTable table, [Random? rng]) {
  rng ??= lootRng;
  final ids = <String>[];

  for (final e in table.always) {
    // ⚠️ `chance` is honoured HERE too, not just in `bonus`. "always" names
    // *when* the bucket is consulted — every kill, one roll per entry — not
    // that every entry pays. Ignoring it silently made every authored rate in
    // this bucket a lie: `flora_crystal` at `chance: 0.25` on the mini-boss
    // table dropped on 100% of kills, and `content_export.dart` published the
    // 0.25 to the wiki under the promise that "a wiki that prints 12% got it
    // from the roller."
    //
    // ⭐ The `< 1` guard is load-bearing, not a micro-optimisation: a
    // guaranteed entry must not consume a number from [rng], so a table whose
    // `always` slots are all certain (both bosses) rolls the exact same
    // sequence it always did. Only tables that actually asked for a chance
    // shift.
    if (e.chance < 1 && rng.nextDouble() >= e.chance) continue;
    ids.addAll(_expand(e, rng));
  }

  final picked = _drawOne(table.main, rng);
  if (picked != null) ids.addAll(_expand(picked, rng));

  for (final e in table.bonus) {
    if (rng.nextDouble() < e.chance) ids.addAll(_expand(e, rng));
  }

  return _materialise(ids, rng);
}

/// Rolls one KILL: [table]'s own drops, then the consolation item if they
/// came to nothing, then whatever the enemy's [rank] earns on top.
///
/// ✅ **RULING (Christian, 2026-09-30, playtest note 4 — "Ionwake carried
/// nothing"): every monster drops SOMETHING.** When [table]'s roll is empty
/// the kill pays exactly one unit of [consolationOf] [table]. ⭐ **One rule,
/// 26 zones** — never authored into a table, so the `nothing` weights stay
/// what they are and keep meaning what they mean (the share of kills whose
/// `main` draw came up empty). ⚠️ [DropTable.empty] is the ONLY way a kill
/// pays nothing: it has no consolation to give.
///
/// ✅ **RULING (2026-09-25, widened 2026-09-30 for note 5): rank gear** — a
/// boss always, and a mini on a [miniGearChance] roll, adds one
/// rare-or-better piece of the zone's own gear; see [rollRankGear]. Keyed on
/// [rank] here, never authored into a table, so no zone can forget it.
///
/// ✅ **RULING (2026-09-30, note 11 — "double dropped Leanstone Charm from a
/// boss"): a rare never drops twice in one kill.** Every def id the table
/// (or its consolation) already paid is excluded from the rank-gear pool.
///
/// ⚠️ [table] is rolled FIRST and exactly as [rollDrops] rolls it, so a
/// table's own rates — the ones `content_export` publishes — are untouched;
/// the consolation and the rank gear only ever add. 📝 The consolation is
/// judged on the table's roll, before rank gear: moot by content, since every
/// mini and boss `always` line pays guaranteed shards. [zoneId] is the zone
/// whose catalogue rank gear draws from, i.e. the run's zone.
///
/// Omitting [rng] is the production call, same as [rollDrops].
Loot rollKill(
  DropTable table, {
  required EnemyRank rank,
  required String zoneId,
  Random? rng,
}) {
  rng ??= lootRng;
  var base = rollDrops(table, rng);
  if (base.isEmpty) {
    final consolation = consolationOf(table);
    // ⭐ Every consolation is fungible by content (a craftable, or Mirage's
    // Dust), so materialising it draws nothing from [rng]: the rank-gear roll
    // below sees the same numbers whether or not the consolation paid.
    if (consolation != null) base = _materialise([consolation], rng);
  }
  final gear = rollRankGear(
    rank,
    zoneId,
    rng,
    excluding: {for (final s in base.slots) s.defId},
  );
  if (gear == null) return base;
  final extra = _materialise([gear], rng);
  return Loot(
    [...base.slots, ...extra.slots],
    {...base.instances, ...extra.instances},
  );
}

/// The one unit a kill pays when [table]'s own roll came to nothing (ruling
/// 2026-09-30), or null for a table with nothing to give.
///
/// ⭐ **The heaviest-weighted [MaterialDef] in [DropTable.main]** — the
/// creature's signature craftable, the thing its table most wants to pay.
/// ⚠️ A [MoteDef] never qualifies through `main`: the same day's ruling leans
/// kills toward craftables, and a consolation of Dust would be the opposite.
/// Ties go to the first entry, so the answer reads straight off the source.
///
/// ⚠️ **A `main` with no [MaterialDef] falls back to the first `always`
/// entry's def** — as of 2026-09-30 only The Kiln Desert's Mirage (its role is
/// `mote` alone, ENEMIES §2e), which therefore consoles with Solar Dust.
/// [DropTable.empty] has neither and returns null: the only kill that pays
/// nothing.
String? consolationOf(DropTable table) {
  DropEntry? best;
  for (final e in table.main) {
    final id = e.defId;
    if (id == null || ItemCatalogue.tryById(id) is! MaterialDef) continue;
    if (best == null || e.weight > best.weight) best = e;
  }
  if (best != null) return best.defId;
  for (final e in table.always) {
    if (e.defId != null) return e.defId;
  }
  return null;
}

/// The chance a rank-gear piece is drawn from the zone's EPIC gear rather
/// than its rare gear (ruling 2026-09-25) — ⚠️ for a boss's guaranteed piece
/// AND a mini's [miniGearChance] piece (ruling 2026-09-30: the epic share is
/// identical), despite the name.
///
/// ⭐ **Christian tunes this.** It is the one place the number lives.
const double bossEpicChance = 0.25;

/// The chance a MINI-BOSS kill pays one rare-or-better piece of the zone's
/// gear on top of its table (ruling 2026-09-30, playtest note 5: minis should
/// pay rare and epic gear more often; amended the same day from 0.20 to 0.30).
///
/// ⭐ **Christian tunes this, and this is the one place the number lives** —
/// comments, docs and tests name [miniGearChance] rather than restating it.
/// The piece is the very roll a boss's guarantee makes ([bossEpicChance] for
/// the epic share), gated on this chance. A common never rolls it.
const double miniGearChance = 0.30;

/// Every piece rank gear in [zoneId] may pay: the zone catalogue's
/// [EquipmentDef]s at [Rarity.rare] or above, minus [excluding].
///
/// ⚠️ **Falls back to the zone's best rarity** when it has nothing rare or
/// better, so the roll never silently pays nothing. 📝 As of 2026-09-25 every
/// one of the 26 catalogues has rare-or-better gear and the fallback is dead
/// code by content — a test pins that, so it only ever wakes for a new zone.
///
/// ⭐ [excluding] (ruling 2026-09-30, note 11) is applied AFTER the rarity
/// cut, never before it: a kill whose table already paid the zone's only rare
/// gets an epic or nothing, and exclusion never drags the pool down to
/// uncommon gear.
List<EquipmentDef> rankGearCandidates(
  String zoneId, {
  Set<String> excluding = const {},
}) {
  final gear = [...?ItemCatalogue.byZone[zoneId]?.whereType<EquipmentDef>()];
  if (gear.isEmpty) return const [];
  var pool = [
    for (final d in gear)
      if (d.rarity.index >= Rarity.rare.index) d,
  ];
  if (pool.isEmpty) {
    final best = gear
        .map((d) => d.rarity.index)
        .reduce((a, b) => a > b ? a : b);
    pool = [
      for (final d in gear)
        if (d.rarity.index == best) d,
    ];
  }
  return [
    for (final d in pool)
      if (!excluding.contains(d.id)) d,
  ];
}

/// The def id [rank] earns on top of its table in [zoneId], or null.
///
/// - **boss** — always one piece (ruling 2026-09-25).
/// - **mini** — one piece on a [miniGearChance] roll (ruling 2026-09-30).
/// - **common** — never, and draws nothing from [rng].
///
/// ⭐ **Epic on a [bossEpicChance] roll when the zone has an epic, else
/// rare.** The roll is ALWAYS drawn, whether or not the zone can answer it,
/// so every zone consumes the same numbers from [rng] and a seeded run does
/// not change shape with the catalogue.
///
/// ⚠️ **A mini draws its WHOLE roll — gate, epic share and pick — whether or
/// not the gate hits**, the same discipline: a seeded run's shape must not
/// depend on the outcome, so only the pay-out is gated. (A piece that does
/// pay then mints its quality and instance id in [rollKill]; those are the
/// kill's last draws, after every decision.)
///
/// ⚠️ **A tier the zone lacks yields to the one it has** — a zone with only
/// an epic (Ashfall Vale, as of 2026-09-25) pays that epic every time, rather
/// than rolling "rare" into an empty list and paying nothing. Mythic and
/// legendary gear, should any zone ever author some, is reachable only
/// through that same fallback: the ruling names rare and epic, and a boss
/// handing out mythics by default is a decision, not a side effect.
///
/// ⭐ [excluding] holds every def id the kill already paid (ruling
/// 2026-09-30, note 11): a rare never drops twice in one kill. When nothing is
/// left after exclusion, no piece is paid.
String? rollRankGear(
  EnemyRank rank,
  String zoneId,
  Random rng, {
  Set<String> excluding = const {},
}) {
  final chance = rankGearChance(rank);
  if (chance <= 0) return null;
  // ⭐ The `< 1` guard, as in [rollDrops]'s `always` bucket: a certain piece
  // (a boss's) draws no gate, so the boss roll consumes exactly the numbers
  // it did before minis shared it.
  final hit = chance >= 1 || rng.nextDouble() < chance;
  final id = _rollRarePlus(zoneId, rng, excluding);
  return hit ? id : null;
}

/// The chance a kill of [rank] pays a rank-gear piece: a boss 1, a mini
/// [miniGearChance], a common 0. ⭐ [rollRankGear] rolls against this and
/// `content_export` publishes it, so the wiki's number is the roller's.
double rankGearChance(EnemyRank rank) => switch (rank) {
  EnemyRank.boss => 1,
  EnemyRank.mini => miniGearChance,
  EnemyRank.common => 0,
};

/// One rare-or-better piece of [zoneId]'s gear — the roll [rollRankGear]
/// makes for every rank that earns one.
String? _rollRarePlus(String zoneId, Random rng, Set<String> excluding) {
  final candidates = rankGearCandidates(zoneId, excluding: excluding);
  final epicRoll = rng.nextDouble() < bossEpicChance;
  if (candidates.isEmpty) return null;
  List<EquipmentDef> at(Rarity r) => [
    for (final d in candidates)
      if (d.rarity == r) d,
  ];
  // ⚠️ The asked-for tier, then rare, then epic, and only then whatever the
  // fallback found — so a zone that one day authors a mythic beside its rare
  // still pays the rare, not a coin flip between the two.
  final pool = [
    at(epicRoll ? Rarity.epic : Rarity.rare),
    at(Rarity.rare),
    at(Rarity.epic),
    candidates,
  ].firstWhere((p) => p.isNotEmpty);
  return pool[rng.nextInt(pool.length)].id;
}

/// Turns rolled ids into slots, minting an instance for every non-fungible.
Loot _materialise(List<String> ids, Random rng) {
  final slots = <InventorySlot>[];
  final instances = <String, ItemInstance>{};
  for (final id in ids) {
    // ⚠️ Throws on an unknown id rather than skipping. A drop table naming an
    // item that does not exist is a content bug, and swallowing it here would
    // turn a loud failure into a player quietly getting nothing.
    final def = ItemCatalogue.byId(id);
    if (def.isFungible) {
      slots.add(InventorySlot(defId: id));
    } else {
      final instanceId = _mintId(rng);
      instances[instanceId] = ItemInstance(
        instanceId: instanceId,
        defId: id,
        quality: rollDropQuality(rng),
      );
      slots.add(InventorySlot(defId: id, instanceId: instanceId));
    }
  }
  return Loot(slots, instances);
}

/// The quality a DROPPED piece of equipment arrives at (ruling 2026-08-18):
/// Standard 90%, Ornate 8%, Master 2%.
///
/// ⭐ **No Rough.** Rough exists to make crafting at the edge of your ability
/// feel like working at the edge of your ability; a drop was never your
/// hands, so a sub-baseline tier would be a penalty with no story. The floor
/// of found gear is the baseline.
///
/// ⚠️ Same [Random] stream as the drop roll itself, so a seeded run is fully
/// reproducible — do not give quality its own rng.
Quality rollDropQuality(Random rng) {
  final r = rng.nextDouble();
  if (r < 0.02) return Quality.master;
  if (r < 0.10) return Quality.ornate;
  return Quality.standard;
}

/// One entry's ids, repeated by its rolled quantity.
List<String> _expand(DropEntry e, Random rng) {
  if (e.defId == null) return const [];
  final n = e.min + (e.max > e.min ? rng.nextInt(e.max - e.min + 1) : 0);
  return [for (var i = 0; i < n; i++) e.defId!];
}

/// Weighted draw of exactly one entry. Returns null when the "nothing" slot
/// wins, which is a legitimate and common result.
DropEntry? _drawOne(List<DropEntry> entries, Random rng) {
  if (entries.isEmpty) return null;
  final total = entries.fold<int>(0, (a, e) => a + e.weight);
  if (total <= 0) return null;
  var roll = rng.nextInt(total);
  for (final e in entries) {
    roll -= e.weight;
    if (roll < 0) return e.defId == null ? null : e;
  }
  return null;
}

/// A unique id for one physical item.
///
/// ⚠️ Random rather than sequential on purpose: a counter would collide the
/// moment the same character is open on two devices, which is exactly the case
/// the whole instance model exists to support.
String _mintId(Random rng) {
  const hex = '0123456789abcdef';
  return List.generate(24, (_) => hex[rng.nextInt(16)]).join();
}
