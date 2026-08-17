/// The Cinderpeak Foothills bestiary — Lv 6–11, Pyro (ENEMIES_DESIGN §2d).
///
/// ⭐ **Theme: the mountain is breathing, and it is breathing faster.** From
/// the arrival text — *"somewhere above, the mountain is breathing; the air
/// tastes of struck flint."* ⚠️ **Pressure, not eruption.** A volcano
/// mid-eruption is a set piece; a volcano getting ready is a threat, and it
/// leaves the eruption available for The Molten Deep twenty levels later.
///
/// ⚠️ **Heat is internal here.** Everything below glows through cracks, seams
/// and vents rather than being on fire. A roster of open flame would spend the
/// zone's premise in the first encounter.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/cinderpeak_test.dart`
/// resolves every id against [ItemCatalogue] instead.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_def.dart';

const _zone = 'cinderpeak_foothills';
const _pyro = [MagicElement.pyro];

/// Motes and bulk fall from everything; the main table is what varies.
const _commonAlways = [DropEntry('pyro_dust', chance: 0.75, min: 1, max: 2)];

abstract final class CinderpeakBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`. A Bruiser is
  /// the right first impression for a zone about pressure: it is **completely
  /// telegraphed**, and the charge bar is the whole tell.
  static const ashjawBrute = EnemyDef(
    id: 'ashjaw_brute',
    name: 'Ashjaw Brute',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _pyro,
    lore:
        'Ox-sized, and caked in grey ash that has dried and cracked like a '
        'riverbed. There is orange light in the cracks. It stands square and '
        'keeps its head low, which is not deference.',
    moves: [
      Spell(
        id: 'cp_shoulder',
        name: 'Shoulder',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ Expensive and slow on purpose — the Bruiser must charge, and the
      // charge bar is the tell. That telegraph is what it pays for its stats.
      Spell(
        id: 'cp_comedown',
        name: 'Come Down',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(31, 39),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('tuskhide', weight: 55, min: 1, max: 3),
        DropEntry('pyro_shard', weight: 20),
      ],
    ),
  );

  /// ⭐ Priority 5 is the Skirmisher's whole lesson: it acts before you.
  static const flintSkink = EnemyDef(
    id: 'flint_skink',
    name: 'Flint Skink',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _pyro,
    lore:
        'Forearm-length, and its scales are knapped flint — faceted, dark, and '
        'glowing orange between the plates. It crosses rock too hot to stand '
        'on and does not appear to notice.',
    moves: [
      Spell(
        id: 'cp_skitter',
        name: 'Skitter',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'cp_strikesparks',
        name: 'Strike Sparks',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(10, 14),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('copper_ore', weight: 45),
        DropEntry('pyro_shard', weight: 15),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage. The raws stay small **because the archetype
  /// multiplies them** — a Glasswing written at Bruiser numbers deletes a
  /// level-6 player from full health.
  static const cinderMoth = EnemyDef(
    id: 'cinder_moth',
    name: 'Cinder Moth',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _pyro,
    lore:
        'Two hands across, wings a translucent ash-grey shot through with '
        'ember veins that brighten toward the body. It looks one touch from '
        'disintegrating, and that turns out to be accurate.',
    moves: [
      Spell(
        id: 'cp_dustoff',
        name: 'Dust Off',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'cp_gooutbright',
        name: 'Go Out Bright',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(12, 16),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('copper_ore', weight: 50, min: 1, max: 2),
        DropEntry('pyro_shard', weight: 15),
      ],
    ),
  );

  /// ⭐ The zone's shield tutor: the wall is bigger than anything the player
  /// owns at level 8, and the answer is to break it rather than out-damage it.
  static const slagshellTortoise = EnemyDef(
    id: 'slagshell_tortoise',
    name: 'Slagshell Tortoise',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _pyro,
    lore:
        'The shell is one lump of cooled lava, pitted and cracked with dull '
        'red still down in the fissures. The face underneath it is ancient and '
        'entirely patient. It draws in slightly and waits you out.',
    moves: [
      Spell(
        id: 'cp_shove',
        name: 'Shove',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 16),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'cp_drawin',
        name: 'Draw In',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('copper_ore', weight: 40),
        DropEntry('pyro_shard', weight: 25, min: 1, max: 2),
        DropEntry('tuskhide', weight: 5),
      ],
    ),
  );

  /// ⭐ The Blighter wins by out-lasting rather than out-hitting: 0.60 damage,
  /// every move multi-hit, and nothing it throws is ever frightening on its
  /// own.
  static const ventworm = EnemyDef(
    id: 'ventworm',
    name: 'Ventworm',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _pyro,
    lore:
        'Half out of a fissure and as long as a man, dull red-brown and '
        'segmented. Its front end is a ring of small plates rather than a '
        'mouth, and sulphur comes out of it steadily whether or not it moves.',
    moves: [
      Spell(
        id: 'cp_fume',
        name: 'Fume',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'cp_sourair',
        name: 'Sour Air',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('copper_ore', weight: 50, min: 2, max: 3),
        DropEntry('pyro_shard', weight: 20),
      ],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const slagheart = EnemyDef(
    id: 'slagheart',
    name: 'Slagheart',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _pyro,
    lore:
        'A man-shape of cooled black lava, cracked throughout, with one '
        'fist-sized cavity in the chest and a molten core sitting in it. The '
        'arms do not match. It moves deliberately and it is balanced.',
    moves: [
      Spell(
        id: 'cp_backhand',
        name: 'Backhand',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(13, 17),
      ),
      Spell(
        id: 'cp_openthecore',
        name: 'Open the Core',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(27, 34),
      ),
      Spell(
        id: 'cp_coolover',
        name: 'Cool Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition — planted over the fissure it guards, sunk
  /// into the rock, and in no hurry to be anywhere else.
  static const ventWarden = EnemyDef(
    id: 'vent_warden',
    name: 'Vent Warden',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _pyro,
    lore:
        'Twice as wide as a man and barely taller, fused slag and black basalt, '
        'with its legs sunk into the rock over a fissure. Its whole chest is a '
        'grate glowing deep orange. There is no head; the shoulders simply end.',
    moves: [
      Spell(
        id: 'cp_vent',
        name: 'Vent',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'cp_sealover',
        name: 'Seal Over',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 38),
      ),
      Spell(
        id: 'cp_blowoff',
        name: 'Blow Off',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(22, 28),
      ),
    ],
    drops: _miniDrops,
  );

  static const charTusk = EnemyDef(
    id: 'char_tusk',
    name: 'Char-Tusk',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _pyro,
    lore:
        'A boar shoulder-high to a man, hide burnt black and split with '
        'glowing seams, two great upward tusks of cracked stone with the tips '
        'still hot. It puts one foreleg forward and then does not move again.',
    moves: [
      Spell(
        id: 'cp_hook',
        name: 'Hook',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(27, 33),
      ),
      // ⚠️ The Executioner's contract: five charges of telegraph, and then a
      // number that ends an unshielded player outright.
      Spell(
        id: 'cp_carrythrough',
        name: 'Carry Through',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(47, 57),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is **priority, not status**: it always connects,
  /// and its cheap move lands ahead of everything on the board.
  /// 📝 Same note as every Hexer in the quarter — the engine has no
  /// creature-applied debuff yet (§4.2 unbuilt), so the archetype is written
  /// with the levers that actually resolve.
  static const theEmberqueen = EnemyDef(
    id: 'the_emberqueen',
    name: 'The Emberqueen',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _pyro,
    lore:
        'A moth the size of a large dog, wings a deep smouldering red held '
        'wide and scorched into a pattern I could not copy accurately. She '
        'displays rather than beats them. She has not once tried to leave.',
    moves: [
      Spell(
        id: 'cp_wingdust',
        name: 'Wing Dust',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'cp_smoulder',
        name: 'Smoulder',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(3, 4, hits: 4),
      ),
      Spell(
        id: 'cp_scorchmark',
        name: 'Scorch Mark',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(14, 18, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// ⛰️ **The endurance boss** — the mountainside itself, hunched, breathing.
  /// A Juggernaut pays for its size by being predictable, and this one is
  /// barely distinguishable from the slope it is standing on.
  static const theBreathingStone = EnemyDef(
    id: 'the_breathing_stone',
    name: 'The Breathing Stone',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _pyro,
    lore:
        'Four storeys of grey rock and scree in the rough shape of something '
        'hunched. The fissures down its back widen and narrow, slowly, in '
        'time. Vapour comes off its shoulders. It is the mountain, and the '
        'mountain is what has been breathing.',
    moves: [
      Spell(
        id: 'cp_breatheout',
        name: 'Breathe Out',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(44, 54),
      ),
      Spell(
        id: 'cp_closetheseams',
        name: 'Close the Seams',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'cp_slowheat',
        name: 'Slow Heat',
        chargeCost: 4,
        priority: 5,
        effect: DamageEffect(11, 14, hits: 2),
      ),
    ],
    drops: _bossDrops,
  );

  /// 👑 **The Tyrant — the mind.** ⭐ It is the only boss in the quarter with
  /// no weakness to exploit: a one-charge wall it can always afford, a fast
  /// mid-cost hit that lands **ahead of the player's shield**, and a finisher.
  /// The threat is not the statline; it is that it plays well.
  static const flintmaw = EnemyDef(
    id: 'flintmaw',
    name: 'Flintmaw',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _pyro,
    lore:
        'A great cat rendered in fractured volcanic glass, horse-sized and '
        'low, every plane sharp and faintly reflective with molten orange in '
        'the seams between. The jaw is too long. It watches, and it waits, '
        'and it is clearly deciding something.',
    moves: [
      Spell(
        id: 'cp_wait',
        name: 'Wait',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(12, 16),
      ),
      // ⭐ Priority 2 puts this ahead of the player's own shield (priority 3).
      // A Tyrant is the archetype that knows what that is worth.
      Spell(
        id: 'cp_pickthemoment',
        name: 'Pick the Moment',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(24, 30),
      ),
      Spell(
        id: 'cp_finishit',
        name: 'Finish It',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 52),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ Crystal appears here and nowhere below — the mote ladder's first real
  /// step is a mini-boss reward (ITEMS §8).
  ///
  /// 📝 The Cinder Loop's authored dropper is **The Emberqueen**
  /// (`cinderpeak_items.dart`). The pool shares one table, per the Whispering
  /// Woods shape, so it hangs off all four minis at the chase weight.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('pyro_shard', min: 1, max: 3),
      DropEntry('pyro_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('tuskhide', weight: 40, min: 2, max: 4),
      DropEntry('copper_ore', weight: 35, min: 2, max: 4),
      DropEntry('pyro_shard', weight: 20, min: 2, max: 4),
      DropEntry('cinder_loop', weight: 5),
    ],
  );

  /// ⚠️ No Epic in this zone — the quarter's only one is Ashfall Vale's
  /// Charlock. ⏳ Note how much copper a boss pays: it is a **banking**
  /// material with no Q1 recipe, and the size of the pile is the promise
  /// that Forgeholm will want it at 15 (ITEMS §9b.8).
  static const _bossDrops = DropTable(
    always: [
      DropEntry('pyro_crystal', min: 1, max: 2),
      DropEntry('pyro_shard', min: 3, max: 6),
      // ⭐ The gate item. The third of Hearthwood's "three ordinary proofs",
      // and the one that completes the set.
      DropEntry('proof_of_the_foothills'),
    ],
    main: [
      DropEntry('tuskhide', weight: 45, min: 4, max: 8),
      DropEntry('copper_ore', weight: 25, min: 4, max: 8),
      DropEntry('cinder_loop', weight: 20),
      DropEntry('pyro_shard', weight: 10, min: 4, max: 8),
    ],
  );

  static const commons = <EnemyDef>[
    ashjawBrute,
    flintSkink,
    cinderMoth,
    slagshellTortoise,
    ventworm,
  ];

  static const minis = <EnemyDef>[
    slagheart,
    ventWarden,
    charTusk,
    theEmberqueen,
  ];

  static const bosses = <EnemyDef>[theBreathingStone, flintmaw];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
