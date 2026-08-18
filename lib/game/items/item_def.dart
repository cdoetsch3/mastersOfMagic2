/// What an item **is**, as opposed to what a player **owns**.
///
/// ⚠️ **Definitions live in code; instances live in the database.** The duel
/// resolves against these values, and the netcode is lockstep commit-reveal —
/// both clients must agree exactly. Server-loaded definitions would add a
/// second way for two clients to disagree, timed by whenever each last
/// refreshed. See ITEMS_DESIGN §10.1, and the login content-version gate that
/// makes this safe (IMPLEMENTATION_PLAN).
///
/// ⭐ **Sealed on purpose.** Dart's switch is exhaustive over a sealed type, so
/// adding a kind becomes a compile error everywhere it matters rather than a
/// silent fallthrough — the same reasoning `LocationKind` already uses.
library;

import 'package:flutter/foundation.dart';
import 'package:mom_engine/mom_engine.dart';

/// The six-rarity ladder (ITEMS §8). Ordered; index is meaningful.
enum Rarity { common, uncommon, rare, epic, mythic, legendary }

/// ITEMS §6c. ⚠️ **Bound is permanent** — it is what stops gold buying what
/// rare drops were meant to gate. Untradeable is freed by an unbinding
/// enchant; Bound never is.
enum Tradability { tradeable, untradeable, bound }

/// The crafting roll (ITEMS §9b.4). ⚠️ **Quality never raises equip level** —
/// a Master Oak wand is still a level-1 item, deliberately.
enum Quality {
  rough,
  standard,
  ornate,
  master;

  /// What every COMBAT stat is multiplied by (ruling, Christian 2026-08-18):
  /// ⭐ **a percentage of the definition, never a flat bonus**, so quality is
  /// worth the same proportion at every tier and a Master tier-1 wand can
  /// never out-scale an ordinary tier-2 one.
  ///
  /// ⚠️ Standard is 100 on purpose — the middle of the ladder is the
  /// *baseline*, which is why null (a drop, or an instance minted before this
  /// ruling) can read as Standard without changing a single number.
  /// 📝 The four values are the tuning knob; the shape is the ruling.
  int get statPercent => switch (this) {
    Quality.rough => 80,
    Quality.standard => 100,
    Quality.ornate => 120,
    Quality.master => 140,
  };
}

/// Ten slots (ITEMS §1). ⭐ Only the five armour slots carry sets (§3.2).
enum EquipSlot {
  hat,
  robeTop,
  robeBottom,
  boots,
  gloves,
  neck,
  ring,
  mainHand,
  offHand,

  /// ⭐ The one slot whose value is deliberately **not** combat power. It
  /// grants [ItemModifiers.beltSlots] today; 📝 further modifiers that shape
  /// what belt consumables *do* are expected later (ITEMS §10.3d).
  belt;

  /// Whether a set piece can occupy this slot.
  ///
  /// ⚠️ **Listed explicitly, not derived from [index].** An index comparison
  /// silently changes meaning the moment someone inserts a value in the middle
  /// of the enum, and that is exactly the kind of edit nobody reviews closely.
  bool get carriesSet => const {
    EquipSlot.hat,
    EquipSlot.robeTop,
    EquipSlot.robeBottom,
    EquipSlot.boots,
    EquipSlot.gloves,
  }.contains(this);
}

/// The mote ladder (ITEMS §6.0, §8). ⚠️ Tops out at Epic — Mythic and
/// Legendary have no mote tier.
enum MoteTier { dust, shard, crystal, core, heart }

/// The six making skills, one per town until Zenith (ITEMS §6a).
enum CraftSkill {
  woodcarving,
  tailoring,
  metalworking,
  potionsAndAlchemy,
  enchanting,
  jewelry,
}

// ---- traits ------------------------------------------------------------
//
// ⭐ Mixins describe what an item CAN DO; the sealed kinds below describe what
// it IS. A deep hierarchy fails here because things are two things at once —
// a crafted staff is Equipment *and* Salvageable.
//
// ⚠️ There is deliberately no `Stackable`. Whether something stacks is a
// consequence of [ItemDef.isFungible], not an independent fact, and modelling
// both would let them disagree (ITEMS §10.3a).

