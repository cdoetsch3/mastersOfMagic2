/// Putting things on, taking things off, and what it all adds up to.
///
/// ⭐ **Pure functions over the profile's own state** — the `equipped` map
/// (slot → instance id) and the instance pool. `GameState` owns the mutation
/// and persistence; this file owns the rules, so the rules are testable
/// without a profile, a duel, or a widget.
library;

import 'package:mom_engine/mom_engine.dart';

import 'enchants.dart';
import 'item_catalogue.dart';
import 'item_def.dart';
import 'item_instance.dart';
import 'item_naming.dart';

abstract final class Equipping {
  /// What one **owned** item actually grants: the definition's base stats as
  /// its own quality roll made them (`ItemModifiers.scaledBy`).
  ///
  /// ⭐ **THE resolution seam.** An `ItemDef` says what an item is worth in
  /// the abstract; only an [ItemInstance] knows what *this* one is worth. Every
  /// reader — the duel's totals, the equip screen, the item dialog — comes
  /// through here, so a scaling rule changed once is changed everywhere and no
  /// two screens can quote different numbers for the same wand.
  ///
  /// ⚠️ Anything that is not equipment grants nothing: gems carry modifiers
  /// too, but a socketed gem is resolved through the *host* item's sockets,
  /// not by wearing the gem.
  ///
  /// ⭐ **The overlay** (ENCHANTING_DESIGN §1, §4, §5): the def's stats scaled
  /// by quality, **plus** [enchantOverlay] (the enchant, or a bare aspect's
  /// Lesser affinity), **plus** every socket's [socketOverlays]. ⚠️ Quality
  /// scales the def's share ONLY — an enchant is the enchanter's work and a
  /// gem the jeweller's, not the smith's, so a Rough staff and a Master staff
  /// wearing the same Charred (Standard) gain the same +8.
  ///
  /// ⚠️ **No clamp here.** The overlay sums honestly past every combat cap;
  /// `CombatClamps` clamps the OUTPUT at resolution (§7a, ruled 2026-08-26), so
  /// a ninth Greater Geo enchant is worthless on the field and still honest
  /// on the panel.
  static ItemModifiers modifiersOf(ItemDef? def, [ItemInstance? instance]) {
    if (def is! EquipmentDef) return ItemModifiers.none;
    final base = def.modifiers.scaledBy(instance?.quality);
    if (instance == null) return base;
    var sum = base + enchantOverlay(instance);
    for (final gem in socketOverlays(def, instance)) {
      if (gem != null) sum = sum + gem;
    }
    return sum;
  }

  /// What [instance]'s enchant grants — or, with no enchant, what its bare
  /// aspect grants.
  ///
  /// - **Enchanted** → the enchant's `grants` (stats, plus the proc at
  ///   Greater). An `enchantId` the table does not hold — the reserved
  ///   `unbind`, or a save from a newer build — grants nothing, and ⚠️ does
  ///   NOT fall back to the aspect: an enchant replaces the aspect (§4.4),
  ///   whether or not this build can read it.
  /// - **Aspected, not enchanted** (a §4.4 drop) → its element's **Lesser**
  ///   affinity: "pre-enchanted sidegrades, weaker than a real enchant".
  /// - Neither → nothing.
  static ItemModifiers enchantOverlay(ItemInstance instance) {
    if (instance.enchantId != null) {
      return Enchants.tryById(instance.enchantId)?.grants ?? ItemModifiers.none;
    }
    final aspect = instance.aspect;
    if (aspect == null) return ItemModifiers.none;
    return Enchants.of(aspect, EnchantTier.lesser).grants;
  }

