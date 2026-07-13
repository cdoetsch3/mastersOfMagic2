import 'dart:math';

import 'action.dart';
import 'element.dart';
import 'events.dart';
import 'mage.dart';
import 'spell.dart';

/// Result of resolving one simultaneous turn.
class TurnResult {
  final int turn;
  final List<DuelEvent> events;

  const TurnResult(this.turn, this.events);

  @override
  String toString() => events.map((e) => '  $e').join('\n');
}

/// A 1v1 duel between two mages (player or monster — identical rules).
///
/// Both sides submit an action, then [resolveTurn] resolves them together:
/// casts are ordered by priority (1 acts first); equal priorities resolve
/// simultaneously (attacks see the pre-priority-step world, so a same-priority
/// shield does not block a same-priority attack). A mage defeated at an
/// earlier priority step does not get to resolve casts at later steps —
/// equal-priority mutual kills are a draw.
class DuelEngine {
  final MageState mage1;
  final MageState mage2;

  /// Damage rolls come from here — inject a seeded [Random] for
  /// deterministic tests, replays, and (later) server-side resolution.
  final Random rng;

  int turnNumber = 0;

  DuelEngine(this.mage1, this.mage2, {Random? rng}) : rng = rng ?? Random();

  int _roll(int min, int max) =>
      min >= max ? min : min + rng.nextInt(max - min + 1);

  bool get isOver => !mage1.alive || !mage2.alive;

  bool get isDraw => !mage1.alive && !mage2.alive;

  MageState? get winner {
    if (!isOver || isDraw) return null;
    return mage1.alive ? mage1 : mage2;
  }

  /// [mage] forfeits the duel (surrender in PvP, flee in the campaign):
  /// they drop to 0 hp and the duel ends immediately as their loss.
  void concede(MageState mage) {
    if (isOver) {
      throw StateError('The duel is already over.');
    }
    mage.hp = 0;
  }

  TurnResult resolveTurn(MageAction action1, MageAction action2) {
    if (isOver) {
      throw StateError('The duel is already over.');
    }
    _validate(mage1, action1);
    _validate(mage2, action2);
    turnNumber++;
    final events = <DuelEvent>[];

    // Charging resolves unconditionally and interacts with nothing.
    for (final (mage, action) in [(mage1, action1), (mage2, action2)]) {
      if (action is ChargeAction) {
        mage.element ??= action.element;
        mage.charge++;
        events.add(ChargedEvent(mage, mage.element!, mage.charge));
      }
    }

    // Build pending casts with effective priorities.
    final casts = <_PendingCast>[];
    for (final (mage, opponent, action) in [
      (mage1, mage2, action1),
      (mage2, mage1, action2),
    ]) {
      if (action is CastAction) {
        final element = mage.element ?? action.element!;
        var priority = action.spell.priority;
        if (action.spell.isOffensive && mage.quickenPriority != null) {
          priority = mage.quickenPriority!;
          mage.quickenPriority = null;
        }
        casts.add(_PendingCast(
          caster: mage,
          target: opponent,
          spell: action.spell,
          element: element,
          chargeSpent: mage.charge,
          priority: priority,
        ));
      }
    }
    casts.sort((a, b) => a.priority.compareTo(b.priority));

    // Resolve casts grouped by priority. Within a group, offense resolves
    // against the pre-group world before defense/aux applies (simultaneity).
    var i = 0;
    while (i < casts.length) {
      var j = i;
      while (j < casts.length && casts[j].priority == casts[i].priority) {
        j++;
      }
      // Snapshot who is alive at the START of this priority step — a mage
      // killed within the step still resolves their simultaneous cast.
      final group = casts.sublist(i, j).where((c) => c.caster.alive).toList();
      final offense = group.where((c) => c.spell.isOffensive).toList();
      final support = group.where((c) => !c.spell.isOffensive).toList();
      for (final cast in offense) {
        _resolveCast(cast, events);
      }
      for (final cast in support) {
        _resolveCast(cast, events);
      }
      i = j;
    }

    // Casting consumes all charge and ends the element cycle.
    for (final cast in casts) {
      cast.caster.charge = 0;
      cast.caster.element = null;
    }

    for (final mage in [mage1, mage2]) {
      if (!mage.alive) events.add(DefeatedEvent(mage));
    }
    return TurnResult(turnNumber, events);
  }

  void _validate(MageState mage, MageAction action) {
    switch (action) {
      case ChargeAction(:final element):
        if (mage.charge >= MageState.maxCharge) {
          throw ArgumentError(
              '${mage.name} is already at maximum charge (${MageState.maxCharge}).');
        }
        if (mage.charge == 0 && element == null) {
          throw ArgumentError(
              '${mage.name} must choose an element to begin charging.');
        }
        if (mage.charge > 0 && element != null && element != mage.element) {
          throw ArgumentError(
              '${mage.name} cannot switch elements mid-cycle.');
        }
      case CastAction(:final spell, :final element):
        if (spell.xCost) {
          if (mage.charge < 1) {
            throw ArgumentError(
                '${spell.name} needs at least 1 charge.');
          }
        } else if (spell.chargeCost > mage.charge) {
          throw ArgumentError(
              '${spell.name} needs ${spell.chargeCost} charge; '
              '${mage.name} has ${mage.charge}.');
        }
        if (mage.charge == 0 && element == null) {
          throw ArgumentError(
              '${mage.name} must choose an element to cast ${spell.name}.');
        }
        if (mage.charge > 0 && element != null && element != mage.element) {
          throw ArgumentError(
              '${mage.name} cannot switch elements mid-cycle.');
        }
    }
  }