/// What breaking this item down returns (ITEMS §9b.4).
@immutable
class SalvageYield {
  final String defId;
  final int min;
  final int max;

  const SalvageYield(this.defId, this.min, this.max);
}

/// Can be broken back down for components, to reroll quality.
mixin Salvageable {
  List<SalvageYield> get salvage;
}

/// Can carry an enchant — the element axis, and the unbinding enchant.
mixin Enchantable {}

/// Has gem sockets (ITEMS §6d).
mixin Socketed {
  int get socketCount;
}

/// Can be loaded onto the **belt** and used during a duel (ITEMS §10.3b).
///
/// ⭐ **Using a belt item spends your turn**, which is what makes potions a
/// decision rather than a tax: in a simultaneous-turn duel a turn spent
/// drinking is a turn not casting, and the opponent committed blind — so a
/// heal can be baited. ⚠️ Not every consumable is Beltable; a field ration is
/// a between-encounters item and belongs in the backpack.
mixin Beltable {}

/// Flat and percentage bonuses an item grants (ITEMS §4).
///
/// ⭐ **Field names mirror `MageState` deliberately.** Every one of these has
/// to be applied to a real mage; naming them anything else invites a mapping
/// layer that can silently drift.
@immutable
class ItemModifiers {
  /// Added to the 80% base hit chance (ITEMS §9b.8). ⭐ The stat Q1 teaches.
  final int accuracyBonus;

  final int dodge;

  /// Chance (%) that a hit crits. ⚠️ **Standard stats are 0** — crits exist
  /// only through gear, and in Q1 only through one ring (§9b.8).
  final int critChance;

  /// A crit deals 150% damage; each point here adds 1 to the 50 (§9b.8).
  final int critDamage;

  final int deflectChance;
  final int deflectAmount;

  /// Flat max-HP — §4.1's baseline stat, carried by the Tailoring set.
  final int maxHpBonus;

  /// ⭐ The wand lane: flat damage added once per cast, so cheap spells get
  /// proportionally more (§9b.8).
  final int damagePerCast;

  /// ⭐ The quarterstaff lane: flat damage per charge the spell COST — pays
  /// only on commitment. "Charge spent" is §5b.3a's engine-wide definition.
  final int damagePerCharge;

  /// Shields you cast are this % stronger (§4.1 safe list).
  final int shieldStrengthPercent;

  /// Healing you receive is this % larger — potions included.
  final int healingReceivedPercent;

  /// ⭐ Regrow this % of max HP at the end of every turn. The Charlock's
  /// stat; ⚠️ must route through `TurnStatus` when wired (§4.2).
  final int regrowPercent;

  /// ⭐ A non-combat-power axis (ITEMS §6b.2) — build value that does not
  /// inflate damage or HP, which is what a system worried about power creep
  /// wants more of. ⚠️ Clamped by `Carrying.maxBeltSlots`.
  final int beltSlots;

  const ItemModifiers({
    this.accuracyBonus = 0,
    this.dodge = 0,
    this.critChance = 0,
    this.critDamage = 0,
    this.deflectChance = 0,
    this.deflectAmount = 0,
    this.maxHpBonus = 0,
    this.damagePerCast = 0,
    this.damagePerCharge = 0,
    this.shieldStrengthPercent = 0,
    this.healingReceivedPercent = 0,
    this.regrowPercent = 0,
    this.beltSlots = 0,
  });

  static const none = ItemModifiers();

