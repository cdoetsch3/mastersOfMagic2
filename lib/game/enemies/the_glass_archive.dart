/// The Glass Archive bestiary — Lv 43–47, Solar + Arcane
/// (CELESTIAL_CONTRACT §4.7, ENEMIES §2e).
///
/// ⭐ **Theme: an archive readable only at noon, which the reading destroys.**
/// From the arrival text — *"Lenses on every roof, and all of them still
/// aimed… they recorded onto the one thing that will not hold still."* The
/// fusion is the two side-effects read together: Solar's is **Blind** and
/// Arcane's is **Arcane Knowledge**, so the premise falls out of the pairing
/// rather than being imposed on it — too bright to read, too much to know.
///
/// ⚠️ **Deliberately the opposite of The Buried Sky** (46–50) — light that
/// keeps nothing against stone that keeps everything. Stated in ENEMIES §2e,
/// in WORLD_DESIGN §4c.1c and here, in all three places, so nobody "fixes"
/// the pairing into a symmetry later.
///
/// 📝 **Deferred structure.** 🏰 in ENEMIES §2e and `LocationKind.dungeon` in
/// `world.dart` both stand, but ⚠️ **nothing in this file may assume a
/// descending-dungeon run** (KINETIC ruling 4, restated by CELESTIAL §0.3:
/// *"🏰 on two zones is `LocationKind.dungeon` and nothing in this quarter's
/// data may assume a descending run"*). The Molten Deep ships the same way.
///
/// ⭐ **This zone assigns element per creature** (§2h) — the two Solar
/// commons, the two Arcane commons, and the hybrid Adept between them. Read
/// the roster table before touching an element list.
///
/// ⚠️⚠️ **Burnt Index carries the zone's one off-element move** — pyro
/// (§2e.2, four creatures in fifteen zones). Legal because Solar is countered
/// by **Astral** and Arcane by **Umbra**, and Pyro is neither: a boss that
/// punishes correct preparation is the version of this idea that makes
/// players stop preparing (§2h's one non-tunable row). 📝 The engine has no
/// per-move element — a cast takes the element the caster CHARGED — so an
/// off-element move can only be expressed as a third entry in `elements`.
/// At intelligence 7 the brain spends it as a counter-pick against a wall it
/// cannot otherwise beat, which is the behaviour §2h asks for; it is not
/// strictly "one move", and that is the engine's floor, not a design choice.
///
/// ⚠️⚠️ **What Is Left Of It is SOLAR, and the two source docs disagree.**
/// ENEMIES §2e's roster table says solar — *"Blind taken to an extreme is the
/// theme, mechanised — the Aspect destroys the reading by being too bright to
/// read by"*. CELESTIAL §2.4's Aspect table says arcane. ⭐ The roster wins on
/// the **element**, because the contract itself defers creature facts to it
/// (§0.1: *"Creature names, archetypes, boss pools — the roster lane's, not
/// this document's"*; §0.3 repeats it). The contract wins on the **stat
/// block**, which §2.3/§2.4 are explicitly its own: `defl 30 / 25, acc +8`,
/// verbatim. ⭐ The two land compatibly — `accuracyBonus` is Solar's own gear
/// affinity (§2.5a) — and the boss pool ends up one Arcane mind and one Solar
/// glare rather than two of a kind.
///
/// ⚠️ **No `key` on either boss, and that is correct.** §2e.1 puts `key` on
/// both bosses of a *gate zone*, and the Celestial gate's three essences fall
/// in the quarter's three PURE zones (Kiln Desert, Mirrormere, Starfall). The
/// Archive defines `celestial_totem` in its catalogue because the player
/// earns it here (§4.7), but the Totem is **crafted at Meridian**, never
/// dropped.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_glass_archive_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`solar_*`,
/// `pilgrims_ration` and `arcsalt_draught` are cross-zone references** owned
/// by parallel Celestial worktrees (the Kiln Desert and The Shattered
/// Orrery); they resolve once the merge coordinator lands the lanes together.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_glass_archive';
const _solar = [MagicElement.solar];
const _arcane = [MagicElement.arcane];
const _both = [MagicElement.solar, MagicElement.arcane];

