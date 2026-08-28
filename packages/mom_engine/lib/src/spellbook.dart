import 'bank_dots.dart';
import 'bank_stances.dart';
import 'spell.dart';

/// The starter spell catalog.
///
/// All damage/shield numbers are TENTATIVE balance values — tune via the
/// AI-vs-AI simulator. Design rules:
///  - Attacks scale super-linearly with charge (rewarding the risk of
///    charging longer).
///  - Shields scale LINEARLY (midpoint 15 x charge: a 4-charge shield is
///    exactly twice a 2-charge shield), with a tiny overlap between the top
///    of a max-roll same-charge attack and a min-roll shield.
///  - Multi-hit lands slightly above flat damage in total; lifesteal
///    slightly below.
abstract final class Spellbook {
  // Flat damage (priority 9, regular). All damage rolls min–max (~10–15%).
  static const flick = Spell(
      id: 'flick', name: 'Flick', chargeCost: 0, priority: 5,
      effect: DamageEffect(4, 6));
  static const bolt = Spell(
      id: 'bolt', name: 'Bolt', chargeCost: 1, priority: 9,
      effect: DamageEffect(11, 14));
  static const blast = Spell(
      id: 'blast', name: 'Blast', chargeCost: 2, priority: 9,
      effect: DamageEffect(20, 26));
  static const surge = Spell(
      id: 'surge', name: 'Surge', chargeCost: 3, priority: 9,
      effect: DamageEffect(31, 39));
  static const ruin = Spell(
      id: 'ruin', name: 'Ruin', chargeCost: 4, priority: 9,
      effect: DamageEffect(44, 53));
  static const cataclysm = Spell(
      id: 'cataclysm', name: 'Cataclysm', chargeCost: 5, priority: 9,
      effect: DamageEffect(59, 72));

  // Quick attacks (priority 5): cheaper damage that beats aux/regular spells
  // to the punch but not shields. Jolt also seizes Haste.
  static const jolt = Spell(
      id: 'jolt', name: 'Jolt', chargeCost: 2, priority: 5,
      grantsHaste: true, effect: DamageEffect(14, 18));

  // Multi-hit (priority 9) — each hit rolls independently.
  static const flurry = Spell(
      id: 'flurry', name: 'Flurry', chargeCost: 1, priority: 9,
      effect: DamageEffect(3, 5, hits: 3));
  static const volley = Spell(
      id: 'volley', name: 'Volley', chargeCost: 3, priority: 9,
      effect: DamageEffect(7, 10, hits: 4));
  static const barrage = Spell(
      id: 'barrage', name: 'Barrage', chargeCost: 1, xCost: true, priority: 9,
      effect: BarrageEffect(7, 10));

  // Lifesteal (priority 9) — heals for HALF the health the target actually
  // LOST, not half the damage rolled (playtest ruling). Overkill pays
  // nothing: a 16 into a 10hp mage heals 5, not 8. Never heals for damage a
  // shield soaked (only [DamageEvent.toHp] counts, and that is now the
  // clamped, genuinely-lost figure), and the Astral Alignment pierce does
  // count, since that lands on health.
  static const _lifestealRate = 0.5;
  static const sap = Spell(
      id: 'sap', name: 'Sap', chargeCost: 1, priority: 9,
      effect: DamageEffect(9, 11, lifesteal: _lifestealRate));
  static const leech = Spell(
      id: 'leech', name: 'Leech', chargeCost: 3, priority: 9,
      effect: DamageEffect(25, 31, lifesteal: _lifestealRate));
  static const drain = Spell(
      id: 'drain', name: 'Drain', chargeCost: 5, priority: 9,
      effect: DamageEffect(47, 58, lifesteal: _lifestealRate));

  // Shields (priority 3) — linear: midpoint 15 x charge, rolled.
  static const ward = Spell(
      id: 'ward', name: 'Ward', chargeCost: 1, priority: 3,
      effect: ShieldEffect(13, 17));
  static const aegis = Spell(
      id: 'aegis', name: 'Aegis', chargeCost: 2, priority: 3,
      effect: ShieldEffect(26, 34));
  static const bulwark = Spell(
      id: 'bulwark', name: 'Bulwark', chargeCost: 3, priority: 3,
      effect: ShieldEffect(39, 51));
  static const rampart = Spell(
      id: 'rampart', name: 'Rampart', chargeCost: 4, priority: 3,
      effect: ShieldEffect(52, 68));
  static const sanctuary = Spell(
      id: 'sanctuary', name: 'Sanctuary', chargeCost: 5, priority: 3,
      effect: ShieldEffect(65, 85));
  static const barrier = Spell(
      id: 'barrier', name: 'Barrier', chargeCost: 2, priority: 3,
      effect: BarrierEffect());