  void _resolveCast(_PendingCast cast, List<DuelEvent> events) {
    final caster = cast.caster;
    events.add(SpellCastEvent(caster, cast.spell, cast.element));
    switch (cast.spell.effect) {
      case DamageEffect(
          :final minAmount,
          :final maxAmount,
          :final hits,
          :final lifesteal,
          :final ignoresShields
        ):
        final buffs = caster.consumeOffensiveBuffs();
        _attack(
          cast,
          minPerHit: minAmount,
          maxPerHit: maxAmount,
          multiplier: buffs.multiplier,
          hits: hits,
          lifesteal: lifesteal,
          ignoresShields: ignoresShields || buffs.phase,
          events: events,
        );
      case BarrageEffect(:final minPerCharge, :final maxPerCharge):
        final buffs = caster.consumeOffensiveBuffs();
        _attack(
          cast,
          minPerHit: minPerCharge * cast.chargeSpent,
          maxPerHit: maxPerCharge * cast.chargeSpent,
          multiplier: buffs.multiplier,
          hits: 1,
          lifesteal: 0,
          ignoresShields: buffs.phase,
          events: events,
        );
      case ShieldEffect(:final minStrength, :final maxStrength):
        caster.shield = ActiveShield.elemental(
            cast.element, _roll(minStrength, maxStrength));
        events.add(ShieldRaisedEvent(caster, caster.shield!));
      case BarrierEffect():
        caster.shield = ActiveShield.barrier();
        events.add(ShieldRaisedEvent(caster, caster.shield!));
      case EmpowerEffect(:final multiplier):
        caster.empowerMultiplier = multiplier;
        events.add(BuffAppliedEvent(
            caster, 'next offensive spell deals ${multiplier}x damage'));
      case QuickenEffect(:final priorityOverride):
        caster.quickenPriority = priorityOverride;
        events.add(BuffAppliedEvent(
            caster, 'next offensive spell resolves at priority $priorityOverride'));
      case PhaseEffect():
        caster.phaseNext = true;
        events.add(BuffAppliedEvent(
            caster, 'next offensive spell ignores shields'));
    }
  }

  void _attack(
    _PendingCast cast, {
    required int minPerHit,
    required int maxPerHit,
    required int multiplier,
    required int hits,
    required double lifesteal,
    required bool ignoresShields,
    required List<DuelEvent> events,
  }) {
    final target = cast.target;
    var totalToHp = 0;
    for (var h = 0; h < hits; h++) {
      final perHit = _roll(minPerHit, maxPerHit) * multiplier;
      final shield = ignoresShields ? null : target.shield;
      if (shield == null) {
        target.takeHpDamage(perHit);
        totalToHp += perHit;
        events.add(DamageEvent(target, cast.spell, toShield: 0, toHp: perHit));
      } else if (shield.isBarrier) {
        target.shield = null;
        events.add(DamageEvent(target, cast.spell,
            toShield: perHit, toHp: 0, shieldBroken: true));
      } else {
        final countered = cast.element.counters(shield.element!);
        final counterMult = countered ? 2 : 1;
        final effective = perHit * counterMult;
        if (effective < shield.remaining) {
          shield.remaining -= effective;
          events.add(DamageEvent(target, cast.spell,
              toShield: effective, toHp: 0, countered: countered));
        } else {
          // Overflow: the raw damage spent breaking the shield is rounded in
          // the defender's favor; the rest strikes health at normal rate.
          final absorbed = shield.remaining;
          final rawConsumed = (absorbed + counterMult - 1) ~/ counterMult;
          final toHp = perHit - rawConsumed;
          target.shield = null;
          target.takeHpDamage(toHp);
          totalToHp += toHp;
          events.add(DamageEvent(target, cast.spell,
              toShield: absorbed,
              toHp: toHp,
              countered: countered,
              shieldBroken: true));
        }
      }
    }
    if (lifesteal > 0 && totalToHp > 0) {
      final healed = (totalToHp * lifesteal).round();
      cast.caster.heal(healed);
      events.add(HealedEvent(cast.caster, healed));
    }
  }
}

class _PendingCast {
  final MageState caster;
  final MageState target;
  final Spell spell;
  final MagicElement element;
  final int chargeSpent;
  final int priority;

  _PendingCast({
    required this.caster,
    required this.target,
    required this.spell,
    required this.element,
    required this.chargeSpent,
    required this.priority,
  });
}
