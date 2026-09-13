/// The Ladder's 27-bot pool (LADDER_DESIGN.md §4, §5).
///
/// ⭐ **A bot is a body, not a fixed opponent.** The body — level, archetype
/// (kit shape + intelligence), hand-written loadout and gear — lives here.
/// The mind is bolted on separately by [LadderBot.toPersona] /
/// [AiPersona.buildBrain]: `LadderAi(intelligence, ...)`. Rating, wins and
/// losses are NOT here — LADDER_DESIGN §4 puts those in Firestore
/// (`bots/{id}`), because they are the only state that actually mutates.
///
/// ⚠️ **`hpScale`/`damageScale` on [EnemyArchetype] are never read.**
/// LADDER_DESIGN §1 law 5: bots are mages, not monsters, and the archetype
/// contributes intelligence and offensive-core *shape* only (move count, cost
/// band). Power comes from level, kit and gear — same as a player.
library;

import 'package:flutter/material.dart' show Color;
import 'package:mom_engine/mom_engine.dart';

import '../ai_personas.dart';
import '../enemies/enemy_archetype.dart';
import '../items/equipping.dart';
import '../items/item_catalogue.dart';
import '../items/item_def.dart';
import '../items/item_instance.dart';
import '../loadout.dart';
import '../mage_apparel.dart';

/// A gear tier for a bot's wardrobe (LADDER_DESIGN §5). ⭐ [term] is the
/// seed-rating contribution (§2's geared formula); the design-doc rarity
/// band is what the wardrobe below aims for.
///
/// ⚠️ **The catalogue does not have every rarity yet.** As of this writing
/// `ItemCatalogue` ships only common/rare/epic equipment (no uncommon, no
/// mythic, no legendary — see `test/ladder_roster_test.dart`'s catalogue
/// survey), and three slots (`robeBottom`, `boots`, `offHand`) have no
/// rare-or-better piece at any level. So "Kitted" below is built from rare
/// pieces where they exist and steps down to common where they don't;
/// "Prized" and "Peak" do the same one rung higher. Each step-down is a
/// content gap, not a bug — flagged 📝 at the piece, once per gap-shaped
/// slot, rather than 27 times.
enum GearTier {
  bare(0),
  worn(15),
  kitted(30),
  prized(45),
  peak(60);

  final int term;
  const GearTier(this.term);
}

/// One worn piece: a catalogue item id at a quality.
///
/// ⭐ Deliberately just an id + a [Quality] — never an [ItemInstance]. A bot
/// has no inventory and no instance ids; [LadderBot.gearModifiers] mints a
/// throwaway instance only to reuse [Equipping.modifiersOf] verbatim, so a
/// stat-scaling rule changed once is changed for players and bots alike.
class BotGearPiece {
  final String itemId;
  final Quality quality;
  const BotGearPiece({required this.itemId, required this.quality});
}

/// A named ladder opponent (LADDER_DESIGN §4): a level, an archetype (kit
/// shape + intelligence), a hand-written loadout, a look, and a wardrobe.
class LadderBot {
  final String id;
  final String name;
  final String title;

  /// 1–50. Procarius alone sits above the cap, and is not in this pool
  /// (LADDER_DESIGN §4 table, and the campaign boss he already is).
  final int level;

  /// Supplies **intelligence** and the offensive core's **shape** only
  /// (move count, cost band) — never `hpScale`/`damageScale`. See the
  /// library doc.
  final EnemyArchetype archetype;

  final MageApparel apparel;

  /// Hand-written, legal for [level] — see `test/ladder_roster_test.dart`.
  final Loadout loadout;

  final GearTier gearTier;

  /// May be empty (Bare). Never two pieces in the same [EquipSlot] — guarded
  /// by the roster test, not by this type, because the slot lives on the
  /// looked-up [EquipmentDef], not on [BotGearPiece] itself.
  final List<BotGearPiece> gear;

  const LadderBot({
    required this.id,
    required this.name,
    required this.title,
    required this.level,
    required this.archetype,
    required this.apparel,
    required this.loadout,
    required this.gearTier,
    required this.gear,
  });

  /// ⭐ The archetype's rung, LADDER_DESIGN §4 — never a rating in itself.
  int get intelligence => archetype.intelligence;