/// ⚠️ The zone's **one** off-element creature (§2e.2). Pyro is neither
/// Solar's counter (Astral) nor Arcane's (Umbra).
const _solarAndTheBurning = [MagicElement.solar, MagicElement.pyro];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.7's drop table, the shipped Frostfell shape).
///
/// ⭐⭐ `arcane_dust` is defined in THIS zone's catalogue (§3.2) — the Glass
/// Archive is the game's first Arcane zone, seven levels before The Collapsed
/// Academy. `solar_dust` is the Kiln Desert's.
const _commonAlways = [
  DropEntry('solar_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('arcane_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class GlassArchiveBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster (§2e: *"a wright is a maker, and a maker
  /// fights you straight"*). It carries no [EnemyCombatStats] on purpose —
  /// §2.3 calls the Adept row the yardstick, and a yardstick with a thumb on
  /// the scale stops being one.
  ///
  /// ⭐ Its drop row is §4.7's third common line. ⚠️ That line is labelled
  /// *"the Siphon"* in the contract, which was written against a roster draft
  /// in which Palimpsest was a Siphon; §2f then cut the Siphon from this zone
  /// entirely. The row lands here by ELEMENT, which is how the other two
  /// resolve: it is the only common row that pays no motes of its own, and
  /// the Glasswright is the only common that would otherwise owe both
  /// ladders. A glass-wright handing over archive glass also reads.
  static const glasswright = EnemyDef(
    id: 'glasswright',
    name: 'Glasswright',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A lean figure of fitted plate-glass panes held in a lead armature, '
        'still wearing the apron shape of the trade it died in. It squares '
        'up to you the way a craftsman squares up to a job, and it does not '
        'hurry any part of it.',
    moves: [
      Spell(
        id: 'ga_scorethepane',
        name: 'Score the Pane',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The Adept's honest kit: cheap hit, one shield, big hit.
      Spell(
        id: 'ga_settheframe',
        name: 'Set the Frame',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'ga_cuttosize',
        name: 'Cut to Size',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 20),
        DropEntry('aetherglass', weight: 65),
        DropEntry('arcsalt_draught', weight: 15),
      ],
    ),
  );

  /// ⚠️ 0.50 HP and 1.70 damage, so ⭐ **the raws sit ~35% under §1.3's common
  /// column** (§1.4's Glasswing row, the shipped Breathfrost shape) — the
  /// archetype does the multiplying. Pure Solar: noon is the whole creature.
  ///
  /// ⚠️ Nothing here is written as fire. Solar is **light**, and the zone's
  /// one licensed burning thing is Burnt Index.
  static const noonmark = EnemyDef(
    id: 'noonmark',
    name: 'Noonmark',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _solar,
    lore:
        'A person-sized wedge of hard white light standing on the hillside '
        'where a lens happens to be pointed, edged as cleanly as a shadow '
        'is edged. It has wings only in the sense that the edges of it beat '
        'once in a while, and it is gone by the middle of the afternoon.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'ga_strikenoon',
        name: 'Strike Noon',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'ga_overexpose',
        name: 'Overexpose',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: _materialCommon,
  );

  /// ⭐ *"A page scraped clean and rewritten **writes over you** — that is a
  /// status, not a drink"* (§2e). ⚠️ **Siphon cut** (§2f): a shock that
  /// happens in half the game is not a shock, and the Blighter says the same
  /// idea without taking anything.
  ///
  /// ⚠️ **Both moves multi-hit** (§1.3's per-archetype rule) — a Blighter
  /// wins by out-lasting, and a palimpsest is made one erasure at a time.
  static const palimpsest = EnemyDef(
    id: 'palimpsest',
    name: 'Palimpsest',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _arcane,
    lore:
        'A standing sheet of vellum about the height of a person, scraped '
        'thin in patches and written over so many times that no single hand '
        'is legible. The oldest layer keeps surfacing through the newest, '
        'and it is the one still moving.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'ga_writeover',
        name: 'Write Over',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ga_scrapeandbegin',
        name: 'Scrape and Begin',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: _hideCommon,
  );

  /// ⭐ *"Loose unread leaves arrive all at once"* (§2e) — the Lasher stated
  /// as a fact about paper. 📝 ENEMIES proposes renaming this to **Loose
  /// Quire** (a quire is a gathering of leaves, which is a Lasher said in one
  /// archaic word); the old name is kept in code so the change stays visible
  /// and is a one-line rename when it is ruled.
  static const readerless = EnemyDef(
    id: 'readerless',
    name: 'Readerless',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _arcane,
    lore:
        'Several dozen loose written leaves travelling together at about '
        'chest height, holding no shape for longer than a step, none of '
        'them bound to any of the others. Every one of them is face-up and '
        'none of them has been read.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      // ⭐ Every Lasher move is multi-hit — the archetype expressed where the
      // player feels it: each leaf meets the wall on its own.
      Spell(
        id: 'ga_comeapart',
        name: 'Come Apart',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ga_arriveatonce',
        name: 'Arrive At Once',
        chargeCost: 3,
        priority: 5,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: _hideCommon,
  );

  /// ⭐ The zone's priority tutor (§2e's *"Priority"*), and the Skirmisher's
  /// signature is where it sits on the ladder, not what it does: both moves
  /// at 5, ahead of every ordinary attack and behind every shield.
  static const lensfly = EnemyDef(
    id: 'lensfly',
    name: 'Lensfly',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _solar,
    lore:
        'A hand-span of ground lens on four thin legs, skating across the '
        'roof tiles and turning to keep its face toward the sun. It is '
        'never where the glare says it is, because the glare is a moment '
        'behind it.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'ga_cutacross',
        name: 'Cut Across',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ga_catchtheangle',
        name: 'Catch the Angle',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: _materialCommon,
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⭐ The zone's only mini that carries both elements — the one who was
  /// here for the reading and stayed for it.
  static const theLastReader = EnemyDef(
    id: 'the_last_reader',
    name: 'The Last Reader',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'A seated figure a head taller than a person, robed in smoked glass '
        'panes with a reading-frame still braced across its lap. It stands '
        'to meet you without putting the frame down, and it keeps its place '
        'with one finger the entire time.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'ga_takeonepage',
        name: 'Take One Page',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ga_shadetheglass',
        name: 'Shade the Glass',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ga_readtotheend',
        name: 'Read to the End',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition, pure Solar — an aperture's whole job is
  /// deciding how much gets through, and it decides less and less.
  static const aperture = EnemyDef(
    id: 'aperture',
    name: 'Aperture',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _solar,
    lore:
        'A ring of overlapping brass leaves twice the height of a person, '
        'standing upright on the hillside with nothing holding it there. '
        'The opening at its centre narrows and widens on its own schedule, '
        'and the light behind it is much older than the light around it.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'ga_stopdown',
        name: 'Stop Down',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'ga_closetoaslit',
        name: 'Close to a Slit',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ga_openwide',
        name: 'Open Wide',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️⚠️ **The zone's one off-element creature** (§2e.2) — and see the
  /// library note above for why an off-element *move* has to be written as a
  /// third element on the creature. *"The index burned."*
  ///
  /// ⚠️ **The Executioner's cost cap stays at 4** (§1.3, lowered by KINETIC
  /// and not raised back): at L47 a mini five-charge raw would land 884–1153
  /// against a 607 HP bar — not a two-cast kill, a one-shot with change. At
  /// cost 4 it lands 300–392, which is the ratio the archetype is for.
  static const burntIndex = EnemyDef(
    id: 'burnt_index',
    name: 'Burnt Index',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _solarAndTheBurning,
    lore:
        'A tall freestanding case of index cards charred black from one end, '
        'the unburnt half still filed in perfect order and the burnt half '
        'still holding its shape as ash. It knows exactly where everything '
        'was, which is not the same as where anything is.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'ga_findtheentry',
        name: 'Find the Entry',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      // ⚠️ The off-element one. Written as fire on purpose — unlike the
      // Sealed Garden's Cherub, whose blade is light precisely BECAUSE Pyro
      // is Flora's counter (§2e.2). Here Pyro counters neither of this
      // zone's elements, so it is allowed to be what it says it is.
      Spell(
        id: 'ga_catchlight',
        name: 'Catch Light',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects, its
  /// cheap move lands ahead of the whole board, and one thing it throws goes
  /// straight through a wall. 📝 The engine has no creature-applied debuff
  /// yet, so the archetype is written with the levers that actually resolve.
  static const theMarginalia = EnemyDef(
    id: 'the_marginalia',
    name: 'The Marginalia',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _arcane,
    lore:
        'A dense crowd of small annotating hands, each one no larger than a '
        'child\'s, crawling in the blank space at the edges of everything '
        'and writing steadily inward. Whatever they are commenting on, they '
        'have been commenting on it for centuries and they are not finished.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'ga_noteinthemargin',
        name: 'Note in the Margin',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'ga_alreadyanswered',
        name: 'Already Answered',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'ga_writebetweenthelines',
        name: 'Write Between the Lines',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 👑 **The mind boss — *"A mind, and it wrote this down"*** (§2e). The
  /// Tyrant's lesson is that the intelligence is the threat: it is the
  /// highest-rung brain in the game short of the Citadel, and its kit is
  /// cheap-to-dear so there is always something it can afford to do to you.
  static const whatWasWritten = EnemyDef(
    id: 'what_was_written',
    name: 'What Was Written',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _arcane,
    lore:
        'A column of standing script four storeys tall, every line of it in '
        'the same unhurried hand, holding together without a page to be '
        'written on. It reads from the top down and the ground beneath it '
        'is the only part of the hillside with nothing recorded on it.',
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
        id: 'ga_stateitplainly',
        name: 'State It Plainly',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ga_setitdown',
        name: 'Set It Down',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'ga_finishthesentence',
        name: 'Finish the Sentence',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// ✨ **The Aspect — ⭐ Blind taken to an extreme, mechanised** (§2e): it
  /// destroys the reading by being too bright to read by. ⚠️ Single-element
  /// by rule (ENEMIES §2.5), and **Solar** — see the library note on the
  /// §2e / §2.4 disagreement and why the roster wins the element while the
  /// contract wins the stat block (`defl 30 / 25`, EV 7.5%, `acc +8`).
  ///
  /// ⭐ The pair is a mind and its erasure rather than a mirror: killing What
  /// Was Written does not preserve anything, and killing What Is Left Of It
  /// does not restore anything.
  static const whatIsLeftOfIt = EnemyDef(
    id: 'what_is_left_of_it',
    name: 'What Is Left Of It',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _solar,
    lore:
        'Not a body — the hillside at noon with every lens aimed at the same '
        'spot, and the shape standing in that spot is only where the light '
        'has nothing left to go through. Looking at it directly costs you '
        'the rest of the afternoon.',
    // ⚠️ §2.4's row, verbatim: defl 30/25 (EV 7.5%), acc +8.
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      deflectChance: 30,
      deflectAmount: 25,
    ),
    moves: [
      Spell(
        id: 'ga_comeuptonoon',
        name: 'Come Up to Noon',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ga_washthepage',
        name: 'Wash the Page',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'ga_toobrighttoreadby',
        name: 'Too Bright to Read By',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------
  //
  // ⭐ §0.4's join: the contract names drop ROLES, the roster names creatures,
  // and the two meet on the zone. §4.7 gives this zone three common rows —
  // *hide ×2*, *material-A ×2* and one more — and they land by ELEMENT: the
  // hide row pays Arcane motes and goes to the two Arcane commons, the
  // material row pays Solar motes and goes to the two Solar commons. See
  // [glasswright] for the third.

  /// ⭐ The `hide` role, and this zone HAS a hide, so §3.5.1's
  /// second-material fallback does not apply — `palimpsest_vellum` is a real
  /// kill-only material (ITEMS §9b.7b, *"a palimpsest is a hide"*).
  static const _hideCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 15),
      DropEntry('palimpsest_vellum', weight: 64),
      DropEntry('arcane_shard', weight: 5, min: 1, max: 2),
      DropEntry('arcane_dust', weight: 11, min: 2, max: 3),
      DropEntry('sunbleach_tonic', weight: 5),
    ],
  );

  /// ⭐ The `material` role. ⚠️ `pilgrims_ration` rides `bonus` at 2% — every
  /// Celestial zone carries a consumable, exactly as `hardtack` appears on
  /// all six Kinetic zones (§3.3).
  static const _materialCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 12),
      DropEntry('sunbleach_lichen', weight: 74, min: 1, max: 3),
      DropEntry('solar_shard', weight: 5),
      DropEntry('solar_dust', weight: 9, min: 1, max: 2),
    ],
    bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
  );

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.7) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('solar_shard'),
      DropEntry('arcane_shard'),
      DropEntry('solar_dust', min: 1, max: 3),
      DropEntry('arcane_dust', min: 1, max: 3),
      DropEntry('solar_crystal', chance: 0.15),
      DropEntry('arcane_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('palimpsest_vellum', weight: 35, min: 2, max: 4),
      DropEntry('sunbleach_lichen', weight: 30, min: 2, max: 4),
      DropEntry('aetherglass', weight: 30, min: 1, max: 2),
      DropEntry('the_last_reading', weight: 5),
    ],
  );

  /// ⚠️ **No gate part on this table.** The Celestial Totem's three essences
  /// fall in the quarter's three pure zones (§3.4); the Archive defines the
  /// Totem but never drops it, and nothing here may read like the rejected
  /// collect-three-keys Sigil.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('solar_crystal', min: 1, max: 2),
      DropEntry('arcane_crystal', min: 1, max: 2),
      DropEntry('solar_shard', min: 1, max: 2),
      DropEntry('arcane_shard', min: 1, max: 2),
      DropEntry('solar_dust', min: 3, max: 6),
      DropEntry('arcane_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('palimpsest_vellum', weight: 35, min: 4, max: 8),
      DropEntry('sunbleach_lichen', weight: 20, min: 3, max: 6),
      DropEntry('aetherglass', weight: 15, min: 2, max: 4),
      DropEntry('the_last_reading', weight: 20),
      DropEntry('the_noon_hour', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    glasswright,
    noonmark,
    palimpsest,
    readerless,
    lensfly,
  ];

  static const minis = <EnemyDef>[
    theLastReader,
    aperture,
    burntIndex,
    theMarginalia,
  ];

  static const bosses = <EnemyDef>[whatWasWritten, whatIsLeftOfIt];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