  /// Field-wise sum — what wearing two things means.
  ItemModifiers operator +(ItemModifiers o) => ItemModifiers(
    accuracyBonus: accuracyBonus + o.accuracyBonus,
    dodge: dodge + o.dodge,
    critChance: critChance + o.critChance,
    critDamage: critDamage + o.critDamage,
    deflectChance: deflectChance + o.deflectChance,
    deflectAmount: deflectAmount + o.deflectAmount,
    maxHpBonus: maxHpBonus + o.maxHpBonus,
    damagePerCast: damagePerCast + o.damagePerCast,
    damagePerCharge: damagePerCharge + o.damagePerCharge,
    shieldStrengthPercent: shieldStrengthPercent + o.shieldStrengthPercent,
    healingReceivedPercent: healingReceivedPercent + o.healingReceivedPercent,
    regrowPercent: regrowPercent + o.regrowPercent,
    beltSlots: beltSlots + o.beltSlots,
  );

  /// This item's stats **as the quality roll made them** (ruling 2026-08-18):
  /// every combat field times [Quality.statPercent].
  ///
  /// ⚠️ **[beltSlots] passes through untouched.** It is the one deliberately
  /// non-combat axis (ITEMS §6b.2), and letting quality move it would turn a
  /// crafting roll into a carrying-capacity roll — the exact power-creep lane
  /// §6b.2 exists to keep open *without* stats attached.
  ///
  /// ⭐ **Null is Standard, not "no quality"** — dropped gear rolls an aspect
  /// instead (see [ItemInstance.quality]) and every instance minted before
  /// this ruling has no field at all. Both must keep exactly the numbers they
  /// have always had, so ×1.00 is the only safe reading and this returns
  /// `this` untouched for it.
  ///
  /// ⚠️ **Integer arithmetic on purpose.** `(v * pct + 50) ~/ 100` is
  /// round-half-away-from-zero *exactly*; `(v * 1.4).round()` is at the mercy
  /// of binary floating point (12 × 1.4 is 16.799999999999997). Truncation
  /// toward zero after a signed nudge is what keeps negatives symmetric.
  ///
  /// ⭐ Zero stays zero at every tier: quality multiplies power, it never
  /// invents a stat the definition does not have.
  ItemModifiers scaledBy(Quality? quality) {
    if (quality == null || quality == Quality.standard) return this;
    final pct = quality.statPercent;
    int s(int v) => (v * pct + (v < 0 ? -50 : 50)) ~/ 100;
    return ItemModifiers(
      accuracyBonus: s(accuracyBonus),
      dodge: s(dodge),
      critChance: s(critChance),
      critDamage: s(critDamage),
      deflectChance: s(deflectChance),
      deflectAmount: s(deflectAmount),
      maxHpBonus: s(maxHpBonus),
      damagePerCast: s(damagePerCast),
      damagePerCharge: s(damagePerCharge),
      shieldStrengthPercent: s(shieldStrengthPercent),
      healingReceivedPercent: s(healingReceivedPercent),
      regrowPercent: s(regrowPercent),
      // ⚠️ Not scaled. See the doc above — this is the ruling, not an omission.
      beltSlots: beltSlots,
    );
  }

  /// The wire form, for the matchmaking handshake (ITEMS §7.4 — PvP is the
  /// GEARED ladder, so both clients must know both wardrobes).
  ///
  /// ⚠️ **Only non-zero fields are emitted**, matching `content_export`'s
  /// `_modifiers`: an absent key and a zero mean the same thing, and shipping
  /// thirteen zeroes on every queue ticket is bytes nobody reads.
  ///
  /// ⚠️ **Total on purpose** — every field here and every field in
  /// [fromJson]. This map is one half of a lockstep agreement: a field that
  /// silently fails to cross the wire is a stat one client applies and the
  /// other does not, which is a desync, not a cosmetic loss.
  Map<String, Object?> toJson() => {
    if (accuracyBonus != 0) 'accuracyBonus': accuracyBonus,
    if (dodge != 0) 'dodge': dodge,
    if (critChance != 0) 'critChance': critChance,
    if (critDamage != 0) 'critDamage': critDamage,
    if (deflectChance != 0) 'deflectChance': deflectChance,
    if (deflectAmount != 0) 'deflectAmount': deflectAmount,
    if (maxHpBonus != 0) 'maxHpBonus': maxHpBonus,
    if (damagePerCast != 0) 'damagePerCast': damagePerCast,
    if (damagePerCharge != 0) 'damagePerCharge': damagePerCharge,
    if (shieldStrengthPercent != 0)
      'shieldStrengthPercent': shieldStrengthPercent,
    if (healingReceivedPercent != 0)
      'healingReceivedPercent': healingReceivedPercent,
    if (regrowPercent != 0) 'regrowPercent': regrowPercent,
    if (beltSlots != 0) 'beltSlots': beltSlots,
  };

