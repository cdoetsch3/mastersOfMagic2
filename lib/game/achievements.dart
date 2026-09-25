/// The achievement catalogue: what can be earned, named and described.
///
/// ⭐ **Minimal on purpose** (ruling, Christian 2026-09-25). The first entry
/// ships with the Pennycross gate; the catalogue grows later. A character
/// holds only the **ids** it has earned (`PlayerProfile.achievements`), so a
/// renamed achievement or a rewritten blurb never touches a save.
///
/// ⚠️ **An id is forever.** Once shipped, an id is on disk in every profile
/// that earned it. Rename the [AchievementDef.name] freely; never the id.
library;

/// One thing a character can earn.
class AchievementDef {
  /// Stable key, persisted on the profile. ⚠️ See the library note.
  final String id;

  /// What the player sees: the Achievements screen and the toast.
  final String name;

  /// One line on what it was for — shown under the [name].
  final String blurb;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.blurb,
  });
}

abstract final class Achievements {
  /// ⭐ The game's first achievement: opening the Pennycross gate, which
  /// costs the three proofs (ruling 2026-09-25).
  static const papersInOrder = AchievementDef(
    id: 'papers_in_order',
    name: 'Papers in Order',
    blurb: 'Pennycross unlocked. The proofs stay with the guard.',
  );

  /// Every achievement, in the order the Achievements screen lists them.
  static const all = <AchievementDef>[papersInOrder];

  /// The def for [id], or null for an id no catalogue entry claims — a save
  /// from a future build, or a retired entry.
  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
