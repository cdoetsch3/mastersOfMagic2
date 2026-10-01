/// ACHIEVEMENTS §5.2 — mastery is charges, not wins (§2.2).
///
/// ⭐ **Generated from `MagicElement.values`**: twelve families
/// (`mastery_<element>`), five tiers each at [Achievements.masteryThresholds],
/// so a retuned threshold moves the entry, its progress bar and its blurb
/// together.
///
/// ⚠️ Ids are `mastery_<element>_<tier>` — `MagicElement.name` is therefore
/// on disk twice (here and as a `PlayerProfile.charges` key). Never rename
/// an element.
library;

import 'package:mom_engine/mom_engine.dart';

import '../achievements.dart';
import '../loadout.dart';
import '../player_profile.dart';
import '../progression.dart';
import 'shared.dart';

abstract final class MasteryAchievements {
  /// Points for tiers I–V (§3.1).
  static const tierPoints = <int>[5, 10, 25, 25, 50];

  /// The family every tier of [element] shares.
  static String familyOf(MagicElement element) => 'mastery_${element.name}';

  /// ⭐ `<Element> Mastery I–V` for every element, element by element in
  /// enum order (the tier order), tiers ascending.
  static final List<AchievementDef> tiers = List.unmodifiable([
    for (final e in MagicElement.values)
      for (var t = 1; t <= Achievements.masteryThresholds.length; t++)
        _tier(e, t),
  ]);

  static AchievementDef _tier(MagicElement element, int tier) {
    final threshold = Achievements.masteryThresholds[tier - 1];
    return AchievementDef(
      id: '${familyOf(element)}_$tier',
      name: '${element.displayName} Mastery ${tierNumeral(tier)}',
      blurb:
          '${element.displayName} charged ${groupedDigits(threshold)} times.',
      category: AchievementCategory.mastery,
      points: tierPoints[tier - 1],
      family: familyOf(element),
      tier: tier,
      progress: (p) => cappedProgress(p.chargesOf(element), threshold),
    );
  }

  /// ⭐ The flagship (§5.2): tier I in every element — the one entry that
  /// asks a player to leave the loadout they are comfortable in.
  static final twelvefold = AchievementDef(
    id: 'twelvefold',
    name: 'Twelvefold',
    blurb:
        'All twelve elements charged '
        '${groupedDigits(Achievements.masteryThresholds.first)} times each.',
    category: AchievementCategory.mastery,
    points: 100,
    progress: _elementsAtTierOne,
  );

  /// Every element slot unlocked — [Progression.elementsAtLevel] reaching
  /// [Loadout.maxElementSlots] (level 40 by today's schedule).
  ///
  /// ⚠️ **The schedule, not the usable count.** Slots are not enforced yet
  /// (`Progression.enforceSlotLimits`), so `usableElementsAtLevel` is five
  /// at level 1 and would hand this to a brand-new character.
  static final elementalist = AchievementDef(
    id: 'elementalist',
    name: 'Elementalist',
    blurb: 'All ${Loadout.maxElementSlots} element slots unlocked.',
    category: AchievementCategory.mastery,
    points: 25,
    progress: _elementSlots,
  );

  /// Every Mastery entry: the sixty tiers, then [twelvefold] and
  /// [elementalist].
  static final List<AchievementDef> all = List.unmodifiable([
    ...tiers,
    twelvefold,
    elementalist,
  ]);

  static AchievementProgress _elementsAtTierOne(PlayerProfile p) =>
      cappedProgress(
        MagicElement.values
            .where(
              (e) => p.chargesOf(e) >= Achievements.masteryThresholds.first,
            )
            .length,
        MagicElement.values.length,
      );

  static AchievementProgress _elementSlots(PlayerProfile p) => cappedProgress(
    Progression.elementsAtLevel(p.level),
    Loadout.maxElementSlots,
  );
}
