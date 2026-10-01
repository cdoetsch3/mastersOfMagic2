/// The Kiln Desert bestiary — Lv 30–34, Solar (CELESTIAL_CONTRACT §4.1).
///
/// ⭐ **Theme: burning and freezing at once.** From the arrival text — *"the
/// air is too thin to hold heat, so the sun burns while the wind bites…
/// Your shadow is the hardest-edged thing you have ever seen."* The zone is a
/// **contradiction**, not a heat, and every creature here is written to be two
/// things that should not be true together.
///
/// ⭐ **A pure zone** (ENEMIES §2e; CELESTIAL_CONTRACT §2.4) — one of the
/// quarter's three, so every creature is single-element Solar and the whole
/// roster pays in one mote ladder. ⚠️ No off-element move: §2e.2 names four
/// creatures in fifteen zones and none of them is here.
///
/// ⭐⭐ **Solar's passive IS the zone's status tutor, and it costs no new
/// effect.** The engine applies Blind on any landed Solar attack at 10% per
/// charge spent (`duel.dart`, `ElementTuning.blindPercentPerCharge`), so a
/// creature blinds harder the more it charged. That is why the Sunstruck
/// Pilgrim's kit is cheap and constant and the Solar Deity's dear move is
/// cost 4: the same mechanic, read at two volumes.
///
/// ⭐ **The boss pair is the contradiction at full size** (ENEMIES §2e's
/// roster note): The Cold Shadow is what the sun cannot reach — a **mass**,
/// so a Juggernaut, because §2g gives Tyrant to *"a person, a will, something
/// that decided"* and nothing decided this. The Solar Deity is the sun
/// itself. ⚠️ Not a mirror and not the same creature twice; do not "fix" the
/// Juggernaut into a Tyrant to make the pair symmetrical.
///
/// ⚠️ **The Aspect must be single-element** (ENEMIES §2.5) and its stat block
/// is copied verbatim from CELESTIAL_CONTRACT §2.4: `acc +25, crit 10/+10` —
/// *"an Aspect of the sun does not miss and takes your sight while it does
/// not."*
///
/// ⚠️ **Combat stats (§2.2/§2.3) copy each archetype's row verbatim**,
/// reaching the duel through `EnemyDef.combatStats` /
/// `OpponentDriver.opponentCombatStats`, never through gear. The Adept is
/// deliberately left blank (`EnemyCombatStats.none`, the field's own default):
/// §2.3 calls it "the yardstick," and a yardstick with a thumb on the scale
/// stops being one.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects** — Dart
/// forbids field access in a const expression. `test/the_kiln_desert_test.dart`
/// resolves every id against [ItemCatalogue] instead.
///
/// ⭐ **The `hide` role has no hide item here and resolves to `glasswort`** —
/// the zone's SECOND gatherable material (ETHEREAL_CONTRACT §3.5.1, adopted
/// for both quarters): *"everywhere else 'something died' pays in the zone's
/// stuff."* The Kiln Desert defines no cloth and no hide on purpose — §4.1,
/// *"there is no cloth in the Kiln Desert because nothing here is soft."*
///
/// ⚠️ **Both bosses carry the gate part on `always`, never weighted**
/// (ENEMIES §2e.1). A run draws one boss of two; a `solar_essence` that only
/// fell from the boss you did not draw would make a mandatory progression
/// item a coin flip.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_combat_stats.dart';
import 'enemy_def.dart';

const _zone = 'the_kiln_desert';
const _solar = [MagicElement.solar];

/// ⭐ A pure zone pays one mote ladder at the full 0.75, the shipped shape
/// (CELESTIAL_CONTRACT §4.1's `_commonAlways`). A hybrid would pay two at
/// half each; this zone has only one element to pay in.
const _commonAlways = [DropEntry('solar_dust', chance: 0.75, min: 1, max: 2)];

abstract final class KilnDesertBestiary {
  // ---- commons ----------------------------------------------------------