  /// What each of [def]'s sockets grants on [instance], index for index —
  /// `def.socketCount` entries, null for an empty socket.
  ///
  /// ⭐ **Diminishing repeats** (§5.1, ITEMS §6d.3 fix 2): the FIRST copy of a
  /// gem id on a piece gives its full modifiers; the second and every later
  /// copy gives [ItemModifiers.halved] (integer, floor). "First" is socket
  /// order, so the numbers read left to right exactly as the cells do.
  ///
  /// ⚠️ Per PIECE, never per wardrobe — the same Lesser Pyro gem in a hat and
  /// in a ring is two first copies. ⚠️ A socket past `socketCount`, an empty
  /// one, or an id that is not a [GemDef] grants nothing: the instance does
  /// not know its catalogue (see `ItemInstance.withSocket`), so this is where
  /// a bad write is made harmless.
  static List<ItemModifiers?> socketOverlays(
    EquipmentDef def,
    ItemInstance instance,
  ) {
    final seen = <String>{};
    return [
      for (var i = 0; i < def.socketCount; i++)
        switch (i < instance.socketed.length
            ? ItemCatalogue.tryById(instance.socketed[i])
            : null) {
          final GemDef gem =>
            seen.add(gem.id) ? gem.modifiers : gem.modifiers.halved(),
          _ => null,
        },
    ];
  }

  /// The sum of every worn item's modifiers.
  ///
  /// ⭐ **This is THE number the whole system feeds** — the duel reads it, the
  /// belt sizes itself off it, and the Inventory screen shows it. A dangling
  /// instance id contributes nothing rather than throwing: the profile guards
  /// against them, and a stats panel is the wrong place to crash.
  ///
  /// ⚠️ **Resolved, then summed** — quality scales each piece on its own,
  /// because scaling the sum would let one Master ring lift a whole wardrobe.
  static ItemModifiers totals({
    required Map<EquipSlot, String> equipped,
    required Map<String, ItemInstance> instances,
  }) {
    var sum = ItemModifiers.none;
    for (final id in equipped.values) {
      final instance = instances[id];
      final def = ItemCatalogue.tryById(instance?.defId ?? '');
      sum = sum + modifiersOf(def, instance);
    }
    return sum;
  }

  /// Why [def] cannot be equipped right now — null means it can.
  ///
  /// ⭐ Player-facing strings, decided here so every code path refuses with
  /// the same words.
  static String? refusal(ItemDef? def, {required int playerLevel}) {
    if (def is! EquipmentDef) return 'That cannot be worn.';
    if (def.equipLevel > playerLevel) {
      return 'Requires level ${def.equipLevel}.';
    }
    return null;
  }

  /// What a player is told when an offhand meets a two-handed main hand.
  ///
  /// ⭐ **One string, three readers** — [handsRefusal], and through it both
  /// `GameState` equip paths and the Inventory tab's greyed-out Equip button.
  /// A screen that explains the rule in its own words is a screen that can
  /// drift from the rule.
  static const String bothHandsMessage = 'Both hands are on your staff.';

  /// What a player is told when a two-handed main hand has nowhere to put the
  /// offhand it displaces. ⚠️ Names the fix, not just the problem: the pack is
  /// full *and* an offhand is coming off, and "Your pack is full." alone would
  /// send them to the wrong screen.
  static const String noRoomForOffhandMessage =
      'Your pack is full — take off your offhand first.';

  /// Why [def] cannot be worn **alongside what is already in the hands** —
  /// null when it can (ruling, Christian 2026-09-21).
  ///
  /// ⭐ **Separate from [refusal] on purpose.** [refusal] judges an item
  /// against the *player* (level, kind) and needs nothing but the def; this
  /// one judges it against the *wardrobe*, which [refusal]'s callers do not
  /// all have. Splitting them is what lets the Inventory tab grey a button
  /// with the identical words `GameState` would refuse with, instead of
  /// discovering the refusal only after the tap.
  ///
  /// ⚠️ **Only an offhand is ever refused here.** The other direction — a
  /// two-hander going on over a worn offhand — is allowed and *displaces* the
  /// offhand into the pack, because refusing there would make a staff
  /// unequippable rather than expensive. That swap needs storage, which is a
  /// `GameState` question, not a pure one.
  static String? handsRefusal({
    required EquipmentDef def,
    required EquipmentDef? wornMainHand,
  }) {
    if (def.slot != EquipSlot.offHand) return null;
    if (wornMainHand?.twoHanded ?? false) return bothHandsMessage;
    return null;
  }

