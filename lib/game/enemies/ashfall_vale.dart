/// The Ashfall Vale bestiary — Lv 10–14, Pyro + Flora (ENEMIES_DESIGN §2d).
///
/// ⭐ **Theme: an argument between fire and regrowth, still unresolved.** The
/// arrival text already wrote it — *"fire came through here, and something is
/// arguing about whether it won."* ⚠️ Every creature must show **both at
/// once**: new green through burnt black, or old embers surviving inside new
/// growth. A creature that is only one side of the argument breaks the zone.
///
/// ⭐ **The boss pool IS the theme, and that is the point.** Which boss you
/// draw tells you which side is winning today — The Blackened Crown (fire won)
/// or The Rooting (green won). ⭐ This is the strongest possible use of the
/// 2-of-2 draw (§3d): the pool is not variety for its own sake, it is the zone
/// saying something different each time you clear it. **Worth copying wherever
/// a later hybrid has a genuine tension.**
///
/// ⭐ **The argument is legible in the statlines, not just the names** (§2g):
/// First Green is the Redoubt and Last Ember is the Executioner, because
/// regrowth wins by outlasting and fire wins by being faster. ⚠️ Do not swap
/// those two archetypes in any later refinement — the theme is carried there.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/ashfall_vale_test.dart`
/// resolves every id against [ItemCatalogue] instead.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_def.dart';

const _zone = 'ashfall_vale';

/// ⭐ **Both, by default** (§2h) — the zone's premise is two elements
/// contesting, so a creature carrying one of them is a creature that has
/// already settled the argument.
const _both = [MagicElement.pyro, MagicElement.flora];

/// ⚠️ The single exception, and the doc calls it out by name: Last Ember has
/// *"nothing green on it anywhere — the one creature in the zone that is only
/// fire"* (BESTIARY_ART). It is the only creature here entitled to one element.
const _pyro = [MagicElement.pyro];

