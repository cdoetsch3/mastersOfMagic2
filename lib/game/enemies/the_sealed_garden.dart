/// The Sealed Garden bestiary — Lv 49–53, Flora + Sanctus
/// (ETHEREAL_CONTRACT §4.4, ENEMIES §2e).
///
/// ⭐ **Theme: the garden is still perfect, it is still guarded, and you are
/// still not allowed in.** ⚠️ **The turn that makes it more than a costume:
/// the religion that set the guard is gone.** Nobody has come to relieve the
/// watch in an age and the watch has not noticed — ⚠️ **the guardians are not
/// defending a faith, they are keeping a promise that outlived everyone who
/// cared about it.** Every lore line below is written to that, not to
/// "overgrown temple".
///
/// ⭐⭐ **The game's FIRST element guarded by its LAST** (`world.dart`): Flora
/// is where the player started at level 1 and Sanctus is where they are now.
/// ⚠️ That is also why the drop tables reach all the way back to
/// `whispering_woods_items.dart` for `flora_*` — see [_commonAlways].
///
/// ⚠️ **Guardrails, carried forward from WORLD_DESIGN §4c.1a and binding on
/// this file:** use the **roles** — Gardener, Guardian, Serpent, Vow — and
/// never name a real religious figure or quote a text. 🚫 **"Bloom" is
/// reserved** (renamed to Photosynthesis project-wide); no creature and no
/// move here may use the word. ⚠️ **The Sanctus naming trap:** a Sanctus name
/// that could plausibly be Solar is the wrong name, which is why the gates,
/// the orchard, the vow and the wardens below carry no sun imagery.
///
/// ⭐ **This zone assigns element per creature** (§2h) — Sanctus is the rule,
/// Flora is the garden doing the asking, and the three creatures that are
/// both are the ones where consecration and orchard stopped being separable.
/// Read the roster table before touching an element list.
///
/// ⚠️⚠️ **The Cherub of the Turning Blade carries the zone's one off-element
/// move, and it is SOLAR — never pyro** (§2e.2). Pyro is **Flora's own
/// counter**, and §2h's one non-tunable row is that a creature must never
/// carry the thing which beats the player's correct counter-pick. The flaming
/// sword is therefore written as *light*. 📝 The engine has no per-move
/// element — a cast takes the element the caster CHARGED — so an off-element
/// move can only be expressed as an extra entry in `elements`, exactly as the
/// Glass Archive's Burnt Index does it (`lib/game/enemies/the_glass_archive.dart`).
///
/// ⚠️⚠️ **The Cherub's dear move is cost 4, not the roster sketch's 5.**
/// ENEMIES §2e's kit table writes *"Come Down Once (5 …)"*, but
/// ETHEREAL_CONTRACT §1.3 carries the standing ⚠️ *"The Executioner's cost cap
/// stays at 4"* with the arithmetic attached: at L53 a mini five-charge raw
/// (46–60) lands **672–876** against a 769 HP bar, which is a one-shot rather
/// than the two-cast kill the archetype exists for; at cost 4 it lands
/// 380–497. ⭐ The contract owns the damage table (§0.1 defers creature facts
/// to the roster and keeps the numbers for itself), and all six shipped
/// Celestial Executioners are already 3/4. The zone test pins the 4.
///
/// ⚠️ **NOT a gate zone, and the boss table must stay that way.**
/// §4.4's drop block still lists `the_kept_third` on `always`; §3.5's
/// reconciliation then moved that fragment to **Hallowmarch** (the gate parts
/// fall in the quarter's three PURE zones — Hallowmarch, The Umbral Wastes,
/// The Collapsed Academy). The reconciliation is the later ruling and it
/// wins; nothing here drops a Third.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_sealed_garden_test.dart`
/// resolves every id against [ItemCatalogue] instead. ⚠️ **`sanctus_*` and
/// `climbers_ration` are cross-lane references** owned by the parallel
/// Hallowmarch worktree; they resolve once the merge coordinator lands the
/// lanes together.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_sealed_garden';
const _flora = [MagicElement.flora];
const _sanctus = [MagicElement.sanctus];
const _both = [MagicElement.flora, MagicElement.sanctus];

