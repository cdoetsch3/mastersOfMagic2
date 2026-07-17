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
      effect: DamageEffect(8, 11, hits: 4));
  static const barrage = Spell(
      id: 'barrage', name: 'Barrage', chargeCost: 1, xCost: true, priority: 9,
      effect: BarrageEffect(10, 12));

  // Lifesteal (priority 9) — heals for damage dealt to health, not shields.
  static const sap = Spell(
      id: 'sap', name: 'Sap', chargeCost: 1, priority: 9,
      effect: DamageEffect(9, 11, lifesteal: 1));
  static const leech = Spell(
      id: 'leech', name: 'Leech', chargeCost: 3, priority: 9,
      effect: DamageEffect(25, 31, lifesteal: 1));
  static const drain = Spell(
      id: 'drain', name: 'Drain', chargeCost: 5, priority: 9,
      effect: DamageEffect(47, 58, lifesteal: 1));

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

  // Aux (priority 7) — investments: casting ends your cycle, so the buff
  // pays off in a future cycle.
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

  // Charge control: wipes all of the opponent's charge (no damage). At
  // priority 7 it beats a priority-9 Barrage/Overload, fizzling them.
  static const discharge = Spell(
      id: 'discharge', name: 'Discharge', chargeCost: 3, priority: 7,
      effect: DischargeEffect());

  // Punish: ~8-12 damage per point of the ENEMY's charge (a full attack —
  // respects shields, benefits from Empower/Phase). Read live at resolution.
  static const overload = Spell(
      id: 'overload', name: 'Overload', chargeCost: 2, priority: 7,
      effect: OverloadEffect(8, 12));

  static const List<Spell> all = [
    flick, bolt, blast, surge, ruin, cataclysm,
    jolt,
    flurry, volley, barrage,
    sap, leech, drain,
    ward, aegis, bulwark, rampart, sanctuary, barrier,
    empower, quicken, phase,
    hasty, discharge, overload,
  ];

  static Spell byId(String id) => all.firstWhere((s) => s.id == id);
}
