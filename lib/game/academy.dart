import 'items/item_def.dart';
import 'player_profile.dart';

/// The Academy — the level playing field (ruled 2026-09-10).
///
/// ⭐ Everyone duels as if they were level 50, wearing nothing, carrying no
/// potions, and winning nothing: no XP, no gold, no loot, no quest credit.
/// One dedicated loadout per player, drawn from EVERY spell and element the
/// game has regardless of the player's real level — so when spell unlocks
/// switch on, the Academy still opens the whole book. It is its own
/// matchmaking queue, and it is the one mode a guest without an account can
/// play online (an anonymous sign-in supplies the uid the rules need).
abstract final class Academy {
  /// The level both mages are built at — the cap, so the Academy tests the
  /// endgame game and not the gear race.
  static const int level = 50;

  /// Ticket and room field values. Legacy tickets without a mode are geared.
  static const String mode = 'academy';
  static const String gearedMode = 'geared';

  static const String presetName = 'Academy';

  /// Caps for the Academy loadout — today's caps, by ruling (10 spells, 5
  /// elements), never the level-50 slot schedule.
  static const int spellSlots = 10;
  static const int elementSlots = 5;
}

/// What a player brings into a duel — level, wardrobe, belt — resolved for
/// the mode. Pure, so the one seam every duel launch passes through can be
/// pinned without a widget tree.
///
/// ⚠️ [academy] overrides ALL THREE at once. A launch that took the Academy
/// level but kept the belt would let a potion into the level playing field.
({int level, ItemModifiers gear, List<String> belt}) duelInputsFor({
  required bool academy,
  required PlayerProfile profile,
  required ItemModifiers equipment,
}) => academy
    ? (level: Academy.level, gear: ItemModifiers.none, belt: const [])
    : (level: profile.level, gear: equipment, belt: profile.belt.loaded);