  // Aux-DEFENSE (priority 7, [SpellPriority.auxDefense]) — self-targeting
  // investments: casting ends your cycle, so the buff pays off in a future
  // one. Enemy-targeting aux lives one rung slower, at 8 (see Discharge).
  static const empower = Spell(
      id: 'empower', name: 'Empower', chargeCost: 3, priority: 7,
      effect: EmpowerEffect(2));
  static const quicken = Spell(
      id: 'quicken', name: 'Quicken', chargeCost: 2, priority: 7,
      effect: QuickenEffect(2));
  static const phase = Spell(
      id: 'phase', name: 'Phase', chargeCost: 3, priority: 7,
      effect: PhaseEffect());

  // Initiative: seizes Haste for free.
  static const hasty = Spell(
      id: 'hasty', name: 'Hasty', chargeCost: 0, priority: 7,
      grantsHaste: true, effect: HasteEffect());

  // Charge control: wipes all of the opponent's charge (no damage). Still
  // beats the priority-9 attacks — Barrage and Overload both fizzle against a
  // well-timed Discharge.
  //
  // ⭐ Priority 8, the aux-OFFENSE lane (ruling, 2026-08-26 — TYPE_EFFECTS
  // §7a). It points at the enemy and deals no damage, which is the exact
  // definition of the new lane; sitting at 7 gave it the timing of a
  // self-buff. What actually changes: an opponent's self-targeting aux — a
  // Hasty, a Hallow, an Empower, a stance from the banked generation — now
  // resolves BEFORE the Discharge that would have raced it. Their commitment
  // lands; your interference lands after. Attacks are untouched.
  static const discharge = Spell(
      id: 'discharge', name: 'Discharge', chargeCost: 2,
      priority: SpellPriority.auxOffense,
      effect: DischargeEffect());

  // Punish: ~7-11 damage per point of the ENEMY's charge (a full attack —
  // respects shields, benefits from Empower/Phase).
  //
  // ⭐ Priority 9, the regular-attack slot (ruling, 2026-07-28, re-affirmed by
  // TYPE_EFFECTS §7a's "Overload → 9" 2026-08-26 — it had already moved off 7
  // by then, so §7a's reclassification is a no-op here and the spell's timing
  // is unchanged). It is an offensive spell and belongs on the same clock as
  // one; sitting at 7 gave it a quick-spell's timing on a full attack's
  // payload. At 9 it reads the board *after* the turn's shields and quick
  // attacks have landed, so punishing a charge bar means punishing one its
  // owner chose to keep.
  static const overload = Spell(
      id: 'overload', name: 'Overload', chargeCost: 2,
      priority: SpellPriority.attack,
      effect: OverloadEffect(7, 11));

  // Status defence: banks Grace (blocks the next debuff). Element-neutral, so
  // any loadout can answer a status deck without playing Sanctus. Priority 7,
  // so quick attacks land their proc before Grace exists — it's pre-emptive.
  static const hallow = Spell(
      id: 'hallow', name: 'Hallow', chargeCost: 1, priority: 7,
      effect: HallowEffect());

  // ======================================================================
  // ⬇⬇ BANKED STAT STANCES — TYPE_EFFECTS §7a "STATUS SETS" ⬇⬇
  // Ten self-targeting aux spells, five sets, two price points each. Every
  // one grants a status through the derivation seam; none of them touches a
  // base stat. See bank_stances.dart for the statuses and the replace rule.
  //
  // ⚠️ **Deliberately NOT in [all] yet** — see the note above that list.
  // ======================================================================

  /// **Lightfoot** — dodge. The cheap stance and the long one.
  static const lightfoot = Spell(
      id: 'lightfoot', name: 'Lightfoot', chargeCost: 2,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(
          statusId: 'lightfoot', grant: LightfootStatus.lightfoot));
  static const twinkleToes = Spell(
      id: 'twinkleToes', name: 'Twinkle Toes', chargeCost: 4,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(
          statusId: 'lightfoot', grant: LightfootStatus.twinkleToes));

