import 'dart:collection';
import 'dart:math';

import 'action.dart';
import 'element.dart';
import 'element_status.dart';
import 'element_tuning.dart';
import 'events.dart';
import 'mage.dart';
import 'spell.dart';
import 'status.dart';
import 'status_snapshot.dart';

/// Result of resolving one simultaneous turn.
class TurnResult {
  final int turn;
  final List<DuelEvent> events;

  /// A status snapshot of both mages taken immediately after each event,
  /// parallel to [events]. Lets the UI advance status pips one event at a
  /// time instead of jumping to the end-of-turn state the moment the turn
  /// resolves. Empty only for results built without a recording list.
  final List<StatusFrame> frames;

  const TurnResult(this.turn, this.events, [this.frames = const []]);

  @override
  String toString() => events.map((e) => '  $e').join('\n');
}

/// A [List] of events that also records a [StatusFrame] for every event
/// appended, so the UI can replay status changes in step with the animation.
///
/// It implements `List<DuelEvent>` deliberately: the engine passes
/// `List<DuelEvent> events` through a dozen private methods, and this way none
/// of those signatures — or their call sites — have to change.
class _RecordingEvents extends ListBase<DuelEvent> {
  final List<DuelEvent> _events = [];
  final List<StatusFrame> frames = [];
  final MageState _m1;
  final MageState _m2;

  _RecordingEvents(this._m1, this._m2);

  StatusFrame _snap() =>
      (mage1: StatusSnapshot.of(_m1), mage2: StatusSnapshot.of(_m2));

  @override
  int get length => _events.length;
  @override
  set length(int v) {
    _events.length = v;
    frames.length = v;
  }

  @override
  DuelEvent operator [](int i) => _events[i];
  @override
  void operator []=(int i, DuelEvent e) {
    _events[i] = e;
    frames[i] = _snap();
  }

  @override
  void add(DuelEvent e) {
    _events.add(e);
    frames.add(_snap());
  }

  @override
  void insert(int i, DuelEvent e) {
    _events.insert(i, e);
    // Reuse the frame already at that index: the spliced event (a Haste
    // transfer) is being reported at the moment that state was current.
    frames.insert(i, i < frames.length ? frames[i] : _snap());
  }
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

  /// Sudden death (TYPE_EFFECTS_DESIGN.md §8): after [fatigueThreshold] turns,
  /// both mages take escalating **unblockable** damage at end of turn, growing
  /// by [fatiguePerTurn] each turn. Guarantees every duel terminates — kills
  /// stall strategies (e.g. Photosynthesis turtling) and backstops the
  /// disconnect/forfeit handling. Threshold/step are tentative — tune later.
  static const int fatigueThreshold = 50;
  static const int fatiguePerTurn = 3;

  /// Whether element side-effects (Ignite procs, Photosynthesis,
  /// Waterlogged, …) fire on casts. Always true in real duels; tests of core
  /// resolution semantics (priority, shields, Haste) may switch them off so
  /// hand-computed expectations aren't perturbed by procs.
  final bool elementEffects;

  /// The entries being resolved this turn.
  ///
  /// ⚠️ Held so a drain can reach charge that has already been **committed**
  /// to a cast which has not resolved yet. Same-priority casts all pay before
  /// any of them resolves (so neither can read a bar the other has spent), and
  /// without this a Static Feedback or Discharge landing in that window would
  /// find a zeroed bar and silently do nothing.
  List<_Entry> _turnEntries = const [];

  /// The mage grabbing Haste via Tailwind this turn (last grab wins if both
  /// somehow qualify). Applied after normal Haste transfer — the wind always
  /// wins the turn's initiative scramble.
  MageState? _tailwindGrab;

  DuelEngine(this.mage1, this.mage2, {Random? rng, this.elementEffects = true})
      : rng = rng ?? Random();

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

  /// The **shared, public** moon phase for the **next turn to be resolved**
  /// (Lunar — §4b.2), i.e. the one the players are choosing an action in.
  /// [turnNumber] is the last *resolved* turn, so the upcoming turn is +1.
  /// Both clients derive it; for the HUD's moon chrome.
  MoonPhase get moonPhase => moonPhaseForTurn(turnNumber + 1);

  /// The phase after [moonPhase] — for a "next: Full" preview so a Lunar mage
  /// can plan the turn ahead.
  MoonPhase get nextMoonPhase => moonPhaseForTurn(turnNumber + 2);

  /// The moon phase actually governing [mage]'s Lunar spells next turn — the
  /// shared moon unless they're eclipsed (Blind active), which locks them to
  /// New. The HUD reads this to show an eclipse badge distinct from the global
  /// moon.
  MoonPhase effectiveMoonPhaseFor(MageState mage) =>
      mage.missChance > 0 ? MoonPhase.newMoon : moonPhase;

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
    final events = _RecordingEvents(mage1, mage2);
    mage1.activeElementThisTurn = null;
    mage2.activeElementThisTurn = null;

    // Haste holder BEFORE this turn transfers it — used to break ties.
    final startHolder = hasteHolder;

