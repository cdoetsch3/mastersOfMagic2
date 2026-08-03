import 'dart:ui' show Color;

import 'package:mom_engine/mom_engine.dart';

import 'loadout.dart';
import 'mage_apparel.dart';

/// A named AI opponent with a level, look, spell kit, and tactical skill.
/// Personas fill two roles: a practice roster, and matchmaking stand-ins
/// when no human opponent is found.
///
/// ⚠️ **The roster is NOT the intelligence scale.** Intelligence 1–10
/// (GAME_DESIGN §6b) is a property every enemy carries — wild monsters,
/// mini-bosses, bosses and these personas alike. This list is just the handful
/// of *named, fightable* opponents; there is no one-persona-per-rating
/// mapping, and adding a persona does not mean adding a rating.
class AiPersona {
  final String id;
  final String name;
  final String title;
  final int level;
  final MageApparel apparel;
  final Loadout loadout;

  /// **Intelligence 1–10** — how *well* this opponent plays, on the capability
  /// ladder in GAME_DESIGN §6b. 1 flicks forever · 3 is random · 5 is
  /// counter-aware · 7 predicts · 9 is genuinely sharp · 10 is optimal.
  ///
  /// Deliberately separate from [aggression] and [caution], which describe how
  /// an opponent *prefers* to play. Skill and personality are different axes:
  /// a cautious level-9 and a reckless level-9 are both hard, differently.
  final int intelligence;

  /// Personality dials (see TunableAi) — orthogonal to [intelligence].
  final double aggression;
  final double caution;

  const AiPersona({
    required this.id,
    required this.name,
    required this.title,
    required this.level,
    required this.intelligence,
    required this.apparel,
    required this.loadout,
    required this.aggression,
    required this.caution,
  });

  /// Blunder rate implied by [intelligence]. Retained for personas that still
  /// want a fumbling brain rather than a laddered one.
  double get mistakeChance => blunderChanceForIntelligence(intelligence);

  /// ⭐ **The brain is [LadderAi], built from [intelligence] alone.**
  ///
  /// Skill is a *separate entity* from the character: the persona supplies the
  /// body (level, loadout, look) and the rating supplies the mind, and the two
  /// compose. The same loadout at intelligence 3 and at 9 is two genuinely
  /// different opponents, and the same rating can be dropped on any monster
  /// without borrowing anything else from a persona.
  /// ⚠️ **Elements matter as much as spells here.** In this game the element
  /// of a cast comes from what the mage *charged*, not from the spell — so a
  /// brain given every element charges at random and a Flora creature's own
  /// move lands as Astral. That shipped: a Listening Fawn cast Astral and
  /// Aqua, and a Thornback Sprite cast Aero and Sanctus.
  DuelAi buildBrain() => LadderAi(
    intelligence,
    spells: loadout.spells,
    elements: loadout.elements,
  );
}

/// Chance an enemy of the given [intelligence] throws away its turn.
///
/// Delegates to the engine's table so there is exactly one curve — the AI and
/// the design docs cannot drift apart. See `LadderAi` for the competence ladder
/// this sits on top of.
double blunderChanceForIntelligence(int intelligence) =>
    blunderRateForIntelligence(intelligence);

/// The Phase-1 roster, weakest to strongest.
abstract final class AiRoster {
  // Loadouts scale with level in BOTH kit and size. Elements and spells share
  // one slot pool (PROGRESSION_DESIGN §1), and each persona fills exactly the
  // pool a *player* of its level would have — 5 slots at L1 up to 15 at L50 —
  // so an opponent is never carrying more than the person fighting it.
  //
  // Every kit is also legal for its level (Kinetic L15, Celestial L30, Ethereal
  // L45), so no opponent wields magic the player could not yet face.

  // 5 slots — exactly a level-1 player's pool, so the tutorial dummy is not
  // quietly better equipped than the person fighting it.
  static final Loadout _novice = Loadout(
    elements: const [MagicElement.pyro, MagicElement.aqua],
    spells: [Spellbook.flick, Spellbook.bolt, Spellbook.ward],
  );