/// ⚠️ A hybrid pays in **two** mote currencies, so each is thinner than a pure
/// zone's single 0.75 roll — the total handed over stays comparable.
///
/// ⭐ **Dust routine, Shards uncommon** (ruling, 2026-08-17 — the reasoning is
/// written out once, on `whispering_woods.dart`). Every `*_shard` weight below
/// is a third of what it was and the freed weight went to the matching
/// `*_dust`, so the mains still sum to 100. ⚠️ A hybrid's elevated ranks pay
/// **both** ladders, so their per-element bands are half a pure zone's.
const _commonAlways = [
  DropEntry('pyro_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('flora_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class AshfallValeBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`. A burnt
  /// thing still seeding is the argument in one creature, which is why it is
  /// the name a player meets first.
  static const cinderbloomHusk = EnemyDef(
    id: 'cinderbloom_husk',
    name: 'Cinderbloom Husk',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _both,
    lore:
        'A burnt stalk the height of a man, hollow and brittle, topped with a '
        'charred seed head that sheds grey without stopping. Green shoots have '
        'already broken through the black stem. It walks on stiff roots.',
    moves: [
      // ⭐ Both moves multi-hit: the Blighter wins by out-lasting rather than
      // out-hitting, and nothing it throws is frightening on its own.
      Spell(
        id: 'av_shedash',
        name: 'Shed Ash',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'av_seedfall',
        name: 'Seed Fall',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('charcoal', weight: 45),
        DropEntry('brookmint', weight: 15),
      ],
    ),
  );

  /// ⭐ New growth drinking the burn — §2b's rule applied exactly: *a plant
  /// that absorbs should absorb*, so this is a Siphon rather than a small tree
  /// with a Bruiser statline.
  static const ashrootSapling = EnemyDef(
    id: 'ashroot_sapling',
    name: 'Ashroot Sapling',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _both,
    lore:
        'No taller than a man, bark scorched black down one side and pale '
        'green down the other, walking on a splay of roots. The roots are '
        'visibly drawing ash up into the trunk, and the green side is the '
        'better for it.',
    moves: [
      Spell(
        id: 'av_takeup',
        name: 'Take Up',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8, lifesteal: 0.5),
      ),
      Spell(
        id: 'av_drawthegrey',
        name: 'Draw the Grey',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(13, 17, lifesteal: 0.75),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('birch_log', weight: 50, min: 1, max: 2),
        DropEntry('flora_shard', weight: 7),
        DropEntry('flora_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage — the raws stay small **because the archetype
  /// multiplies them**. ⭐ A seed that germinates in fire: fragile, and it
  /// *pops*.
  static const emberseed = EnemyDef(
    id: 'emberseed',
    name: 'Emberseed',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _both,
    lore:
        'A melon-sized pod hovering a hand above the ground, husk cracked open '
        'in a spiral around a fiercely glowing core. Charred filaments trail '
        'behind it. Everything about it reads as about to burst.',
    moves: [
      Spell(
        id: 'av_crack',
        name: 'Crack',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'av_burst',
        name: 'Burst',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(12, 17),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('charcoal', weight: 45),
        DropEntry('pyro_shard', weight: 7),
        DropEntry('pyro_dust', weight: 13, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Priority 5 is the Skirmisher's whole lesson: it acts before you.
  static const scorchmoth = EnemyDef(
    id: 'scorchmoth',
    name: 'Scorchmoth',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _both,
    lore:
        'Hand-sized and narrow in the wing, sooty black with tiny bright green '
        'spots across it like new leaves. Thin body, long legs, and it does '
        'not hold still long enough to be counted. Ash falls around it '
        'constantly.',
    moves: [
      Spell(
        id: 'av_dartthrough',
        name: 'Dart Through',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'av_passclose',
        name: 'Pass Close',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(10, 14),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('brookmint', weight: 40),
        DropEntry('pyro_shard', weight: 7),
        DropEntry('pyro_dust', weight: 13, min: 1, max: 2),
        // ⚠️ Deliberately thin. Tonics are meant to be CRAFTED (§9b.8) — the
        // brookmint is the real drop, and a generous potion faucet would make
        // Potions & Alchemy pointless before it opens.
        DropEntry('brookmint_tonic', weight: 5),
      ],
    ),
  );

  static const charwoodWalker = EnemyDef(
    id: 'charwood_walker',
    name: 'Charwood Walker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _both,
    lore:
        'A dead tree twice a man\'s height, charred and stripped, walking on '
        'two thick root-legs with branches for arms. Dull orange heat still '
        'sits in the cracks. One green branch grows from a shoulder, and it '
        'has not been shed.',
    moves: [
      Spell(
        id: 'av_swingdown',
        name: 'Swing Down',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ Expensive and slow on purpose — the Bruiser must charge, and the
      // charge bar is the tell.
      Spell(
        id: 'av_topple',
        name: 'Topple',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(32, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('birch_log', weight: 55, min: 1, max: 3),
        DropEntry('charcoal', weight: 20),
      ],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const theGreyStag = EnemyDef(
    id: 'the_grey_stag',
    name: 'The Grey Stag',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'A tall stag the colour of cold ash, coat gone uniform grey, antlers '
        'burnt black at the tips. Small green leaves are growing from the base '
        'of the antlers. It raises its head and it does not run.',
    moves: [
      Spell(
        id: 'av_lowerthehead',
        name: 'Lower the Head',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(13, 17),
      ),
      Spell(
        id: 'av_drivethrough',
        name: 'Drive Through',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(27, 34),
      ),
      Spell(
        id: 'av_greyover',
        name: 'Grey Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ **Regrowth wins by outlasting** — the green half of the argument, and
  /// the reason it is a Redoubt. Its wall goes up early and its damage move
  /// heals it: there is no clock under which this loses.
  static const firstGreen = EnemyDef(
    id: 'first_green',
    name: 'First Green',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _both,
    lore:
        'A thicket of new growth risen into a squat figure twice a man\'s '
        'width, every surface crowded with bright young leaves. Underneath the '
        'green there are glimpses of blackened wood. It is rooted, and it does '
        'not intend to move.',
    moves: [
      Spell(
        id: 'av_pushthrough',
        name: 'Push Through',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'av_growover',
        name: 'Grow Over',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(32, 40),
      ),
      Spell(
        id: 'av_comeback',
        name: 'Come Back',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(14, 18, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ **Fire wins by being faster** — the other half of the argument. ⚠️ Note
  /// the priority: its cheaper move resolves in the **quick** band (5), which
  /// no other Executioner in the quarter does. That is the theme written into
  /// the turn order rather than into the lore.
  static const lastEmber = EnemyDef(
    id: 'last_ember',
    name: 'Last Ember',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _pyro,
    lore:
        'Man-height and thin as a whip, charcoal and living flame, trailing '
        'sparks it does not seem to miss. Cracked black over white heat all '
        'the way down. There is nothing green on it anywhere.',
    moves: [
      Spell(
        id: 'av_takeitfast',
        name: 'Take It Fast',
        chargeCost: 3,
        priority: 5,
        effect: DamageEffect(25, 31),
      ),
      Spell(
        id: 'av_lastheat',
        name: 'Last Heat',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(48, 60),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is **priority, not status**, and Kindleroot's
  /// priority-1 move does both halves of the argument in one action: it burns
  /// and it grows, in the same breath.
  static const kindleroot = EnemyDef(
    id: 'kindleroot',
    name: 'Kindleroot',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _both,
    lore:
        'A cart-wide sprawl of root lifted up off the ground, every tip '
        'glowing orange like a slow match. Wherever it has crossed there are '
        'small fires and small shoots, both, in the same tracks. It has no '
        'head at all.',
    moves: [
      Spell(
        id: 'av_creep',
        name: 'Creep',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'av_bothatonce',
        name: 'Both At Once',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(5, 7, lifesteal: 1),
      ),
      Spell(
        id: 'av_catch',
        name: 'Catch',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(14, 18, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// 👑 **Fire won.** ⭐ A Tyrant is *a mind* — something that decided — and
  /// this one is deliberately regal: a cheap wall it can always afford, a
  /// mid-cost hit that lands **ahead of the player's shield**, and a finisher.
  /// The threat is that it plays well, not that it is large.
  static const theBlackenedCrown = EnemyDef(
    id: 'the_blackened_crown',
    name: 'The Blackened Crown',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _both,
    lore:
        'Four storeys of burnt heartwood in roughly the shape of a man, broad '
        'in the shoulder, upright, still. The head is ringed with charred '
        'branches burning steadily and white. Nothing grows on it. It looks '
        'like it won.',
    moves: [
      Spell(
        id: 'av_stand',
        name: 'Stand',
        chargeCost: 1,
        priority: 3,
        effect: ShieldEffect(14, 18),
      ),
      // ⭐ Priority 2 puts this ahead of the player's own shield (priority 3).
      Spell(
        id: 'av_holdthevale',
        name: 'Hold the Vale',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(24, 30),
      ),
      Spell(
        id: 'av_burnitagain',
        name: 'Burn It Again',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 52),
      ),
    ],
    drops: _bossDrops,
  );

  /// ✨ **Green won.** The Aspect: one element taken to an extreme, and here
  /// the extreme is that **nothing keeps it out**. ⭐ Cheap constant sustain, a
  /// mid-cost hit that goes straight through the wall, and a swallow. Where
  /// the Crown out-thinks you, this simply arrives.
  static const theRooting = EnemyDef(
    id: 'the_rooting',
    name: 'The Rooting',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _both,
    lore:
        'A mound of new growth four storeys across and only two high, made of '
        'thousands of young saplings and ferns and vines grown together. Burnt '
        'timber and old bones are visible inside it, being swallowed. It looks '
        'like it is winning.',
    moves: [
      Spell(
        id: 'av_spread',
        name: 'Spread',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9, lifesteal: 1),
      ),
      Spell(
        id: 'av_growthrough',
        name: 'Grow Through',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(16, 21, ignoresShields: true),
      ),
      Spell(
        id: 'av_swallowit',
        name: 'Swallow It',
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
  /// crystals at roughly half the chance each.
  ///
  /// ⚠️ **No chase item on this table**, and that is a real asymmetry with the
  /// other four Primal zones: Ashfall Vale's only unique is the Epic Charlock,
  /// which is boss-only by rarity rule (ITEMS §8). 📝 If the zone ever wants a
  /// mini chase, it needs a new Rare authored — not the Charlock moved down.
  static const _miniDrops = DropTable(
    always: [
      // ⭐ Half a Shard per ladder, where a pure zone's mini guarantees one —
      // so a hybrid mini still pays **one Shard on average**, exactly the way
      // it already splits its Crystal chance (0.15 + 0.15 against a pure
      // zone's 0.25) instead of handing over two. ⚠️ Two guaranteed Shards
      // here is what made the hybrids the worst offenders: this bucket was
      // the bulk of the zone's Shard income (see `whispering_woods.dart`'s
      // _miniDrops). The Dust is new — elevated ranks never dropped any.
      DropEntry('pyro_shard', chance: 0.5),
      DropEntry('flora_shard', chance: 0.5),
      DropEntry('pyro_dust', min: 1, max: 2),
      DropEntry('flora_dust', min: 1, max: 2),
      DropEntry('pyro_crystal', chance: 0.15),
      DropEntry('flora_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('birch_log', weight: 40, min: 2, max: 4),
      DropEntry('charcoal', weight: 30, min: 2, max: 4),
      DropEntry('brookmint', weight: 25, min: 2, max: 4),
      DropEntry('brookmint_tonic', weight: 5),
    ],
  );

  /// ⭐ **The quarter's only Epic sits here**, at weight 10 of 100 — the same
  /// rate Whispering Woods gives the Heartwood Staff. 📝 The Charlock's
  /// authored dropper is **The Rooting** (`ashfall_vale_items.dart`): regrowth
  /// as a stat, off the boss that IS regrowth. The pool shares one table per
  /// the Whispering Woods shape, so The Blackened Crown pays it too.
  ///
  /// ⚠️ No gate item — proofs are a **pure**-zone reward, one per Primal
  /// element.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('pyro_crystal', min: 1, max: 2),
      DropEntry('flora_crystal', min: 1, max: 2),
      // ⭐ Was 2–4 of each; one apiece now, with Dust carrying the volume.
      DropEntry('pyro_shard'),
      DropEntry('flora_shard'),
      DropEntry('pyro_dust', min: 2, max: 4),
      DropEntry('flora_dust', min: 2, max: 4),
    ],
    main: [
      DropEntry('birch_log', weight: 45, min: 4, max: 8),
      DropEntry('charcoal', weight: 25, min: 3, max: 6),
      DropEntry('brookmint', weight: 20, min: 3, max: 6),
      DropEntry('the_charlock', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    cinderbloomHusk,
    ashrootSapling,
    emberseed,
    scorchmoth,
    charwoodWalker,
  ];

  static const minis = <EnemyDef>[
    theGreyStag,
    firstGreen,
    lastEmber,
    kindleroot,
  ];

  static const bosses = <EnemyDef>[theBlackenedCrown, theRooting];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
