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
/// Both sides submit an action; [resolveTurn] resolves them together. Every
/// action carries a **priority** (1 acts first): instant 1, shields 3,
/// channel 4, quick attacks 5, aux 7, regular 9. Equal-priority collisions are
/// broken by the **Haste** token — the holder's spell resolves first, so a
/// lethal hit lands before the opponent can fire back. When nobody holds
/// Haste, equal priorities resolve simultaneously and can trade kills (a draw).
///
/// Haste rules:
///  - Only matters as the same-priority tiebreak (uses the START-of-turn holder).
///  - While unheld: the first non-channel cast grabs it; if both cast, the
///    faster one grabs it; a same-priority pair leaves it unheld.
///  - Once held: only a Haste-granting spell (grantsHaste) moves it, and it
///    goes to the LAST grant to resolve — so a same-priority pair flips it to
///    the opponent (the holder resolves first, the other's grant lands last),
///    and among different priorities the slower grant wins.
///  - Channeling never grants or moves Haste.
class DuelEngine {
  final MageState mage1;
  final MageState mage2;

  /// Damage rolls come from here — inject a seeded [Random] for
  /// deterministic tests, replays, and (later) server-side resolution.
  final Random rng;

  int turnNumber = 0;

  static const int channelPriority = 4;

  DuelEngine(this.mage1, this.mage2, {Random? rng}) : rng = rng ?? Random();

  int _roll(int min, int max) =>
      min >= max ? min : min + rng.nextInt(max - min + 1);

  bool get isOver => !mage1.alive || !mage2.alive;

  bool get isDraw => !mage1.alive && !mage2.alive;

  MageState? get winner {
    if (!isOver || isDraw) return null;
    return mage1.alive ? mage1 : mage2;
  }

  /// The mage currently holding the Haste initiative token, or null.
  MageState? get hasteHolder =>
      mage1.hasHaste ? mage1 : (mage2.hasHaste ? mage2 : null);

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

    // Haste holder BEFORE this turn transfers it — used to break ties.
    final startHolder = hasteHolder;

    // One resolution entry per mage. Channel is priority 4; casts use their
    // spell priority (with a pending Quicken override for offense).
    final entries = <_Entry>[];
    for (final (mage, opponent, action) in [
      (mage1, mage2, action1),
      (mage2, mage1, action2),
    ]) {
      switch (action) {
        case ForfeitAction():
          events.add(ForfeitedEvent(mage));
        case ChargeAction():
          entries.add(_Entry(
            caster: mage,
            target: opponent,
            action: action,
            element: mage.element ?? action.element!,
            priority: channelPriority,
          ));
        case CastAction(:final spell):
          var priority = spell.priority;
          if (spell.isOffensive && mage.quickenPriority != null) {
            priority = mage.quickenPriority!;
            mage.quickenPriority = null;
          }
          entries.add(_Entry(
            caster: mage,
            target: opponent,
            action: action,
            element: mage.element ?? action.element!,
            priority: priority,
          ));
      }
    }
    entries.sort((a, b) => a.priority.compareTo(b.priority));

    // Resolve in priority order, grouped by equal priority.
    var i = 0;
    while (i < entries.length) {
      var j = i;
      while (j < entries.length && entries[j].priority == entries[i].priority) {
        j++;
      }
      final group = entries.sublist(i, j).where((e) => e.caster.alive).toList();
      final twoCasts =
          group.length == 2 && group.every((e) => !e.isChannel);

      if (twoCasts && startHolder != null) {
        // Haste tiebreak: the holder resolves first; if it kills the
        // opponent, the opponent's same-priority spell never fires.
        final first =
            identical(group[0].caster, startHolder) ? group[0] : group[1];
        final second = identical(first, group[0]) ? group[1] : group[0];
        _resolveEntry(first, events);
        if (second.caster.alive) _resolveEntry(second, events);
      } else {
        // Simultaneous: offense before support (a same-priority shield does
        // not block a same-priority attack), then channels. No mid-group
        // alive re-check, so same-priority mutual kills are still possible
        // when nobody holds Haste.
        final ordered = [
          ...group.where((e) => e.isOffensive),
          ...group.where((e) => !e.isOffensive && !e.isChannel),
          ...group.where((e) => e.isChannel),
        ];
        for (final e in ordered) {
          _resolveEntry(e, events);
        }
      }
      i = j;
    }

    // Casting consumes all charge and ends the element cycle (channels keep it).
    for (final e in entries) {
      if (!e.isChannel) {
        e.caster.charge = 0;
        e.caster.element = null;
      }
    }

    _updateHaste(entries, startHolder, events);