  /// ⭐ **The yardstick**, and the only honest thing in a zone built on
  /// contradiction: a figure the sun has taken the shadow from, fighting you
  /// perfectly straight. ⚠️ Adept → `EnemyCombatStats.none`, deliberately.
  static const shadeless = EnemyDef(
    id: 'shadeless',
    name: 'Shadeless',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.adept,
    elements: _solar,
    lore:
        'A person-shaped figure walking the flat with nothing on the ground '
        'beneath it, at a pace that neither hurries nor slows. Whatever took '
        'its shadow took nothing else, and it has kept walking since.',
    moves: [
      Spell(
        id: 'kd_closethegap',
        name: 'Close the Gap',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8),
      ),
      // ⭐ The Adept's honest kit: cheap hit, big hit, one shield. Nothing
      // clever, which is the point of a yardstick.
      Spell(
        id: 'kd_setthestance',
        name: 'Set the Stance',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(16, 22),
      ),
      Spell(
        id: 'kd_strikestraight',
        name: 'Strike Straight',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 17),
        DropEntry('glasswort', weight: 69),
        DropEntry('solar_shard', weight: 5),
        DropEntry('solar_dust', weight: 9, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ **The zone's anchor name** (`World.opponentNameFor`), and ⭐⭐ its
  /// status tutor: Solar's passive is Blind and this creature is named for
  /// sun-blindness. It barely damages you and you lose anyway.
  ///
  /// ⚠️ **Blighter, re-banded from Drudge** (ENEMIES §2e, 2026-09-22) — so
  /// this is also the creature that inherits the contract's "the Drudge" drop
  /// row, `pilgrims_ration` and all. Both its moves are multi-hit, the §1.3
  /// per-archetype rule: a Blighter wins by out-lasting, not out-hitting.
  static const sunstruckPilgrim = EnemyDef(
    id: 'sunstruck_pilgrim',
    name: 'Sunstruck Pilgrim',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _solar,
    lore:
        'Wrapped to the eyes and still burnt through the cloth, walking a '
        'line it fixed on days ago and has not been able to see since. It '
        'reaches for you the way someone reaches for a wall in the dark.',
    combatStats: EnemyCombatStats(accuracyBonus: 8),
    moves: [
      Spell(
        id: 'kd_reachout',
        name: 'Reach Out',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'kd_keepwalking',
        name: 'Keep Walking',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 20),
        DropEntry('glasswort', weight: 65),
        DropEntry('pilgrims_ration', weight: 15),
      ],
    ),
  );

  /// ⭐ The zone's `material` common, and therefore the one that pays in
  /// **ironwood** — the headline material, the mirror of the `hide` ruling
  /// that sends the other three commons to the second one. Bruiser: reading
  /// the charge bar, and a slab that crosses the pan without stopping is
  /// the most telegraphed thing in the desert.
  static const glasspanCrawler = EnemyDef(
    id: 'glasspan_crawler',
    name: 'Glasspan Crawler',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _solar,
    lore:
        'A low slab of salt fused to green glass by something that happened '
        'here once, crossing the pan at a walking pace and never turning '
        'aside for anything, including the road.',
    combatStats: EnemyCombatStats(
      accuracyBonus: -8,
      critChance: 8,
      critDamage: 25,
    ),
    moves: [
      Spell(
        id: 'kd_grindacross',
        name: 'Grind Across',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ Expensive and slow on purpose (§2.5, tempo lean = cost band) —
      // the Bruiser must charge, and the charge bar is the whole tell.
      Spell(
        id: 'kd_crossthepan',
        name: 'Cross the Pan',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 40),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 12),
        DropEntry('ironwood_log', weight: 74, min: 1, max: 3),
        DropEntry('solar_shard', weight: 5),
        DropEntry('solar_dust', weight: 9, min: 1, max: 2),
      ],
      bonus: [DropEntry('pilgrims_ration', chance: 0.02)],
    ),
  );

