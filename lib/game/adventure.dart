/// One run through a zone: the encounters, the push-your-luck choice, and the
/// loot that is not yours until you walk out with it.
///
/// ⭐ **The whole run is rolled up front** (GAME_DESIGN "World structure":
/// *"each adventure shows its encounter count up front so progress is
/// visible"*). Rolling per step would make "encounter 3 of 9" a lie.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:mom_engine/mom_engine.dart';

import 'enemies/bestiary.dart';
import 'enemies/enemy_def.dart';
import 'enemies/enemy_encounter.dart';
import 'items/item_catalogue.dart';
import 'items/item_def.dart';
import 'items/item_instance.dart';
import 'world.dart';

/// How many commons stand between the milestones, by tier.
///
/// ⭐ ✅ *"Sizes grow with the game — the first few zones run lean"* (§3d). A
/// Primal route is a short outing; an Ethereal one is an expedition.
int commonsPerSectionFor(MagicTier? tier) => switch (tier) {
  MagicTier.primal => 2,
  MagicTier.kinetic => 3,
  MagicTier.celestial => 4,
  _ => 5,
};

/// Where a run currently stands.
enum RunOutcome {
  /// Still going — the player may push on or walk away.
  running,

  /// Walked out. ⭐ Loot is banked.
  returned,

  /// The boss fell and the zone is cleared.
  cleared,

  /// ⚠️ Died. The run's loot is gone (GAME_DESIGN defeat penalty).
  died,
}

/// A run in progress.
class AdventureRun {
  final String zoneId;

  /// Every fight, in order, decided when the run starts.
  final List<EnemyEncounter> encounters;

  /// How far in. Equals [encounters].length once the boss is down.
  int index;

  /// ⭐ **HP persists between encounters** (GAME_DESIGN) — that is the whole
  /// tension of pushing on. Charge and shields reset; only health carries.
  int playerHp;

  /// Loot taken so far. ⚠️ **Not the player's yet.** It only reaches the
  /// backpack on [RunOutcome.returned] or [RunOutcome.cleared].
  final List<InventorySlot> pendingLoot;

  /// Instances minted for that loot, waiting on the same condition.
  final Map<String, ItemInstance> pendingInstances;

  RunOutcome outcome;

  AdventureRun({
    required this.zoneId,
    required this.encounters,
    required this.playerHp,
    this.index = 0,
    List<InventorySlot>? pendingLoot,
    Map<String, ItemInstance>? pendingInstances,
    this.outcome = RunOutcome.running,
  }) : pendingLoot = pendingLoot ?? [],
       pendingInstances = pendingInstances ?? {};

  /// Builds a run from a zone's roster.
  ///
  /// ⭐ **The pool is drawn here, once** — 2 of the 4 mini-bosses and 1 of the
  /// 2 bosses (§3d). Which ones you get is the reason a zone is worth running
  /// twice, and it is why Purge takes about 4 clears (ACHIEVEMENTS §2.3).
  factory AdventureRun.roll({
    required GameLocation zone,
    required List<EnemyDef> roster,
    required int playerHp,
    required Random rng,
  }) {
    final commons = roster.where((e) => e.rank == EnemyRank.common).toList();
    final minis = roster.where((e) => e.rank == EnemyRank.mini).toList()
      ..shuffle(rng);
    final bosses = roster.where((e) => e.rank == EnemyRank.boss).toList()
      ..shuffle(rng);

    final perSection = commonsPerSectionFor(zone.tier);
    final drawnMinis = minis.take(2).toList();
    final line = <EnemyDef>[];
    final bag = _CommonsBag(commons, rng);

    // ⭐ Three sections, each a run of commons capped by something bigger
    // (§3d). The last section ends on the boss instead of a mini.
    for (var section = 0; section < 3; section++) {
      for (var i = 0; i < perSection; i++) {
        final drawn = bag.draw();
        if (drawn != null) line.add(drawn);
      }
      if (section < 2) {
        if (section < drawnMinis.length) line.add(drawnMinis[section]);
      } else if (bosses.isNotEmpty) {
        line.add(bosses.first);
      }
    }

    return AdventureRun(
      zoneId: zone.id,
      encounters: [
        for (var i = 0; i < line.length; i++)
          EnemyEncounter(
            def: line[i],
            // ⚠️ Elevated ranks fight at the top of the band, not on the ramp —
            // otherwise a boss is a common with more health.
            level: line[i].rank == EnemyRank.common
                ? _rampedLevel(zone, i, line.length)
                : zone.maxLevel,
          ),
      ],
      playerHp: playerHp,
    );
  }

  /// Which section (0-2) the encounter at [index] belongs to.
  ///
  /// ⭐ Derived from the roster shape rather than stored: a section ENDS on a
  /// mini or a boss, so the count of elevated enemies already passed is the
  /// section number.
  int sectionAt(int i) {
    var section = 0;
    for (var n = 0; n < i && n < encounters.length; n++) {
      if (encounters[n].def.rank != EnemyRank.common) section++;
    }
    return section;
  }

