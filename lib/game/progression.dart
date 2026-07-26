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

  static const int winXp = 60;
  static const int winGold = 30;
  static const int lossXp = 15;
  static const int lossGold = 0;

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

  // ---- Loadout slot pool ---------------------------------------------
  //
  // ⭐ Elements and spells share ONE pool. Spending a slot on a fourth element
  // is spending it away from a tenth spell — that tension is the strategy.

  /// Slots from levelling alone: **5 at level 1, 15 at level 50.**
  static const int startingSlots = 5;
  static const int slotsAtCap = 15;

  /// The extra slots equipment can grant on top of the level curve, taking the
  /// ceiling to [Loadout.maxSlots] = 20.
  static const int maxEquipmentSlots = 5;

  /// Levels at which a slot is granted — ten gains across levels 1-50, spaced
  /// so the early ones land close together (a new player feels the pool open
  /// up) and later ones stretch out.
  static const List<int> slotUnlockLevels = [
    3, 6, 10, 15, 20, 26, 32, 38, 44, 50,
  ];

  /// Slots unlocked by levelling at [level] — [startingSlots] plus one per
  /// threshold passed, so exactly [slotsAtCap] at 50.
  static int slotsAtLevel(int level) =>
      startingSlots + slotUnlockLevels.where((l) => l <= level).length;

  /// ⚠️ TEMPORARY: the pool is not level-gated yet. Enforcing [slotsAtLevel] is
  /// deliberately one of the LAST things to turn on, because playtesting needs
  /// every element and spell available at once. Until then the effective cap is
  /// the absolute ceiling, and [slotsAtLevel] is data only.
  static const bool enforceSlotLimits = false;

  /// Slots a player of [level] may actually fill right now.
  static int usableSlotsAtLevel(int level) =>
      enforceSlotLimits ? slotsAtLevel(level) : Loadout.maxSlots;

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
