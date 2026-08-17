import 'package:mom_engine/mom_engine.dart';

import 'loadout.dart';

/// Leveling, unlock, and reward rules. All values are Phase-1 tentative and
/// live in one place so balancing is a single-file edit.
abstract final class Progression {
  // ---- XP / levels ----------------------------------------------------

  /// XP needed to advance FROM [level] to [level] + 1.
  static int xpToNext(int level) => 100 + (level - 1) * 50;

  /// The level a given cumulative XP total corresponds to (level >= 1).
  static int levelForXp(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (remaining >= xpToNext(level)) {
      remaining -= xpToNext(level);
      level++;
    }
    return level;
  }

  /// XP already earned toward the next level, given a cumulative total.
  static int xpIntoLevel(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (remaining >= xpToNext(level)) {
      remaining -= xpToNext(level);
      level++;
    }
    return remaining;
  }

  // ---- Duel rewards ---------------------------------------------------

  // ⚠️ 2026-08-10 ruling — single-player XP was HALVED (win 60→30, per-level
  // 10→5, loss 15→8) because playtesting hit "level 10 before the first zone
  // was beatable": the curve was handing out levels faster than the campaign
  // could hand out challenges, so the ladder's difficulty ramp never landed.
  // [xpForDuel] is the one formula, so the halving reaches every mode.
  static const int winXp = 30;
  static const int winGold = 30;
  static const int lossXp = 8; // 15 halves to 7.5; the designer chose 8
  static const int lossGold = 0;

  /// XP per level of the defeated opponent.
  ///
  /// ⭐ Reward tracks who you beat, not merely that you won. Flat XP made
  /// farming the easiest reachable enemy the optimal way to level, which is
  /// the opposite of what the campaign wants — the fight worth taking should
  /// be the one that pays.
  static const int xpPerOpponentLevel = 5;

  /// XP for a duel against an opponent of [opponentLevel].
  ///
  /// A loss still pays [lossXp] — a floor, deliberately not scaled, so losing
  /// to something far above you is consolation rather than a payday.
  static int xpForDuel({required bool won, required int opponentLevel}) =>
      won ? winXp + xpPerOpponentLevel * opponentLevel : lossXp;

  // ---- Loadout preset slots ------------------------------------------

  /// A new preset slot unlocks at each of these levels (up to 5 total).
  static const List<int> presetSlotUnlockLevels = [1, 3, 6, 10, 15];

  static int presetSlotsAtLevel(int level) =>
      presetSlotUnlockLevels.where((l) => l <= level).length;

  // ---- Spell unlock levels -------------------------------------------

  /// Level at which each spell becomes available. Spells not listed default
  /// to level 1. The starter ten are all level 1 so a new player has a full
  /// preset immediately; the rest form the progression ladder.
  static const Map<String, int> spellUnlockLevel = {
    // Starter ten (level 1): flick, bolt, blast, jolt, flurry, sap, ward,
    // aegis, bulwark, empower.
    'volley': 3,
    'leech': 4,
    'surge': 4,
    'barrier': 4,
    'rampart': 5,
    'barrage': 5,
    'ruin': 6,
    'quicken': 6,
    'sanctuary': 7,
    'drain': 8,
    'phase': 8,
    'cataclysm': 10,
    'hallow': 25, // status defence (Grace), TYPE_EFFECTS §4c.4
  };

  static int unlockLevelOf(Spell spell) => spellUnlockLevel[spell.id] ?? 1;

  /// TEMPORARY: all spells are unlocked until the leveling/unlock schedule is
  /// finalized. [spellUnlockLevel] is retained for when gating returns.
  static bool isSpellUnlockedAt(Spell spell, int level) => true;

  /// All elements are available from level 1 in Phase 1 (element unlocking is
  /// a later-phase refinement).
  static bool isElementUnlockedAt(MagicElement element, int level) => true;

  // ---- Loadout pools -------------------------------------------------
  //
  // ⭐ Elements and spells are SEPARATE pools, each with its own unlock
  // schedule. A fourth element does not cost a tenth spell.
  //
  // 📝 PLANNED — not yet enforced. The schedules below are the intended
  // gating (PROGRESSION_DESIGN §"Slot pool"); [enforceSlotLimits] stays false
  // until the campaign can hand spells back, which is one of the last things
  // before v1. Until then every element and spell is available for
  // playtesting, and these are data only.

  /// Elements known at level 1, growing to [Loadout.maxElementSlots] = 5.
  static const int startingElements = 1;

  /// Levels that grant a new element: 10, 20, 30, 40 — four gains on top of
  /// the one you start with, reaching five at level 40.
  static const List<int> elementUnlockLevels = [10, 20, 30, 40];

  /// Spells known at level 1, growing to [Loadout.maxSpellSlots] = 10.
  static const int startingSpells = 4;

  /// Levels that grant a new spell: 8, 16, 24, 32, 40, 48 — six gains on top
  /// of the four you start with, reaching ten at level 48.
  static const List<int> spellUnlockLevels = [8, 16, 24, 32, 40, 48];

  /// Elements a player of [level] has unlocked, by the schedule above.
  static int elementsAtLevel(int level) =>
      startingElements + elementUnlockLevels.where((l) => l <= level).length;

  /// Spells a player of [level] has unlocked, by the schedule above.
  static int spellsAtLevel(int level) =>
      startingSpells + spellUnlockLevels.where((l) => l <= level).length;

  /// ⚠️ TEMPORARY: pools are not level-gated yet — see the note above. Until
  /// this flips, the usable caps are the absolute ceilings and the schedules
  /// are data only.
  static const bool enforceSlotLimits = false;

  /// Elements a player of [level] may actually fill right now.
  static int usableElementsAtLevel(int level) =>
      enforceSlotLimits ? elementsAtLevel(level) : Loadout.maxElementSlots;

  /// Spells a player of [level] may actually fill right now.
  static int usableSpellsAtLevel(int level) =>
      enforceSlotLimits ? spellsAtLevel(level) : Loadout.maxSpellSlots;

  /// The elements a brand-new player's first preset is filled with.
  static const List<String> starterPresetElementIds = ['pyro', 'aqua', 'flora'];

  /// The spells a brand-new player's first preset is filled with.
  static const List<String> starterPresetSpellIds = [
    'flick',
    'bolt',
    'blast',
    'ward',
    'flurry',
  ];
}