  /// Reads [toJson]'s output back. ⭐ **Missing key → 0, null map → [none]** —
  /// the inverse of dropping zeroes, and what makes an older client's ticket
  /// (or a room doc written before gear crossed the wire) read as "unequipped"
  /// instead of throwing mid-matchmaking.
  factory ItemModifiers.fromJson(Map<String, Object?>? json) {
    if (json == null) return none;
    // Firestore hands integers back as `num`; be liberal about which.
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return ItemModifiers(
      accuracyBonus: read('accuracyBonus'),
      dodge: read('dodge'),
      critChance: read('critChance'),
      critDamage: read('critDamage'),
      deflectChance: read('deflectChance'),
      deflectAmount: read('deflectAmount'),
      maxHpBonus: read('maxHpBonus'),
      damagePerCast: read('damagePerCast'),
      damagePerCharge: read('damagePerCharge'),
      shieldStrengthPercent: read('shieldStrengthPercent'),
      healingReceivedPercent: read('healingReceivedPercent'),
      regrowPercent: read('regrowPercent'),
      beltSlots: read('beltSlots'),
    );
  }

  bool get isEmpty =>
      accuracyBonus == 0 &&
      dodge == 0 &&
      critChance == 0 &&
      critDamage == 0 &&
      deflectChance == 0 &&
      deflectAmount == 0 &&
      maxHpBonus == 0 &&
      damagePerCast == 0 &&
      damagePerCharge == 0 &&
      shieldStrengthPercent == 0 &&
      healingReceivedPercent == 0 &&
      regrowPercent == 0 &&
      beltSlots == 0;
}

// ---- the sealed root ---------------------------------------------------

@immutable
sealed class ItemDef {
  /// Stable and never displayed. Saves, drop tables and the Collector log all
  /// key on this, so ⚠️ **renaming an id is a save migration**.
  final String id;

  final Rarity rarity;
  final Tradability tradability;

  /// ✅ Every item has one (ITEMS §9b.3), and an item you cannot yet equip can
  /// still be acquired.
  final int equipLevel;

  /// ⭐ The "players who care can learn more" channel. Never mechanical.
  final String lore;

  /// A written name, for the kinds that have no naming grammar.
  ///
  /// ⚠️ **Equipment must leave this null.** Its name is *composed* from
  /// aspect + quality + material + form (ITEMS §9b.5a) precisely so the name
  /// cannot drift from the facts; writing one down here would reintroduce the
  /// drift that rule exists to prevent. Guarded by a test.
  final String? properName;

  /// Gold. ⚠️ A tuning knob — a candidate for server-side config later, since
  /// nothing the duel resolves depends on it.
  final int value;

  const ItemDef({
    required this.id,
    required this.rarity,
    required this.lore,
    this.properName,
    this.tradability = Tradability.tradeable,
    this.equipLevel = 1,
    this.value = 0,
  });

  /// Whether two of these are interchangeable.
  ///
  /// ⭐ **The axis the whole storage model turns on** (ITEMS §10.3a). Fungible
  /// means the definition fully determines the item, so a slot holding one
  /// needs only a `defId`. Non-fungible items carry per-instance rolls and
  /// each needs its own UUID.
  bool get isFungible;
}

// ---- the kinds ---------------------------------------------------------