  /// **Divert** — the deflect pair (activation %, damage deflected %).
  static const glance = Spell(
      id: 'glance', name: 'Glance', chargeCost: 1,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(statusId: 'divert', grant: DivertStatus.glance));
  static const divert = Spell(
      id: 'divert', name: 'Divert', chargeCost: 3,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(statusId: 'divert', grant: DivertStatus.divert));

  /// **Truesight** — own accuracy. ⭐ Both granters also cleanse Blind on cast
  /// (§7a): the element lane's blinder gets an element-agnostic answer, and it
  /// costs one charge.
  static const _cleansesBlind =
      (statusId: 'blind', momentId: blindLiftedStatusId);
  static const truesight = Spell(
      id: 'truesight', name: 'Truesight', chargeCost: 1,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(
          statusId: 'truesight',
          grant: TruesightStatus.truesight,
          cleanses: _cleansesBlind));
  static const hawkeye = Spell(
      id: 'hawkeye', name: 'Hawkeye', chargeCost: 3,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(
          statusId: 'truesight',
          grant: TruesightStatus.hawkeye,
          cleanses: _cleansesBlind));

  /// **Keen** — crit chance.
  static const keen = Spell(
      id: 'keen', name: 'Keen', chargeCost: 2,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(statusId: 'keen', grant: KeenStatus.keen));
  static const ardent = Spell(
      id: 'ardent', name: 'Ardent', chargeCost: 4,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(statusId: 'keen', grant: KeenStatus.ardent));

  /// **Heavyhand** — crit damage.
  static const heavyhand = Spell(
      id: 'heavyhand', name: 'Heavyhand', chargeCost: 2,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(
          statusId: 'heavyhand', grant: HeavyhandStatus.heavyhand));
  static const overkill = Spell(
      id: 'overkill', name: 'Overkill', chargeCost: 4,
      priority: SpellPriority.auxDefense,
      effect: StanceEffect(
          statusId: 'heavyhand', grant: HeavyhandStatus.overkill));

  /// The ten stat stances, in set order (cheap price point first).
  ///
  /// ⚠️ **A separate list, not [all] — a deliberate gate, not an oversight.**
  /// Everything in [all] is a spell the APP ships: `tooltip_consistency_test`
  /// requires a description and an icon in `lib/game/element_style.dart` for
  /// every entry, and the loadout, shop and spellbook screens read it. Those
  /// are the app lane's to write, and the unlock table (§7a's draft) is still
  /// unruled. Promoting the bank is therefore one line — fold this list into
  /// [all] — taken once the player-facing copy lands, and until then the
  /// engine is fully built and testable without half-describing ten spells to
  /// players.
  static const List<Spell> stances = [
    lightfoot, twinkleToes,
    glance, divert,
    truesight, hawkeye,
    keen, ardent,
    heavyhand, overkill,
  ];
  // ⬆⬆ END BANKED STAT STANCES ⬆⬆

  // =======================================================================
  // BANK — DoT engine & debuff suite (TYPE_EFFECTS_DESIGN.md §7a)
  // =======================================================================
  // ⭐ One contiguous block, and a list of its own. These are built and tested
  // but not yet in [all], because everything in [all] must carry player-facing
  // copy — a description, an icon, a tooltip arm — that lives in the Flutter
  // app and that `tooltip_consistency_test` enforces. The app lane folds the
  // bank in when that copy exists, by making [all] `[...shipped, ...bankDots]`.
  // [byId] already finds them, so netcode and the engine can address a bank
  // spell today.
  //
  // Two lanes:
  //  - **Attacks, [SpellPriority.attack]** — ordinary to-hit and crit rules on
  //    the HIT; the DoT rider is a debuff, so Grace can eat the rider and
  //    never the damage.
  //  - **[SpellPriority.auxOffense]** — enemy-facing but not attacks: slower
  //    than aux-defence, faster than a real attack, and no to-hit roll at all.

  /// The quick bleed: fully paid out in three ticks, the first on the turn it
  /// lands. ~10–13 up front plus 21 over time for 2 charge — a surplus over
  /// Blast, and the delay is its price.
  static const agony = Spell(
      id: 'agony', name: 'Agony', chargeCost: 2,
      priority: SpellPriority.attack,
      effect: DotAttackEffect(10, 13,
          dotId: 'agony', dotName: 'Agony', damagePerTick: 7, ticks: 3));