  static final Loadout _skirmisher = Loadout(
    elements: const [
      MagicElement.pyro,
      MagicElement.aero,
      MagicElement.electro,
    ],
    spells: [
      Spellbook.flick,
      Spellbook.bolt,
      Spellbook.blast,
      Spellbook.jolt,
      Spellbook.ward,
      Spellbook.aegis,
    ],
  );

  static final Loadout _warden = Loadout(
    elements: const [
      MagicElement.geo,
      MagicElement.flora,
      MagicElement.aqua,
      MagicElement.aero,
    ],
    spells: [
      Spellbook.bolt,
      Spellbook.blast,
      Spellbook.surge,
      Spellbook.aegis,
      Spellbook.bulwark,
      Spellbook.barrier,
      Spellbook.hallow,
    ],
  );

  // Celestial — the first roster kit to use Solar/Lunar/Astral at all, so the
  // three newest elements are something a player actually faces.
  static final Loadout _duelist = Loadout(
    elements: const [
      MagicElement.solar,
      MagicElement.lunar,
      MagicElement.astral,
      MagicElement.electro, // not Ethereal — that tier is still locked at 40
    ],
    spells: [
      Spellbook.flick,
      Spellbook.blast,
      Spellbook.surge,
      Spellbook.jolt,
      Spellbook.bulwark,
      Spellbook.rampart,
      Spellbook.empower,
      Spellbook.discharge,
      Spellbook.volley,
    ],
  );

  // Al'Dorian — Ethereal, and a full level-50 pool: 15 slots, split 5/10.
  static final Loadout _lastWarden = Loadout(
    elements: const [
      MagicElement.sanctus,
      MagicElement.umbra,
      MagicElement.arcane,
      MagicElement.solar,
      MagicElement.aqua,
    ],
    spells: [
      Spellbook.bolt,
      Spellbook.surge,
      Spellbook.ruin,
      Spellbook.leech,
      Spellbook.bulwark,
      Spellbook.sanctuary,
      Spellbook.barrier,
      Spellbook.hallow,
      Spellbook.empower,
      Spellbook.quicken,
    ],
  );

  // Procarius — every tier represented, and the whole toolbox.
  static final Loadout _archmage = Loadout(
    elements: const [
      MagicElement.arcane,
      MagicElement.umbra,
      MagicElement.lunar,
      MagicElement.electro,
      MagicElement.pyro,
    ],
    spells: [
      Spellbook.jolt,
      Spellbook.blast,
      Spellbook.ruin,
      Spellbook.cataclysm,
      Spellbook.barrage,
      Spellbook.drain,
      Spellbook.sanctuary,
      Spellbook.barrier,
      Spellbook.overload,
      Spellbook.discharge,
    ],
  );

