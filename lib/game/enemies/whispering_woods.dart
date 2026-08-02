/// The Whispering Woods bestiary — Lv 1–5, Flora (ENEMIES_DESIGN §2d).
///
/// ⭐ **Theme: the wood is one creature, and you are standing on it.** Nothing
/// here is an animal that happens to live in a forest; everything is an
/// extension of one organism, which is why it notices you. Every creature
/// below should read as *part of the wood*, never as wildlife.
///
/// ⚠️ **Drops are referenced by STRING id, not by the item objects.** Dart
/// forbids field access in a const expression, so `WhisperingWoodsItems.oakLog.id`
/// cannot appear here. `test/whispering_woods_test.dart` resolves every id
/// against [ItemCatalogue] instead — a typo fails the suite, not the player.
///
/// ⚠️ **Move names are held to the strict Primal standard** (§3.3): this is
/// first impressions, and a player who decides in the first hour that this is
/// a Pokémon clone will not revise that opinion. Nothing here would look at
/// home in a Pokédex; everything would look at home in a field notebook.
library;

import 'package:mom_engine/mom_engine.dart';

import 'drop_table.dart';
import 'enemy_archetype.dart';
import 'enemy_def.dart';

const _zone = 'whispering_woods';
const _flora = [MagicElement.flora];

/// Motes and bulk fall from everything; the main table is what varies.
const _commonAlways = [DropEntry('flora_dust', chance: 0.75, min: 1, max: 2)];

abstract final class WhisperingWoodsBestiary {
  // ---- commons --------------------------------------------------------

