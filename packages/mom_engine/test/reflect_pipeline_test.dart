import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Integration tests written AT THE MERGE of the specials lane (Reflect) and
/// the DoT lane (the shared `_damagePacket` pipeline): the tick ruling of
/// 2026-08-28 says "Divert can deflect it (Reflect returns what it deflects)",
/// which means Reflect must fire at EVERY deflect site — not only the attack
/// path the specials lane tested. Each expectation was mutation-verified by
/// deleting the corresponding `_maybeReflect` call and watching it fail.

/// `nextInt` always 0: any guarded chance > 0 fires, damage rolls minimum.
class _AlwaysHits implements Random {
  @override
  double nextDouble() => 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// A deflect source speaking only the [StatModifier] seam, so these tests are
/// strangers to the stance lane's classes — same stance the DoT lane took.
class _Divert extends TurnStatus implements StatModifier {
  @override
  int contributionTo(CombatStat stat) => switch (stat) {
        CombatStat.deflectActivation => 100,
        CombatStat.deflectAmount => 50,
        _ => 0,
      };

  @override
  String get id => 'divert';

  @override
  StatusPolarity get polarity => StatusPolarity.buff;

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) => const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => false;
}

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno')
      ..statuses.add(_Divert())
      ..statuses.add(ReflectStatus.reflect());
  });

  DuelEngine engine() => DuelEngine(alice, bruno,
      rng: _AlwaysHits(), elementEffects: false, baseMissPercent: 0);

  test('⭐ a deflected DoT TICK is returned by Reflect', () {
    bruno.statuses.add(
        BankDotStatus(id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 3));
    final duel = engine();
    final r = duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
    final back = r.events
        .whereType<EffectDamageEvent>()
        .where((e) => e.source == 'Reflect')
        .single;
    expect(back.target, same(alice),
        reason: 'the return goes to the OPPONENT — every hostile packet in a '
            'duel originates there. Mutant killed: Reflect firing only on the '
            'attack path (the pre-merge specials shape), which never sees a '
            'tick deflect at all.');
    expect(back.toHp, 5,
        reason: 'exactly the deflected half of the 10 tick, 100% returned '
            '(§7a ruling) — not the full tick, not a re-rolled amount');
    expect(alice.hp, 95,
        reason: 'and it is real damage, not just an event row');
  });

  test('⭐ a deflected Scour packet is returned by Reflect', () {
    bruno.statuses.add(
        BankDotStatus(id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 3));
    final duel = engine();
    alice
      ..charge = Spellbook.scour.chargeCost
      ..element = MagicElement.flora;
    final r = duel.resolveTurn(
        CastAction(Spellbook.scour, MagicElement.flora),
        const ForfeitAction());
    final back = r.events
        .whereType<EffectDamageEvent>()
        .where((e) => e.source == 'Reflect')
        .single;
    expect(back.toHp, 15,
        reason: 'the packet is the burn\'s full remaining 30, deflected by '
            'half and returned in full — ONE packet, one deflect roll, one '
            'return. Mutant killed: no _maybeReflect at the Scour site.');
    expect(alice.hp, 85,
        reason: 'the collector pays for detonating into a Reflect stance');
  });
}
