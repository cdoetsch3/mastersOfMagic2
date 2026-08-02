/// Turning a bestiary entry into something the duel screen can fight.
///
/// ⭐ **The engine needed no new concept.** `Loadout` holds `Spell` objects
/// rather than ids, and `LadderAi` takes an arbitrary move list — so a
/// creature's own moves drop straight in where a mage's spells would go
/// (ENEMIES §3.1). What the adapter adds is the *body*: archetype HP and
/// damage, and the level the zone fights at.
library;

import '../ai_personas.dart';
import '../element_style.dart';
import '../loadout.dart';
import '../mage_apparel.dart';
import 'enemy_def.dart';

/// One fight: a creature, and the level it is met at.
class EnemyEncounter {
  final EnemyDef def;
  final int level;

  const EnemyEncounter({required this.def, required this.level});

  /// The body and brain, ready for `LocalAiDriver`.
  ///
  /// ⚠️ HP and damage are **not** set here — they ride on the driver as
  /// `opponentHpScale` / `opponentPowerScale`, because `MageState` is built by
  /// `DuelController` and the persona never sees it.
  AiPersona toPersona() => AiPersona(
    id: 'enemy_${def.id}',
    name: def.name,
    title: def.archetype.name,
    level: level,
    intelligence: def.archetype.intelligence,
    apparel: _apparelFor(def),
    loadout: Loadout(elements: def.elements, spells: def.moves),
    // ⚠️ Dead fields on LadderAi (see IMPLEMENTATION_PLAN); passed for the
    // constructor's sake, not because they do anything.
    aggression: 0.5,
    caution: 0.5,
  );
}

/// ⭐ A creature wears its element rather than a mage's robes — the same
/// procedural approach the rest of the game uses, with no image assets.
MageApparel _apparelFor(EnemyDef def) {
  final c = elementStyles[def.elements.first]!.color;
  return MageApparel(
    hat: c,
    hatTrim: c,
    robe: c,
    robeTrim: c,
    gloves: c,
    boots: c,
  );
}