  /// The long burn: 45 over nine turns behind a small hit. The biggest surplus
  /// in the book and the longest exposure to the duel ending first — Scour is
  /// how you collect early.
  static const torment = Spell(
      id: 'torment', name: 'Torment', chargeCost: 3,
      priority: SpellPriority.attack,
      effect: DotAttackEffect(8, 10,
          dotId: 'torment', dotName: 'Torment', damagePerTick: 5, ticks: 9));

  /// Feeds whatever is burning: +3 ticks to EVERY DoT on the target, Ignite
  /// included, behind a small hit.
  static const fester = Spell(
      id: 'fester', name: 'Fester', chargeCost: 1,
      priority: SpellPriority.auxOffense,
      effect: FesterEffect(damage: 5, bonusTicks: 3));

  /// The collection agency: every DoT resolves all its remaining ticks now, as
  /// one packet, and is consumed.
  static const scour = Spell(
      id: 'scour', name: 'Scour', chargeCost: 1,
      priority: SpellPriority.auxOffense,
      effect: ScourEffect());

  /// Murk set — the enemy's accuracy, taxed. Miasma is the tier-2 price point;
  /// one status, last cast wins.
  static const murk = Spell(
      id: 'murk', name: 'Murk', chargeCost: 1,
      priority: SpellPriority.auxOffense,
      effect: DebuffGrantEffect(BankDebuff.murk, magnitude: -15, turns: 10));
  static const miasma = Spell(
      id: 'miasma', name: 'Miasma', chargeCost: 3,
      priority: SpellPriority.auxOffense,
      effect: DebuffGrantEffect(BankDebuff.murk, magnitude: -25, turns: 20));

  /// Wither set — the anti-heal tax. ⭐ Ruled: the status is ALWAYS −50%;
  /// Atrophy buys triple the DURATION, never more depth.
  static const wither = Spell(
      id: 'wither', name: 'Wither', chargeCost: 2,
      priority: SpellPriority.auxOffense,
      effect: DebuffGrantEffect(BankDebuff.wither,
          magnitude: WitherStatus.witherPercent, turns: 10));
  static const atrophy = Spell(
      id: 'atrophy', name: 'Atrophy', chargeCost: 4,
      priority: SpellPriority.auxOffense,
      effect: DebuffGrantEffect(BankDebuff.wither,
          magnitude: WitherStatus.witherPercent, turns: 30));

  /// Binary: their heals become damage. Supersedes Wither while both are up.
  static const blight = Spell(
      id: 'blight', name: 'Blight', chargeCost: 4,
      priority: SpellPriority.auxOffense,
      effect: DebuffGrantEffect(BankDebuff.blight, turns: 20));

  /// The meta-leash on stance-stacking: strips the target's buffs.
  static const dispel = Spell(
      id: 'dispel', name: 'Dispel', chargeCost: 4,
      priority: SpellPriority.auxOffense,
      effect: DispelEffect());

  /// The turtle-breaker: no damage, but shields, Barrier and Divert all go.
  /// Priced at 5 deliberately, so Discharge can keep it off the table.
  static const shatter = Spell(
      id: 'shatter', name: 'Shatter', chargeCost: 5,
      priority: SpellPriority.auxOffense,
      effect: ShatterEffect());

  /// The banked DoT/debuff generation — see the block above.
  static const List<Spell> bankDots = [
    agony, torment,
    fester, scour,
    murk, miasma,
    wither, atrophy, blight,
    dispel, shatter,
  ];
  // ⬆⬆ END BANKED DoT / DEBUFF SUITE ⬆⬆

  /// The spells the game ships to players. ⚠️ See [stances] and [bankDots]:
  /// the banked generations are built but not yet listed here, because
  /// everything in this list needs app-side copy the engine lane does not own.
  static const List<Spell> all = [
    flick, bolt, blast, surge, ruin, cataclysm,
    jolt,
    flurry, volley, barrage,
    sap, leech, drain,
    ward, aegis, bulwark, rampart, sanctuary, barrier,
    empower, quicken, phase,
    hasty, discharge, overload, hallow,
  ];

  /// Every spell the engine can resolve — the shipped book plus every banked
  /// lane. ⚠️ Lookup only ([byId], netcode): it is deliberately NOT what an AI
  /// draws from, and not what the app offers a player.
  static const List<Spell> everything = [...all, ...stances, ...bankDots];

  static Spell byId(String id) => everything.firstWhere((s) => s.id == id);
}