  /// ⭐ The level-1 teaching enemy, and it pays off the zone's arrival text
  /// directly — *"it stops the moment you stand still to listen"*.
  static const listeningFawn = EnemyDef(
    id: 'listening_fawn',
    name: 'Listening Fawn',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.drudge,
    elements: _flora,
    lore:
        'It does not flee and it does not approach. Twice I have looked up to '
        'find it closer without having seen it move, and both times it was '
        'facing the ground rather than me.',
    moves: [
      Spell(
        id: 'ww_startle',
        name: 'Startle',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(4, 7),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 40),
        DropEntry('fawnhide', weight: 45),
        DropEntry('foragers_ration', weight: 15),
      ],
    ),
  );

  static const thornbackSprite = EnemyDef(
    id: 'thornback_sprite',
    name: 'Thornback Sprite',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.skirmisher,
    elements: _flora,
    lore:
        'Small, and gone before the swing finishes. The thorns are not for '
        'defence — it plants them, and comes back for them later.',
    moves: [
      // ⭐ Priority 5 is the Skirmisher's whole lesson: it acts before you.
      Spell(
        id: 'ww_prick',
        name: 'Prick',
        chargeCost: 1,
        priority: 5,
        effect: DamageEffect(5, 8),
      ),
      Spell(
        id: 'ww_nettle',
        name: 'Nettle',
        chargeCost: 2,
        priority: 5,
        effect: DamageEffect(9, 13),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 35),
        DropEntry('bindweed_fibre', weight: 50, min: 1, max: 2),
        DropEntry('flora_shard', weight: 15),
      ],
    ),
  );

  /// ⭐ A Flora Blighter wins by *out-lasting* — repeated Flora casts feed
  /// Photosynthesis, so it heals itself while barely hurting you.
  static const sporecapShambler = EnemyDef(
    id: 'sporecap_shambler',
    name: 'Sporecap Shambler',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.blighter,
    elements: _flora,
    lore:
        'The cap is the animal and the body is scaffolding. Cut the body and '
        'the cap simply builds another, more slowly and slightly wrong.',
    moves: [
      Spell(
        id: 'ww_puffburst',
        name: 'Puffburst',
        chargeCost: 1,
        priority: 8,
        effect: DamageEffect(3, 5, hits: 2),
      ),
      Spell(
        id: 'ww_settle',
        name: 'Settle',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('bindweed_fibre', weight: 40),
        DropEntry('flora_shard', weight: 25, min: 1, max: 2),
        DropEntry('sapwort_draught', weight: 5),
      ],
    ),
  );

  /// ⭐ The first lesson that chip damage does not always accumulate.
  static const bindweedCreeper = EnemyDef(
    id: 'bindweed_creeper',
    name: 'Bindweed Creeper',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.siphon,
    elements: _flora,
    lore:
        'It drinks. Everything in this wood that stands still long enough is '
        'eventually part of the same drink, and it is patient about it.',
    moves: [
      Spell(
        id: 'ww_bind',
        name: 'Bind',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(5, 8, lifesteal: 0.5),
      ),
      Spell(
        id: 'ww_throttle',
        name: 'Throttle',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(13, 17, lifesteal: 0.5),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 30),
        DropEntry('bindweed_fibre', weight: 50, min: 2, max: 3),
        DropEntry('flora_shard', weight: 20),
      ],
      bonus: [DropEntry('bindweed_belt', chance: 0.01)],
    ),
  );

  static const rootknuckle = EnemyDef(
    id: 'rootknuckle',
    name: 'Rootknuckle',
    zoneId: _zone,
    rank: EnemyRank.common,
    archetype: Archetypes.bruiser,
    elements: _flora,
    lore:
        'A knot of root that comes up through the path where the path is '
        'thinnest. It is not hunting. You are simply standing on it.',
    moves: [
      Spell(
        id: 'ww_knuckle',
        name: 'Knuckle',
        chargeCost: 2,
        priority: 9,
        effect: DamageEffect(11, 15),
      ),
      // ⭐ Expensive and slow on purpose — the Bruiser must charge, and the
      // charge bar is the tell. That telegraph is what it pays for its stats.
      Spell(
        id: 'ww_upheave',
        name: 'Upheave',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(30, 38),
      ),
    ],
    drops: DropTable(
      always: _commonAlways,
      main: [
        DropEntry.nothing(weight: 25),
        DropEntry('oak_log', weight: 55, min: 1, max: 3),
        DropEntry('flora_shard', weight: 20),
      ],
      bonus: [DropEntry('oak_circlet', chance: 0.02)],
    ),
  );

  // ---- mini-bosses ----------------------------------------------------
  // ⭐ One of each archetype, so the two drawn per run are always a different
  // pair of tactical roles (ENEMIES §2g).

  static const elderroot = EnemyDef(
    id: 'elderroot',
    name: 'Elderroot',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.champion,
    elements: _flora,
    lore:
        'Older than the path, and the path was surveyed twice. It has been '
        'doing this longer than anything else here and it shows.',
    moves: [
      Spell(
        id: 'ww_grasp',
        name: 'Grasp',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(12, 16),
      ),
      Spell(
        id: 'ww_sunder',
        name: 'Sunder',
        chargeCost: 4,
        priority: 9,
        effect: DamageEffect(26, 33),
      ),
      Spell(
        id: 'ww_barkover',
        name: 'Bark Over',
        chargeCost: 2,
        priority: 3,
        effect: ShieldEffect(18, 24),
      ),
    ],
    drops: _miniDrops,
  );

  static const motherSpore = EnemyDef(
    id: 'mother_spore',
    name: 'Mother Spore',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.redoubt,
    elements: _flora,
    lore:
        'Every shambler in the wood is hers, and she does not appear to care '
        'about any of them individually.',
    moves: [
      Spell(
        id: 'ww_choke',
        name: 'Choke',
        chargeCost: 2,
        priority: 8,
        effect: DamageEffect(4, 6, hits: 3),
      ),
      Spell(
        id: 'ww_encyst',
        name: 'Encyst',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(30, 38),
      ),
      Spell(
        id: 'ww_flourish',
        name: 'Flourish',
        chargeCost: 4,
        priority: 4,
        effect: DamageEffect(9, 12, lifesteal: 1),
      ),
    ],
    drops: _miniDrops,
  );

  static const hollowStag = EnemyDef(
    id: 'hollow_stag',
    name: 'Hollow Stag',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.executioner,
    elements: _flora,
    lore:
        'What is left of a Listening Fawn that listened for long enough. It '
        'is still facing the ground.',
    moves: [
      Spell(
        id: 'ww_gore',
        name: 'Gore',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(26, 32),
      ),
      Spell(
        id: 'ww_runthrough',
        name: 'Run Through',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(48, 58),
      ),
    ],
    drops: _miniDrops,
  );

  static const theMurmur = EnemyDef(
    id: 'the_murmur',
    name: 'The Murmur',
    zoneId: _zone,
    rank: EnemyRank.mini,
    archetype: Archetypes.hexer,
    elements: _flora,
    lore:
        'The sound the whole wood makes, standing in one place for once. It '
        'knows the shape of what you were about to do.',
    moves: [
      Spell(
        id: 'ww_undertone',
        name: 'Undertone',
        chargeCost: 1,
        priority: 4,
        effect: DamageEffect(6, 9),
      ),
      Spell(
        id: 'ww_sayyourname',
        name: 'Say Your Name',
        chargeCost: 3,
        priority: 2,
        effect: DamageEffect(14, 18, ignoresShields: true),
      ),
      Spell(
        id: 'ww_closein',
        name: 'Close In',
        chargeCost: 2,
        priority: 1,
        effect: HasteEffect(),
      ),
    ],
    drops: _miniDrops,
  );

  // ---- bosses ---------------------------------------------------------

  /// ⭐ The tree the root network runs from — enormous, slow, unavoidable.
  static const heartwood = EnemyDef(
    id: 'heartwood',
    name: 'Heartwood',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.juggernaut,
    elements: _flora,
    lore:
        'Everything under the path runs back to here. Standing at its base, '
        'the murmur is not a sound any more; it is a pressure.',
    moves: [
      Spell(
        id: 'ww_heave',
        name: 'Heave',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(44, 54),
      ),
      Spell(
        id: 'ww_rootwall',
        name: 'Rootwall',
        chargeCost: 3,
        priority: 2,
        effect: ShieldEffect(40, 52),
      ),
      Spell(
        id: 'ww_deepen',
        name: 'Deepen',
        chargeCost: 4,
        priority: 5,
        effect: DamageEffect(16, 20, lifesteal: 1),
      ),
    ],
    drops: _bossDrops,
  );

  /// ⭐ Flora embodied, taken to an extreme the player has not seen: it never
  /// stops healing. ⚠️ Deliberately unsettling — the quarter's first "this
  /// world is not safe" beat.
  static const theStandingGreen = EnemyDef(
    id: 'the_standing_green',
    name: 'The Standing Green',
    zoneId: _zone,
    rank: EnemyRank.boss,
    archetype: Archetypes.aspect,
    elements: _flora,
    lore:
        'The wood grew this in the shape of a person, and got the proportions '
        'nearly right. It is the "nearly" that stays with you.',
    moves: [
      Spell(
        id: 'ww_reach',
        name: 'Reach',
        chargeCost: 2,
        priority: 7,
        effect: DamageEffect(14, 19, lifesteal: 0.75),
      ),
      Spell(
        id: 'ww_standcloser',
        name: 'Stand Closer',
        chargeCost: 4,
        priority: 6,
        effect: DamageEffect(30, 37, lifesteal: 0.5),
      ),
      Spell(
        id: 'ww_greenover',
        name: 'Green Over',
        chargeCost: 3,
        priority: 3,
        effect: DamageEffect(12, 16, lifesteal: 1),
      ),
    ],
    drops: _bossDrops,
  );

  // ---- shared tables --------------------------------------------------

  /// ⚠️ Crystal appears here and nowhere below — the mote ladder's first real
  /// step is a mini-boss reward (ITEMS §8).
  static const _miniDrops = DropTable(
    always: [
      DropEntry('flora_shard', min: 1, max: 3),
      DropEntry('flora_crystal', chance: 0.25),
    ],
    main: [
      DropEntry('oak_log', weight: 40, min: 2, max: 4),
      DropEntry('bindweed_fibre', weight: 30, min: 2, max: 4),
      DropEntry('sapwort_draught', weight: 25),
      DropEntry('sporecap_mantle', weight: 5),
    ],
  );

  static const _bossDrops = DropTable(
    always: [
      DropEntry('flora_crystal', min: 1, max: 2),
      DropEntry('flora_shard', min: 3, max: 6),
      // ⭐ The gate item. One of Aldermere's "three ordinary proofs".
      DropEntry('proof_of_the_woods'),
    ],
    main: [
      DropEntry('oak_log', weight: 45, min: 4, max: 8),
      DropEntry('bindweed_belt', weight: 25),
      DropEntry('sporecap_mantle', weight: 20),
      DropEntry('heartwood_stave', weight: 10),
    ],
  );

  static const commons = <EnemyDef>[
    listeningFawn,
    thornbackSprite,
    sporecapShambler,
    bindweedCreeper,
    rootknuckle,
  ];

  static const minis = <EnemyDef>[
    elderroot,
    motherSpore,
    hollowStag,
    theMurmur,
  ];

  static const bosses = <EnemyDef>[heartwood, theStandingGreen];

  static const all = <EnemyDef>[...commons, ...minis, ...bosses];

  /// Every item the zone can yield, for the Collector achievement.
  static Set<String> get allDrops => {
    for (final e in all) ...e.drops.possibleDrops,
  };
}