  /// Weakest to strongest. ✅ **Levels spread evenly from 1 to 50** — the
  /// player cap — with Procarius alone above it at 60, matching the Eclipsed
  /// Citadel's enemy band (GAME_DESIGN §5).
  ///
  /// ✅ Each persona's loadout is **legal for its level**: Kinetic elements
  /// only from L15, Celestial from L30, Ethereal from L45. And loadout *size*
  /// scales too — a level-50 opponent fills the whole 15-slot pool, because a
  /// player at 50 can. All of this is enforced by `test/ai_roster_test.dart`.
  static final List<AiPersona> all = [
    AiPersona(
      id: 'wick',
      name: 'Wick',
      title: 'Candle Apprentice',
      level: 1,
      intelligence: 1, // flicks and hopes — the tutorial dummy
      apparel: MageApparel.apprenticeBlue,
      loadout: _novice,
      aggression: 0.5,
      caution: 0.15,
    ),
    AiPersona(
      id: 'brightgale',
      name: 'Brightgale',
      title: 'Storm Skirmisher',
      level: 15,
      intelligence: 3, // unpredictable, but wastes charge freely
      apparel: MageApparel(
        hat: const Color(0xFF9BB8C4),
        hatTrim: const Color(0xFFE8C547),
        robe: const Color(0xFF5F7C8A),
        robeTrim: const Color(0xFFE8C547),
        gloves: const Color(0xFF3A2E37),
        boots: const Color(0xFF2C2230),
      ),
      loadout: _skirmisher,
      aggression: 0.55,
      caution: 0.25,
    ),
    AiPersona(
      id: 'thornwall',
      name: 'Thornwall',
      title: 'Warden of the Quarry',
      level: 28,
      intelligence: 5, // reads your shield and picks its counter
      apparel: MageApparel(
        hat: const Color(0xFF6B7F3E),
        hatTrim: const Color(0xFFB0851E),
        robe: const Color(0xFF55663A),
        robeTrim: const Color(0xFFB0851E),
        gloves: const Color(0xFF5C4632),
        boots: const Color(0xFF3A2E20),
      ),
      loadout: _warden,
      aggression: 0.2,
      caution: 0.7, // the defensive one — same skill, different temperament
    ),
    AiPersona(
      id: 'morwen',
      name: 'Morwen',
      title: 'Duelist of the Deep',
      level: 40,
      intelligence: 7, // starts predicting what you are charging toward
      apparel: MageApparel.duskWitch,
      loadout: _duelist,
      aggression: 0.45,
      caution: 0.45,
    ),
    AiPersona(
      id: 'aldorian',
      name: "Al'Dorian",
      title: 'Warden of the Last Gate',
      level: 50, // the player cap — the last mortal opponent
      intelligence: 9,
      apparel: MageApparel(
        hat: const Color(0xFFF2E7C9),
        hatTrim: const Color(0xFFD9B44A),
        robe: const Color(0xFFE4DAC0),
        robeTrim: const Color(0xFFD9B44A),
        gloves: const Color(0xFF6E6A7A),
        boots: const Color(0xFF4A4270),
      ),
      loadout: _lastWarden,
      aggression: 0.4,
      caution: 0.5,
    ),
    AiPersona(
      id: 'procarius',
      name: 'Procarius',
      title: 'The Eclipsed',
      level: 60, // above the cap, in the Citadel's own band
      intelligence: 10,
      apparel: MageApparel(
        hat: const Color(0xFF2C2230),
        hatTrim: const Color(0xFF8B5CD6),
        robe: const Color(0xFF3A2E37),
        robeTrim: const Color(0xFF8B5CD6),
        gloves: const Color(0xFF1E1836),
        boots: const Color(0xFF141021),
      ),
      loadout: _archmage,
      aggression: 0.4,
      caution: 0.55,
    ),
  ];

  static AiPersona byId(String id) => all.firstWhere((p) => p.id == id);

  /// A themed campaign foe: a roster persona's kit re-skinned with the location
  /// monster's name and dropped to [level].
  ///
  /// Borrows from [strongestAtOrBelow] rather than [nearestToLevel]. Because
  /// this overrides the level, the *nearest* persona can be a stronger one —
  /// which used to hand a level-9 foe Brightgale's Aero, magic the player
  /// cannot own until 15. Borrowing downward keeps the kit legal for the level
  /// the foe actually fights at.
  static AiPersona campaignFoe({required String name, required int level}) {
    final base = strongestAtOrBelow(level);
    return AiPersona(
      id: 'campaign_$name',
      name: name,
      title: 'Wild opponent',
      level: level,
      intelligence: base.intelligence,
      apparel: base.apparel,
      loadout: base.loadout,
      aggression: base.aggression,
      caution: base.caution,
    );
  }

  /// The toughest persona a mage of [level] could legally be, falling back to
  /// the weakest. Use this whenever a persona's *kit* is being reused at some
  /// other level; [nearestToLevel] is only safe when the persona keeps its own.
  static AiPersona strongestAtOrBelow(int level) {
    AiPersona best = all.first; // all is level-ascending (guarded by tests)
    for (final p in all) {
      if (p.level <= level) best = p;
    }
    return best;
  }

  /// The persona closest to [level] — the matchmaking stand-in. Safe here
  /// because the stand-in fights at its *own* level, kit and level in step.
  static AiPersona nearestToLevel(int level) {
    AiPersona best = all.first;
    var bestDiff = (best.level - level).abs();
    for (final p in all) {
      final diff = (p.level - level).abs();
      if (diff < bestDiff) {
        best = p;
        bestDiff = diff;
      }
    }
    return best;
  }
}