/// ⚠️ The zone's **one** off-element creature (§2e.2), and the element on it
/// is the whole point: Flora is countered by **Pyro** and Sanctus by
/// **Umbra**, so a burning sword would be the one thing §2h forbids. Solar is
/// neither counter, and a sword of light is the same image anyway.
const _sanctusAndTheLight = [MagicElement.sanctus, MagicElement.solar];

/// ⚠️ A hybrid pays in **two** mote currencies at half chance each, so the
/// total handed over stays comparable to a pure zone's single 0.75 roll
/// (§4.4's drop table, the shipped Frostfell shape).
///
/// ⭐⭐ **`flora_*` resolves to `whispering_woods_items.dart` — the level 1–5
/// catalogue.** ⚠️ A builder will assume that is a mistake. §7.3 says
/// otherwise in bold: it is the quarter's deepest cross-quarter mote
/// reference, and it is the drop table saying out loud what the zone is for.
/// `sanctus_*` is Hallowmarch's.
const _commonAlways = [
  DropEntry('flora_dust', chance: 0.5, min: 1, max: 2),
  DropEntry('sanctus_dust', chance: 0.5, min: 1, max: 2),
];

abstract final class SealedGardenBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ The zone's anchor name, kept from `World.opponentNameFor`, and ⭐ one
  /// of the seven Sentinels §2b keeps — *rooted and set to guard* is the
  /// archetype's own definition, and this is the creature it was written for.
  ///
  /// ⚠️ Pure Sanctus. It is not part of the orchard; it was **posted** to it.
  static const orchardWarden = EnemyDef(
    id: 'orchard_warden',
    name: 'Orchard Warden',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.sentinel,
    elements: _sanctus,
    lore:
        'Set at the foot of one tree to watch it, and has watched it long '
        'enough that the bark has grown around where it stands. It does not '
        'patrol and it does not follow. It steps in front of the tree.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 20),
    moves: [
      Spell(
        id: 'sg_closetherow',
        name: 'Close the Row',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ The Sentinel's whole argument: it is easier to break than to
      // out-wait, which is what makes Barrage feel good two zones later.
      Spell(
        id: 'sg_keepthewatch',
        name: 'Keep the Watch',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(28, 36),
      ),
    ],
    drops: _materialCommon,
  );

  /// ⭐⭐ **One of the three zones §2f keeps the Siphon in** — *the temptation,
  /// written as a stat block.* ⚠️ **Both of its moves heal it**, which is the
  /// lesson: chip damage never accumulates here, so commit to burst.
  ///
  /// ⚠️ It is the serpent's argument in a common's body, a whole zone before
  /// the serpent makes it — fruit already on the ground, already yours, no
  /// gate involved.
  static const windfall = EnemyDef(
    id: 'windfall',
    name: 'Windfall',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _flora,
    lore:
        'Fruit already on the ground, perfect, unbruised, and warmer than '
        'fruit on the ground has any business being. Nothing has taken a '
        'piece out of it and nothing has walked on it.',
    // ⚠️ §2.3's Siphon row: it must CONNECT to steal, so accuracy, and it
    // must SURVIVE to keep stealing, so a little dodge. ⚠️ No crit — a
    // lifesteal crit heals it for the crit too.
    combatStats: EnemyCombatStats(accuracyBonus: 6, dodge: 6),
    moves: [
      Spell(
        id: 'sg_drawup',
        name: 'Draw Up',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8, lifesteal: 0.5),
      ),
      Spell(
        id: 'sg_takethewholehand',
        name: 'Take the Whole Hand',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23, lifesteal: 0.6),
      ),
    ],
    drops: _siphonCommon,
  );

  /// ⭐ The Blighter, and the zone's tutorial in *what statuses actually do* —
  /// it barely touches you and you lose anyway.
  ///
  /// ⚠️ **Both moves land the same `dotId` at two price points**, so the
  /// second replaces the first rather than stacking with it (`bank_dots.dart`
  /// law 5). That is the archetype's shape, not a saving: a Suggestion is one
  /// idea getting louder, never two ideas at once.
  static const whisperling = EnemyDef(
    id: 'whisperling',
    name: 'Whisperling',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _flora,
    lore:
        'A small coiled thing high in the branches that talks, pleasantly, '
        'and offers you something you had not thought to want. It waits for '
        'an answer and it is content to keep waiting.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'sg_suggestit',
        name: 'Suggest It',
        chargeCost: 1,
        priority: 9,
        effect: DotAttackEffect(
          2,
          4,
          dotId: 'sg_suggestion',
          dotName: 'Suggestion',
          damagePerTick: 4,
          ticks: 3,
        ),
      ),
      Spell(
        id: 'sg_keeptalking',
        name: 'Keep Talking',
        chargeCost: 2,
        priority: 9,
        effect: DotAttackEffect(
          4,
          6,
          dotId: 'sg_suggestion',
          dotName: 'Suggestion',
          damagePerTick: 5,
          ticks: 5,
        ),
      ),
    ],
    drops: _hideCommon,
  );

  /// ⭐ The yardstick — and ⭐ **the one creature in the garden doing its job
  /// correctly.** It carries no [EnemyCombatStats] on purpose: §2.3 calls the
  /// Adept row the yardstick, and a yardstick with a thumb on the scale stops
  /// being one.
  ///
  /// ⚠️ Both elements, because the office and the vine are the same act here:
  /// it is singing the hours *and* it is a plant, and neither half explains
  /// the other away.
  static const choristerVine = EnemyDef(
    id: 'chorister_vine',
    name: 'Chorister Vine',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _both,
    lore:
        'A vine still singing the hours to an empty cloister, on time, in a '
        'form of the office nobody has used in an age. It finishes the hour '
        'it is on before it turns to look at you.',
    moves: [
      // ⭐ The Adept's honest kit: cheap hit, one shield, big hit.
      Spell(
        id: 'sg_takeupthehour',
        name: 'Take Up the Hour',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'sg_closetheoffice',
        name: 'Close the Office',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'sg_singitthrough',
        name: 'Sing It Through',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: _materialCommon,
  );

  /// ⭐ The zone's charge-bar tutor — completely telegraphed, and the dear
  /// move is the whole fight. ⚠️ Both elements: the briar is Flora and the
  /// posture is Sanctus, and the creature is the sentence where they meet.
  ///
  /// ⭐ It is also where `thornpenitent_hide` comes from, which is why the
  /// material is kill-only and has no node (§3.1).
  static const thornpenitent = EnemyDef(
    id: 'thornpenitent',
    name: 'Thornpenitent',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _both,
    lore:
        'A briar that grew through and around someone kneeling, and kept the '
        'posture after there stopped being a reason for it. It rises out of '
        'the kneel to swing and it goes back down afterwards.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'sg_kneelintoit',
        name: 'Kneel Into It',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      Spell(
        id: 'sg_bearthewholepenance',
        name: 'Bear the Whole Penance',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: _hideCommon,
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  /// ⭐ **The only mortal still inside, and not hostile until you reach for
  /// anything.** A clean skill check, which is what a Champion is for.
  /// 📝 The "not hostile until" beat lives in the encounter text, not in this
  /// file — nothing in `EnemyDef` can express a conditional aggro yet, and
  /// inventing a field for one creature would be worse than the note.
  static const theLastGardener = EnemyDef(
    id: 'the_last_gardener',
    name: 'The Last Gardener',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _both,
    lore:
        'The only mortal still inside, in working clothes gone the colour of '
        'the beds, carrying tools that have been maintained. It watches you '
        'walk the path and says nothing until you reach for something.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      // ⭐ Priority 5, the quick rung: pruning is done before anything else
      // gets a say, and it is the cheapest move in the mini pool.
      Spell(
        id: 'sg_prune',
        name: 'Prune',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'sg_putitback',
        name: 'Put It Back',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'sg_turnthebedover',
        name: 'Turn the Bed Over',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ Attrition — the oldest stock in the orchard, and every other tree here
  /// is a runner off it. ⚠️ Pure Flora: nobody consecrated the matriarch, she
  /// was simply here first and the consecration was built around her.
  ///
  /// 📝 §2.3's recommended deflect drop (35 → 25) applies to the Redoubts in
  /// **The Buried Sky and The Reliquary Deep** — 2.20 bodies inside dungeons
  /// a player cannot retreat from. The Sealed Garden is a route, so the row
  /// stands here unmodified.
  static const rootMatriarch = EnemyDef(
    id: 'root_matriarch',
    name: 'Root Matriarch',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _flora,
    lore:
        'The oldest stock in the orchard, and every other tree in here is a '
        'runner off it. What is above ground is the smaller half of it, and '
        'the ground for a long way around belongs to the other half.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'sg_putdownarunner',
        name: 'Put Down a Runner',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'sg_thicken',
        name: 'Thicken',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      // ⭐ The attrition clause: it does not out-damage you, it out-lasts you,
      // and the lifesteal is why the stalemate clock matters (§2.2).
      Spell(
        id: 'sg_drawfromthewholeorchard',
        name: 'Draw From the Whole Orchard',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, lifesteal: 0.4),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️⚠️ **The zone's one off-element creature** (§2e.2) — and the element is
  /// **solar, never pyro**: see the library note. *The flaming sword that
  /// turns every way*, and it has never stopped turning.
  ///
  /// ⚠️ **Cost 4, not the sketch's 5** — §1.3's standing Executioner cap, with
  /// the arithmetic in the library note above.
  static const cherubOfTheTurningBlade = EnemyDef(
    id: 'cherub_of_the_turning_blade',
    name: 'Cherub of the Turning Blade',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _sanctusAndTheLight,
    lore:
        'A blade at the gate turning end over end on nothing, fast enough to '
        'read as a disc and slow enough to count. Whatever is holding it is '
        'the same colour as the air. It has never once stopped turning.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      // ⭐ "Turns every way" is the myth's own phrase, and two hits is the
      // only honest way to say it — §1.3 has no mini cost-3 multi row, so the
      // pair sums into the cost-3 single band (25–33) instead of inventing one.
      Spell(
        id: 'sg_turneveryway',
        name: 'Turn Every Way',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(13, 16, hits: 2),
      ),
      // ⚠️ The off-element one. Written as LIGHT, never fire — Pyro is
      // Flora's counter and §2h's one non-tunable row forbids it.
      Spell(
        id: 'sg_comedownonce',
        name: 'Come Down Once',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ *"It punishes a bad loadout, not bad reflexes."* The Hexer's signature
  /// is priority, not status: it always connects, two of its three moves land
  /// ahead of the whole board, and the dear one goes straight through a wall.
  /// 📝 The engine has no creature-applied debuff yet, so the archetype is
  /// written with the levers that actually resolve.
  ///
  /// ⚠️ Pure Sanctus. An oath with a body is the rule with nothing growing on
  /// it.
  static const theKeptVow = EnemyDef(
    id: 'the_kept_vow',
    name: 'The Kept Vow',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _sanctus,
    lore:
        'An oath with a body. Nobody remembers the wording and it has not '
        'needed to be reminded, and the shape it holds is roughly the shape '
        'of the person who gave it.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'sg_holdyoutoit',
        name: 'Hold You To It',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'sg_sayitback',
        name: 'Say It Back',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'sg_thevowdoesnotlapse',
        name: 'The Vow Does Not Lapse',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------
  //
  // ⭐ **Which boss you draw decides whether the garden confronts you or
  // tempts you** — the Ashfall Vale pattern landing at the opposite end of the
  // game. ⭐ And the elements carry it: Sanctus is the rule, Flora is the
  // garden doing the asking.

  /// 👑 ⭐ **The rule. It will not let you in. Not angry, not negotiating.**
  /// Endurance — a wall does not need a plan, which is the Juggernaut's whole
  /// lesson, and [youAreNotAllowedIn] is the theme written as a move.
  static const guardianOfTheWorldTree = EnemyDef(
    id: 'guardian_of_the_world_tree',
    name: 'Guardian of the World Tree',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _sanctus,
    lore:
        'It stands in the gateway with the tree behind it and it does not '
        'move aside for anything. There is no anger anywhere in it and there '
        'is nothing to say to it. It was left here and it stayed.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'sg_bartheway',
        name: 'Bar the Way',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'sg_rootthegate',
        name: 'Root the Gate',
        chargeCost: 4,
        priority: 3,
        effect: ShieldEffect(44, 56),
      ),

      /// ⭐ The theme, as a move.
      Spell(
        id: 'sg_youarenotallowedin',
        name: 'You Are Not Allowed In',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// 👑 ⭐ **The invitation. It would very much like to let you in.** ⭐ The
  /// intelligence is the threat (§2g): *the rule is a wall you must get
  /// through; the tempter's threat is that it plays well.* The Tyrant's brain
  /// is the second-highest in the game and its kit runs cheap-to-dear, so
  /// there is always something it can afford to do to you.
  ///
  /// ⭐⭐ **The tempter takes your charge, not your health** — [DischargeEffect]
  /// is the mechanical form of *"you were saving that for something."* ⚠️ It
  /// is the first creature move in the game to use it; the engine resolves
  /// enemy and player casts through the same path, and `Spell.isHarmful`
  /// already accounts for Discharge.
  static const theSerpentInTheBranches = EnemyDef(
    id: 'the_serpent_in_the_branches',
    name: 'The Serpent in the Branches',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.tyrant,
    elements: _flora,
    lore:
        'It is already in the canopy over the path when you notice it, and '
        'it has been letting you notice it for a while. Nothing about the '
        'way it addresses you is a threat, and it does not repeat itself.',
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
        id: 'sg_leancloser',
        name: 'Lean Closer',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 8 is the aux-offense rung — where Discharge itself sits in
      // the player's own book, so the creature is playing by the same ladder.
      Spell(
        id: 'sg_namewhatyouwant',
        name: 'Name What You Want',
        chargeCost: 2,
        priority: 8,
        effect: DischargeEffect(),
      ),
      // ⭐ The band's top, and the only thing it ever actually says.
      Spell(
        id: 'sg_sayyes',
        name: 'Say Yes',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------
  //
  // ⭐ §0.4's join: the contract names drop ROLES, the roster names creatures,
  // and the two meet on the zone. §4.4 gives this zone three common rows —
  // *hide ×2*, *material-A ×2* and *the Siphon* — and for once the join is
  // exact: the roster's two `hide` commons are Whisperling and Thornpenitent,
  // its two `material` commons are the Orchard Warden and the Chorister Vine,
  // and the zone really does field a Siphon for the third row.

  /// ⭐ The `hide` role, and this zone HAS a hide, so §3.5.1's
  /// second-material fallback does not apply — `thornpenitent_hide` is a real
  /// kill-only material (§3.1), off something that was let in and did not
  /// leave.
  ///
  /// ⚠️ This row pays the **Flora** ladder: the hide comes off the briar.
  static const _hideCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 30),
      DropEntry('thornpenitent_hide', weight: 40),
      DropEntry('flora_shard', weight: 8, min: 1, max: 2),
      DropEntry('flora_dust', weight: 17, min: 2, max: 3),
      DropEntry('climbers_ration', weight: 5),
    ],
  );

  /// ⭐ The `material` role, and it pays the **Sanctus** ladder — the two
  /// creatures on it are the posted guard and the office still being sung.
  /// ⚠️ `climbers_ration` rides `bonus` at 2%: every Ethereal zone carries the
  /// quarter's Ration, exactly as `hardtack` appears on all six Kinetic zones
  /// (§3.3).
  static const _materialCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 25),
      DropEntry('worldroot', weight: 55, min: 1, max: 3),
      DropEntry('sanctus_shard', weight: 7),
      DropEntry('sanctus_dust', weight: 13, min: 1, max: 2),
    ],
    bonus: [DropEntry('climbers_ration', chance: 0.02)],
  );

  /// ⭐ §4.4's third common row, labelled *"the Siphon"* in the contract and
  /// landing on the creature that actually is one. ⚠️ It is the only common
  /// row that can pay the zone's **Tonic**, which reads: the thing that heals
  /// itself off you is the thing that leaves a bottle of healing behind.
  static const _siphonCommon = DropTable(
    always: _commonAlways,
    main: [
      DropEntry.nothing(weight: 40),
      DropEntry('orchard_amber', weight: 45),
      DropEntry('worldroot_tonic', weight: 15),
    ],
  );

  /// ⭐ A hybrid mini pays BOTH mote ladders (§4.4) — Crystal from either
  /// family, the mote ladder's first real step, is still a mini-boss reward.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('flora_shard'),
      DropEntry('sanctus_shard'),
      DropEntry('flora_dust', min: 2, max: 4),
      DropEntry('sanctus_dust', min: 2, max: 4),
      DropEntry('flora_crystal', chance: 0.25),
      DropEntry('sanctus_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('thornpenitent_hide', weight: 35, min: 2, max: 4),
      DropEntry('worldroot', weight: 30, min: 2, max: 4),
      DropEntry('orchard_amber', weight: 30, min: 1, max: 2),
      DropEntry('the_gardeners_loop', weight: 5),
    ],
  );

  /// ⚠️⚠️ **No gate part on this table, and §4.4's own drop block is out of
  /// date about it.** That block still lists `the_kept_third` on `always`;
  /// §3.5's reconciliation moved the fragment to **Hallowmarch** so the three
  /// Thirds fall in the quarter's three PURE zones, which is how every other
  /// tier gate in the game is derived (§2e.1). The later ruling wins.
  ///
  /// ⭐ Both uniques hang here rather than one per boss: a run draws one boss
  /// of two, and splitting the pair would make which epic exists a coin flip.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('flora_crystal', min: 1, max: 2),
      DropEntry('sanctus_crystal', min: 1, max: 2),
      DropEntry('flora_shard', min: 1, max: 2),
      DropEntry('sanctus_shard', min: 1, max: 2),
      DropEntry('flora_dust', min: 4, max: 8),
      DropEntry('sanctus_dust', min: 4, max: 8),
    ],
    main: [
      DropEntry('thornpenitent_hide', weight: 35, min: 4, max: 8),
      DropEntry('worldroot', weight: 20, min: 3, max: 6),
      DropEntry('orchard_amber', weight: 15, min: 2, max: 4),
      DropEntry('the_gardeners_loop', weight: 20),
      DropEntry('the_season_at_once', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    orchardWarden,
    windfall,
    whisperling,
    choristerVine,
    thornpenitent,
  ];

  static const minis = <EnemyDef>[
    theLastGardener,
    rootMatriarch,
    cherubOfTheTurningBlade,
    theKeptVow,
  ];

  static const bosses = <EnemyDef>[
    guardianOfTheWorldTree,
    theSerpentInTheBranches,
  ];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