/// Worn or wielded. ⚠️ Never fungible — quality, aspect, enchant and sockets
/// are all per-instance.
final class EquipmentDef extends ItemDef
    with Salvageable, Enchantable, Socketed {
  final EquipSlot slot;

  /// ⭐ Fixed vocabulary encoding mechanical role, never rank (ITEMS §9b.5a).
  /// "Quarterstaff", not "Spire".
  final String form;

  /// Encodes tier and therefore level. "Oak" → "Aetherwood".
  final String material;

  /// Set membership. ⚠️ Only the five armour slots may carry one (§3.2).
  final String? setId;
  final int? setTier;

  final ItemModifiers modifiers;

  @override
  final int socketCount;

  @override
  final List<SalvageYield> salvage;

  const EquipmentDef({
    required super.id,
    required super.rarity,
    required super.lore,
    required this.slot,
    required this.form,
    required this.material,
    this.modifiers = ItemModifiers.none,
    this.setId,
    this.setTier,
    this.socketCount = 0,
    this.salvage = const [],
    super.tradability,
    super.equipLevel,
    super.value,
    // ⭐ Only for NAMED equipment — boss uniques and drop-only jewelry
    // (§9b.5). Crafted gear must leave this null so the material+form
    // grammar composes the name.
    super.properName,
  });

  @override
  bool get isFungible => false;
}

/// What using an item does.
///
/// ⭐ **One vocabulary for every consumable**, whether it is eaten between
/// fights or drunk off the belt mid-duel. Adding an effect means adding a
/// field here and a case in [describe] — never a new code path per item.
///
/// ⚠️ Deliberately small. Only healing exists because only healing is
/// designed; a speculative effect vocabulary would be a system nobody has
/// balanced against spells.
@immutable
class ItemEffect {
  /// Health restored, as a **percentage of max** rather than a flat number, so
  /// one item does not trivialise level 2 and become worthless by level 20.
  final int healPercent;

  /// The Tonic shape (ITEMS §9b.8): heal [healPerTurnPercent] at the end of
  /// each of the next [healTurns] turns. ⚠️ **In a duel only.** Outside
  /// combat the whole amount applies at once — [healFor] already includes it,
  /// so callers between encounters need no special case.
  final int healPerTurnPercent;
  final int healTurns;

  const ItemEffect({
    this.healPercent = 0,
    this.healPerTurnPercent = 0,
    this.healTurns = 0,
  }) : assert(
         (healPerTurnPercent == 0) == (healTurns == 0),
         'over-time needs both a rate and a duration',
       );

  static const none = ItemEffect();

  bool get isNothing => healPercent == 0 && healPerTurnPercent == 0;

  /// The total this restores for a mage with [maxHp] — flat plus the full
  /// over-time amount, which is what out-of-combat use applies. At least 1 if
  /// it heals at all: an item that does nothing reads as a bug.
  int healFor(int maxHp) {
    final percent = healPercent + healPerTurnPercent * healTurns;
    if (percent == 0) return 0;
    final amount = (maxHp * percent / 100).round();
    return amount < 1 ? 1 : amount;
  }

  /// One line for a tooltip, built from the effect rather than written per
  /// item — ⭐ so a number changed here cannot disagree with its own text.
  String get describe {
    if (healPerTurnPercent > 0) {
      return 'Restores $healPerTurnPercent% health per turn for '
          '$healTurns turns';
    }
    return healPercent > 0 ? 'Restores $healPercent% health' : 'No effect';
  }
}

/// Anything a player can use up.
///
/// ⭐ **The interface the UI talks to**, so a "use" button never needs to know
/// whether it is holding food, a potion, or something not invented yet.
mixin Usable {
  ItemEffect get effect;
}

/// Something used up. Consumed from the **backpack** between encounters.
///
/// ⚠️ A plain [ConsumableDef] cannot be used in combat — that is what
/// [BeltableDef] is for. Splitting them means "can this be drunk mid-duel" is
/// a **type**, not a flag someone can forget to check (ITEMS §6b.3).
final class ConsumableDef extends ItemDef with Usable {
  @override
  final ItemEffect effect;