  /// The slot as the player reads it, in the one place that decides the
  /// wording.
  ///
  /// ⭐ **A two-hander says so**: 'Main hand · two-handed', so the player
  /// meets the rule on the item that causes it rather than on the refusal
  /// that enforces it.
  static String slotLabel(EquipmentDef def) =>
      def.twoHanded ? '${slotName(def.slot)} · two-handed' : slotName(def.slot);

  /// The player-facing name of an equipment slot. ⚠️ Spelled out rather than
  /// prettified from [EquipSlot.name]: 'robeTop' does not become 'Robe top' by
  /// any rule worth writing, and a slot added without a word here should read
  /// oddly in review, not silently in the game.
  static String slotName(EquipSlot slot) => switch (slot) {
    EquipSlot.hat => 'Hat',
    EquipSlot.robeTop => 'Robe top',
    EquipSlot.robeBottom => 'Robe bottom',
    EquipSlot.gloves => 'Gloves',
    EquipSlot.boots => 'Boots',
    EquipSlot.neck => 'Neck',
    EquipSlot.ring => 'Ring',
    EquipSlot.mainHand => 'Main hand',
    EquipSlot.offHand => 'Off hand',
    EquipSlot.belt => 'Belt',
  };

  /// The stat lines a worn item (or a total) shows, in a fixed order.
  ///
  /// ⭐ **One writer for every stats panel** — built from the modifiers so a
  /// renamed or added field shows up everywhere or nowhere, never in one
  /// screen and not another. Only non-zero lines are emitted (the export
  /// makes the same choice, for the same reason).
  ///
  ///
  /// 📝 Ruling 2026-09-30: the rolled number ONLY. Until then the dialog
  /// passed the definition's modifiers alongside so a quality-scaled potency
  /// line could read '(base 10%) +14%'; Christian asked for the parenthesis
  /// to go — the Value line already teaches that quality moves a belt, and
  /// the worked example under the stats shows the roll in use.
  static List<String> describe(ItemModifiers m) => [
    if (m.maxHpBonus != 0) '+${m.maxHpBonus} max health',
    if (m.damagePerCast != 0) '+${m.damagePerCast} damage per cast',
    if (m.damagePerCharge != 0) '+${m.damagePerCharge} damage per charge spent',
    if (m.accuracyBonus != 0) '+${m.accuracyBonus}% accuracy',
    if (m.critChance != 0) '+${m.critChance}% crit chance',
    if (m.critDamage != 0) '+${m.critDamage}% crit damage',
    if (m.dodge != 0) '+${m.dodge}% dodge',
    if (m.deflectChance != 0) '+${m.deflectChance}% deflect chance',
    if (m.deflectAmount != 0) '${m.deflectAmount}% deflected',
    if (m.shieldStrengthPercent != 0)
      '+${m.shieldStrengthPercent}% shield strength',
    if (m.healingReceivedPercent != 0)
      '+${m.healingReceivedPercent}% healing received',
    if (m.regrowPercent != 0) 'Regrow ${m.regrowPercent}% health each turn',
    if (m.beltSlots != 0) '+${m.beltSlots} belt slots',
    if (m.consumablePotencyPercent != 0)
      potencyLine(m.consumablePotencyPercent),
    for (final e in MagicElement.values)
      if (m.gearProcs.contains(e)) procLine(e),
  ];

  /// A gear proc's stat line: '15% on hit: Ignite' (ENCHANTING §4.1a).
  ///
  /// ⭐ The 15 is [ElementTuning.gearProcPercent], the number the engine rolls
  /// against — never typed here.
  static String procLine(MagicElement element) =>
      '${ElementTuning.gearProcPercent}% on hit: '
      '${Enchants.procEffectName(element)}';