    // START phase — pre-move effects (reserved; empty until any exist).
    _resolvePhase(TurnPhase.start, events);
    if (isOver) {
      for (final mage in [mage1, mage2]) {
        if (!mage.alive) events.add(DefeatedEvent(mage));
      }
      return TurnResult(turnNumber, events, events.frames);
    }

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
          mage.activeElementThisTurn = mage.element ?? action.element;
          entries.add(_Entry(
            caster: mage,
            target: opponent,
            action: action,
            element: mage.element ?? action.element!,
            priority: channelPriority + _consumePriorityPenalty(mage),
          ));
        case CastAction(:final spell):
          var priority = spell.priority;
          if (spell.isOffensive && mage.quickenPriority != null) {
            priority = mage.quickenPriority!;
            mage.quickenPriority = null;
          }
          // Waterlogged slows even a Quickened action (+10, applied last).
          priority += _consumePriorityPenalty(mage);
          // Counts as element activity even if it later fizzles or misses
          // (those "behave like a charge" of the cycling element).
          mage.activeElementThisTurn = mage.element ?? action.element;
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
    _turnEntries = entries;

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
        //
        // ⭐ The holder also PAYS first, which is what makes Haste matter to
        // Overload: the holder reads a full enemy charge bar, and the
        // opponent's Overload then reads the zero the holder just left behind.
        final first =
            identical(group[0].caster, startHolder) ? group[0] : group[1];
        final second = identical(first, group[0]) ? group[1] : group[0];
        _spendFor(first);
        _resolveEntry(first, events);
        first.endEventIndex = events.length;
        if (second.caster.alive) {
          _spendFor(second);
          _resolveEntry(second, events);
        }
        second.endEventIndex = events.length;
      } else {
        // Simultaneous: offense before support (a same-priority shield does
        // not block a same-priority attack), then channels. No mid-group
        // alive re-check, so same-priority mutual kills are still possible
        // when nobody holds Haste.
        //
        // ⭐ Everyone PAYS before anyone resolves. With no Haste there is no
        // "first", so neither caster may read a charge bar the other has
        // already committed: two Overloads thrown at each other both find
        // nothing to punish, and two Discharges both end on zero.
        final ordered = [
          ...group.where((e) => e.isOffensive),
          ...group.where((e) => !e.isOffensive && !e.isChannel),
          ...group.where((e) => e.isChannel),
        ];
        for (final e in ordered) {
          _spendFor(e);
        }
        for (final e in ordered) {
          _resolveEntry(e, events);
          e.endEventIndex = events.length;
        }
      }
      i = j;
    }

    // ⚠️ Charge is spent in [_spendFor] as each cast resolves, NOT swept up
    // after the turn. The sweep was a real defect: a mage who cast a shield at
    // priority 3 still showed a full charge bar to an Overload at priority 9,
    // so Overload punished charge its target had already committed. Fizzles
    // and channels keep what they had, per Static Feedback's "you'd still have
    // 3 charge".

    _updateHaste(entries, startHolder, events);

    // Tailwind overrides the normal Haste scramble: the wind takes the token.
    final grab = _tailwindGrab;
    _tailwindGrab = null;
    if (grab != null && !grab.hasHaste) {
      mage1.hasHaste = identical(grab, mage1);
      mage2.hasHaste = identical(grab, mage2);
      // Same as the normal transfer: report it right after the Aero cast the
      // wind came from, not at end of turn.
      final from = entries
          .where((e) => !e.isChannel && identical(e.caster, grab))
          .map((e) => e.endEventIndex);
      events.insert(
          from.isEmpty ? events.length : from.last.clamp(0, events.length),
          HasteChangedEvent(grab));
    }

    // END phase — post-move effects (DoTs like Ignite, HoTs like
    // Photosynthesis). Skipped if the main phase already ended the duel.
    if (!isOver) {
      _resolvePhase(TurnPhase.end, events);
    }

    // Shadow (Creeping Dark 5+) conceals the caster's charging element.
    for (final mage in [mage1, mage2]) {
      mage.concealed = _statusOf<CreepingDarkStatus>(mage)?.shadow ?? false;
    }

    // Sudden death: unblockable, escalating, after the heal band has had its
    // say. The Haste holder ticks first (consistent with lane ties) — if that
    // kills them, the other mage survives the turn: never a fatigue draw.
    if (!isOver && turnNumber > fatigueThreshold) {
      final dmg = (turnNumber - fatigueThreshold) * fatiguePerTurn;
      final order =
          identical(hasteHolder, mage2) ? [mage2, mage1] : [mage1, mage2];
      for (final mage in order) {
        if (isOver) break;
        mage.takeHpDamage(dmg);
        events.add(
            EffectDamageEvent(mage, 'Fatigue', toShield: 0, toHp: dmg));
      }
    }

    for (final mage in [mage1, mage2]) {
      if (!mage.alive) events.add(DefeatedEvent(mage));
    }
    return TurnResult(turnNumber, events, events.frames);
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
    e.resolved = true;
    if (e.isChannel) {
      e.caster.element ??= e.element;
      e.caster.charge++;
      events.add(ChargedEvent(e.caster, e.caster.element!, e.caster.charge));
      return;
    }
    _resolveCast(e, events);
  }

  /// Whether [spell] could be cast with [charge] in the bar.
  bool _hasChargeToCast(Spell spell, int charge) =>
      spell.xCost ? charge >= 1 : charge >= spell.chargeCost;

  /// Charge that can still be taken from [mage] — live, plus anything
  /// committed to a cast of theirs that has not resolved yet.
  int _drainableCharge(MageState mage) {
    var total = mage.charge;
    for (final e in _turnEntries) {
      if (identical(e.caster, mage) && !e.isChannel && !e.resolved) {
        total += e.chargeAtCast;
      }
    }
    return total;
  }

  /// Take up to [amount] charge from [mage]; returns how much was actually
  /// taken.
  ///
  /// ⭐ Drains live charge first, then eats into charge already **committed**
  /// to an unresolved cast — which is what lets a same-priority strip drop a
  /// spell below its cost and fizzle it. Without the second half, Static
  /// Feedback and Discharge would be no-ops against anyone casting at their
  /// own priority, because payment has already zeroed the visible bar.
  int _drainCharge(MageState mage, int amount) {
    var remaining = amount;
    final live = mage.charge < remaining ? mage.charge : remaining;
    mage.charge -= live;
    remaining -= live;

    for (final e in _turnEntries) {
      if (remaining <= 0) break;
      if (identical(e.caster, mage) && !e.isChannel && !e.resolved) {
        final taken = e.chargeAtCast < remaining ? e.chargeAtCast : remaining;
        e.chargeAtCast -= taken;
        remaining -= taken;
      }
    }
    if (mage.charge == 0) mage.element = null;
    return amount - remaining;
  }

  /// Commit a cast's charge, at the moment it resolves.
  ///
  /// ⭐ Casting spends **all** charge and ends the element cycle — the cost is
  /// a floor to cast at all, not a price. Doing this at resolution rather than
  /// after the turn is what lets a spell see the board as it actually stands:
  /// charge already committed to an earlier-priority spell is gone.
  ///
  /// Channels keep their charge. So do fizzles — but a fizzle is only known
  /// once we try to resolve, so [_resolveCast] hands it back via [_refund].
  void _spendFor(_Entry entry) {
    if (entry.isChannel) return;
    entry.chargeAtCast = entry.caster.charge;
    entry.caster.charge = 0;
    entry.caster.element = null;
  }

  /// Undo a payment for a cast that never went off.
  void _refund(_Entry entry) {
    entry.caster.charge = entry.chargeAtCast;
    entry.caster.element = entry.element;
  }

  int _consumePriorityPenalty(MageState mage) {
    final p = mage.priorityPenalty;
    mage.priorityPenalty = 0;
    return p;
  }

  void _resolveCast(_Entry cast, List<DuelEvent> events) {
    final caster = cast.caster;
    final spell = cast.spell!;

    // Precedence step 1 — Fizzle: a committed spell whose charge was pulled
    // below its cost does not cast.
    //
    // ⚠️ Tests what this cast PAID, not the caster's live charge — by now the
    // payment has already zeroed it. A fizzle hands the charge straight back:
    // the spell never went off, so it was never really spent.
    if (!_hasChargeToCast(spell, cast.chargeAtCast)) {
      cast.fizzled = true;
      _refund(cast);
      events.add(SpellFizzledEvent(caster, spell));
      return;
    }

    // Precedence step 3 — Hit roll: a single unified accuracy check (§5.2).
    //   hitChance = spellAccuracy + gearAccuracy − targetDodge − blind
    // Blind is folded in as a flat −50 (no separate miss system); Astral is
    // exempt (Astral slips Solar, §4b). Only harmful spells roll, and only
    // when the hit chance is actually below 100 — so a default-stat cast (100
    // accuracy, 0 dodge, unblinded) consumes no RNG, leaving the sim unmoved.
    // Miss ⇒ no effect, charge still spent (post-resolution sweep), no streak.
    if (spell.isHarmful && cast.element != MagicElement.astral) {
      final blindPenalty = (caster.missChance * 100).round(); // 50 if blinded
      final hitChance =
          spell.accuracy + caster.accuracyBonus - cast.target.dodge - blindPenalty;
      final missPercent = 100 - hitChance;
      if (missPercent > 0 && rng.nextDouble() * 100 < missPercent) {
        events.add(SpellMissedEvent(caster, spell));
        return;
      }
    }

    // Any resolved cast (offensive or not) advances the element streak.
    // Fizzles and misses returned early — they leave the streak untouched.
    // Recorded BEFORE the first event so the streak pip appears on the cast
    // itself; every status frame from here on carries the new count.
    caster.recordCastForStreak(cast.element);

    events.add(SpellCastEvent(caster, spell, cast.element));
    // ⚠️ What this cast PAID, not the live bar — payment happens before
    // resolution now, so the live bar reads zero by the time we get here.
    final chargeSpent = cast.chargeAtCast;

    // Precedence step 2/4 — Stagger is consumed by any harmful spell that
    // resolves (Discharge too — a harmless "stagger-eater").
    var staggerScale = 1.0;
    if (spell.isHarmful) {
      staggerScale = caster.nextOffensiveDamageScale;
      caster.nextOffensiveDamageScale = 1.0;
    }

    // The Lunar phase modifier is additive alongside Arcane Knowledge (§5.2
    // step 5), and only for a Lunar attack. New −25 / Waxing +25 / Full +50 /
    // Waning 0; an eclipsed Lunar mage is locked to New (−25).
    final lunarPercent = (cast.element == MagicElement.lunar && spell.isOffensive)
        ? lunarAttackPercent(_effectiveMoonPhase(caster))
        : 0;

    // Damage modifiers in order: additive (Arcane Knowledge +5%/stack, Lunar
    // phase) then multipliers (Empower ×2, Stagger ×0.5).
    double damageScale(({int multiplier, bool phase}) buffs) =>
        (1 + (caster.bonusDamagePercent + lunarPercent) / 100) *
        buffs.multiplier *
        staggerScale;

    var rawDamage = 0; // total pre-shield damage rolled (for Ignite)
    _lastAttackToHp = 0; // reset; _attack sets it, non-attacks leave it 0
    switch (spell.effect) {
      case DamageEffect(
          :final minAmount,
          :final maxAmount,
          :final hits,
          :final lifesteal,
          :final ignoresShields
        ):
        final buffs = caster.consumeOffensiveBuffs();
        rawDamage = _attack(
          cast,
          minPerHit: minAmount,
          maxPerHit: maxAmount,
          scale: damageScale(buffs),
          hits: hits,
          lifesteal: lifesteal,
          ignoresShields: ignoresShields || buffs.phase,
          events: events,
        );
      case BarrageEffect(:final minPerCharge, :final maxPerCharge):
        final buffs = caster.consumeOffensiveBuffs();
        // What this cast actually paid. Still reflects an earlier-priority
        // Discharge, because payment happens at resolution and Discharge (7)
        // resolves before Barrage (9).
        final charge = cast.chargeAtCast;
        // One hit PER CHARGE, each rolled independently — the Volley shape.
        // Same damage band as the old single roll, but every hit meets the
        // shield, a Barrier point, crit and deflection on its own. The fizzle
        // gate guarantees charge >= 1 for an X-cost spell.
        rawDamage = _attack(
          cast,
          minPerHit: minPerCharge,
          maxPerHit: maxPerCharge,
          scale: damageScale(buffs),
          hits: charge,
          lifesteal: 0,
          ignoresShields: buffs.phase,
          events: events,
        );
      case OverloadEffect(:final minPerCharge, :final maxPerCharge):
        final buffs = caster.consumeOffensiveBuffs();
        final base = _roll(minPerCharge, maxPerCharge) * cast.target.charge;
        rawDamage = _attack(
          cast,
          minPerHit: base,
          maxPerHit: base,
          scale: damageScale(buffs),
          hits: 1,
          lifesteal: 0,
          ignoresShields: buffs.phase,
          events: events,
        );
      case ShieldEffect(:final minStrength, :final maxStrength):
        // ⭐ Shields scale with level on the same 4% curve as health and
        // damage. Without it a level-60's shield soaks a level-60's hit for
        // one tenth as long as a level-1's does against a level-1 — defence
        // would quietly stop being a strategy as the game went on.
        final strength =
            (_roll(minStrength, maxStrength) * caster.levelScale).round();
        caster.shield = ActiveShield.elemental(cast.element, strength);
        events.add(ShieldRaisedEvent(caster,
            element: cast.element, isBarrier: false, strength: strength));
      case BarrierEffect():
        // Barrier stacks: each cast adds a point, up to the cap. `strength`
        // reports the resulting point count so the UI can show the level.
        caster.barrierPoints =
            (caster.barrierPoints + 1).clamp(0, MageState.maxBarrierPoints);
        events.add(ShieldRaisedEvent(caster,
            element: null,
            isBarrier: true,
            strength: caster.barrierPoints));
      case EmpowerEffect(:final multiplier):
        caster.empowerMultiplier = multiplier;
        events.add(BuffAppliedEvent(
            caster, 'next offensive spell deals ${multiplier}x damage',
            statusId: 'empower'));
      case QuickenEffect(:final priorityOverride):
        caster.quickenPriority = priorityOverride;
        events.add(BuffAppliedEvent(caster,
            'next offensive spell resolves at priority $priorityOverride',
            statusId: 'quicken'));
      case PhaseEffect():
        caster.phaseNext = true;
        events.add(BuffAppliedEvent(
            caster, 'next offensive spell ignores shields',
            statusId: 'phase'));
      case HasteEffect():
        // Initiative only; the grantsHaste flag does the work post-resolution.
        break;
      case DischargeEffect():
        final target = cast.target;
        // Takes everything, including charge already committed to a cast of
        // theirs that has not gone off yet — which is what fizzles it.
        final drained = _drainCharge(target, _drainableCharge(target));
        target.element = null;
        events.add(ChargeDrainedEvent(target, drained));
      case HallowEffect():
        // Grace doesn't stack past one, so casting Hallow while already warded
        // is a wasted turn — say so rather than logging a fresh success.
        if (caster.hasGrace) {
          events.add(BuffAppliedEvent(
              caster, 'Already warded — Grace unchanged',
              statusId: 'graceAlready'));
        } else {
          caster.hasGrace = true;
          events.add(BuffAppliedEvent(
              caster, 'Grace — next debuff blocked', statusId: 'grace'));
        }
    }

    // Fire this element's on-cast effects (Tier 1: Ignite, Photosynthesis,
    // Waterlogged, and the Aqua-shield cleanse).
    if (elementEffects) {
      _triggerElementEffects(cast, rawDamage, chargeSpent, events);
    }
  }

  /// The health damage the most recent [_attack] actually dealt (past shields
  /// and pierce). Read by charge-spent triggers that must ignore fully-shielded
  /// hits — Arcane → Sanctus (§4c.3). Reset at the top of each cast.
  int _lastAttackToHp = 0;

  /// Returns the total pre-shield damage rolled (for Ignite's 10%).
  int _attack(
    _Entry cast, {
    required int minPerHit,
    required int maxPerHit,
    required double scale,
    required int hits,
    required double lifesteal,
    required bool ignoresShields,
    required List<DuelEvent> events,
  }) {
    // ⭐ Gear's flat damage (ITEMS §9b.8): per-cast plus per-charge-spent,
    // added ONCE — to the first hit — after the level scale, before crit and
    // deflection meet it. Per-hit gear was deliberately not built; the wand
    // ruling is per CAST precisely to avoid multi-hit optimisation this early.
    final flatBonus =
        cast.caster.damagePerCast +
        cast.caster.damagePerCharge *
            (cast.spell!.xCost ? cast.chargeAtCast : cast.spell!.chargeCost);
    final target = cast.target;
    final spell = cast.spell!;
    // Astral Alignment: this fraction of each hit bypasses the shield to
    // health at 100%, splitting the attack rather than shrinking it (§4b.4).
    // Only matters when there's a shield to pierce and the hit isn't already
    // going straight to health (Phase wins that turn).
    final piercePct =
        (!ignoresShields &&
                (target.shield != null || target.barrierPoints > 0))
            ? (_statusOf<AstralAlignmentStatus>(cast.caster)?.piercePercent ?? 0)
            : 0;
    final caster = cast.caster;
    var totalToHp = 0;
    var totalRaw = 0;
    for (var h = 0; h < hits; h++) {
      // ⭐ Level scales damage as well as health (4%/level, compounding), so a
      // level advantage is a real advantage rather than just a bigger pool to
      // grind through. Without this a level-60 boss has 683 HP and still hits
      // for level-1 numbers — which is exactly how it shipped once.
      var perHit =
          (_roll(minPerHit, maxPerHit) *
                  scale *
                  caster.levelScale *
                  caster.powerScale)
              .round();
      if (h == 0 && flatBonus > 0) perHit += flatBonus;

      // Crit (§5.2 step 4/5, per hit). Guarded on chance > 0 so a no-crit
      // build rolls nothing. The bonus is a multiplier atop the damage mods.
      var crit = false;
      if (caster.critChance > 0 && rng.nextInt(100) < caster.critChance) {
        crit = true;
        perHit = (perHit * (100 + caster.critDamage) / 100).round();
      }

      // Ignite reads the attack's full output, so a crit burns harder — count
      // it after the crit multiplier but before the defender's deflection
      // (that's mitigation of the strike, not a change to its force).
      totalRaw += perHit;

      // Deflection (§5.2 step 6, defender side, per hit). Pure reduction — the
      // deflected portion is removed, not reflected. Also chance-guarded.
      var deflected = 0;
      if (target.deflectChance > 0 && rng.nextInt(100) < target.deflectChance) {
        deflected = (perHit * target.deflectAmount.clamp(0, 100) / 100).round();
        perHit -= deflected;
      }

      final pierce = piercePct > 0 ? (perHit * piercePct / 100).round() : 0;
      final r = _applyOneHit(target, perHit - pierce, cast.element, ignoresShields);
      if (pierce > 0) target.takeHpDamage(pierce);
      final toHp = r.toHp + pierce;
      totalToHp += toHp;
      events.add(DamageEvent(target, spell,
          toShield: r.toShield,
          toHp: toHp,
          shieldMultiplierPercent: r.multiplierPercent,
          shieldBroken: r.broken,
          barrierPopped: r.barrierPopped,
          crit: crit,
          deflected: deflected));
    }
    if (lifesteal > 0 && totalToHp > 0) {
      final healed = (totalToHp * lifesteal).round();
      cast.caster.heal(healed);
      events.add(HealedEvent(cast.caster, healed));
    }
    _lastAttackToHp = totalToHp;
    return totalRaw;
  }

  // ---- Element on-cast effects (TYPE_EFFECTS_DESIGN.md §2–§4) ------------

  /// Dispatches the caster's element effects after a cast resolves. [rawDamage]
  /// is the attack's total pre-shield damage (0 for non-damaging spells).
  /// [chargeSpent] is the charge consumed by this cast (casting spends all).
  void _triggerElementEffects(
      _Entry cast, int rawDamage, int chargeSpent, List<DuelEvent> e) {
    final caster = cast.caster;
    final target = cast.target;
    final spell = cast.spell!;
    switch (cast.element) {
      // ---- Tier 1 — Primal ---------------------------------------------
      case MagicElement.pyro:
        // Ignite — 25% on a damaging hit (even a fully-shielded one).
        if (rawDamage > 0 &&
            rng.nextDouble() < ElementTuning.ignitePercent / 100) {
          _applyIgnite(target, rawDamage, e);
        }
      case MagicElement.flora:
        // Photosynthesis — ⭐ streak-gated like Tailwind. Nothing happens for
        // the first four consecutive Flora casts; from the 5th onward the
        // caster heals 1% max HP per turn and cannot be Waterlogged.
        if (PhotosynthesisStatus.activeFor(caster)) {
          if (_statusOf<PhotosynthesisStatus>(caster) == null) {
            caster.statuses.add(PhotosynthesisStatus());
            e.add(BuffAppliedEvent(caster, 'Photosynthesis — active',
                statusId: 'photosynthesis'));
          }
        }
      case MagicElement.aqua:
        // Waterlogged — every 3rd consecutive Aqua cast slows the opponent's
        // next action by +10 priority, unless they hold Photosynthesis.
        if (caster.streakElement == MagicElement.aqua &&
            caster.streakCount % ElementTuning.waterloggedEveryNthCast == 0) {
          if (_statusOf<PhotosynthesisStatus>(target) == null &&
              !_graceBlocks(target, e)) {
            target.priorityPenalty = ElementTuning.waterloggedPriorityPenalty;
            e.add(BuffAppliedEvent(
                target, 'Waterlogged — next action slowed',
                statusId: 'waterlogged'));
          }
        }
        // An Aqua elemental shield cleanses the caster's Ignite.
        if (spell.effect is ShieldEffect &&
            _statusOf<IgniteStatus>(caster) != null) {
          caster.statuses.removeWhere((s) => s is IgniteStatus);
          e.add(BuffAppliedEvent(caster, 'Ignite doused',
              statusId: 'igniteDoused'));
        }

      // ---- Tier 2 — Kinetic --------------------------------------------
      case MagicElement.electro:
        if (rawDamage > 0) {
          // Any Electro attack wipes the target's Tailwind streak (their
          // already-held Haste is untouched).
          if (target.streakElement == MagicElement.aero &&
              target.streakCount > 0) {
            target.streakElement = null;
            target.streakCount = 0;
            e.add(BuffAppliedEvent(target, 'Tailwind scattered',
                statusId: 'tailwindScattered'));
          }
          // Static Feedback — 20% on hit strips one charge. Grounded out by
          // a Geo shield still standing after the hit.
          final grounded = target.shield?.element == MagicElement.geo;
          if (!grounded &&
              _drainableCharge(target) > 0 &&
              rng.nextDouble() < ElementTuning.staticFeedbackPercent / 100) {
            final taken = _drainCharge(target, 1);
            if (taken > 0) e.add(ChargeDrainedEvent(target, taken));
          }
        }
      case MagicElement.aero:
        // Tailwind — from the 3rd consecutive Aero cast onward, each cast
        // grabs the Haste token (applied after normal Haste transfer, so the
        // wind always wins the turn's initiative scramble).
        if (caster.streakElement == MagicElement.aero &&
            caster.streakCount >= ElementTuning.tailwindStreak) {
          _tailwindGrab = caster;
        }
      case MagicElement.geo:
        // Stagger — every 4th consecutive Geo cast blunts the opponent's
        // next offensive spell to 50% damage. Whiffs against an active
        // Tailwind streak of 3+ (Aero weathers Geo).
        if (caster.streakElement == MagicElement.geo &&
            caster.streakCount % ElementTuning.staggerEveryNthCast == 0) {
          final windShielded = target.streakElement == MagicElement.aero &&
              target.streakCount >= 3;
          if (!windShielded && !_graceBlocks(target, e)) {
            target.nextOffensiveDamageScale =
              ElementTuning.staggerDamagePercent / 100;
            e.add(BuffAppliedEvent(
                target, 'Staggered — next offensive spell halved',
                statusId: 'stagger'));
          }
        }

      // ---- Tier 3 — Celestial ------------------------------------------
      case MagicElement.solar:
        // Blind — 10% per charge spent, on attack (even fully shielded).
        // Inherited from Radiant; the immunity is now Astral, and the proc no
        // longer clears Creeping Dark (that moved to Absolution). While
        // present, Blind also eclipses the target's moon to New (§4b.3).
        if (rawDamage > 0 &&
            chargeSpent > 0 &&
            rng.nextDouble() <
                ElementTuning.blindPercentPerCharge / 100 * chargeSpent) {
          _applyBlind(target, e);
        }
      case MagicElement.lunar:
        // Lunar → Astral: a Lunar attack strips one Alignment stack from the
        // target; under a Full Moon it strips them all (§4b table).
        if (rawDamage > 0) {
          final align = _statusOf<AstralAlignmentStatus>(target);
          if (align != null) {
            if (_effectiveMoonPhase(caster) == MoonPhase.full) {
              target.statuses.removeWhere((s) => s is AstralAlignmentStatus);
              e.add(BuffAppliedEvent(
                  target, 'Alignment scattered (Full Moon)',
                  statusId: 'alignmentStripped'));
            } else {
              align.stacks--;
              if (align.stacks <= 0) {
                target.statuses.removeWhere((s) => s is AstralAlignmentStatus);
              }
              e.add(BuffAppliedEvent(target, 'Alignment stripped',
                  statusId: 'alignmentStripped'));
            }
          }
        }
      case MagicElement.astral:
        // Astral Alignment — +1 stack per CHARGE SPENT on the cast (max 20),
        // so committing a big Astral spell aligns far faster than spamming
        // cheap ones. Decay is the status's end-of-turn bookkeeping.
        // A 0-charge cast (Flick) grants nothing — spending is the commitment.
        if (chargeSpent > 0) {
          final align = _statusOf<AstralAlignmentStatus>(caster) ??
              (() {
                final s = AstralAlignmentStatus(0);
                caster.statuses.add(s);
                return s;
              })();
          align.addStacks(chargeSpent);
          e.add(BuffAppliedEvent(
              caster,
              'Astral Alignment (${align.stacks} — ${align.piercePercent}% pierce)',
              statusId: 'astralAlignment'));
        }

      // ---- Tier 4 — Ethereal -------------------------------------------
      case MagicElement.sanctus:
        // Absolution — every 3rd consecutive Sanctus cast. Schedules a purge
        // for the end heal band (before Ignite's E8) via a one-shot status.
        if (caster.streakElement == MagicElement.sanctus &&
            caster.streakCount % 3 == 0) {
          caster.statuses.add(PendingAbsolutionStatus());
          e.add(BuffAppliedEvent(caster, 'Absolution rising',
              statusId: 'absolutionRising'));
        }
      case MagicElement.umbra:
        // Creeping Dark — stacks grow by the charge spent on each cast.
        if (chargeSpent > 0) {
          final dark = _statusOf<CreepingDarkStatus>(caster) ??
              (() {
                final s = CreepingDarkStatus();
                caster.statuses.add(s);
                return s;
              })();
          dark.addStacks(chargeSpent);
          e.add(BuffAppliedEvent(
              caster, 'Creeping Dark (${dark.stacks} stacks)',
              statusId: 'creepingDark'));
        }
      case MagicElement.arcane:
        // Arcane → Sanctus: an Arcane attack that lands on health resets the
        // target's Sanctus streak to 0, pushing Absolution three casts away
        // (§4c.3). Fully-shielded / missed / fizzled hits don't count (§5.4),
        // hence _lastAttackToHp rather than rawDamage.
        if (_lastAttackToHp > 0 &&
            target.streakElement == MagicElement.sanctus) {
          target.streakElement = null;
          target.streakCount = 0;
          e.add(BuffAppliedEvent(target, 'Sanctus rite unravelled',
              statusId: 'sanctusUnravelled'));
        }
        // Arcane Knowledge — a 4+ charge Arcane cast earns a stack, unless
        // the opponent's darkness is at Dusk or worse (Umbra corrupts
        // Arcane).
        if (chargeSpent >= 4) {
          final theirDark = _statusOf<CreepingDarkStatus>(target);
          if (theirDark == null || !theirDark.dusk) {
            final ak = _statusOf<ArcaneKnowledgeStatus>(caster);
            if (ak == null) {
              caster.statuses.add(ArcaneKnowledgeStatus());
            } else {
              ak.addStack();
            }
            final stacks = _statusOf<ArcaneKnowledgeStatus>(caster)!.stacks;
            caster.bonusDamagePercent =
                stacks * ArcaneKnowledgeStatus.percentPerStack;
            e.add(BuffAppliedEvent(
                caster,
                'Arcane Knowledge ($stacks stacks, '
                    '+${caster.bonusDamagePercent}% damage)',
                statusId: 'arcaneKnowledge'));
          }
        }
    }
  }

  /// Applies (or refreshes) Blind on [target]. Under V2 this no longer clears
  /// Creeping Dark (that job is Absolution's); it does, while it persists,
  /// eclipse the target's moon (read by [_effectiveMoonPhase]).
  void _applyBlind(MageState target, List<DuelEvent> e) {
    if (_graceBlocks(target, e)) return;
    final existing = _statusOf<BlindStatus>(target);
    if (existing != null) {
      existing.refresh();
    } else {
      target.statuses.add(BlindStatus());
    }
    e.add(BuffAppliedEvent(target, 'Blinded — 50% miss for 3 turns',
        statusId: 'blind'));
  }

  /// The moon phase governing [mage]'s Lunar spells: the global clock, unless
  /// they are eclipsed — while Blind is *active* (its 3-turn miss window),
  /// their moon locks to New, denying the Full-Moon bonus (Solar → Lunar,
  /// §4b.3). Keyed on the miss window (`missChance > 0`), not mere presence,
  /// so the eclipse matches Blind's 3 turns exactly and skips the application
  /// turn — the same "starts next turn" rule the misses follow. Per-mage: the
  /// Solar caster's own moon still turns.
  MoonPhase _effectiveMoonPhase(MageState mage) => mage.missChance > 0
      ? MoonPhase.newMoon
      : moonPhaseForTurn(turnNumber);

  /// If [target] holds Grace, consume it and return true (the incoming debuff
  /// is blocked). Grace is max-1 and persists until spent (§4c.1).
  bool _graceBlocks(MageState target, List<DuelEvent> e) {
    if (!target.hasGrace) return false;
    target.hasGrace = false;
    e.add(BuffAppliedEvent(target, 'Grace absorbs the debuff',
        statusId: 'graceConsumed'));
    return true;
  }

  /// Applies (or refreshes) Ignite on [target]: a burn of 10% of [rawDamage]
  /// per tick. Landing Ignite breaks the target's Flora streak, which ends
  /// any active Photosynthesis — stripping the status alone would let it return
  /// on their very next Flora cast.
  void _applyIgnite(MageState target, int rawDamage, List<DuelEvent> e) {
    final perTick = (rawDamage * 0.10).round();
    if (perTick < 1) return; // a sub-1 burn is no burn
    if (_graceBlocks(target, e)) return;
    // ⚠️ Break the STREAK, not just the status. Photosynthesis is derived from
    // the streak now, so removing the status alone would let it reappear on the
    // very next Flora cast and Ignite would counter nothing.
    if (target.streakElement == MagicElement.flora) {
      target.streakElement = null;
      target.streakCount = 0;
    }
    target.statuses.removeWhere((s) => s is PhotosynthesisStatus);
    final existing = _statusOf<IgniteStatus>(target);
    if (existing != null) {
      existing.refresh(perTick);
    } else {
      target.statuses.add(IgniteStatus(perTick));
    }
    e.add(BuffAppliedEvent(target, 'Ignited ($perTick/turn)',
        statusId: 'ignite'));
  }

  T? _statusOf<T extends TurnStatus>(MageState mage) {
    for (final s in mage.statuses) {
      if (s is T) return s;
    }
    return null;
  }

  /// Applies one [amount] of damage to [target], resolving shields and counter
  /// math, and mutating hp/shield. Returns the breakdown so callers can emit
  /// the right event. Shared by spell attacks and status ticks (DoTs), so
  /// shield behavior is identical everywhere. [attackElement] null = element-
  /// agnostic (never counters); [ignoresShields] strikes health directly.
  ({
    int toShield,
    int toHp,
    bool broken,
    int multiplierPercent,
    bool barrierPopped
  }) _applyOneHit(
    MageState target,
    int amount,
    MagicElement? attackElement,
    bool ignoresShields,
  ) {
    // The Barrier slot is checked FIRST and independently of the elemental
    // shield — the two coexist, so a Barrier eats this hit whole and shatters
    // while the shield underneath is left completely untouched for the next.
    if (!ignoresShields && target.barrierPoints > 0) {
      target.barrierPoints--;
      // `broken` stays false: the ELEMENTAL shield is untouched and still
      // standing. Callers distinguish the two via [barrierPopped].
      return (
        toShield: amount,
        toHp: 0,
        broken: false,
        multiplierPercent: 100,
        barrierPopped: true
      );
    }
    final shield = ignoresShields ? null : target.shield;
    if (shield == null) {
      target.takeHpDamage(amount);
      return (
        toShield: 0,
        toHp: amount,
        broken: false,
        multiplierPercent: 100,
        barrierPopped: false
      );
    }
    // Defensive: barriers belong in [MageState.barrier], but an element-less
    // shield in this slot must degrade gracefully rather than crash on
    // `element!` below.
    if (shield.isBarrier) {
      target.shield = null;
      return (
        toShield: amount,
        toHp: 0,
        broken: false,
        multiplierPercent: 100,
        barrierPopped: true
      );
    }
    // §0.3 shield multiplier (50/75/100/150/200%). All arithmetic stays
    // integer so both lockstep clients land on the identical remainder.
    final pct = shieldMultiplierPercent(attackElement, shield.element!);
    final effective = amount * pct ~/ 100;
    if (effective < shield.remaining) {
      shield.remaining -= effective;
      return (
        toShield: effective,
        toHp: 0,
        broken: false,
        multiplierPercent: pct,
        barrierPopped: false
      );
    }
    // Overflow: the raw damage spent breaking the shield is rounded in the
    // defender's favor (ceil of absorbed ÷ multiplier); the rest strikes
    // health at the normal 1× rate.
    final absorbed = shield.remaining;
    final rawConsumed = (absorbed * 100 + pct - 1) ~/ pct;
    final toHp = amount - rawConsumed;
    target.shield = null;
    target.takeHpDamage(toHp);
    return (
      toShield: absorbed,
      toHp: toHp,
      broken: true,
      multiplierPercent: pct,
      barrierPopped: false
    );
  }

  /// Resolves one turn phase (start or end): gathers each mage's status ops,
  /// orders them survivability-first (low lane = earlier; heals before damage),
  /// breaks same-lane ties with the Haste holder, and applies them one at a
  /// time. Deaths are instant — the first lethal op ends the phase (this is why
  /// the Haste holder "dies first" to symmetric end-of-turn DoTs). End-phase
  /// bookkeeping advances/expires durations after all ops.
  void _resolvePhase(TurnPhase phase, List<DuelEvent> events) {
    final tieHolder = hasteHolder;
    final queued =
        <({MageState holder, TurnStatus status, StatusOp op, int seq})>[];
    var seq = 0;
    for (final mage in [mage1, mage2]) {
      for (final status in mage.statuses) {
        for (final op in status.operationsFor(phase, mage)) {
          queued.add((holder: mage, status: status, op: op, seq: seq++));
        }
      }
    }
    queued.sort((a, b) {
      final byLane = a.op.lane.compareTo(b.op.lane);
      if (byLane != 0) return byLane;
      final aHaste = identical(a.holder, tieHolder);
      final bHaste = identical(b.holder, tieHolder);
      if (aHaste != bHaste) return aHaste ? -1 : 1;
      return a.seq.compareTo(b.seq); // fully deterministic for lockstep
    });
    for (final q in queued) {
      if (isOver) break; // instant death stops the phase
      if (!q.holder.alive) continue;
      // A status removed earlier this phase (e.g. Absolution in the heal band
      // purging an Ignite) cancels its own later ops — so a purged burn never
      // gets its E8 tick. Ops are gathered up-front, so we re-check presence.
      if (!q.holder.statuses.contains(q.status)) continue;
      _applyStatusOp(q.holder, q.op, events);
    }
    // Bookkeeping band (E9–E10): advance durations/stacks once per turn.
    if (phase == TurnPhase.end) {
      for (final mage in [mage1, mage2]) {
        mage.statuses.removeWhere((s) => s.advanceAndCheckExpiry(mage));
      }
    }
  }

  void _applyStatusOp(MageState holder, StatusOp op, List<DuelEvent> events) {
    switch (op) {
      case StatusHeal(:final amount, :final source):
        final before = holder.hp;
        holder.heal(amount);
        events.add(EffectHealEvent(holder, source, holder.hp - before));
      case StatusDamage(
          :final amount,
          :final element,
          :final bypassShield,
          :final source
        ):
        final r = _applyOneHit(holder, amount, element, bypassShield);
        events.add(EffectDamageEvent(holder, source,
            toShield: r.toShield,
            toHp: r.toHp,
            shieldMultiplierPercent: r.multiplierPercent,
            shieldBroken: r.broken,
            barrierPopped: r.barrierPopped));
      case StatusPurge():
        _resolveAbsolution(holder, events);
    }
  }

  /// Resolves Absolution for [holder] (Sanctus, §4c). Two parts, both
  /// unconditional on the purge outcome:
  ///  1. **Sanctus → Umbra:** strip 5 Creeping Dark from the opponent.
  ///  2. **Self:** remove one random [Debuff]; if there is none, bank Grace.
  void _resolveAbsolution(MageState holder, List<DuelEvent> events) {
    final opponent = identical(holder, mage1) ? mage2 : mage1;
    final dark = _statusOf<CreepingDarkStatus>(opponent);
    if (dark != null) {
      dark.stacks = (dark.stacks - 5).clamp(0, CreepingDarkStatus.maxStacks);
      if (dark.stacks <= 0) {
        opponent.statuses.removeWhere((s) => s is CreepingDarkStatus);
      }
      events.add(BuffAppliedEvent(opponent, 'Creeping Dark seared (−5)',
          statusId: 'darkSeared'));
    }

    // The removable-debuff pool is every lingering [Debuff] status PLUS the
    // two field-debuffs (Waterlogged, Stagger) — which aren't statuses but are
    // still afflictions the doc's purge list names (§4c.1). Built in a fixed
    // order so the shared-seed pick is identical on both lockstep clients.
    final removable = <({String label, void Function() clear})>[
      for (final s in holder.statuses.whereType<Debuff>().cast<TurnStatus>())
        (label: s.id, clear: () => holder.statuses.remove(s)),
      if (holder.priorityPenalty > 0)
        (label: 'Waterlogged', clear: () => holder.priorityPenalty = 0),
      if (holder.nextOffensiveDamageScale < 1.0)
        (label: 'Stagger', clear: () => holder.nextOffensiveDamageScale = 1.0),
    ];

    if (removable.isEmpty) {
      // Nothing to purge → bank Grace instead, so Absolution is never a dead
      // cast against a status-light opponent.
      if (!holder.hasGrace) {
        holder.hasGrace = true;
        events.add(BuffAppliedEvent(holder, 'Grace — next debuff blocked',
            statusId: 'grace'));
      }
    } else {
      // Uniformly random, from the shared per-turn seed (§4c.1).
      final victim = removable[rng.nextInt(removable.length)];
      victim.clear();
      events.add(BuffAppliedEvent(
          holder, 'Absolution — ${victim.label} purged',
          statusId: 'absolution'));
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
    if (identical(newHolder, startHolder)) return;

    // Report it immediately after the cast that seized it, not at end of turn
    // — "you seize the initiative" arriving after all the damage read as a
    // separate, unexplained beat. When Haste becomes contested (a
    // same-priority tie, newHolder == null) there is no single owning cast, so
    // it lands after the later of the two.
    final owner = newHolder == null
        ? qualifying.map((e) => e.endEventIndex).reduce((a, b) => a > b ? a : b)
        : qualifying
            .firstWhere((e) => identical(e.caster, newHolder))
            .endEventIndex;
    events.insert(owner.clamp(0, events.length), HasteChangedEvent(newHolder));
  }
}

/// One mage's resolved action for a turn (a channel or a spell cast).
class _Entry {
  final MageState caster;
  final MageState target;
  final MageAction action;
  final MagicElement element;
  final int priority;

  /// Set true when the cast fizzled (charge pulled below cost at resolution),
  /// so the caster keeps the charge they had.
  bool fizzled = false;

  /// True once this entry has been resolved, so a later drain in the same turn
  /// cannot retroactively strip charge from a spell that already went off.
  bool resolved = false;

  /// The caster's charge at the moment they paid for this cast.
  ///
  /// ⚠️ Needed because payment happens **when the cast resolves**, not in a
  /// sweep after the whole turn. Barrage scales with its own caster's charge,
  /// which by resolution time has already been spent — so it reads this.
  int chargeAtCast = 0;

  /// Index just past this entry's last emitted event. Lets the Haste transfer
  /// be reported immediately after the cast that seized it (its rules need to
  /// see BOTH casts, so it can only be *computed* once the turn has resolved).
  int endEventIndex = 0;

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