  const ConsumableDef({
    this.effect = ItemEffect.none,
    required super.id,
    required super.rarity,
    required super.lore,
    super.tradability,
    super.equipLevel,
    super.value,
    super.properName,
  });

  @override
  bool get isFungible => true;
}

/// A consumable that may be loaded onto the belt and used mid-duel.
final class BeltableDef extends ItemDef with Beltable, Usable {
  @override
  final ItemEffect effect;

  const BeltableDef({
    this.effect = ItemEffect.none,
    required super.id,
    required super.rarity,
    required super.lore,
    super.tradability,
    super.equipLevel,
    super.value,
    super.properName,
  });

  @override
  bool get isFungible => true;
}

/// Bulk crafting input — wood, cloth, ore, herbs, hides.
final class MaterialDef extends ItemDef with Salvageable {
  /// Which of the six skills consumes it.
  final CraftSkill skill;

  /// Material tier, which is what drives the level band it serves.
  final int tier;

  @override
  final List<SalvageYield> salvage;

  const MaterialDef({
    required super.id,
    required super.rarity,
    required super.lore,
    required this.skill,
    required this.tier,
    this.salvage = const [],
    super.tradability,
    super.equipLevel,
    super.value,
    super.properName,
  });

  @override
  bool get isFungible => true;
}

/// The elemental currency ladder (ITEMS §6).
final class MoteDef extends ItemDef {
  /// Null means a neutral mote, which converts into an element (§6.0b).
  final MagicElement? element;
  final MoteTier tier;

  const MoteDef({
    required super.id,
    required super.rarity,
    required super.lore,
    required this.tier,
    this.element,
    super.tradability,
    super.equipLevel,
    super.value,
    super.properName,
  });

  @override
  bool get isFungible => true;
}

/// A rare part for a Tier III/IV set piece (ITEMS §3.5).
///
/// ⚠️ **Deliberately NOT a [MaterialDef].** Components are Bound, never
/// gathered and never bulk. Modelling them as materials would let
/// bulk-crafting logic reach them, which is exactly the loophole §6c closed by
/// binding them in the first place.
final class ComponentDef extends ItemDef {
  /// The enemy or zone this drops from, for the Collector log.
  final String sourceId;

  const ComponentDef({
    required super.id,
    required super.rarity,
    required super.lore,
    required this.sourceId,
    super.equipLevel,
    super.value,
  }) : super(tradability: Tradability.bound);

  @override
  bool get isFungible => true;
}

/// A gathering tool (ITEMS §9b.7a). Carries a quality roll, so not fungible.
final class ToolDef extends ItemDef with Salvageable {
  final CraftSkill skill;
  final int tier;

  @override
  final List<SalvageYield> salvage;

  const ToolDef({
    required super.id,
    required super.rarity,
    required super.lore,
    required this.skill,
    required this.tier,
    this.salvage = const [],
    super.tradability,
    super.equipLevel,
    super.value,
    super.properName,
  });

  @override
  bool get isFungible => false;
}

/// Socketable (ITEMS §6d).
final class GemDef extends ItemDef {
  final MagicElement? element;
  final ItemModifiers modifiers;

  const GemDef({
    required super.id,
    required super.rarity,
    required super.lore,
    this.element,
    this.modifiers = ItemModifiers.none,
    super.tradability,
    super.equipLevel,
    super.value,
    super.properName,
  });

  @override
  bool get isFungible => true;
}

/// A tier-gate item.
///
/// ⚠️ **Every gate in `world.dart` is currently a prose string with no item
/// behind it** — the proofs, the Kinetic Sigil, the Celestial Totem, the
/// Ethereal key fragments and the Concordant Crown. This kind exists so they
/// have somewhere to land.
final class KeyDef extends ItemDef {
  /// The location id this opens.
  final String gates;

  const KeyDef({
    required super.id,
    required super.rarity,
    required super.lore,
    required this.gates,
    super.equipLevel,
    super.properName,
  }) : super(tradability: Tradability.bound, value: 0);

  @override
  bool get isFungible => true;
}