  /// The stat lines for one OWNED piece — the item dialog's (ENCHANTING §7).
  ///
  /// ⭐ The def's own lines as quality made them ([describe]), then one line
  /// for the element axis, then one line per socket:
  ///
  /// - `Enchant: Charred (Standard) · +8% crit damage`
  /// - `Aspect: Charred · +4% crit damage` — a §4.4 drop with no enchant
  /// - `Socket: Lesser Pyro Gem · +2% crit damage`
  /// - `Socket: Lesser Pyro Gem · +1% crit damage (repeat, half)`
  /// - `Socket: empty`
  ///
  /// ⚠️ **[describe] stays for the modifier-only callers** (the "From
  /// equipment" panel and every total) — this one needs the instance. Each
  /// overlay line prints what [modifiersOf] actually adds, read through
  /// [enchantOverlay] and [socketOverlays], so the dialog and the totals can
  /// never quote different numbers for the same piece.
  static List<String> describeInstance(
    EquipmentDef def,
    ItemInstance instance,
  ) {
    String joined(ItemModifiers m) => describe(m).join(', ');
    final enchant = Enchants.tryById(instance.enchantId);
    final aspect = instance.aspect;
    final overlay = enchantOverlay(instance);
    final sockets = socketOverlays(def, instance);
    final seen = <String>{};
    return [
      ...describe(def.modifiers.scaledBy(instance.quality)),
      if (enchant != null)
        'Enchant: ${enchant.label} · ${joined(overlay)}'
      else if (instance.enchantId == null && aspect != null)
        'Aspect: ${aspectPrefixes[aspect.name]} · ${joined(overlay)}',
      for (var i = 0; i < sockets.length; i++)
        switch (sockets[i]) {
          null => 'Socket: empty',
          final m => _socketLine(
            ItemCatalogue.byId(instance.socketed[i]),
            m,
            repeat: !seen.add(instance.socketed[i]),
          ),
        },
    ];
  }

  static String _socketLine(
    ItemDef gem,
    ItemModifiers m, {
    required bool repeat,
  }) {
    final line =
        'Socket: ${ItemCatalogue.displayName(gem)} · '
        '${describe(m).join(', ')}';
    return repeat ? '$line (repeat, half)' : line;
  }

  /// The consumable-potency stat line: 'Consumable potency +14%'.
  ///
  /// ⚠️ The ROLLED number, with no '(base 10%)' beside it (ruling
  /// 2026-09-30, reversing 2026-09-25's parenthesis). Quality's effect on a
  /// belt is shown by the example line under the stats, not restated here.
  static String potencyLine(int percent) {
    final signed = '${percent >= 0 ? '+' : ''}$percent%';
    return 'Consumable potency $signed';
  }

  /// The def id [potencyExample] quotes — the first Draught in the game.
  static const potencyExampleId = 'sapwort_draught';

  /// One worked example under a belt's stats: 'A Sapwort Draught heals
  /// 30 → 34 with this belt.' — or null when [m] carries no potency.
  ///
  /// ⭐ **Computed, never typed.** The 30 is the shipped Draught's own
  /// `ItemEffect.heal`, and the arrow's far side is `applyPotency` — the same
  /// function both drinking doors call — so a retuned Draught or a retuned
  /// belt cannot leave this sentence quoting an old number.
  ///
  /// ⚠️ The BELT's number alone: the wearer's healing-received gear is left
  /// out on purpose, because this line describes the item in the hand, not
  /// the wardrobe — the same "an item shows its contribution" rule as
  /// [describe].
  static String? potencyExample(ItemModifiers m) {
    if (m.consumablePotencyPercent == 0) return null;
    final draught = ItemCatalogue.tryById(potencyExampleId);
    if (draught == null || draught is! Usable) return null;
    final heal = (draught as Usable).effect.heal;
    if (heal <= 0) return null;
    return 'A ${ItemCatalogue.displayName(draught)} heals '
        '$heal → ${applyPotency(heal, m.consumablePotencyPercent)} '
        'with this belt.';
  }

  /// Base hit chance, before any accuracy gear (ITEMS §9b.8).
  ///
  /// ⭐ **Derived, never typed twice.** The duel rolls against
  /// `ElementTuning.baseMissPercent`; if that dial moves, the number the player
  /// reads moves with it.
  static const int baseHitPercent = 100 - ElementTuning.baseMissPercent;

