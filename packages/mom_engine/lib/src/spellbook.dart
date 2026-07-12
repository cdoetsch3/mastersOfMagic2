import 'spell.dart';

/// The starter spell catalog.
///
/// All damage/shield numbers are TENTATIVE balance values — the shape
/// (shields ~25% stronger than same-charge attacks, multi-hit slightly above
/// flat damage in total, lifesteal slightly below) matters more than the
/// exact numbers. Tune via the AI-vs-AI simulator.
abstract final class Spellbook {
  // Flat damage (priority 9, regular).
  static const flick = Spell(
      id: 'flick', name: 'Flick', chargeCost: 0, priority: 9,
      effect: DamageEffect(5));
  static const bolt = Spell(
      id: 'bolt', name: 'Bolt', chargeCost: 1, priority: 9,
      effect: DamageEffect(12));
  static const blast = Spell(
      id: 'blast', name: 'Blast', chargeCost: 2, priority: 9,
      effect: DamageEffect(22));
  static const surge = Spell(
      id: 'surge', name: 'Surge', chargeCost: 3, priority: 9,
      effect: DamageEffect(34));
  static const ruin = Spell(
      id: 'ruin', name: 'Ruin', chargeCost: 4, priority: 9,
      effect: DamageEffect(48));
  static const cataclysm = Spell(
      id: 'cataclysm', name: 'Cataclysm', chargeCost: 5, priority: 9,
      effect: DamageEffect(65));

  // Quick attack (priority 5): cheaper damage that beats aux/regular spells
  // to the punch but not shields.
  static const jolt = Spell(
      id: 'jolt', name: 'Jolt', chargeCost: 2, priority: 5,
      effect: DamageEffect(16));

  // Multi-hit (priority 9).
  static const flurry = Spell(
      id: 'flurry', name: 'Flurry', chargeCost: 1, priority: 9,
      effect: DamageEffect(4, hits: 3));
  static const volley = Spell(
      id: 'volley', name: 'Volley', chargeCost: 3, priority: 9,
      effect: DamageEffect(9, hits: 4));
  static const barrage = Spell(
      id: 'barrage', name: 'Barrage', chargeCost: 1, xCost: true, priority: 9,
      effect: BarrageEffect(11));

  // Lifesteal (priority 9) — heals for damage dealt to health, not shields.
  static const sap = Spell(
      id: 'sap', name: 'Sap', chargeCost: 1, priority: 9,
      effect: DamageEffect(10, lifesteal: 1));
  static const leech = Spell(
      id: 'leech', name: 'Leech', chargeCost: 3, priority: 9,
      effect: DamageEffect(28, lifesteal: 1));
  static const drain = Spell(
      id: 'drain', name: 'Drain', chargeCost: 5, priority: 9,
      effect: DamageEffect(52, lifesteal: 1));

  // Shields (priority 3) — ~25% stronger than same-charge attacks.
  static const ward = Spell(
      id: 'ward', name: 'Ward', chargeCost: 1, priority: 3,
      effect: ShieldEffect(15));
  static const aegis = Spell(
      id: 'aegis', name: 'Aegis', chargeCost: 2, priority: 3,
      effect: ShieldEffect(28));
  static const bulwark = Spell(
      id: 'bulwark', name: 'Bulwark', chargeCost: 3, priority: 3,
      effect: ShieldEffect(42));
  static const rampart = Spell(
      id: 'rampart', name: 'Rampart', chargeCost: 4, priority: 3,
      effect: ShieldEffect(60));
  static const sanctuary = Spell(
      id: 'sanctuary', name: 'Sanctuary', chargeCost: 5, priority: 3,
      effect: ShieldEffect(82));
  static const barrier = Spell(
      id: 'barrier', name: 'Barrier', chargeCost: 3, priority: 3,
      effect: BarrierEffect());

  // Aux (priority 7) — investments: casting ends your cycle, so the buff
  // pays off in a future cycle.
  static const empower = Spell(
      id: 'empower', name: 'Empower', chargeCost: 2, priority: 7,
      effect: EmpowerEffect(2));
  static const quicken = Spell(
      id: 'quicken', name: 'Quicken', chargeCost: 2, priority: 7,
      effect: QuickenEffect(2));
  static const phase = Spell(
      id: 'phase', name: 'Phase', chargeCost: 2, priority: 7,
      effect: PhaseEffect());

  static const List<Spell> all = [
    flick, bolt, blast, surge, ruin, cataclysm,
    jolt,
    flurry, volley, barrage,
    sap, leech, drain,
    ward, aegis, bulwark, rampart, sanctuary, barrier,
    empower, quicken, phase,
  ];

  static Spell byId(String id) => all.firstWhere((s) => s.id == id);
}