  /// The wardrobe's combat contribution, summed exactly as a player's
  /// equipment is: [Equipping.modifiersOf] resolves each piece against its
  /// own [BotGearPiece.quality] (so quality scales per piece, never the
  /// total), then the pieces add.
  ItemModifiers get gearModifiers {
    var sum = ItemModifiers.none;
    for (final piece in gear) {
      final def = ItemCatalogue.tryById(piece.itemId);
      final instance = ItemInstance(
        instanceId: 'bot_${id}_${piece.itemId}',
        defId: piece.itemId,
        quality: piece.quality,
      );
      sum = sum + Equipping.modifiersOf(def, instance);
    }
    return sum;
  }

  /// LADDER_DESIGN §2 — ⭐ the engine's formula, so the roster and `Elo`
  /// can never disagree about where a bot starts.
  int get seedGeared => LadderSeeds.gearedBot(
    level: level,
    intelligence: intelligence,
    gearTerm: gearTier.term,
  );

  /// LADDER_DESIGN §2: skill is the only variable on that ladder.
  int get seedAcademy => LadderSeeds.academyBot(intelligence: intelligence);

  /// Bridges to the shape today's `LocalAiDriver` / campaign code already
  /// knows how to drive: the body here, the brain from [intelligence].
  AiPersona toPersona() => AiPersona(
    id: id,
    name: name,
    title: title,
    level: level,
    intelligence: intelligence,
    apparel: apparel,
    loadout: loadout,
  );
}