  /// What a crit deals with no crit-damage gear: 200% of the hit (ruling
  /// 2026-09-30, up from 150%).
  ///
  /// ⭐ **Derived, never typed twice** — the 100% a normal hit deals plus
  /// [MageState.baseCritDamage], the engine's own const. Retune the engine
  /// and the panel's "Crit damage" base moves with it.
  static const int baseCritDamagePercent = 100 + MageState.baseCritDamage;

  /// Every mage's crit chance before gear: 5% (ruling 2026-09-30).
  ///
  /// ⭐ **Derived, never typed twice** — the engine's
  /// [MageState.baseCritChance], the same number `DuelController` adds gear
  /// to. It makes crit chance a BASED stat on the panel, like accuracy.
  static const int baseCritChancePercent = MageState.baseCritChance;

  /// The same stats as [describe], but as the numbers the player **ends up
  /// with** — for the "From equipment" panel.
  ///
  /// ⭐ **An ITEM shows its contribution; the PANEL shows your totals**
  /// (designer, 2026-08-17). "+11 max health" answers "what does this hat do";
  /// it does not answer "how much health do I have", which is the question the
  /// panel is on screen to answer. So a stat with a real base prints
  /// `Max health 159 (+11)` — the total, with the gear's share still visible so
  /// the panel keeps saying what the gear is worth.
  ///
  /// ⚠️ **Only stats with a base get the total form.** Damage per cast, shield
  /// strength, healing received, regrow, belt slots and consumable potency
  /// have no baseline to add to (the mage starts at zero of each and nothing else grants them), so a
  /// "total" would be the bonus wearing a disguise. They keep `+N`.
  ///
  /// ⚠️ Still emits only non-zero lines, exactly like [describe]: this panel is
  /// "from equipment", and a full stat sheet listing everything gear does *not*
  /// touch would bury the four lines that matter.
  static List<String> describeTotals(ItemModifiers m, {required int level}) => [
    for (final l in statTotals(m, level: level))
      l.base != null
          ? '${l.label} ${l.total} (${l.bonus >= 0 ? '+' : ''}${l.bonus})'
          : l.label == 'Deflect amount'
          ? '${l.bonus}% deflected'
          : _legacyBonusLine(l),
  ];

  /// The old `+N stat` grammar, kept so [describeTotals]'s strings do not
  /// shift under the tests and dialogs that read them.
  static String _legacyBonusLine(GearStatLine l) => switch (l.label) {
    'Damage per cast' => '+${l.bonus} damage per cast',
    'Damage per charge' => '+${l.bonus} damage per charge spent',
    'Shield strength' => '+${l.bonus}% shield strength',
    'Healing received' => '+${l.bonus}% healing received',
    'Regrow' => 'Regrow ${l.bonus}% health each turn',
    'Belt slots' => '+${l.bonus} belt slots',
    'Consumable potency' => potencyLine(l.bonus),
    _ => '${l.label} ${l.total}',
  };

