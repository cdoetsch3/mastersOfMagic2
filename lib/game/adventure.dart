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
    final level = ((zone.minLevel + zone.maxLevel) / 2).round();
    final commons = roster.where((e) => e.rank == EnemyRank.common).toList();
    final minis = roster.where((e) => e.rank == EnemyRank.mini).toList()
      ..shuffle(rng);
    final bosses = roster.where((e) => e.rank == EnemyRank.boss).toList()
      ..shuffle(rng);

    final perSection = commonsPerSectionFor(zone.tier);
    final drawnMinis = minis.take(2).toList();
    final line = <EnemyDef>[];

    // ⭐ Three sections, each a run of commons capped by something bigger
    // (§3d). The last section ends on the boss instead of a mini.
    for (var section = 0; section < 3; section++) {
      for (var i = 0; i < perSection; i++) {
        if (commons.isNotEmpty) line.add(commons[rng.nextInt(commons.length)]);
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
        for (final def in line)
          EnemyEncounter(
            def: def,
            // ⚠️ Elevated ranks fight at the top of the band, not the middle —
            // otherwise a boss is a common with more health.
            level: def.rank == EnemyRank.common ? level : zone.maxLevel,
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
  UseOutcome use(String defId, {required int maxHp, required bool carried}) {
    if (isOver) return const UseOutcome.refused('Not now.');
    if (!carried) return const UseOutcome.refused('You are not carrying that.');
    final def = ItemCatalogue.tryById(defId);
    if (def is! Usable || (def as Usable).effect.isNothing) {
      return const UseOutcome.refused('That does nothing.');
    }
    final effect = (def as Usable).effect;

    final healed = _heal(effect.healFor(maxHp), maxHp);
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
