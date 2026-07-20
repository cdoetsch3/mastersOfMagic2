import 'dart:ui' show Color;

import 'package:mom_engine/mom_engine.dart';

import 'loadout.dart';
import 'mage_apparel.dart';

/// A named AI opponent with a level, look, spell kit, and tactical skill.
/// Personas fill two roles: a practice roster, and matchmaking stand-ins
/// when no human opponent is found.
class AiPersona {
  final String id;
  final String name;
  final String title;
  final int level;
  final MageApparel apparel;
  final Loadout loadout;

  /// Skill dials (see TunableAi): blunder rate falls and tactical instincts
  /// sharpen as level rises.
  final double mistakeChance;
  final double aggression;
  final double caution;

  const AiPersona({
    required this.id,
    required this.name,
    required this.title,
    required this.level,
    required this.apparel,
    required this.loadout,
    required this.mistakeChance,
    required this.aggression,
    required this.caution,
  });

  DuelAi buildBrain() => TunableAi(
        spells: loadout.spells,
        mistakeChance: mistakeChance,
        aggression: aggression,
        caution: caution,
      );
}

/// The Phase-1 roster, weakest to strongest.
abstract final class AiRoster {
  static final Loadout _novice = Loadout(
    elements: const [MagicElement.geo, MagicElement.aqua, MagicElement.pyro]
        .toList(),
    spells: [
      Spellbook.flick,
      Spellbook.bolt,
      Spellbook.flurry,
      Spellbook.ward,
      Spellbook.sap,
    ],
  );

  static final Loadout _skirmisher = Loadout(
    elements:
        const [MagicElement.pyro, MagicElement.aero, MagicElement.electro]
            .toList(),
    spells: [
      Spellbook.flick,
      Spellbook.bolt,
      Spellbook.blast,
      Spellbook.jolt,
      Spellbook.ward,
    ],
  );

  static final Loadout _warden = Loadout(
    elements: const [MagicElement.geo, MagicElement.flora, MagicElement.radiant]
        .toList(),
    spells: [
      Spellbook.bolt,
      Spellbook.blast,
      Spellbook.aegis,
      Spellbook.bulwark,
      Spellbook.barrier,
    ],
  );

  static final Loadout _duelist = Loadout(
    elements:
        const [MagicElement.pyro, MagicElement.aqua, MagicElement.umbra]
            .toList(),
    spells: [
      Spellbook.flick,
      Spellbook.blast,
      Spellbook.jolt,
      Spellbook.bulwark,
      Spellbook.surge,
    ],
  );

  static final Loadout _archmage = Loadout(
    elements:
        const [MagicElement.radiant, MagicElement.umbra, MagicElement.electro]
            .toList(),
    spells: [
      Spellbook.jolt,
      Spellbook.blast,
      Spellbook.bulwark,
      Spellbook.overload,
      Spellbook.cataclysm,
    ],
  );

  static final List<AiPersona> all = [
    AiPersona(
      id: 'wick',
      name: 'Wick',
      title: 'Candle Apprentice',
      level: 1,
      apparel: MageApparel.apprenticeBlue,
      loadout: _novice,
      mistakeChance: 0.55,
      aggression: 0.5,
      caution: 0.15,
    ),
    AiPersona(
      id: 'brightgale',
      name: 'Brightgale',
      title: 'Storm Skirmisher',
      level: 3,
      apparel: MageApparel(
        hat: const Color(0xFF9BB8C4),
        hatTrim: const Color(0xFFE8C547),
        robe: const Color(0xFF5F7C8A),
        robeTrim: const Color(0xFFE8C547),
        gloves: const Color(0xFF3A2E37),
        boots: const Color(0xFF2C2230),
      ),
      loadout: _skirmisher,
      mistakeChance: 0.35,
      aggression: 0.55,
      caution: 0.25,
    ),
    AiPersona(
      id: 'thornwall',
      name: 'Thornwall',
      title: 'Warden of the Quarry',
      level: 5,
      apparel: MageApparel(
        hat: const Color(0xFF6B7F3E),
        hatTrim: const Color(0xFFB0851E),
        robe: const Color(0xFF55663A),
        robeTrim: const Color(0xFFB0851E),
        gloves: const Color(0xFF5C4632),
        boots: const Color(0xFF3A2E20),
      ),
      loadout: _warden,
      mistakeChance: 0.22,
      aggression: 0.2,
      caution: 0.7,
    ),
    AiPersona(
      id: 'morwen',
      name: 'Morwen',
      title: 'Duelist of the Deep',
      level: 8,
      apparel: MageApparel.duskWitch,
      loadout: _duelist,
      mistakeChance: 0.1,
      aggression: 0.45,
      caution: 0.45,
    ),
    AiPersona(
      id: 'procarius',
      name: 'Procarius',
      title: 'The Eclipsed',
      level: 12,
      apparel: MageApparel(
        hat: const Color(0xFF2C2230),
        hatTrim: const Color(0xFF8B5CD6),
        robe: const Color(0xFF3A2E37),
        robeTrim: const Color(0xFF8B5CD6),
        gloves: const Color(0xFF1E1836),
        boots: const Color(0xFF141021),
      ),
      loadout: _archmage,
      mistakeChance: 0.02,
      aggression: 0.4,
      caution: 0.55,
    ),
  ];

  static AiPersona byId(String id) => all.firstWhere((p) => p.id == id);

  /// A themed campaign foe: the roster persona nearest [level], re-skinned
  /// with the location monster's name.
  static AiPersona campaignFoe({required String name, required int level}) {
    final base = nearestToLevel(level);
    return AiPersona(
      id: 'campaign_$name',
      name: name,
      title: 'Wild opponent',
      level: level,
      apparel: base.apparel,
      loadout: base.loadout,
      mistakeChance: base.mistakeChance,
      aggression: base.aggression,
      caution: base.caution,
    );
  }

  /// The persona closest to [level] — the matchmaking stand-in.
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
