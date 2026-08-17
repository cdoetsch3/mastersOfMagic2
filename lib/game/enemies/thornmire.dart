/// The Thornmire bestiary — Lv 8–13, Flora + Aqua (ENEMIES_DESIGN §2d).
///
/// ⭐ **Theme: the green has beaten the water, and is drinking it.** From the
/// arrival text — *"the path becomes a suggestion, then a rumour, then water…
/// everything green here is winning."*
///
/// ⚠️ **This is the fusion, not a Flora monster standing next to an Aqua one.**
/// The two elements are one idea — **plants that absorb** — which is why this
/// zone is the natural home of the Siphon and the clearest example of the §2b
/// rule in the game. ⚠️ The failure mode to guard against on every future
/// hybrid: if the theme still makes sense with one element removed, it is not
/// a hybrid theme yet.
///
/// ⭐ **Two Siphons is deliberate** (§2d) and it is the thing to watch. Chip
/// damage does not accumulate against either of them, so a player who has
/// settled into safe play at level 8 finds the whole zone unwinnable until
/// they commit to burst. That is the lesson; it is also, if the level-8 spell
/// pool is thin, a wall. **Verify in the balance sim before shipping.**
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/thornmire_test.dart`
/// resolves every id against [ItemCatalogue] instead.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_def.dart';

const _zone = 'thornmire';

/// ⭐ **Both, by default** (§2h). A hybrid may assign one element per creature
/// or use both; here the premise is one element drinking the other, so almost
/// everything genuinely uses both. The single exception is the Thirstvine,
/// which §2h names outright as the "obviously Flora" case.
const _both = [MagicElement.flora, MagicElement.aqua];
const _flora = [MagicElement.flora];

/// ⚠️ A hybrid pays in **two** mote currencies, so each is thinner than a pure
/// zone's single 0.75 roll — the total handed over stays comparable.
///
/// ⭐ **Dust routine, Shards uncommon** (ruling, 2026-08-17 — the reasoning is
/// written out once, on `whispering_woods.dart`). Every `*_shard` weight below
/// is a third of what it was and the freed weight went to the matching
/// `*_dust`, so the mains still sum to 100. ⚠️ A hybrid's elevated ranks pay
/// **both** ladders, so their per-element bands are half a pure zone's.
const _commonAlways = [
  DropEntry('flora_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('aqua_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class ThornmireBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and an
  /// **Adept** — the competent fight, and the yardstick the two Siphons are
  /// felt against. ⚠️ Without it the zone is all trick and no baseline.
  static const mirewalker = EnemyDef(
    id: 'mirewalker',
    name: 'Mirewalker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'Tall, thin and long in the limb, black waterlogged wood hung with '
        'weed, wading upright. Bog water runs out of its joints the whole '
        'time. Its head is a narrow bud with nothing on it.',
    moves: [
      Spell(
        id: 'tm_wadein',
        name: 'Wade In',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'tm_bearunder',
        name: 'Bear Under',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      Spell(
        id: 'tm_weedover',
        name: 'Weed Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('bogflax_fibre', weight: 45),
        DropEntry('fenroot', weight: 15),
      ],
    ),
  );

  /// ⭐ **The zone's thesis in one creature**, and the §2h worked example: a
  /// Thirstvine is *obviously Flora drinking Aqua*, so it carries Flora alone
  /// while everything around it carries both.
  static const thirstvine = EnemyDef(
    id: 'thirstvine',
    name: 'Thirstvine',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _flora,
    lore:
        'Coiled like a python and swollen tight with what it has taken. Where '
        'it has fed the vine is fat and bright; where it has not, it is thin '
        'and grey. You can read its week off it.',
    moves: [
      Spell(
        id: 'tm_takeadrink',
        name: 'Take a Drink',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(4, 7, lifesteal: 0.6),
      ),
      Spell(
        id: 'tm_swell',
        name: 'Swell',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(12, 16, lifesteal: 0.75),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('bogflax_fibre', weight: 50, min: 1, max: 2),
        DropEntry('flora_shard', weight: 5),
        DropEntry('flora_dust', weight: 10, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ **The second drinker**, and the reason the zone teaches rather than
  /// merely surprises: one Siphon is a shock, two is a *rule about this
  /// place*. ⚠️ Its cheap move is FULL lifesteal at low damage — the most
  /// annoying possible expression of "attrition does not work here".
  static const leechcap = EnemyDef(
    id: 'leechcap',
    name: 'Leechcap',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _both,
    lore:
        'A plate-sized mushroom of wet dark red travelling gill-side down on a '
        'fringe of pale feelers. The underside spirals in to a small dark '
        'opening. Water runs off the cap and never into it.',
    moves: [
      Spell(
        id: 'tm_settleon',
        name: 'Settle On',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(4, 6, lifesteal: 1),
      ),
      Spell(
        id: 'tm_feed',
        name: 'Feed',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(14, 18, lifesteal: 0.5),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('fenroot', weight: 40),
        // ⭐ Still the zone's mote-richest common — it just pays in Dust now.
        DropEntry('aqua_shard', weight: 8, min: 1, max: 2),
        DropEntry('aqua_dust', weight: 17, min: 2, max: 3),
        // ⏳ Amber banks for Jewelry, which opens at Rimeholt (45). ⚠️ Kept
        // deliberately thin — an uncommon that a common hands out freely
        // stops being worth banking.
        DropEntry('amber', weight: 5),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage — the raws stay small **because the archetype
  /// multiplies them**.
  static const bogLantern = EnemyDef(
    id: 'bog_lantern',
    name: 'Bog Lantern',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _both,
    lore:
        'A seed-head the size of a man\'s head floating at chest height, lit '
        'greenish-white from inside, trailing a crown of fine filaments. The '
        'light is warm. The thing itself is not.',
    moves: [
      Spell(
        id: 'tm_comecloser',
        name: 'Come Closer',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'tm_gutter',
        name: 'Gutter',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(12, 16),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('fenroot', weight: 45),
        DropEntry('flora_shard', weight: 7),
        DropEntry('flora_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ The zone's shield tutor, and the one creature here that is not
  /// drinking anything — it simply waits, armoured, in the shallows.
  static const reedbackLurker = EnemyDef(
    id: 'reedback_lurker',
    name: 'Reedback Lurker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _both,
    lore:
        'Boat-sized, half submerged, its back a plate of green-black shell so '
        'overgrown with living reed that it reads as a piece of the bank. Two '
        'small dark eyes at the waterline. I walked past it twice.',
    moves: [
      Spell(
        id: 'tm_riseunder',
        name: 'Rise Under',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 16),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band).
      Spell(
        id: 'tm_reedover',
        name: 'Reed Over',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('bogflax_fibre', weight: 55, min: 1, max: 3),
        DropEntry('aqua_shard', weight: 7),
        DropEntry('aqua_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const oldWallow = EnemyDef(
    id: 'old_wallow',
    name: 'Old Wallow',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'Cart-sized, low and broad like a hippopotamus, and so thoroughly '
        'overgrown with moss and ferns and small saplings that the animal is '
        'a rumour under a garden. Small eyes, set high. Half out of the water.',
    moves: [
      Spell(
        id: 'tm_maul',
        name: 'Maul',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(13, 17),
      ),
      Spell(
        id: 'tm_rollover',
        name: 'Roll Over',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(27, 34),
      ),
      Spell(
        id: 'tm_mudover',
        name: 'Mud Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition, with no face to read it off — a wall that
  /// erodes you, and the only thing it does is keep coming.
  static const theGreenDrowning = EnemyDef(
    id: 'the_green_drowning',
    name: 'The Green Drowning',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _both,
    lore:
        'A standing wall of matted weed and root three times a man\'s height '
        'and as wide, rising sheer out of the bog with water pouring off it '
        'without stopping. No limbs. No face. It advances.',
    moves: [
      Spell(
        id: 'tm_advance',
        name: 'Advance',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'tm_thicken',
        name: 'Thicken',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 38),
      ),
      Spell(
        id: 'tm_bearover',
        name: 'Bear Over',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(22, 28),
      ),
    ],
    drops: _miniDrops,
  );

  static const wickerdrowned = EnemyDef(
    id: 'wickerdrowned',
    name: 'Wickerdrowned',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _both,
    lore:
        'A man-shape woven out of wet withies, hollow all the way through, '
        'with black water sloshing audibly inside the ribs. The arms have been '
        'sharpened. The head is a woven cage, tilted, listening.',
    moves: [
      Spell(
        id: 'tm_openyou',
        name: 'Open You',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(26, 33),
      ),
      // ⚠️ The Executioner's contract: five charges of telegraph, then a
      // number that ends an unshielded player outright.
      Spell(
        id: 'tm_fillyouup',
        name: 'Fill You Up',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(46, 58),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is **priority, not status** — and hers is the
  /// only priority-1 move in the quarter that also drinks, which is the zone
  /// asserting itself over the archetype (§2b: fiction picks the mechanics).
  static const fenmother = EnemyDef(
    id: 'fenmother',
    name: 'Fenmother',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _both,
    lore:
        'Hunched and broad-hipped, twice a man\'s bulk, woven reed over black '
        'mud and standing waist-deep. Her arms are long bundles of dripping '
        'root. Where a face should be there is a mat of green weed, hanging.',
    moves: [
      Spell(
        id: 'tm_countyou',
        name: 'Count You',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'tm_weighyoudown',
        name: 'Weigh You Down',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(8, 11, lifesteal: 1),
      ),
      Spell(
        id: 'tm_takeitback',
        name: 'Take It Back',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(13, 17, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// ⛰️ **The endurance boss.** A sinkhole wider than a house lying flush with
  /// the bog — a Juggernaut is a *mass or a force*, and almost none of this
  /// one is above the surface to hit.
  static const mirethroat = EnemyDef(
    id: 'mirethroat',
    name: 'Mirethroat',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _both,
    lore:
        'A ring of dark muscular plant matter wider than a house, lying level '
        'with the bog and opening into a funnel lined with rows of soft '
        'inward-pointing spines. The water spirals into it, slowly, always.',
    moves: [
      Spell(
        id: 'tm_swallow',
        name: 'Swallow',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(44, 54),
      ),
      Spell(
        id: 'tm_ringclose',
        name: 'Ring Close',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'tm_drawdown',
        name: 'Draw Down',
        chargeCost: 4,
        priority: 5,
        effect: DamageEffect(16, 20, lifesteal: 1),
      ),
    ],
    drops: _bossDrops,
  );

  /// ✨ **The trick boss**, and the zone's thesis at full scale: six drowned
  /// trees grown into one thing whose roots are out of the water and feeding.
  /// ⭐ Its extreme is **cheap** sustain — a one-charge full-lifesteal move it
  /// can afford every single turn, so there is no window in which it is not
  /// healing. The Standing Green heals when it hits; this heals as a habit.
  static const theDrinkingGrove = EnemyDef(
    id: 'the_drinking_grove',
    name: 'The Drinking Grove',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _both,
    lore:
        'Six drowned trees that have grown into one four-storey creature, '
        'trunks fused and canopy shared. Its roots are lifted clear of the '
        'water and end in a thicket of pale swollen tendrils, all dripping. '
        'The high branches are in full leaf and perfectly healthy.',
    moves: [
      Spell(
        id: 'tm_rootup',
        name: 'Root Up',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9, lifesteal: 1),
      ),
      Spell(
        id: 'tm_reachdown',
        name: 'Reach Down',
        chargeCost: 2,
        priority: 7,
        effect: DamageEffect(14, 19, lifesteal: 0.75),
      ),
      Spell(
        id: 'tm_drinkitdry',
        name: 'Drink It Dry',
        chargeCost: 4,
        priority: 6,
        effect: DamageEffect(30, 38, lifesteal: 0.5),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ Crystal appears here and nowhere below — the mote ladder's first real
  /// step is a mini-boss reward (ITEMS §8). ⭐ A hybrid drops **both parents'**
  /// crystals, at roughly half the chance each, so the total is comparable to
  /// a pure zone's while the player's mote drawer fills in two colours.
  ///
  /// 📝 The Wickerbound Ring's authored dropper is the **Fenmother**
  /// (`thornmire_items.dart`). The pool shares one table, per the Whispering
  /// Woods shape, so it hangs off all four minis at the chase weight.
  static const _miniDrops = DropTable(
    always: [
      // ⭐ Half a Shard per ladder, where a pure zone's mini guarantees one —
      // so a hybrid mini still pays **one Shard on average**, exactly the way
      // it already splits its Crystal chance (0.15 + 0.15 against a pure
      // zone's 0.25) instead of handing over two. ⚠️ Two guaranteed Shards
      // here is what made the hybrids the worst offenders: this bucket was
      // the bulk of the zone's Shard income (see `whispering_woods.dart`'s
      // _miniDrops). The Dust is new — elevated ranks never dropped any.
      DropEntry('flora_shard', chance: 0.5),
      DropEntry('aqua_shard', chance: 0.5),
      DropEntry('flora_dust', min: 1, max: 2),
      DropEntry('aqua_dust', min: 1, max: 2),
      DropEntry('flora_crystal', chance: 0.15),
      DropEntry('aqua_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('bogflax_fibre', weight: 40, min: 2, max: 4),
      DropEntry('fenroot', weight: 45, min: 2, max: 4),
      DropEntry('amber', weight: 10),
      DropEntry('wickerbound_ring', weight: 5),
    ],
  );

  /// ⚠️ No Epic and no gate item — proofs are a **pure**-zone reward (one per
  /// Primal element), and the quarter's only Epic is Ashfall Vale's Charlock.
  /// A hybrid's compensation is the third material, which is why amber sits on
  /// this table at a real weight.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('flora_crystal', min: 1, max: 2),
      DropEntry('aqua_crystal', min: 1, max: 2),
      // ⭐ Was 2–4 of each; one apiece now, with Dust carrying the volume.
      DropEntry('flora_shard'),
      DropEntry('aqua_shard'),
      DropEntry('flora_dust', min: 2, max: 4),
      DropEntry('aqua_dust', min: 2, max: 4),
    ],
    main: [
      DropEntry('bogflax_fibre', weight: 45, min: 4, max: 8),
      DropEntry('fenroot', weight: 25, min: 3, max: 6),
      DropEntry('wickerbound_ring', weight: 20),
      DropEntry('amber', weight: 10, min: 1, max: 2),
    ],
  );

  static const commons = <EnemyDef>[
    mirewalker,
    thirstvine,
    leechcap,
    bogLantern,
    reedbackLurker,
  ];

  static const minis = <EnemyDef>[
    oldWallow,
    theGreenDrowning,
    wickerdrowned,
    fenmother,
  ];

  static const bosses = <EnemyDef>[mirethroat, theDrinkingGrove];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
