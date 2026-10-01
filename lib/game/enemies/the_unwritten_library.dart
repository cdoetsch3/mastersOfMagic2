/// The Unwritten Library bestiary — Lv 54–58, Umbra + Arcane
/// (ETHEREAL_CONTRACT §4.7, ENEMIES §2e).
///
/// ⭐ **Theme: it is still writing, and it wants you in it.** From the arrival
/// text — *"Every book here is being written right now, by nobody. The shelves
/// go up past where a ceiling would be. Something is taking dictation and it
/// would like your name for the record."* The fusion is **authorship with no
/// author**: Arcane supplies the writing, Umbra supplies the nobody.
///
/// ⭐⭐ **The Author is an ASPECT, not a Tyrant** — ENEMIES §2f's single best
/// archetype change in the pass. §2g gives Tyrant to *"a person, a will,
/// something that decided"*, and this zone's premise is that **there is no
/// author**. An Aspect is the element embodied, and Umbra's Creeping Dark
/// taken to an extreme is *writing done by nobody, in the dark, about you*.
/// ⚠️ Do not "fix" this back into a Tyrant; the name would then contradict
/// the zone out loud.
///
/// ⭐ **Ink-Drinker is one of the three zones the Siphon is kept in** (§2f's
/// literal test: *the zone's premise must be drinking, eating or being fed*).
/// The place feeds on the player; the Siphon is that said once more, smaller.
///
/// 📝 **The third boss, *Your Entry*, is NOT built.** ENEMIES §2e gives this
/// zone a repeat-clear boss gated on
/// `PlayerProfile.hasCleared('the_unwritten_library')`, ❓ with **no
/// archetype and no ruling** — the doc's own recommendation is Tyrant, and
/// ⚠️ explicitly *not* an Aspect, which is now taken by The Author and means
/// something specific here. ⭐ **Nothing in this file or in §4.7's catalogue
/// depends on it**, and the roster laws below are written for the shipped
/// 5 / 4 / 2 template. If it ships it wants a drop of its own.
///
/// ⚠️ **This zone assigns element per creature, not "both" by default**
/// (§2h): the written things are Arcane, the nobody-things are Umbra, and
/// only the two the roster marks `umbra + arcane` carry both. Read the roster
/// table before touching an element list.
///
/// ⚠️ **No off-element move.** §2e.2 names four creatures in fifteen zones
/// and none of them is here, so every creature stays inside `umbra` +
/// `arcane`.
///
/// ⚠️ **No `key` on either boss, and that is correct.** §2e.1 puts `key` on
/// both bosses of a *gate zone*; the three Ethereal fragments fall in
/// Hallowmarch, The Umbral Wastes and The Collapsed Academy (`the_kept_third`
/// / `the_dark_third` / `the_written_third`). The Library gates nothing.
///
/// 📝 **Deferred structure.** 🏰 in ENEMIES §2e and `LocationKind.dungeon` in
/// `world.dart` both stand, but ⚠️ nothing in this file may assume a
/// descending-dungeon run (KINETIC ruling 4, restated by CELESTIAL §0.3).
///
/// ⚠️ **Combat stats (§2.3, via CELESTIAL §2.3's table) copy each archetype's
/// row verbatim**, reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats` — never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`): §2.3 calls it "the
/// yardstick," and a yardstick with a thumb on the scale stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_unwritten_library_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`umbra_*`,
/// `climbers_ration` and `censer_draught` are cross-lane references** owned by
/// parallel Ethereal worktrees (The Umbral Wastes, Hallowmarch and The
/// Reliquary Deep); `arcane_*` is already on main, defined by The Glass
/// Archive (CELESTIAL §3.2).
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_unwritten_library';
const _both = [MagicElement.umbra, MagicElement.arcane];
const _umbra = [MagicElement.umbra];
const _arcane = [MagicElement.arcane];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.7's drop table, the shipped Frostfell shape).
const _commonAlways = [
  DropEntry('umbra_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('arcane_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class UnwrittenLibraryBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and the
  /// only **Adept** in this roster — the yardstick the rest of the Library is
  /// felt against. It is also the one common carrying both elements: the hand
  /// is the writing (Arcane) and the nobody holding it (Umbra) at once.
  static const theDictatingHand = EnemyDef(
    id: 'the_dictating_hand',
    name: 'The Dictating Hand',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A bare forearm and hand at about head height with nothing above the '
        'wrist and nobody behind it, holding a pen and working steadily '
        'across a page that is not there. It does not stop when you arrive; '
        'it simply begins a fresh line.',
    moves: [
      Spell(
        id: 'ul_takeitdown',
        name: 'Take It Down',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The Adept's honest kit: cheap hit, one shield, big hit.
      Spell(
        id: 'ul_ruleamargin',
        name: 'Rule a Margin',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'ul_writeyouin',
        name: 'Write You In',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: _hideCommon,
  );

  /// ⭐ *"A book with nothing written in it is the easiest thing in the room
  /// to destroy and the worst thing to open"* (§2e) — which is the Glasswing
  /// in one sentence. ⚠️ **Glasswing, not Sentinel**: §2f's re-assignment,
  /// and a mutant that restores the Sentinel makes the fragile thing a wall.
  ///
  /// ⚠️ 0.50 HP and 1.70 damage, so **the raws stay small in this column** —
  /// the archetype does the multiplying (§1.4's Glasswing row, the shipped
  /// Breathfrost shape).
  static const blankspine = EnemyDef(
    id: 'blankspine',
    name: 'Blankspine',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _umbra,
    lore:
        'A standing book the height of a child, bound and clasped and '
        'entirely empty, its covers opening a finger\'s width and closing '
        'again at no particular rhythm. Whatever is inside it has never been '
        'written and is waiting to be.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'ul_fallopen',
        name: 'Fall Open',
        chargeCost: 1,
        priority: 7,
        effect: DamageEffect(3, 5),
      ),
      Spell(
        id: 'ul_openonyou',
        name: 'Open On You',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(11, 16),
      ),
    ],
    drops: _materialCommon,
  );

  /// ⭐ *"Damage in pieces — and there are always more of them"* (§2e).
  /// ⚠️ **Both moves multi-hit** (§1.3's per-archetype rule): a Lasher wins by
  /// out-lasting rather than out-hitting, and a footnote arrives one small
  /// mark at a time.
  static const footnote = EnemyDef(
    id: 'footnote',
    name: 'Footnote',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _arcane,
    lore:
        'A low band of small dense script travelling along the floor at '
        'ankle height, wider than a person and never more than a hand deep. '
        'It refers to something further up that you cannot see from here.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'ul_markthepassage',
        name: 'Mark the Passage',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ul_seebelow',
        name: 'See Below',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: _materialCommon,
  );

  /// ⭐ The zone's priority tutor (§2e: *"it corrects you before you have
  /// finished being wrong"*). The Skirmisher's signature is where it sits on
  /// the ladder, not what it does: both moves at 5, ahead of every ordinary
  /// attack and behind every shield.
  static const erratum = EnemyDef(
    id: 'erratum',
    name: 'Erratum',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _arcane,
    lore:
        'A single loose slip of paper about the size of a hand, travelling '
        'upright and at speed, carrying one short line in a tidier script '
        'than anything around it. It arrives before the sentence it is '
        'fixing has finished.',
    combatStats: EnemyCombatStats(accuracyBonus: 5, dodge: 8),
    moves: [
      Spell(
        id: 'ul_strikeitout',
        name: 'Strike It Out',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ul_setitright',
        name: 'Set It Right',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(11, 15),
      ),
    ],
    drops: _colophonCommon,
  );

  /// ⭐⭐ **The Siphon, kept deliberately** (§2f — one of only three zones in
  /// the game): *"the zone's entire premise is that this place feeds on you —
  /// it would like your name for the record."* Every move drinks, because
  /// that is the archetype's whole lesson: chip damage never accumulates, so
  /// the player must commit to burst.
  static const inkDrinker = EnemyDef(
    id: 'ink_drinker',
    name: 'Ink-Drinker',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _umbra,
    lore:
        'A stooped, soft-edged shape about the size of a large dog, moving '
        'along the shelves with its mouth to the spines. The pages behind it '
        'are clean. It is fuller at the end of a row than at the start of '
        'one.',
    // ⚠️ §2.3's Siphon row: it must CONNECT to steal (+6 acc) and SURVIVE to
    // keep stealing (6 dodge), and it carries no crit — a lifesteal crit
    // heals it for the crit too, which is the stalemate §2.2 already fears.
    combatStats: EnemyCombatStats(accuracyBonus: 6, dodge: 6),
    moves: [
      Spell(
        id: 'ul_takeasip',
        name: 'Take a Sip',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8, lifesteal: 0.5),
      ),
      Spell(
        id: 'ul_drinkthepage',
        name: 'Drink the Page',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23, lifesteal: 0.75),
      ),
    ],
    drops: _hideCommon,
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⭐ The Champion as a clean skill check: it looks you up, it shields, and
  /// then it turns to the right page and hits you with it.
  static const theIndex = EnemyDef(
    id: 'the_index',
    name: 'The Index',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _arcane,
    lore:
        'A freestanding wall of small drawered card-cases two people high '
        'and as wide again, every drawer sliding a little way out and back '
        'as it works. It finds what it is looking for faster than anything '
        'that size should.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'ul_lookyouup',
        name: 'Look You Up',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ul_crossreference',
        name: 'Cross-Reference',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ul_turntotheentry',
        name: 'Turn to the Entry',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Redoubt as attrition — a colophon is the mark that says *ends
  /// here*, and nothing in this Library ends.
  ///
  /// 📝 **§2.3's zone-local deviation was NOT applied.** The contract
  /// recommends dropping the Redoubt's deflect to 25/24 (EV 6.0%) in
  /// dungeons, but names exactly two creatures — *Bedrock Colossus* and
  /// *Reliquary Colossus* — and this is neither. The row is copied verbatim
  /// (35/30, EV 10.5%); ⚠️ if the probe widens the deviation to every
  /// Empyrean dungeon, this is the line it moves.
  static const colophon = EnemyDef(
    id: 'colophon',
    name: 'Colophon',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _arcane,
    lore:
        'A squat block of dark polished stone the height of a person, one '
        'face cut with a single deep mark and the rest left rough. It has '
        'been set down at the end of a row the way a full stop is set down, '
        'and the row has continued past it regardless.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'ul_pressthemark',
        name: 'Press the Mark',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'ul_closethebook',
        name: 'Close the Book',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'ul_setthelastpage',
        name: 'Set the Last Page',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **Cost cap lowered from 5 to 4** (§1.3): at L58 a mini five-charge
  /// raw lands against a bar it would simply delete, and there is no reading
  /// of *"kills you in three turns if you misplay one"* that survives a
  /// one-shot. Bring a shield.
  static const redaction = EnemyDef(
    id: 'redaction',
    name: 'Redaction',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _umbra,
    lore:
        'A long hard-edged bar of absolute black, about as tall as a person '
        'and no thicker than a finger, that crosses the space between you in '
        'one movement. What it has been over is not damaged. It is simply no '
        'longer there.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'ul_strikethrough',
        name: 'Strike Through',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'ul_blackitout',
        name: 'Black It Out',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects,
  /// and its cheap move lands ahead of everything on the board. 📝 The engine
  /// has no creature-applied debuff yet, so the archetype is written with the
  /// levers that actually resolve — first to act, and through a wall.
  static const theAmanuensis = EnemyDef(
    id: 'the_amanuensis',
    name: 'The Amanuensis',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _both,
    lore:
        'A seated, stooped figure in plain clerk\'s dress, taller than a '
        'person would be standing, writing without pause and without looking '
        'down. It has been taking this down since before you came in and it '
        'is already ahead of you.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'ul_takedictation',
        name: 'Take Dictation',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'ul_writeitfirst',
        name: 'Write It First',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'ul_alreadyonthepage',
        name: 'Already on the Page',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 📚 **The mass boss — what is written.** ⭐ *"And it is not finished, and
  /// it is not short"* (§2e). The Juggernaut pays for its size by being
  /// predictable, which is the right shape for a record: you can always see
  /// the next volume coming.
  static const theRecord = EnemyDef(
    id: 'the_record',
    name: 'The Record',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _arcane,
    lore:
        'A run of bound volumes standing shoulder to shoulder across the '
        'whole width of the hall and up past where a ceiling would be, each '
        'one the size of a door. The run is longer every time you look along '
        'it, and it is longer at the end you have already passed.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'ul_setitdown',
        name: 'Set It Down',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'ul_boundinfull',
        name: 'Bound in Full',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'ul_itisnotshort',
        name: 'It Is Not Short',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 🖋️ **The Aspect — Umbra taken to an extreme, and there is nobody there.**
  /// ⚠️ **Single-element by rule** (ENEMIES §2.5): Creeping Dark, carried to
  /// its end, is *writing done by nobody, in the dark, about you* — and that
  /// is the whole creature.
  ///
  /// ⚠️⚠️ **The stat block is §2.4's UMBRA row, verbatim** — crit 15 / +70,
  /// defl 20 / 18 (EV 3.6%). Two documents disagree about whether this zone
  /// has an Aspect at all: §2.4 says *"The Unwritten Library field[s] no
  /// Aspect, per ENEMIES §2g"*, while ENEMIES §2f's later pass makes The
  /// Author exactly that (*"the single best archetype change in this pass"*).
  /// ⭐ The roster wins the creature fact — §0.1 and §0.3 both defer creature
  /// names, archetypes and boss pools to it — and the contract still wins the
  /// numbers, so the block is taken from the one Umbra Aspect §2.4 prices.
  /// ⭐ Its reasoning is about the ELEMENT, not the zone: *"Umbra's lean is
  /// crit damage, and Creeping Dark is growth toward one enormous
  /// consequence."* ⚠️ +70 crit damage is the largest number on any stat
  /// block in the game — a crit deals 220% — and it is deliberately paired
  /// with a *low* 15% chance: it does not happen often, and when it does it
  /// was decided. 📝 The Umbral Wastes' own Aspect carries the same row; if
  /// two of them is one too many, this is the copy to move.
  static const theAuthor = EnemyDef(
    id: 'the_author',
    name: 'The Author',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _umbra,
    lore:
        'Not a body — the dark between two shelves, as tall as the shelves '
        'go, with the writing happening inside it at a rate you can hear. '
        'Nothing holds the pen and nothing needs to. It is the only thing '
        'here that knows your name, and it learned it a moment ago.',
    combatStats: EnemyCombatStats(
      critChance: 15,
      critDamage:
          60, // ⭐ +60, not §2.4's +70: the Umbral Wastes' Aspect keeps the game's largest crit-damage number (build manager, 2026-09-22),
      deflectChance: 20,
      deflectAmount: 18,
    ),
    moves: [
      Spell(
        id: 'ul_nobodywritesit',
        name: 'Nobody Writes It',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ul_anotherlineaboutyou',
        name: 'Another Line About You',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'ul_finishtheentry',
        name: 'Finish the Entry',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------
  //
  // ⚠️⚠️ **How §4.7's three common rows were joined to §2e's roster, and it
  // needed a ruling.** The contract's rows are `hide common ×2`,
  // `material-A common ×2` and `the Siphon`; the roster's five commons carry
  // `hide` twice (The Dictating Hand, Ink-Drinker), `material` once
  // (Blankspine) and nothing else twice (Footnote, Erratum). The two shapes
  // do not line up, so one of them bends.
  //
  // ⭐ **The roster won, because the contract says it should** — §0.1 and
  // §0.3 both defer creature facts to the roster lane, and a drop ROLE is a
  // creature fact (§2e.1 defines the five words). So both `hide` creatures
  // take the hide row, the `material` creature takes the material row, and
  // the two role-less commons take the remaining slots.
  //
  // ⚠️ **The consequence: the row labelled *"the Siphon"* does not land on
  // the Siphon.** That label is a draft artefact and demonstrably stale — the
  // same row appears in The Glass Archive and The Reliquary Deep, neither of
  // which has a Siphon at all after §2f, and the Archive lane already
  // resolved it by fit rather than by label. ⚠️ Honouring the label here
  // would have cost Ink-Drinker its `hide` and paid it a *gatherable*
  // material instead, which breaks the role's own definition ("a kill-only
  // material — it exists only because something died"). 📝 The reverse
  // reading is one line: swap `_colophonCommon` and `_hideCommon` between
  // Erratum and Ink-Drinker.

  /// The `hide` role: §4.7's first common row, verbatim. ⭐ It lands on the
  /// two commons §2e marks `mote · hide` — and it reads: what an ink-drinker
  /// leaves behind is a page with nothing on it.
  static const _hideCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 15),
      DropEntry('blankspine_vellum', weight: 64),
      DropEntry('arcane_shard', weight: 5, min: 1, max: 2),
      DropEntry('arcane_dust', weight: 11, min: 2, max: 3),
      DropEntry('nightink_draught', weight: 5),
    ],
  );

  /// The `material` role: §4.7's second common row, verbatim, bonus included.
  static const _materialCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 12),
      DropEntry('nightink', weight: 74, min: 1, max: 3),
      DropEntry('umbra_shard', weight: 5),
      DropEntry('umbra_dust', weight: 9, min: 1, max: 2),
    ],
    bonus: [DropEntry('climbers_ration', chance: 0.02)],
  );

  /// §4.7's third common row, verbatim — the zone's Jewelry material and the
  /// quarter's previous Draught. ⚠️ The only common row that pays no motes of
  /// its own.
  static const _colophonCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 20),
      DropEntry('colophon_stone', weight: 65),
      DropEntry('censer_draught', weight: 15),
    ],
  );

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.7) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('umbra_shard'),
      DropEntry('arcane_shard'),
      DropEntry('umbra_dust', min: 1, max: 3),
      DropEntry('arcane_dust', min: 1, max: 3),
      DropEntry('umbra_crystal', chance: 0.15),
      DropEntry('arcane_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('blankspine_vellum', weight: 35, min: 2, max: 4),
      DropEntry('nightink', weight: 30, min: 2, max: 4),
      DropEntry('colophon_stone', weight: 30, min: 1, max: 2),
      DropEntry('colophon_signet', weight: 5),
    ],
  );

  /// ⚠️ **No gate part on this table.** The Library is not a gate zone
  /// (§2e.1): the three Ethereal fragments fall in Hallowmarch, The Umbral
  /// Wastes and The Collapsed Academy, and nothing here may read like the
  /// rejected collect-three-keys Sigil.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('umbra_crystal', min: 1, max: 2),
      DropEntry('arcane_crystal', min: 1, max: 2),
      DropEntry('umbra_shard', min: 1, max: 2),
      DropEntry('arcane_shard', min: 1, max: 2),
      DropEntry('umbra_dust', min: 3, max: 6),
      DropEntry('arcane_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('blankspine_vellum', weight: 35, min: 4, max: 8),
      DropEntry('nightink', weight: 20, min: 3, max: 6),
      DropEntry('colophon_stone', weight: 15, min: 2, max: 4),
      DropEntry('colophon_signet', weight: 20),
      DropEntry('the_open_colophon', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    theDictatingHand,
    blankspine,
    footnote,
    erratum,
    inkDrinker,
  ];

  static const minis = <EnemyDef>[theIndex, colophon, redaction, theAmanuensis];

  static const bosses = <EnemyDef>[theRecord, theAuthor];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
