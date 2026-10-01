/// The Hallowmarch bestiary — Lv 45–49, Sanctus (ETHEREAL_CONTRACT §4.1).
///
/// ⭐ **Theme: someone is still doing the upkeep, and nobody has seen them.**
/// From the arrival text — *"A raised road, and someone built it… Every mile
/// or so there is a marker, and every marker has been maintained."* Nothing
/// here is ruined and nothing here is angry; every creature is a piece of an
/// obligation that has outlived whoever took it on.
///
/// ⚠️ **Load-bearing (ENEMIES §2e):** the causeway leads to The Sealed
/// Garden and the same oath maintains both. Changing this theme breaks that
/// zone too.
///
/// ⭐ **A PURE zone, so every creature is single-element Sanctus** and the
/// zone carries **no off-element move** — §2e.2 names four creatures in
/// fifteen zones and none of them is here. A pyro or solar move on anything
/// below would be a rule change, not a flourish.
///
/// ⭐⭐ **BOTH bosses drop `the_kept_third` on the `always` line** — one of
/// the three Ethereal fragments that open The Eclipsed Citadel (§3.4,
/// ENEMIES §2e.1). ⚠️ **Never weighted.** A run draws one boss of two, so a
/// gate part on a `main` table would turn mandatory progression into a coin
/// flip. That is the whole of the ruling and it is why both bosses share
/// [HallowmarchBestiary._bossDrops].
///
/// ⚠️ **Pilgrim's Remnant is a Bruiser, not a Drudge.** ENEMIES §2f called a
/// 0.80/0.70 body at level 47 *"the clearest waste in the audit"* and the
/// roster (final 2026-09-22) re-assigned it; the contract's §1.2 warning and
/// its drop table still say "the Drudge", because the contract and the roster
/// were written in parallel. ⭐ **The roster wins the creature, the contract
/// wins the drop row** (§0.1/§0.3) — so it is a Bruiser carrying the Drudge's
/// consumable-bearing table. 📝 The roster also proposes renaming it
/// *Pilgrim's Weight* ("the Bruiser is the pack, not the person"); the old
/// name is kept here exactly as the table keeps it, so the change stays
/// visible.
///
/// ⚠️ **The `hide` drop role resolves to `goldenrood`** — Hallowmarch defines
/// no kill-only hide, so §3.5.1 sends the role to the zone's SECOND
/// gatherable material at the weight a hide would have carried.
///
/// ⚠️ **Combat stats copy each archetype's row verbatim** (CELESTIAL §2.3,
/// held in full by ETHEREAL §2.3), reaching the duel through
/// `EnemyDef.combatStats` — never through gear. ⭐ **The Adept is deliberately
/// blank** (`EnemyCombatStats.none`): §2.3 calls it the yardstick, and a
/// yardstick with a thumb on the scale stops being one.
///
/// ⚠️ **Raw damage comes from §1.3's authoring table, which does NOT grow**
/// with the band. The 45–49 difficulty arrives through the encounter LEVEL —
/// `1.04^(L−1)` — and a builder authoring a level-49 boss will want to doubt
/// that. Hard ceiling: ≤ 60 raw on one move, ≤ 12 raw per charge.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/hallowmarch_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⭐ Every id this zone
/// names is defined in `hallowmarch_items.dart`: Hallowmarch borrows nothing
/// from a sibling lane (§7.3, *"all local"*).
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'hallowmarch';

/// ⭐ Pure zone, so ONE mote ladder at the full 0.75 — a hybrid is what pays
/// two families at half chance each (§3.2, the shipped Frostfell shape).
const _sanctus = [MagicElement.sanctus];

const _commonAlways = [DropEntry('sanctus_dust', chance: 0.75, min: 1, max: 2)];

/// ⭐ §4.1's **material-A** row — the wood, and the only common table that
/// carries the quarter's Ration. ⚠️ `climbers_ration` sits in `bonus`, not
/// `main`: it is rolled independently on top, which is what makes 2% mean 2%
/// rather than two points of a hundred-weight draw.
const _materialA = DropTable(
  always: _commonAlways,
  main: [
    DropEntry.nothing(weight: 12),
    DropEntry('spiritwood_log', weight: 74, min: 1, max: 3),
    DropEntry('sanctus_shard', weight: 5),
    DropEntry('sanctus_dust', weight: 9, min: 1, max: 2),
  ],
  bonus: [DropEntry('climbers_ration', chance: 0.02)],
);