/// The 27-bot pool (LADDER_DESIGN §5), weakest to strongest.
///
/// ⭐ **Five bots are borrowed, not duplicated.** Wick, Brightgale, Thornwall,
/// Morwen and Al'Dorian keep the exact apparel and loadout `AiRoster` already
/// defines — read through `AiRoster.byId`, not retyped — so the two rosters
/// can never quietly drift onto two different Brightgales. Procarius stays a
/// campaign boss and is deliberately absent (§5's table, §4's note).
///
/// ⚠️ **Two documented, deliberate deviations from the "clean" spec**,
/// surfaced by `test/ladder_roster_test.dart` rather than hidden:
///  1. Pim (L3), Orrin (L7) and Dunstan (L13) carry only **one** offensive-core
///     spell, one short of their archetype's `moveCount` of 2. At those
///     levels `Progression.plannedUnlockLevelOf` has not yet unlocked a
///     second attack in the archetype's cost band (skirmisher/sentinel/
///     bruiser all want a second attack that arrives at L5+) — there is
///     nothing else legal to add. 📝 Follow-up: either the planned schedule
///     front-loads a second cheap attack, or these three bots move up a
///     couple of levels.
///  2. Al'Dorian carries **four** offensive-core spells against tyrant's
///     `moveCount` of 3 — his kit is `AiRoster`'s original, unchanged
///     persona and predates the archetype pairing; LADDER_DESIGN §5 also
///     lists him as reusing his existing kit verbatim.
/// `test/ladder_roster_test.dart` asserts these counts explicitly (by id),
/// so a future edit that "fixes" one silently is a test failure, not a
/// surprise.
abstract final class LadderRoster {
  static final List<LadderBot> all = [
    LadderBot(
      id: 'wick',
      name: 'Wick',
      title: 'Candle Apprentice',
      level: 1,
      archetype: Archetypes.drudge,
      apparel: AiRoster.byId('wick').apparel,
      loadout: AiRoster.byId('wick').loadout,
      gearTier: GearTier.bare,
      gear: const [],
    ),
    LadderBot(
      id: 'pim',
      name: 'Pim',
      title: 'Hedge Sprout',
      level: 3,
      archetype: Archetypes.skirmisher,
      apparel: const MageApparel(
        hat: Color(0xFF6FA85A),
        hatTrim: Color(0xFFE0C468),
        robe: Color(0xFF4F8542),
        robeTrim: Color(0xFFE0C468),
        gloves: Color(0xFF5C4632),
        boots: Color(0xFF3A2E20),
      ),
      // 📝 skirmisher wants 2 attacks in [1,2]c; only Bolt (u1) is unlocked
      // at L3 under Progression.plannedUnlockLevel (Sap/Blast unlock at 5).
      loadout: Loadout(
        elements: const [MagicElement.pyro, MagicElement.aqua],
        spells: [Spellbook.bolt, Spellbook.flick, Spellbook.ward],
      ),
      gearTier: GearTier.bare,
      gear: const [],
    ),
    LadderBot(
      id: 'tansy',
      name: 'Tansy',
      title: 'Puddle Witch',
      level: 5,
      archetype: Archetypes.lasher,
      apparel: const MageApparel(
        hat: Color(0xFF4A7A8C),
        hatTrim: Color(0xFFB8D8C0),
        robe: Color(0xFF3A6B7A),
        robeTrim: Color(0xFFB8D8C0),
        gloves: Color(0xFF2E4A52),
        boots: Color(0xFF24393F),
      ),
      // Bolt (1c) + Blast (2c): "two attacks, one cheap one not" (§5).
      loadout: Loadout(
        elements: const [MagicElement.pyro, MagicElement.aqua],
        spells: [
          Spellbook.bolt,
          Spellbook.blast,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
        ],
      ),
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'bindweed_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'bindweed_gloves', quality: Quality.standard),
        BotGearPiece(itemId: 'bindweed_boots', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'orrin',
      name: 'Orrin',
      title: 'Lantern Bearer',
      level: 7,
      archetype: Archetypes.sentinel,
      apparel: const MageApparel(
        hat: Color(0xFFD9A544),
        hatTrim: Color(0xFF8B5A2B),
        robe: Color(0xFFB8863A),
        robeTrim: Color(0xFF8B5A2B),
        gloves: Color(0xFF5C4632),
        boots: Color(0xFF3A2E20),
      ),
      // 📝 sentinel wants 2 attacks in [2,4]c; only Blast (u5) is unlocked at
      // L7 under the planned schedule (Agony u15, Ruin u20). Same gap as Pim.
      loadout: Loadout(
        elements: const [MagicElement.aqua, MagicElement.flora],
        spells: [
          Spellbook.blast,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
        ],
      ),
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'bindweed_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'bindweed_robe', quality: Quality.standard),
        BotGearPiece(itemId: 'bindweed_leggings', quality: Quality.standard),
        BotGearPiece(itemId: 'bindweed_boots', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'marlow',
      name: 'Marlow',
      title: 'Marsh Dabbler',
      level: 9,
      archetype: Archetypes.glasswing,
      apparel: const MageApparel(
        hat: Color(0xFF6B8E4E),
        hatTrim: Color(0xFFCFCB6B),
        robe: Color(0xFF52703C),
        robeTrim: Color(0xFFCFCB6B),
        gloves: Color(0xFF3E4A2E),
        boots: Color(0xFF2C331F),
      ),
      loadout: Loadout(
        elements: const [MagicElement.pyro, MagicElement.aqua],
        spells: [
          Spellbook.bolt,
          Spellbook.blast,
          Spellbook.flick,
          Spellbook.ward,
        ],
      ),
      gearTier: GearTier.worn,
      // Two pieces only — "hits hard, folds fast" is the kit, not the HP
      // (LADDER §1 law 5 ignores hpScale); the light wardrobe echoes it.
      gear: const [
        BotGearPiece(itemId: 'oak_wand', quality: Quality.standard),
        BotGearPiece(itemId: 'oak_knot', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'sable',
      name: 'Sable',
      title: 'Moth Priestess',
      level: 11,
      archetype: Archetypes.blighter,
      apparel: const MageApparel(
        hat: Color(0xFF7A6B8C),
        hatTrim: Color(0xFFD8C8E0),
        robe: Color(0xFF5C4E70),
        robeTrim: Color(0xFFD8C8E0),
        gloves: Color(0xFF3A2E44),
        boots: Color(0xFF241C2C),
      ),
      // 📝 "first DoT kit" (§5) means Agony, but it unlocks at L15
      // (plannedUnlockLevel) and Sable is L11 — ships with Bolt+Sap
      // (both legal, both in blighter's [1,2] band) until she outlevels it.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
        ],
        spells: [
          Spellbook.bolt,
          Spellbook.sap,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.glance,
        ],
      ),
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'bogflax_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'bogflax_robe', quality: Quality.standard),
        BotGearPiece(itemId: 'bogflax_boots', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'dunstan',
      name: 'Dunstan',
      title: 'Quarry Hand',
      level: 13,
      archetype: Archetypes.bruiser,
      apparel: const MageApparel(
        hat: Color(0xFF8C7A5C),
        hatTrim: Color(0xFF4A3E2C),
        robe: Color(0xFF6E5C42),
        robeTrim: Color(0xFF4A3E2C),
        gloves: Color(0xFF3E3222),
        boots: Color(0xFF2A2118),
      ),
      // 📝 bruiser wants 2 attacks in [2,5]c; only Blast (u5) is unlocked at
      // L13 under the planned schedule (Agony/Leech u15, Ruin/Torment u20).
      loadout: Loadout(
        elements: const [MagicElement.pyro, MagicElement.aqua],
        spells: [
          Spellbook.blast,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
        ],
      ),
      gearTier: GearTier.kitted,
      // 📝 Kitted = "uncommon-rare"; the catalogue has no uncommon items at
      // all, so this steps down to rare (+ common where rare doesn't reach).
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'brookstone_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'wickerbound_ring', quality: Quality.standard),
        BotGearPiece(itemId: 'bogflax_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'bogflax_boots', quality: Quality.standard),
        BotGearPiece(itemId: 'birch_wand', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'brightgale',
      name: 'Brightgale',
      title: 'Storm Skirmisher',
      level: 15,
      archetype: Archetypes.skirmisher,
      apparel: AiRoster.byId('brightgale').apparel,
      loadout: AiRoster.byId('brightgale').loadout,
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'bogflax_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'birch_wand', quality: Quality.standard),
        BotGearPiece(itemId: 'birch_knot', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'quill',
      name: 'Quill',
      title: 'Archive Novice',
      level: 17,
      archetype: Archetypes.adept,
      apparel: const MageApparel(
        hat: Color(0xFFB89A5C),
        hatTrim: Color(0xFF4A3E2C),
        robe: Color(0xFF8C6E42),
        robeTrim: Color(0xFF4A3E2C),
        gloves: Color(0xFF4A3E2C),
        boots: Color(0xFF2A2118),
      ),
      // Bolt / Blast / Leech: "balanced three-attack kit" (§5).
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.aero,
        ],
        spells: [
          Spellbook.bolt,
          Spellbook.blast,
          Spellbook.leech,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
        ],
      ),
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'seawrack_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_robe', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_boots', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_gloves', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'hesper',
      name: 'Hesper',
      title: 'Tidewatcher',
      level: 19,
      archetype: Archetypes.siphon,
      apparel: const MageApparel(
        hat: Color(0xFF3A6B8C),
        hatTrim: Color(0xFFA8D0E0),
        robe: Color(0xFF2E5470),
        robeTrim: Color(0xFFA8D0E0),
        gloves: Color(0xFF1E3A4A),
        boots: Color(0xFF14262E),
      ),
      // Sap + Leech (both lifesteal) plus Mend: "drain-and-mend line" (§5).
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.aero,
        ],
        spells: [
          Spellbook.sap,
          Spellbook.leech,
          Spellbook.flick,
          Spellbook.mend,
          Spellbook.ward,
          Spellbook.aegis,
        ],
      ),
      gearTier: GearTier.kitted,
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'brookstone_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'overseers_seal', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_boots', quality: Quality.standard),
        BotGearPiece(itemId: 'birch_knot', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'rook',
      name: 'Rook',
      title: 'Cinder Duelist',
      level: 21,
      archetype: Archetypes.lasher,
      apparel: const MageApparel(
        hat: Color(0xFFA84A3A),
        hatTrim: Color(0xFF2E2018),
        robe: Color(0xFF7A3A2E),
        robeTrim: Color(0xFF2E2018),
        gloves: Color(0xFF3E2A20),
        boots: Color(0xFF241812),
      ),
      // Bolt (cheap) + Agony (chip pressure): "cheap pressure, blunders" —
      // the blundering is intelligence 3, not the kit.
      loadout: Loadout(
        elements: const [MagicElement.pyro, MagicElement.aqua],
        spells: [
          Spellbook.bolt,
          Spellbook.agony,
          Spellbook.flick,
          Spellbook.ward,
        ],
      ),
      gearTier: GearTier.kitted,
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'fulgurite_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'overseers_seal', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'yew_wand', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_gloves', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'isolde',
      name: 'Isolde',
      title: 'Frost Warden',
      level: 23,
      archetype: Archetypes.sentinel,
      apparel: const MageApparel(
        hat: Color(0xFFA8D0E8),
        hatTrim: Color(0xFF3A6B8C),
        robe: Color(0xFF7AAAC8),
        robeTrim: Color(0xFF3A6B8C),
        gloves: Color(0xFF2E4A5C),
        boots: Color(0xFF1E323E),
      ),
      // 📝 "Steadfast + Divert turtle" (§5): Divert unlocks at L25, one past
      // Isolde's L23, so Glance (the cheap tier of the same Divert family,
      // u10) substitutes until she outlevels the real thing.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.geo,
        ],
        spells: [
          Spellbook.blast,
          Spellbook.ruin,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.barrier,
          Spellbook.steadfast,
          Spellbook.glance,
        ],
      ),
      gearTier: GearTier.kitted,
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'fulgurite_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'leanstone_charm', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'seawrack_boots', quality: Quality.standard),
        BotGearPiece(itemId: 'yew_knot', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'garrick',
      name: 'Garrick',
      title: 'Ridge Bruiser',
      level: 25,
      archetype: Archetypes.bruiser,
      apparel: const MageApparel(
        hat: Color(0xFF8C6E4A),
        hatTrim: Color(0xFF3E2E1C),
        robe: Color(0xFF6E5236),
        robeTrim: Color(0xFF3E2E1C),
        gloves: Color(0xFF3A2C1E),
        boots: Color(0xFF241A10),
      ),
      // The gear-check: dumb (int 3) and dressed (Prized) — the kit itself
      // is unremarkable bruiser pressure.
      loadout: Loadout(
        elements: const [MagicElement.pyro, MagicElement.aqua],
        spells: [
          Spellbook.agony,
          Spellbook.ruin,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.rampart,
        ],
      ),
      gearTier: GearTier.prized,
      // 📝 hat/boots/gloves have no rare-or-better piece at L25 (hat epic
      // arrives L29, gloves epic L28) — common stands in; offHand has no
      // rare/epic at any level (see the GearTier doc).
      gear: const [
        BotGearPiece(itemId: 'tussock_hood', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_gloves', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.ornate),
        BotGearPiece(itemId: 'rimebound_ring', quality: Quality.ornate),
        BotGearPiece(itemId: 'uplight', quality: Quality.ornate),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.ornate),
      ],
    ),
    LadderBot(
      id: 'thornwall',
      name: 'Thornwall',
      title: 'Warden of the Quarry',
      level: 28,
      archetype: Archetypes.adept,
      apparel: AiRoster.byId('thornwall').apparel,
      loadout: AiRoster.byId('thornwall').loadout,
      gearTier: GearTier.kitted,
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'countstone_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_gloves', quality: Quality.standard),
        BotGearPiece(itemId: 'rowan_wand', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'nettle',
      name: 'Nettle',
      title: 'Hex Weaver',
      level: 30,
      archetype: Archetypes.blighter,
      apparel: const MageApparel(
        hat: Color(0xFF6B4A8C),
        hatTrim: Color(0xFFC8A8E0),
        robe: Color(0xFF52386E),
        robeTrim: Color(0xFFC8A8E0),
        gloves: Color(0xFF3A2650),
        boots: Color(0xFF241832),
      ),
      // "what statuses actually do" (blighter's teach) via Murk + Wither;
      // Solar is the first Celestial element, unlocking exactly at L30.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.solar,
        ],
        spells: [
          Spellbook.sap,
          Spellbook.agony,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.murk,
          Spellbook.wither,
        ],
      ),
      gearTier: GearTier.kitted,
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'countstone_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.standard),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'corvane',
      name: 'Corvane',
      title: 'Gale Reaver',
      level: 32,
      archetype: Archetypes.glasswing,
      apparel: const MageApparel(
        hat: Color(0xFF8CA8D0),
        hatTrim: Color(0xFF3A4A6E),
        robe: Color(0xFF6E86AC),
        robeTrim: Color(0xFF3A4A6E),
        gloves: Color(0xFF2E3A50),
        boots: Color(0xFF1E2636),
      ),
      // 📝 "Execute + Death Wish gambler" (§5): Execute unlocks at L35, past
      // Corvane's L32 — the offensive core substitutes Agony + Torment (both
      // legal, both in glasswing's [1,3] band); Death Wish itself (u30) is
      // legal and kept, so the gambler flavor survives on the aux side.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.solar,
        ],
        spells: [
          Spellbook.agony,
          Spellbook.torment,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.deathWish,
        ],
      ),
      gearTier: GearTier.prized,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.ornate),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.ornate),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.ornate),
        BotGearPiece(itemId: 'uplight', quality: Quality.ornate),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.ornate),
      ],
    ),
    LadderBot(
      id: 'lisbet',
      name: 'Lisbet',
      title: 'Hollow Chanter',
      level: 34,
      archetype: Archetypes.hexer,
      apparel: const MageApparel(
        hat: Color(0xFF2E2038),
        hatTrim: Color(0xFF8C5CC8),
        robe: Color(0xFF241830),
        robeTrim: Color(0xFF8C5CC8),
        gloves: Color(0xFF1A1224),
        boots: Color(0xFF120C18),
      ),
      // The skill-check: intelligence 8 in a Worn wardrobe. Murk/Miasma
      // are hexer's "punishes a bad loadout, not bad reflexes" (§2 archetype
      // table) made literal.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.aero,
          MagicElement.solar,
        ],
        spells: [
          Spellbook.barrage,
          Spellbook.agony,
          Spellbook.leech,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.murk,
          Spellbook.miasma,
        ],
      ),
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'tussock_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'rowan_wand', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'ashbourne',
      name: 'Ashbourne',
      title: 'Bastion Mage',
      level: 36,
      archetype: Archetypes.redoubt,
      apparel: const MageApparel(
        hat: Color(0xFF5C6E8C),
        hatTrim: Color(0xFFB8C4D8),
        robe: Color(0xFF465470),
        robeTrim: Color(0xFFB8C4D8),
        gloves: Color(0xFF2E3A50),
        boots: Color(0xFF1E2636),
      ),
      // "Shatter-bait; teaches shield-breaking" (§5) is about what a PLAYER
      // should bring, not Ashbourne's own kit — so the kit is simply the
      // heaviest shield ladder available (Ward/Aegis/Bulwark/Rampart).
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.geo,
        ],
        spells: [
          Spellbook.blast,
          Spellbook.leech,
          Spellbook.ruin,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.bulwark,
          Spellbook.rampart,
        ],
      ),
      gearTier: GearTier.prized,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.ornate),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.ornate),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.ornate),
        BotGearPiece(itemId: 'uplight', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.ornate),
      ],
    ),
    LadderBot(
      id: 'vale',
      name: 'Vale',
      title: 'Blade Scholar',
      level: 38,
      archetype: Archetypes.executioner,
      apparel: const MageApparel(
        hat: Color(0xFF8C2E3A),
        hatTrim: Color(0xFF2A1418),
        robe: Color(0xFF6E222C),
        robeTrim: Color(0xFF2A1418),
        gloves: Color(0xFF3A1418),
        boots: Color(0xFF240C10),
      ),
      // Execute + Ruin, both 4-charge: "3-5 charge crits" (§5), backed by
      // Keen/Heavyhand so the Execute crit rider actually pays off.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.solar,
        ],
        spells: [
          Spellbook.execute,
          Spellbook.ruin,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.keen,
          Spellbook.heavyhand,
        ],
      ),
      gearTier: GearTier.kitted,
      gear: const [
        BotGearPiece(itemId: 'sporecap_mantle', quality: Quality.standard),
        BotGearPiece(itemId: 'countstone_pendant', quality: Quality.standard),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.standard),
        BotGearPiece(itemId: 'tussock_gloves', quality: Quality.standard),
        BotGearPiece(itemId: 'rowan_quarterstaff', quality: Quality.standard),
      ],
    ),
    LadderBot(
      id: 'morwen',
      name: 'Morwen',
      title: 'Duelist of the Deep',
      level: 40,
      archetype: Archetypes.champion,
      apparel: AiRoster.byId('morwen').apparel,
      loadout: AiRoster.byId('morwen').loadout,
      gearTier: GearTier.prized,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_leggings', quality: Quality.ornate),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.ornate),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.ornate),
        BotGearPiece(itemId: 'uplight', quality: Quality.ornate),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.ornate),
      ],
    ),
    LadderBot(
      id: 'tarquin',
      name: 'Tarquin',
      title: 'Ledger Duelist',
      level: 42,
      archetype: Archetypes.siphon,
      apparel: const MageApparel(
        hat: Color(0xFF4A6E5C),
        hatTrim: Color(0xFFC8D8B8),
        robe: Color(0xFF385648),
        robeTrim: Color(0xFFC8D8B8),
        gloves: Color(0xFF243A2E),
        boots: Color(0xFF16241C),
      ),
      // "Meditate/Composure sustain" (§5), both legal at 42.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.aero,
        ],
        spells: [
          Spellbook.sap,
          Spellbook.leech,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.meditate,
          Spellbook.composure,
        ],
      ),
      gearTier: GearTier.prized,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_leggings', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.ornate),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.ornate),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.ornate),
        BotGearPiece(itemId: 'uplight', quality: Quality.ornate),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.ornate),
      ],
    ),
    LadderBot(
      id: 'seraphel',
      name: 'Seraphel',
      title: 'Dawn Herald',
      level: 44,
      archetype: Archetypes.champion,
      apparel: const MageApparel(
        hat: Color(0xFFE8D8A8),
        hatTrim: Color(0xFFC89A3A),
        robe: Color(0xFFD8C088),
        robeTrim: Color(0xFFC89A3A),
        gloves: Color(0xFF8C7A4E),
        boots: Color(0xFF5C4E32),
      ),
      // 📝 "Purify + Reflect counterplay" (§5): Purify (u40) is legal at 44,
      // but Reflect unlocks at 45 — one past Seraphel. Composure (u25)
      // substitutes as the counterplay piece until she outlevels Reflect.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.solar,
          MagicElement.lunar,
        ],
        spells: [
          Spellbook.blast,
          Spellbook.leech,
          Spellbook.execute,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.purify,
          Spellbook.composure,
        ],
      ),
      gearTier: GearTier.prized,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.ornate),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.ornate),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.ornate),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.ornate),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.ornate),
        BotGearPiece(itemId: 'uplight', quality: Quality.ornate),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.ornate),
      ],
    ),
    LadderBot(
      id: 'halvard',
      name: 'Halvard',
      title: 'Iron Redoubt',
      level: 46,
      archetype: Archetypes.redoubt,
      apparel: const MageApparel(
        hat: Color(0xFF708C8C),
        hatTrim: Color(0xFFD8E8E8),
        robe: Color(0xFF546E6E),
        robeTrim: Color(0xFFD8E8E8),
        gloves: Color(0xFF3A4E4E),
        boots: Color(0xFF283636),
      ),
      // Ethereal (Sanctus/Umbra) unlocks exactly at L45 — Halvard is the
      // first bot on the ladder to carry it (§5).
      loadout: Loadout(
        elements: const [
          MagicElement.geo,
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.sanctus,
          MagicElement.umbra,
        ],
        spells: [
          Spellbook.overload,
          Spellbook.torment,
          Spellbook.ruin,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.bulwark,
          Spellbook.rampart,
        ],
      ),
      gearTier: GearTier.peak,
      // 📝 Peak wants mythic/legendary; the catalogue has neither at any
      // level, so this is the best available per slot (epic where it
      // exists, rare for ring, common for robeBottom/boots/offHand — see
      // the GearTier doc). Identical set to Nyx/Al'Dorian/Ysolde: it is
      // genuinely the ceiling of what exists today.
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.master),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_leggings', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.master),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.master),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.master),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.master),
        BotGearPiece(itemId: 'uplight', quality: Quality.master),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.master),
      ],
    ),
    LadderBot(
      id: 'nyx',
      name: 'Nyx',
      title: 'Void Adept',
      level: 48,
      archetype: Archetypes.aspect,
      apparel: const MageApparel(
        hat: Color(0xFF1A1424),
        hatTrim: Color(0xFF6C3CA8),
        robe: Color(0xFF120E1A),
        robeTrim: Color(0xFF6C3CA8),
        gloves: Color(0xFF0C0812),
        boots: Color(0xFF080610),
      ),
      // "full 15-slot pool" (§5): 5 elements, 10 spells.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.solar,
          MagicElement.sanctus,
        ],
        spells: [
          Spellbook.agony,
          Spellbook.leech,
          Spellbook.execute,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.bulwark,
          Spellbook.rampart,
          Spellbook.sanctuary,
          Spellbook.keen,
        ],
      ),
      gearTier: GearTier.peak,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.master),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_leggings', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.master),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.master),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.master),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.master),
        BotGearPiece(itemId: 'uplight', quality: Quality.master),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.master),
      ],
    ),
    LadderBot(
      id: 'aldorian',
      name: "Al'Dorian",
      title: 'Warden of the Last Gate',
      level: 50,
      archetype: Archetypes.tyrant,
      apparel: AiRoster.byId('aldorian').apparel,
      loadout: AiRoster.byId('aldorian').loadout,
      gearTier: GearTier.peak,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.master),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_leggings', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.master),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.master),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.master),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.master),
        BotGearPiece(itemId: 'uplight', quality: Quality.master),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.master),
      ],
    ),
    LadderBot(
      id: 'ysolde',
      name: 'Ysolde',
      title: 'Grand Magus',
      level: 50,
      archetype: Archetypes.aspect,
      apparel: const MageApparel(
        hat: Color(0xFFE8E8F0),
        hatTrim: Color(0xFF9C7CD8),
        robe: Color(0xFFC8C8D8),
        robeTrim: Color(0xFF9C7CD8),
        gloves: Color(0xFF6C6C88),
        boots: Color(0xFF48485C),
      ),
      // The second face at the cap — same archetype as Nyx, a different
      // element mix and a different offensive core so the two never play
      // identically.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.flora,
          MagicElement.lunar,
          MagicElement.umbra,
        ],
        spells: [
          Spellbook.barrage,
          Spellbook.torment,
          Spellbook.ruin,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.bulwark,
          Spellbook.rampart,
          Spellbook.sanctuary,
          Spellbook.heavyhand,
        ],
      ),
      gearTier: GearTier.peak,
      gear: const [
        BotGearPiece(itemId: 'the_long_cooling', quality: Quality.master),
        BotGearPiece(itemId: 'the_long_lean', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_leggings', quality: Quality.master),
        BotGearPiece(itemId: 'tussock_boots', quality: Quality.master),
        BotGearPiece(itemId: 'groundfault_grips', quality: Quality.master),
        BotGearPiece(itemId: 'the_holdfast', quality: Quality.master),
        BotGearPiece(itemId: 'firstmelt_loop', quality: Quality.master),
        BotGearPiece(itemId: 'uplight', quality: Quality.master),
        BotGearPiece(itemId: 'rowan_knot', quality: Quality.master),
      ],
    ),
    LadderBot(
      id: 'bramwell',
      name: 'Bramwell',
      title: 'Old Master',
      level: 50,
      archetype: Archetypes.executioner,
      apparel: const MageApparel(
        hat: Color(0xFF888070),
        hatTrim: Color(0xFF4A4438),
        robe: Color(0xFF6C6656),
        robeTrim: Color(0xFF4A4438),
        gloves: Color(0xFF3A362C),
        boots: Color(0xFF24221C),
      ),
      // "Skill over kit at the cap" (§5): a full, sharp spell pool (10
      // slots — intelligence 7 is the same brain everyone else at L50
      // carries) worn over deliberately light (Worn-tier) gear.
      loadout: Loadout(
        elements: const [
          MagicElement.pyro,
          MagicElement.aqua,
          MagicElement.solar,
          MagicElement.lunar,
          MagicElement.sanctus,
        ],
        spells: [
          Spellbook.execute,
          Spellbook.cataclysm,
          Spellbook.flick,
          Spellbook.ward,
          Spellbook.aegis,
          Spellbook.bulwark,
          Spellbook.rampart,
          Spellbook.sanctuary,
          Spellbook.keen,
          Spellbook.heavyhand,
        ],
      ),
      gearTier: GearTier.worn,
      gear: const [
        BotGearPiece(itemId: 'tussock_hood', quality: Quality.standard),
        BotGearPiece(itemId: 'rowan_quarterstaff', quality: Quality.standard),
      ],
    ),
  ];

  static LadderBot byId(String id) => all.firstWhere((b) => b.id == id);

  /// Bots whose seed on the given ladder is within ±[band] of [rating].
  static List<LadderBot> withinBand(
    int rating, {
    required int band,
    required bool academy,
  }) => all
      .where(
        (b) =>
            ((academy ? b.seedAcademy : b.seedGeared) - rating).abs() <= band,
      )
      .toList();
}