  /// [describeTotals]'s data, structured (ruling 2026-08-25, Format 1): the
  /// panel renders `label  TOTAL (base +bonus)` with the total large, the
  /// base muted and the bonus coloured by SIGN — green for a gift, red for a
  /// trade-away. ⚠️ [bonus] may be NEGATIVE by design: stat-lowering gear is
  /// planned, and this seam is why it will need zero UI work.
  ///
  /// [base] is null for the pure-gear stats (nothing else grants them — a
  /// "total" would be the bonus in disguise, so the panel prints the bonus
  /// AS the total and no parenthesis). Base-zero stats (dodge, deflect
  /// chance) keep a parenthesis but hide the pointless 0. ⚠️ Crit chance is
  /// NOT base-zero any more: every mage crits [baseCritChancePercent] (5%)
  /// since the 2026-09-30 ruling, so it prints `(5 +6) 11%` like accuracy.
  static List<GearStatLine> statTotals(ItemModifiers m, {required int level}) =>
      [
        if (m.maxHpBonus != 0)
          (
            label: 'Max health',
            total: '${MageState.scaledMaxHp(level) + m.maxHpBonus}',
            base: MageState.scaledMaxHp(level),
            bonus: m.maxHpBonus,
          ),
        if (m.accuracyBonus != 0)
          (
            label: 'Accuracy',
            total: '${baseHitPercent + m.accuracyBonus}%',
            base: baseHitPercent,
            bonus: m.accuracyBonus,
          ),
        if (m.critChance != 0)
          (
            label: 'Crit chance',
            total: '${baseCritChancePercent + m.critChance}%',
            base: baseCritChancePercent,
            bonus: m.critChance,
          ),
        if (m.critDamage != 0)
          (
            label: 'Crit damage',
            total: '${baseCritDamagePercent + m.critDamage}%',
            base: baseCritDamagePercent,
            bonus: m.critDamage,
          ),
        if (m.dodge != 0)
          (label: 'Dodge', total: '${m.dodge}%', base: 0, bonus: m.dodge),
        if (m.deflectChance != 0)
          (
            label: 'Deflect chance',
            total: '${m.deflectChance}%',
            base: 0,
            bonus: m.deflectChance,
          ),
        if (m.deflectAmount != 0)
          (
            label: 'Deflect amount',
            total: '${m.deflectAmount}%',
            base: null,
            bonus: m.deflectAmount,
          ),
        if (m.damagePerCast != 0)
          (
            label: 'Damage per cast',
            total: '${m.damagePerCast >= 0 ? '+' : ''}${m.damagePerCast}',
            base: null,
            bonus: m.damagePerCast,
          ),
        if (m.damagePerCharge != 0)
          (
            label: 'Damage per charge',
            total: '${m.damagePerCharge >= 0 ? '+' : ''}${m.damagePerCharge}',
            base: null,
            bonus: m.damagePerCharge,
          ),
        if (m.shieldStrengthPercent != 0)
          (
            label: 'Shield strength',
            total:
                '${m.shieldStrengthPercent >= 0 ? '+' : ''}'
                '${m.shieldStrengthPercent}%',
            base: null,
            bonus: m.shieldStrengthPercent,
          ),
        if (m.healingReceivedPercent != 0)
          (
            label: 'Healing received',
            total:
                '${m.healingReceivedPercent >= 0 ? '+' : ''}'
                '${m.healingReceivedPercent}%',
            base: null,
            bonus: m.healingReceivedPercent,
          ),
        if (m.regrowPercent != 0)
          (
            label: 'Regrow',
            total: '${m.regrowPercent}%/turn',
            base: null,
            bonus: m.regrowPercent,
          ),
        if (m.beltSlots != 0)
          (
            label: 'Belt slots',
            total: '${m.beltSlots >= 0 ? '+' : ''}${m.beltSlots}',
            base: null,
            bonus: m.beltSlots,
          ),
        // ⭐ Pure-gear, like healing received: the mage starts at 0 and only
        // a belt grants it (ruling 2026-09-25).
        if (m.consumablePotencyPercent != 0)
          (
            label: 'Consumable potency',
            total:
                '${m.consumablePotencyPercent >= 0 ? '+' : ''}'
                '${m.consumablePotencyPercent}%',
            base: null,
            bonus: m.consumablePotencyPercent,
          ),
        // ⭐ One line per gear proc (ENCHANTING §4.1a), pure-gear like
        // potency: the wardrobe's set is already deduplicated, so two Greater
        // Pyro pieces print ONE 'Ignite on hit 15%' — what the engine rolls.
        for (final e in MagicElement.values)
          if (m.gearProcs.contains(e))
            (
              label: '${Enchants.procEffectName(e)} on hit',
              total: '${ElementTuning.gearProcPercent}%',
              base: null,
              bonus: ElementTuning.gearProcPercent,
            ),
      ];
}

/// One stat line for the "From equipment" panel — see [Equipping.statTotals].
typedef GearStatLine = ({String label, String total, int? base, int bonus});