  /// The section the player is in now.
  int get section => sectionAt(index);

  /// True when [index] is the first encounter of its section — ⭐ the moment a
  /// narrative beat fires.
  bool get atSectionStart => index == 0 || sectionAt(index - 1) != section;

  bool get isOver => outcome != RunOutcome.running;
  bool get isFinished => index >= encounters.length;

  EnemyEncounter? get current =>
      isFinished || isOver ? null : encounters[index];

  /// 1-based, for "encounter 3 of 9".
  int get encounterNumber => index + 1;
  int get encounterCount => encounters.length;

  /// Whether the fight now in front of the player ends the zone.
  bool get atBoss => current?.def.rank == EnemyRank.boss;

  /// Banks a win and moves on.
  void recordVictory({
    required List<InventorySlot> loot,
    required Map<String, ItemInstance> instances,
    required int remainingHp,
  }) {
    final wasBoss = atBoss;
    pendingLoot.addAll(loot);
    pendingInstances.addAll(instances);
    playerHp = remainingHp;
    index++;
    if (wasBoss) outcome = RunOutcome.cleared;
  }

  /// ⚠️ Death costs the entire run's loot (GAME_DESIGN defeat penalty). The
  /// pending lists are cleared here so nothing downstream can bank them by
  /// accident.
  void recordDefeat() {
    pendingLoot.clear();
    pendingInstances.clear();
    outcome = RunOutcome.died;
  }

  /// Uses a carried item.
  ///
  /// ⭐ **Generic on purpose.** It asks whether the def is [Usable] and applies
  /// whatever its [ItemEffect] says — so a new consumable needs no new code
  /// path here, only an effect.
  ///
  /// ⚠️ **Between encounters only** (ITEMS §6b.2). Using something here is
  /// free; the belt is what costs a turn mid-duel, and collapsing the two
  /// would make the belt pointless.
  UseOutcome use(
    String defId, {
    required int maxHp,
    required bool carried,
    int healingReceivedPercent = 0,
  }) {
    if (isOver) return const UseOutcome.refused('Not now.');
    if (!carried) return const UseOutcome.refused('You are not carrying that.');
    final def = ItemCatalogue.tryById(defId);
    if (def is! Usable || (def as Usable).effect.isNothing) {
      return const UseOutcome.refused('That does nothing.');
    }
    final effect = (def as Usable).effect;

    // ⭐ The Wickerbound Ring's promise (ITEMS §9b.8): healing received
    // multiplies potions too, in and out of combat — same rounding as the
    // engine's one door, MageState.heal.
    var amount = effect.healFor(maxHp);
    if (amount > 0 && healingReceivedPercent != 0) {
      amount = (amount * (100 + healingReceivedPercent) / 100).round();
    }
    final healed = _heal(amount, maxHp);
    if (healed == 0) {
      // ⚠️ Not consumed. Using something that changes nothing must not spend
      // it — that reads as the game stealing an item.
      return const UseOutcome.refused('You are already at full health.');
    }
    return UseOutcome.used('You recover $healed health.');
  }

  int _heal(int amount, int maxHp) {
    if (amount <= 0) return 0;
    final before = playerHp;
    playerHp = (playerHp + amount).clamp(0, maxHp);
    return playerHp - before;
  }

  /// Walking out early with what you have.
  void returnToTown() {
    if (outcome == RunOutcome.running) outcome = RunOutcome.returned;
  }

  /// Whether the loot survived. ⭐ The single question the whole loop turns on.
  bool get lootIsBanked =>
      outcome == RunOutcome.returned || outcome == RunOutcome.cleared;

  // ---- Serialization -----------------------------------------------------

  /// ⭐ **Ids and the rolled level, never the creature itself.** Definitions
  /// live in code (ENEMIES §1.2) — storing one would freeze a stale copy of
  /// its move set into the save, and the duel resolves against the live def.
  ///
  /// ⚠️ **[playerHp] is the HP the player *entered* the current encounter
  /// with**, because that is the only HP this class ever tracks; see the
  /// resume ruling on `PlayerProfile.run`.
  Map<String, dynamic> toJson() => {
    'zoneId': zoneId,
    'index': index,
    'playerHp': playerHp,
    'outcome': outcome.name,
    'encounters': [
      for (final e in encounters) {'defId': e.def.id, 'level': e.level},
    ],
    'pendingLoot': [for (final s in pendingLoot) s.toJson()],
    'pendingInstances': {
      for (final e in pendingInstances.entries) e.key: e.value.toJson(),
    },
  };