/// ⭐ §4.1's **material-B** row — the herb out of the meltwater channel, and
/// therefore also where the `hide` role lands (§3.5.1).
const _materialB = DropTable(
  always: _commonAlways,
  main: [
    DropEntry.nothing(weight: 15),
    DropEntry('goldenrood', weight: 72, min: 1, max: 2),
    DropEntry('sanctus_shard', weight: 5, min: 1, max: 2),
    DropEntry('sanctus_dust', weight: 8, min: 2, max: 3),
  ],
);

/// ⭐ §4.1's **"the Drudge"** row, kept on Pilgrim's Remnant although the
/// roster made it a Bruiser. §1.2's reasoning survives the archetype change:
/// *"the drop tables put the zone's **consumable** on the Drudge, so a slot
/// that teaches nothing at least pays something."* ⚠️ 15% is the most
/// generous Ration rate any common in the quarter carries.
const _drudgeDrops = DropTable(
  always: _commonAlways,
  main: [
    DropEntry.nothing(weight: 20),
    DropEntry('goldenrood', weight: 65),
    DropEntry('climbers_ration', weight: 15),
  ],
);

abstract final class HallowmarchBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and one of
  /// the seven Sentinels the audit KEPT (§2f): a warden on a road **is** a
  /// barrier, so the archetype and the noun are the same statement.
  static const causewayWarden = EnemyDef(
    id: 'causeway_warden',
    name: 'Causeway Warden',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _sanctus,
    lore:
        'A broad armoured figure standing square in the middle of the road '
        'rather than beside it, pale stone and pale metal gone the colour of '
        'the causeway it has not stepped off. It does not advance and it has '
        'never been seen to sit down.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'hm_bartheway',
        name: 'Bar the Way',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⚠️ Slow on purpose (§2.5, tempo lean = cost band): the wall is the
      // expensive move, so it telegraphs a full turn before it lands.
      Spell(
        id: 'hm_standthepost',
        name: 'Stand the Post',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: _materialA,
  );

  /// ⭐ **The yardstick** — the zone's Adept, and the only creature here with
  /// a blank stat block. Someone who swore to keep the markers and is keeping
  /// them, fighting you completely straight in a zone whose whole premise is
  /// that nobody has been seen doing the work.
  static const markerSworn = EnemyDef(
    id: 'marker_sworn',
    name: 'Marker-Sworn',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _sanctus,
    lore:
        'A robed figure of ordinary height carrying a short rule and a pot of '
        'whitewash, met walking between two markers. It finishes the stroke '
        'it was making before it turns around, and it picks the stroke up '
        'again afterwards.',
    moves: [
      Spell(
        id: 'hm_keepthemarker',
        name: 'Keep the Marker',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'hm_doitproperly',
        name: 'Do It Properly',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield.
      Spell(
        id: 'hm_swearitagain',
        name: 'Swear It Again',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
    ],
    drops: _materialB,
  );

  /// ⭐ **Damage in pieces** — the Lasher, and the reason a big shield is not
  /// always the answer: each voice meets the wall on its own.
  static const meltwaterChoir = EnemyDef(
    id: 'meltwater_choir',
    name: 'Meltwater Choir',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _sanctus,
    lore:
        'The channel beside the road running over stone that was cut to make '
        'it sound like that. There is no body in it anywhere. It is loudest '
        'in the afternoon and it has been in tune for four hundred years.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      // ⭐ Every Lasher move is multi-hit (§1.3's per-archetype rule).
      Spell(
        id: 'hm_takeuptheline',
        name: 'Take Up the Line',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'hm_carrythewholeverse',
        name: 'Carry the Whole Verse',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: _materialB,
  );

  /// ⭐ **A small flame is one good hit from out, and one good hit from
  /// everything.** ⚠️ 0.50 HP against 1.70 damage — the Glasswing is the
  /// archetype whose lesson is that killing fast beats playing safe.
  static const votive = EnemyDef(
    id: 'votive',
    name: 'Votive',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _sanctus,
    lore:
        'A single small flame standing upright at head height beside a '
        'marker, with no lamp under it and nothing feeding it. Somebody lit '
        'it on purpose. It leans toward whoever is nearest the way a candle '
        'leans toward a draught.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'hm_gutter',
        name: 'Gutter',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The band's top for a common, and the whole creature spent at once.
      Spell(
        id: 'hm_burnthewholewick',
        name: 'Burn the Whole Wick',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: _materialA,
  );

  /// ⚠️ **A Bruiser, not a Drudge** — §2f's re-assignment, and the library
  /// comment above explains why the "Drudge" drop row stays on it anyway.
  /// ⭐ Completely telegraphed: nothing cheap, so it must charge, and the
  /// charge bar is the whole read.
  static const pilgrimsRemnant = EnemyDef(
    id: 'pilgrims_remnant',
    name: "Pilgrim's Remnant",
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _sanctus,
    lore:
        'A pilgrim\'s pack, still roped and still full, standing upright on '
        'the road at about chest height with nobody inside the straps. It is '
        'travelling uphill at a walking pace and it has not put itself down '
        'once.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'hm_shoulderit',
        name: 'Shoulder It',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'hm_setitdownonyou',
        name: 'Set It Down on You',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: _drudgeDrops,
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each mini archetype, so the two drawn per run are always a
  // different pair of tactical roles (ENEMIES §2g).

  static const milestone = EnemyDef(
    id: 'milestone',
    name: 'Milestone',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _sanctus,
    lore:
        'A road-marker twice the height of the ones behind it, cut from the '
        'same pale stone and lettered in the same hand, standing in the '
        'middle of the causeway where no marker has ever stood. The number '
        'on it is the next one.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'hm_countthemile',
        name: 'Count the Mile',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'hm_setthestone',
        name: 'Set the Stone',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'hm_bringthenextone',
        name: 'Bring the Next One',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ **Attrition — there is no going around it.** 2.20 HP with a 10.5% EV
  /// deflection on top. ⚠️ §2.3 recommends dropping that deflect to 25 for
  /// the **dungeon** Redoubts only (Bedrock Colossus, Reliquary Colossus);
  /// Hallowmarch is a route, so the player can retreat and the archetype's
  /// own row stands.
  static const vestalWarden = EnemyDef(
    id: 'vestal_warden',
    name: 'Vestal Warden',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _sanctus,
    lore:
        'A seated armoured figure half again as tall as a person, occupying '
        'a shelter built into the roadside for exactly one occupant, with a '
        'small lamp burning in the niche beside it. The shelter was built '
        'around it and the lamp has never gone out.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'hm_keepthelamp',
        name: 'Keep the Lamp',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does,
      // which is what makes a Redoubt a wall rather than a large target.
      Spell(
        id: 'hm_tendthewatch',
        name: 'Tend the Watch',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      // ⭐ The Redoubt's heal, written with the lever the engine actually
      // has: lifesteal, not a heal effect that does not exist.
      Spell(
        id: 'hm_drawfromthelamp',
        name: 'Draw from the Lamp',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(26, 34, lifesteal: 0.4),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **Cost cap lowered from 5 to 4** (§1.3) — at level 49 a mini
  /// five-charge raw lands well past the player's whole bar, and there is no
  /// reading of *"kills you in three turns if you misplay one"* that survives
  /// a one-shot. ⭐ The archetype's lesson is written into the effect rather
  /// than into the number: it finishes what is already finished.
  static const seraphJudicant = EnemyDef(
    id: 'seraph_judicant',
    name: 'Seraph Judicant',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _sanctus,
    lore:
        'A tall winged figure that arrives already facing you, holding a '
        'plain unrolled writ in both hands and reading from it without '
        'looking down. It has the bearing of something carrying out a '
        'decision taken somewhere else a long time ago.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'hm_readthecharge',
        name: 'Read the Charge',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'hm_passthesentence',
        name: 'Pass the Sentence',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, executeBelowPercent: 30),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ **Something that has been doing a small thing to you for a very long
  /// time.** 📝 The engine has no creature-applied debuff yet, so the Hexer
  /// is written with the levers that actually resolve: its signature is
  /// PRIORITY, not status — it lands before your shield does, and its last
  /// move walks through the shield anyway.
  static const theUpkeep = EnemyDef(
    id: 'the_upkeep',
    name: 'The Upkeep',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _sanctus,
    lore:
        'Not a figure — the work itself, visible as a moving patch of road '
        'that is cleaner than the road around it, about the size of a person '
        'kneeling. It is always a little further along than it was, and it '
        'has never been in front of anybody.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'hm_makeasmallrepair',
        name: 'Make a Small Repair',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'hm_doitagaintomorrow',
        name: 'Do It Again Tomorrow',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'hm_neverstop',
        name: 'Never Stop',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------
  // ⭐⭐ The pair is **who still does it** and **who ordered it** — a force
  // and a will, not a mirror. ⚠️ No Aspect: ENEMIES §2g fields none here, and
  // §2.4 records the consequence out loud — **Sanctus never gets an Aspect
  // anywhere in the game.** Do not "fix" that into a symmetry.

  /// 🛠️ **Who still does it.** The Juggernaut: endurance, and it pays for its
  /// size by being completely predictable.
  static const theKeeperOfTheRoad = EnemyDef(
    id: 'the_keeper_of_the_road',
    name: 'The Keeper of the Road',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _sanctus,
    lore:
        'Four storeys of pale road-stone in roughly the shape of a person '
        'stooping to their work, carrying a straight edge as long as the '
        'causeway is wide. Every marker behind it is true. Every marker '
        'ahead of it is about to be.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'hm_clearthelength',
        name: 'Clear the Length',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'hm_closetheroad',
        name: 'Close the Road',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'hm_finishthework',
        name: 'Finish the Work',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 👑 **Who ordered it.** The Tyrant: the intelligence is the threat, and
  /// the kit says so — an order does not care what you are holding, so the
  /// middle move goes through the shield rather than at it.
  static const theHierophantEternal = EnemyDef(
    id: 'the_hierophant_eternal',
    name: 'The Hierophant Eternal',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _sanctus,
    lore:
        'A vested figure four storeys tall standing at the head of the '
        'causeway facing back down it, hands folded, entirely still. It has '
        'given one instruction in its life and everything on this road is '
        'still carrying it out.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 5,
      dodge: 5,
      critChance: 10,
      critDamage: 15,
      deflectChance: 10,
      deflectAmount: 15,
    ),
    moves: [
      Spell(
        id: 'hm_speaktheorder',
        name: 'Speak the Order',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'hm_requireitofyou',
        name: 'Require It of You',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31, ignoresShields: true),
      ),
      Spell(
        id: 'hm_letitbekept',
        name: 'Let It Be Kept',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⭐ §4.1's mini table. Crystal — the mote ladder's first real step — is a
  /// 15% chance here (a quarter until the 2026-09-30 lean) and guaranteed on
  /// a boss, so the ladder is felt as a
  /// fight the player chose (ITEMS §8). ⚠️ `votive_pendant` at 5 is the
  /// zone's rare chase and the only rarity above `uncommon` a mini hands out.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('sanctus_shard'),
      DropEntry('sanctus_dust', min: 1, max: 3),
      DropEntry('sanctus_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('spiritwood_log', weight: 40, min: 2, max: 4),
      DropEntry('goldenrood', weight: 30, min: 2, max: 4),
      DropEntry('climbers_ration', weight: 25),
      DropEntry('votive_pendant', weight: 5),
    ],
  );

  /// ⭐⭐ **Shared by both bosses, and `the_kept_third` is the reason.** §3.4
  /// and ENEMIES §2e.1 put the gate fragment on BOTH bosses' `always` line at
  /// the default chance of 1 — ⚠️ never weighted, never in `main`, because a
  /// run draws one boss of two and a mandatory part must not be a coin flip.
  ///
  /// ⭐ The zone's `unique` role resolves to this table rather than to a
  /// per-boss id: §4.1 authors one epic and one rare for the whole zone, the
  /// shipped Frostfell shape (`the_holdfast` on the shared boss table).
  static const _bossDrops = DropTable(
    always: [
      DropEntry('the_kept_third'),
      DropEntry('sanctus_crystal', min: 1, max: 2),
      DropEntry('sanctus_shard', min: 1, max: 2),
      DropEntry('sanctus_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('spiritwood_log', weight: 45, min: 4, max: 8),
      DropEntry('goldenrood', weight: 25, min: 3, max: 6),
      DropEntry('votive_pendant', weight: 20),
      DropEntry('the_maintained_road', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    causewayWarden,
    markerSworn,
    meltwaterChoir,
    votive,
    pilgrimsRemnant,
  ];

  static const minis = <EnemyDef>[
    milestone,
    vestalWarden,
    seraphJudicant,
    theUpkeep,
  ];

  static const bosses = <EnemyDef>[theKeeperOfTheRoad, theHierophantEternal];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