  /// ⭐ Killing fast beats playing safe — it is barely there and it hits like
  /// the noon. ⚠️ The only common with no material role at all (ENEMIES
  /// §2e's roster: `mote` alone), so its table is the mote ladder and the
  /// empty slot, nothing else. A mirage does not leave anything behind.
  ///
  /// ⚠️ **The 2026-09-30 lean left this table alone, on purpose** (Christian,
  /// same day): the lean exists to favour craftables, and a table with none
  /// has nothing to lean into. It is the one common `main` still at its
  /// authored 45/15/40. ⚠️ And "nothing behind" is no longer literal: an
  /// empty roll is consoled with one Solar Dust (`consolationOf` — no
  /// craftable in `main`, so the first `always` entry).
  static const mirage = EnemyDef(
    id: 'mirage',
    name: 'Mirage',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.glasswing,
    elements: _solar,
    lore:
        'A stretch of standing water half a mile off that is still half a '
        'mile off when you reach where it was. Close up there is a shape in '
        'it, and the shape is the part that does not move away.',
    combatStats: EnemyCombatStats(critChance: 20, critDamage: 30),
    moves: [
      Spell(
        id: 'kd_waver',
        name: 'Waver',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'kd_bewhereitisnot',
        name: 'Be Where It Is Not',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(18, 23),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 45),
        DropEntry('solar_shard', weight: 15),
        DropEntry('solar_dust', weight: 40, min: 1, max: 2),
      ],
    ),
  );

  /// ⭐ Why a big shield is not always the answer: every move is multi-hit,
  /// so a wall chips rather than holds (§1.3's Lasher rule).
  static const kilnMoth = EnemyDef(
    id: 'kiln_moth',
    name: 'Kiln Moth',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.lasher,
    elements: _solar,
    lore:
        'Wings the colour of ash paper, thin enough to read light through '
        'and scorched along every edge already. It does not circle what '
        'burns it; it goes straight in, over and over, and does not stop.',
    combatStats: EnemyCombatStats(critChance: 15, critDamage: -20),
    moves: [
      Spell(
        id: 'kd_beatpast',
        name: 'Beat Past',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'kd_gobackin',
        name: 'Go Back In',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 4),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 17),
        DropEntry('glasswort', weight: 69),
        DropEntry('solar_shard', weight: 5),
        DropEntry('solar_dust', weight: 9, min: 1, max: 2),
      ],
    ),
  );

  // ---- mini-bosses --------------------------------------------------------
  // ⭐ One of each mini archetype, so the two drawn per run are always a
  // different pair of tactical roles (GAME_DESIGN §3d).

  /// ⭐ Champion — simply good at everything: a cheap opener, a wall, and a
  /// finisher it can actually afford.
  static const sunTemplar = EnemyDef(
    id: 'sun_templar',
    name: 'Sun Templar',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _solar,
    lore:
        'Plate polished to a finish that has not dulled in whatever time it '
        'has stood out here, worn over nothing at all. It keeps the sun at '
        'its back, and it does that on every side of the field.',
    combatStats: EnemyCombatStats(accuracyBonus: 6, critChance: 10),
    moves: [
      Spell(
        id: 'kd_raisethestandard',
        name: 'Raise the Standard',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'kd_closeranks',
        name: 'Close Ranks',
        chargeCost: 3,
        priority: 3,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'kd_bringthenoon',
        name: 'Bring the Noon',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ Redoubt — attrition, and the one lifesteal move §1.3 allows the
  /// archetype. A prism gives back a part of everything it is handed.
  static const prismSentinel = EnemyDef(
    id: 'prism_sentinel',
    name: 'Prism Sentinel',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _solar,
    lore:
        'A standing wedge of clear sand-glass twice a person\'s height, every '
        'face true and none of them the same angle. What arrives at it comes '
        'apart and leaves in several directions at once.',
    combatStats: EnemyCombatStats(deflectChance: 35, deflectAmount: 30),
    moves: [
      Spell(
        id: 'kd_splitthelight',
        name: 'Split the Light',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 17),
      ),
      // ⭐ Priority 2 — the wall goes up before the player's own shield does.
      Spell(
        id: 'kd_turneveryface',
        name: 'Turn Every Face',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 40),
      ),
      Spell(
        id: 'kd_takethelightback',
        name: 'Take the Light Back',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⚠️ **The Executioner's cost cap stays at 4** (CELESTIAL_CONTRACT §1.3,
  /// inherited from KINETIC §1.3). At cost 5 the mini raw would land
  /// 884–1153 at L47 against a 607 HP bar — a one-shot with change. At 4 it
  /// lands the ratio the archetype is supposed to have.
  static const saltmarchWraith = EnemyDef(
    id: 'saltmarch_wraith',
    name: 'Saltmarch Wraith',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _solar,
    lore:
        'A column of salt dust holding the shape of a column of people, '
        'moving along the old crossing at the pace of the slowest of them. '
        'It arrives all at once and never where the front of it was.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 8,
      critChance: 12,
      critDamage: 40,
    ),
    moves: [
      Spell(
        id: 'kd_closethemarch',
        name: 'Close the March',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(25, 33),
      ),
      Spell(
        id: 'kd_finishthecrossing',
        name: 'Finish the Crossing',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 34),
      ),
    ],
    drops: _miniDrops,
  );

  /// ⭐ The Hexer's signature is priority, not status: it always connects and
  /// its middle move lands ahead of everything on the board.
  /// 📝 The engine has no creature-applied debuff yet, so the archetype is
  /// written with the levers that actually resolve.
  static const theShadelessHour = EnemyDef(
    id: 'the_shadeless_hour',
    name: 'The Shadeless Hour',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _solar,
    lore:
        'The part of the day when nothing on the flat casts anything, walking '
        'about as a tall thin absence with the light going through it wrong. '
        'It is over quickly, and it takes something with it when it goes.',
    combatStats: EnemyCombatStats(accuracyBonus: 8, dodge: 10),
    moves: [
      Spell(
        id: 'kd_takeyourshadow',
        name: 'Take Your Shadow',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      // ⭐ Priority 1 — before shields, before quick attacks, before anything.
      Spell(
        id: 'kd_arriveatnoon',
        name: 'Arrive at Noon',
        chargeCost: 2,
        priority: 1,
        effect: DamageEffect(12, 17),
      ),
      Spell(
        id: 'kd_leavenothingstanding',
        name: 'Leave Nothing Standing',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(25, 33, ignoresShields: true),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses -------------------------------------------------------------

  /// 🌑 **The mass boss — what the sun cannot reach.** ⭐ A shadow out here is
  /// a *mass*, not a mind: ENEMIES §2g gives Tyrant to *"a person, a will,
  /// something that decided"*, and nothing decided this. Hence Juggernaut,
  /// re-banded from Tyrant in the 2026-09-22 pass. It pays for its size by
  /// being predictable.
  static const theColdShadow = EnemyDef(
    id: 'the_cold_shadow',
    name: 'The Cold Shadow',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _solar,
    lore:
        'The whole of the cold this place should have, gathered into one '
        'shape the size of a rock shelf and lying where no rock shelf is. '
        'Nothing that walks into it comes out the far side warm.',
    combatStats: EnemyCombatStats(deflectChance: 25, deflectAmount: 35),
    moves: [
      Spell(
        id: 'kd_falloveryou',
        name: 'Fall Over You',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(24, 31),
      ),
      Spell(
        id: 'kd_deepen',
        name: 'Deepen',
        chargeCost: 4,
        priority: 2,
        effect: ShieldEffect(44, 56),
      ),
      Spell(
        id: 'kd_taketheheatwithit',
        name: 'Take the Heat With It',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(42, 54),
      ),
    ],
    drops: _bossDrops,
  );

  /// ☀️ **The Aspect — the sun, and Blind taken further than the player has
  /// seen it.** ⚠️ Single-element by rule (ENEMIES §2.5), and its stat block
  /// is CELESTIAL_CONTRACT §2.4's row verbatim: `acc +25, crit 10/+10`.
  /// ⭐ The cost-4 finisher is the design: the engine's Blind roll is 10% per
  /// charge spent, so its dear move carries a 40% chance of taking your sight
  /// on top of the damage. The archetype's whole lesson — one element, taken
  /// to an extreme — is in the charge cost rather than in a new effect.
  static const solarDeity = EnemyDef(
    id: 'solar_deity',
    name: 'Solar Deity',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _solar,
    lore:
        'Not a figure with light on it but the light itself, standing up off '
        'the pan at about the height of a person and holding that height. '
        'Looking directly at it is the last clear thing you do for a while.',
    combatStats: EnemyCombatStats(
      accuracyBonus: 25,
      critChance: 10,
      critDamage: 10,
    ),
    moves: [
      Spell(
        id: 'kd_comeup',
        name: 'Come Up',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'kd_burnthrough',
        name: 'Burn Through',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(13, 19),
      ),
      Spell(
        id: 'kd_takeyoursight',
        name: 'Take Your Sight',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ `solar_crystal` appears here and on [_bossDrops] and nowhere else
  /// (CELESTIAL_CONTRACT §4.1) — the mote ladder's first real step is a fight
  /// the player chose.
  static const _miniDrops = DropTable(
    always: [
      DropEntry('solar_shard'),
      DropEntry('solar_dust', min: 1, max: 3),
      DropEntry('solar_crystal', chance: 0.15),
    ],
    main: [
      DropEntry('ironwood_log', weight: 40, min: 2, max: 4),
      DropEntry('glasswort', weight: 30, min: 2, max: 4),
      DropEntry('pilgrims_ration', weight: 25),
      DropEntry('the_shadeless_band', weight: 5),
    ],
  );

  /// ⚠️ **`solar_essence` is on the `always` line, not the weighted one**
  /// (CELESTIAL_CONTRACT §4.1, ENEMIES §2e.1). A tier gate that needs a 10%
  /// roll three times is a grind, not a gate — and because a run draws one
  /// boss of two, **both** bosses share this table.
  static const _bossDrops = DropTable(
    always: [
      DropEntry('solar_essence'),
      DropEntry('solar_crystal', min: 1, max: 2),
      DropEntry('solar_shard', min: 1, max: 2),
      DropEntry('solar_dust', min: 3, max: 6),
    ],
    main: [
      DropEntry('ironwood_log', weight: 45, min: 4, max: 8),
      DropEntry('glasswort', weight: 25, min: 3, max: 6),
      DropEntry('the_shadeless_band', weight: 20),
      DropEntry('the_hardest_edge', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    shadeless,
    sunstruckPilgrim,
    glasspanCrawler,
    mirage,
    kilnMoth,
  ];

  static const minis = <EnemyDef>[
    sunTemplar,
    prismSentinel,
    saltmarchWraith,
    theShadelessHour,
  ];

  static const bosses = <EnemyDef>[theColdShadow, solarDeity];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