  /// Rebuilds a stored run, or returns **null** for one that cannot be
  /// rebuilt exactly.
  ///
  /// ⚠️ **A run that no longer resolves is abandoned, never approximated.** A
  /// content patch that removes a creature, renames a zone out of existence,
  /// or an index past the end of the line all land here — and every one of
  /// them returns null rather than throwing or substituting. Standing the
  /// player in front of a *different* enemy than the one they walked away
  /// from is worse than losing the run, and crashing on load is worse than
  /// both. Same contract as `ActiveTrip.fromJson`: a save that cannot be
  /// understood strands nobody.
  static AdventureRun? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    // ⭐ Canonicalised like every other stored location id (World.renamedIds),
    // then checked: a run in a zone that no longer exists is not a run.
    final zoneId = World.canonicalId(json['zoneId'] as String? ?? '');
    if (!World.exists(zoneId)) return null;

    final rows = json['encounters'] as List?;
    if (rows == null || rows.isEmpty) return null;
    final encounters = <EnemyEncounter>[];
    for (final row in rows) {
      if (row is! Map) return null;
      final def = Bestiary.byId(row['defId'] as String? ?? '');
      if (def == null) return null;
      encounters.add(
        EnemyEncounter(def: def, level: (row['level'] as num?)?.toInt() ?? 1),
      );
    }

    final index = (json['index'] as num?)?.toInt() ?? 0;
    // ⚠️ `index == length` is legal and common — that is a run whose boss is
    // down. Only past the end is corrupt.
    if (index < 0 || index > encounters.length) return null;

    return AdventureRun(
      zoneId: zoneId,
      encounters: encounters,
      index: index,
      playerHp: (json['playerHp'] as num?)?.toInt() ?? 0,
      outcome: _outcomeByName(json['outcome'] as String?),
      pendingLoot: [
        for (final s in (json['pendingLoot'] as List? ?? const []))
          if (s is Map) InventorySlot.fromJson(s.cast<String, dynamic>()),
      ],
      pendingInstances: {
        for (final e in (json['pendingInstances'] as Map? ?? const {}).entries)
          if (e.value is Map)
            e.key as String: ItemInstance.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
      },
    );
  }
}

/// ⚠️ An unrecognised outcome reads as [RunOutcome.running] rather than
/// throwing — the run is still standing there either way, and refusing to load
/// it would cost the player more than the wrong badge on the end screen.
RunOutcome _outcomeByName(String? name) {
  for (final o in RunOutcome.values) {
    if (o.name == name) return o;
  }
  return RunOutcome.running;
}

/// The level a common fights at, [position] steps into a line of [length].
///
/// ⭐ **A band is a ramp, not a midpoint.** Whispering Woods advertises levels
/// 1-5 and opened on a level-3 creature, which made the bottom of every band a
/// lie and the first fight a new mage ever takes the hardest thing they had
/// seen. Position is measured across the WHOLE line — minis and boss included
/// — so the climb the player feels matches the progress bar they are watching.
int _rampedLevel(GameLocation zone, int position, int length) {
  if (length <= 1) return zone.maxLevel;
  final span = zone.maxLevel - zone.minLevel;
  return (zone.minLevel + span * position / (length - 1)).round();
}

/// Deals commons out of a reshuffled bag instead of rolling a die each time.
///
/// ⭐ **A bag, not a die.** Uniform draws are memoryless, and a playtest duly
/// got the same creature for three of the first five fights — legal, and it
/// read as the generator being broken. A bag deals every common once before
/// any of them comes round again, so variety is guaranteed rather than merely
/// likely, and it stays deterministic under an injected [Random].
class _CommonsBag {
  final List<EnemyDef> _pool;
  final Random _rng;
  final List<EnemyDef> _bag = [];

  /// The last creature dealt, across bag refills — the whole point of the
  /// seam-fixing below.
  String? _lastId;

  _CommonsBag(this._pool, this._rng);

  /// Null only when the zone has no commons at all.
  EnemyDef? draw() {
    if (_pool.isEmpty) return null;
    if (_bag.isEmpty) _refill();
    final def = _bag.removeLast();
    _lastId = def.id;
    return def;
  }

  void _refill() {
    _bag
      ..addAll(_pool)
      ..shuffle(_rng);
    // ⚠️ The one seam a shuffle bag leaves: the last card of one bag and the
    // first of the next are independent, so they can match. Swap the offender
    // deeper into the bag — never two identical commons back to back, however
    // the shuffle fell. (A one-creature zone has no escape; it keeps its
    // repeat rather than looping forever.)
    if (_bag.length > 1 && _bag.last.id == _lastId) {
      final other = _rng.nextInt(_bag.length - 1);
      final swapped = _bag[other];
      _bag[other] = _bag.last;
      _bag[_bag.length - 1] = swapped;
    }
  }
}

/// What using an item did, and whether it was spent doing it.
@immutable
class UseOutcome {
  /// ⚠️ False means the item is **still in the pack**.
  final bool consumed;

  /// Player-facing, always populated — a silent no-op is the worst outcome.
  final String message;

  const UseOutcome.used(this.message) : consumed = true;
  const UseOutcome.refused(this.message) : consumed = false;
}