    for (final mage in [mage1, mage2]) {
      if (!mage.alive) events.add(DefeatedEvent(mage));
    }
    return TurnResult(turnNumber, events);
  }

  void _validate(MageState mage, MageAction action) {
    switch (action) {
      case ForfeitAction():
        break; // always legal — you may always do nothing
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
            throw ArgumentError('${spell.name} needs at least 1 charge.');
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

  void _resolveEntry(_Entry e, List<DuelEvent> events) {
    if (e.isChannel) {
      e.caster.element ??= e.element;
      e.caster.charge++;
      events.add(ChargedEvent(e.caster, e.caster.element!, e.caster.charge));
      return;
    }
    _resolveCast(e, events);
  }

  void _resolveCast(_Entry cast, List<DuelEvent> events) {
    final caster = cast.caster;
    final spell = cast.spell!;
    events.add(SpellCastEvent(caster, spell, cast.element));
    switch (spell.effect) {
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
        final charge = caster.charge; // live — a same-turn Discharge fizzles it
        _attack(
          cast,
          minPerHit: minPerCharge * charge,
          maxPerHit: maxPerCharge * charge,
          multiplier: buffs.multiplier,
          hits: 1,
          lifesteal: 0,
          ignoresShields: buffs.phase,
          events: events,
        );
      case OverloadEffect(:final minPerCharge, :final maxPerCharge):
        final buffs = caster.consumeOffensiveBuffs();
        final base = _roll(minPerCharge, maxPerCharge) * cast.target.charge;
        _attack(
          cast,
          minPerHit: base,
          maxPerHit: base,
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
        events.add(BuffAppliedEvent(caster,
            'next offensive spell resolves at priority $priorityOverride'));
      case PhaseEffect():
        caster.phaseNext = true;
        events.add(
            BuffAppliedEvent(caster, 'next offensive spell ignores shields'));
      case HasteEffect():
        // Initiative only; the grantsHaste flag does the work post-resolution.
        break;
      case DischargeEffect():
        final target = cast.target;
        final drained = target.charge;
        target.charge = 0;
        target.element = null;
        events.add(ChargeDrainedEvent(target, drained));
    }
  }

  void _attack(
    _Entry cast, {
    required int minPerHit,
    required int maxPerHit,
    required int multiplier,
    required int hits,
    required double lifesteal,
    required bool ignoresShields,
    required List<DuelEvent> events,
  }) {
    final target = cast.target;
    final spell = cast.spell!;
    var totalToHp = 0;
    for (var h = 0; h < hits; h++) {
      final perHit = _roll(minPerHit, maxPerHit) * multiplier;
      final shield = ignoresShields ? null : target.shield;
      if (shield == null) {
        target.takeHpDamage(perHit);
        totalToHp += perHit;
        events.add(DamageEvent(target, spell, toShield: 0, toHp: perHit));
      } else if (shield.isBarrier) {
        target.shield = null;
        events.add(DamageEvent(target, spell,
            toShield: perHit, toHp: 0, shieldBroken: true));
      } else {
        final countered = cast.element.counters(shield.element!);
        final counterMult = countered ? 2 : 1;
        final effective = perHit * counterMult;
        if (effective < shield.remaining) {
          shield.remaining -= effective;
          events.add(DamageEvent(target, spell,
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
          events.add(DamageEvent(target, spell,
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

  // Transfers Haste based on this turn's casts (see class doc for the rules).
  void _updateHaste(
      List<_Entry> entries, MageState? startHolder, List<DuelEvent> events) {
    final casts = entries.where((e) => !e.isChannel).toList();
    final qualifying = startHolder == null
        ? casts // unheld: any non-channel cast grabs it
        : casts.where((e) => e.spell!.grantsHaste).toList();
    if (qualifying.isEmpty) return; // nothing grants Haste this turn

    MageState? newHolder;
    if (qualifying.length == 1) {
      newHolder = qualifying.first.caster;
    } else {
      final a = qualifying[0], b = qualifying[1];
      if (startHolder == null) {
        // Establishing initiative: the FASTER caster claims it; a same-
        // priority pair ties and leaves Haste unheld.
        newHolder = a.priority == b.priority
            ? null
            : (a.priority < b.priority ? a.caster : b.caster);
      } else {
        // Transferring an established Haste: it goes to the LAST grant to
        // resolve. Same priority → the holder resolves first (Haste
        // tiebreak) so the OTHER mage's grant lands last and steals it;
        // different priority → the slower spell resolves last.
        newHolder = a.priority == b.priority
            ? (identical(a.caster, startHolder) ? b.caster : a.caster)
            : (a.priority > b.priority ? a.caster : b.caster);
      }
    }

    mage1.hasHaste = identical(newHolder, mage1);
    mage2.hasHaste = identical(newHolder, mage2);
    if (!identical(newHolder, startHolder)) {
      events.add(HasteChangedEvent(newHolder));
    }
  }
}

/// One mage's resolved action for a turn (a channel or a spell cast).
class _Entry {
  final MageState caster;
  final MageState target;
  final MageAction action;
  final MagicElement element;
  final int priority;

  _Entry({
    required this.caster,
    required this.target,
    required this.action,
    required this.element,
    required this.priority,
  });

  bool get isChannel => action is ChargeAction;

  Spell? get spell =>
      action is CastAction ? (action as CastAction).spell : null;

  bool get isOffensive => spell?.isOffensive ?? false;
}
