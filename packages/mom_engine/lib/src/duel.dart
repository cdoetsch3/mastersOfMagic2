import 'dart:math';

import 'action.dart';
import 'element.dart';
import 'element_status.dart';
import 'events.dart';
import 'mage.dart';
import 'spell.dart';
import 'status.dart';

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

  /// Sudden death (TYPE_EFFECTS_DESIGN.md §8): after [fatigueThreshold] turns,
  /// both mages take escalating **unblockable** damage at end of turn, growing
  /// by [fatiguePerTurn] each turn. Guarantees every duel terminates — kills
  /// stall strategies (e.g. Photosynthesis turtling) and backstops the
  /// disconnect/forfeit handling. Threshold/step are tentative — tune later.
  static const int fatigueThreshold = 50;
  static const int fatiguePerTurn = 3;

  /// Whether element side-effects (Ignite procs, Photosynthesis stacks,
  /// Waterlogged, …) fire on casts. Always true in real duels; tests of core
  /// resolution semantics (priority, shields, Haste) may switch them off so
  /// hand-computed expectations aren't perturbed by procs.
  final bool elementEffects;

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
      return TurnResult(turnNumber, events);
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

    // Casting consumes all charge and ends the element cycle. Channels keep
    // their charge; so do fizzles (the spell never went off — you keep what
    // you had, per Static Feedback's "you'd still have 3 charge").
    for (final e in entries) {
      if (!e.isChannel && !e.fizzled) {
        e.caster.charge = 0;
        e.caster.element = null;
      }
    }

    _updateHaste(entries, startHolder, events);

    // Tailwind overrides the normal Haste scramble: the wind takes the token.
    final grab = _tailwindGrab;
    _tailwindGrab = null;
    if (grab != null && !grab.hasHaste) {
      mage1.hasHaste = identical(grab, mage1);
      mage2.hasHaste = identical(grab, mage2);
      events.add(HasteChangedEvent(grab));
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

  /// Whether [caster] still has the charge [spell] needs at resolution time
  /// (charge may have been stripped by Static Feedback / a same-turn
  /// Discharge since the action was committed).
  bool _hasChargeToCast(MageState caster, Spell spell) =>
      spell.xCost ? caster.charge >= 1 : caster.charge >= spell.chargeCost;

  int _consumePriorityPenalty(MageState mage) {
    final p = mage.priorityPenalty;
    mage.priorityPenalty = 0;
    return p;
  }

  void _resolveCast(_Entry cast, List<DuelEvent> events) {
    final caster = cast.caster;
    final spell = cast.spell!;

    // Precedence step 1 — Fizzle: a committed spell whose charge was pulled
    // below its cost does not cast. Like a charge, it keeps its remaining
    // charge and advances no streak (see the post-resolution charge sweep).
    if (!_hasChargeToCast(caster, spell)) {
      cast.fizzled = true;
      events.add(SpellFizzledEvent(caster, spell));
      return;
    }

    // Precedence step 3 — Miss (Blind): a harmful spell may miss. Unlike a
    // fizzle, the charge is still spent (the post-resolution sweep zeroes it);
    // the spell simply has no effect and advances no streak. Arcane spells
    // are exempt — they never miss (Arcane unravels Sanctus, §4 table).
    if (spell.isHarmful &&
        cast.element != MagicElement.arcane &&
        caster.missChance > 0 &&
        rng.nextDouble() < caster.missChance) {
      events.add(SpellMissedEvent(caster, spell));
      return;
    }

    events.add(SpellCastEvent(caster, spell, cast.element));
    // Casting consumes ALL charge; capture it now for charge-spent triggers
    // (Sanctus/Umbra/Arcane) before effects read or mutate it.
    final chargeSpent = caster.charge;

    // Precedence step 2/4 — Stagger is consumed by any harmful spell that
    // resolves (Discharge too — a harmless "stagger-eater").
    var staggerScale = 1.0;
    if (spell.isHarmful) {
      staggerScale = caster.nextOffensiveDamageScale;
      caster.nextOffensiveDamageScale = 1.0;
    }

    // Damage modifiers in order: additive (Arcane Knowledge +5%/stack) then
    // multipliers (Empower ×2, Stagger ×0.5).
    double damageScale(({int multiplier, bool phase}) buffs) =>
        (1 + caster.bonusDamagePercent / 100) * buffs.multiplier * staggerScale;

    var rawDamage = 0; // total pre-shield damage rolled (for Ignite)
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
        final charge = caster.charge; // live — a same-turn Discharge fizzles it
        rawDamage = _attack(
          cast,
          minPerHit: minPerCharge * charge,
          maxPerHit: maxPerCharge * charge,
          scale: damageScale(buffs),
          hits: 1,
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
        final strength = _roll(minStrength, maxStrength);
        caster.shield = ActiveShield.elemental(cast.element, strength);
        events.add(ShieldRaisedEvent(caster,
            element: cast.element, isBarrier: false, strength: strength));
      case BarrierEffect():
        caster.shield = ActiveShield.barrier();
        events.add(ShieldRaisedEvent(caster,
            element: null, isBarrier: true, strength: 0));
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

    // Any resolved cast (offensive or not) advances the element streak.
    // Fizzles and misses returned early — they leave the streak untouched.
    caster.recordCastForStreak(cast.element);

    // Fire this element's on-cast effects (Tier 1: Ignite, Photosynthesis,
    // Waterlogged, and the Aqua-shield cleanse).
    if (elementEffects) {
      _triggerElementEffects(cast, rawDamage, chargeSpent, events);
    }
  }

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
    final target = cast.target;
    final spell = cast.spell!;
    var totalToHp = 0;
    var totalRaw = 0;
    for (var h = 0; h < hits; h++) {
      final perHit = (_roll(minPerHit, maxPerHit) * scale).round();
      totalRaw += perHit;
      final r = _applyOneHit(target, perHit, cast.element, ignoresShields);
      totalToHp += r.toHp;
      events.add(DamageEvent(target, spell,
          toShield: r.toShield,
          toHp: r.toHp,
          shieldMultiplierPercent: r.multiplierPercent,
          shieldBroken: r.broken));
    }
    if (lifesteal > 0 && totalToHp > 0) {
      final healed = (totalToHp * lifesteal).round();
      cast.caster.heal(healed);
      events.add(HealedEvent(cast.caster, healed));
    }
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
        if (rawDamage > 0 && rng.nextDouble() < 0.25) {
          _applyIgnite(target, rawDamage, e);
        }
      case MagicElement.flora:
        // Photosynthesis — every Flora cast adds a stack.
        final photo = _statusOf<PhotosynthesisStatus>(caster);
        if (photo == null) {
          caster.statuses.add(PhotosynthesisStatus());
        } else {
          photo.addStack();
        }
        e.add(BuffAppliedEvent(caster, 'Photosynthesis '
            '(${_statusOf<PhotosynthesisStatus>(caster)!.stacks} stacks)'));
      case MagicElement.aqua:
        // Waterlogged — every 3rd consecutive Aqua cast slows the opponent's
        // next action by +10 priority, unless they hold Photosynthesis.
        if (caster.streakElement == MagicElement.aqua &&
            caster.streakCount % 3 == 0) {
          if (_statusOf<PhotosynthesisStatus>(target) == null) {
            target.priorityPenalty = 10;
            e.add(BuffAppliedEvent(target, 'Waterlogged — next action slowed'));
          }
        }
        // An Aqua elemental shield cleanses the caster's Ignite.
        if (spell.effect is ShieldEffect &&
            _statusOf<IgniteStatus>(caster) != null) {
          caster.statuses.removeWhere((s) => s is IgniteStatus);
          e.add(BuffAppliedEvent(caster, 'Ignite doused'));
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
            e.add(BuffAppliedEvent(target, 'Tailwind scattered'));
          }
          // Static Feedback — 20% on hit strips one charge. Grounded out by
          // a Geo shield still standing after the hit.
          final grounded = target.shield?.element == MagicElement.geo;
          if (!grounded && target.charge > 0 && rng.nextDouble() < 0.20) {
            target.charge--;
            e.add(ChargeDrainedEvent(target, 1));
            if (target.charge == 0) target.element = null;
          }
        }
      case MagicElement.aero:
        // Tailwind — from the 3rd consecutive Aero cast onward, each cast
        // grabs the Haste token (applied after normal Haste transfer, so the
        // wind always wins the turn's initiative scramble).
        if (caster.streakElement == MagicElement.aero &&
            caster.streakCount >= 3) {
          _tailwindGrab = caster;
        }
      case MagicElement.geo:
        // Stagger — every 4th consecutive Geo cast blunts the opponent's
        // next offensive spell to 50% damage. Whiffs against an active
        // Tailwind streak of 3+ (Aero weathers Geo).
        if (caster.streakElement == MagicElement.geo &&
            caster.streakCount % 4 == 0) {
          final windShielded = target.streakElement == MagicElement.aero &&
              target.streakCount >= 3;
          if (!windShielded) {
            target.nextOffensiveDamageScale = 0.5;
            e.add(BuffAppliedEvent(
                target, 'Staggered — next offensive spell halved'));
          }
        }

      // ---- Tier 3 — Celestial ------------------------------------------
      // Solar/Lunar/Astral effects land in Phase 3 (TYPE_EFFECTS §4b). Listed
      // explicitly so the roster change is visible here rather than falling
      // silently through a non-exhaustive switch statement.
      case MagicElement.solar:
      case MagicElement.lunar:
      case MagicElement.astral:
        break;

      // ---- Tier 4 — Ethereal -------------------------------------------
      case MagicElement.sanctus:
        // Blind — 10% per charge spent, on attack (even fully shielded).
        // A proc also burns away the target's Creeping Dark entirely.
        if (rawDamage > 0 &&
            chargeSpent > 0 &&
            rng.nextDouble() < 0.10 * chargeSpent) {
          _applyBlind(target, e);
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
              caster, 'Creeping Dark (${dark.stacks} stacks)'));
        }
      case MagicElement.arcane:
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
            e.add(BuffAppliedEvent(caster,
                'Arcane Knowledge ($stacks stacks, +${caster.bonusDamagePercent}% damage)'));
          }
        }
    }
  }

  /// Applies (or refreshes) Blind on [target] and dispels their darkness.
  void _applyBlind(MageState target, List<DuelEvent> e) {
    if (_statusOf<CreepingDarkStatus>(target) != null) {
      target.statuses.removeWhere((s) => s is CreepingDarkStatus);
      target.concealed = false;
      e.add(BuffAppliedEvent(target, 'Creeping Dark burned away'));
    }
    final existing = _statusOf<BlindStatus>(target);
    if (existing != null) {
      existing.refresh();
    } else {
      target.statuses.add(BlindStatus());
    }
    e.add(BuffAppliedEvent(target, 'Blinded — 50% miss for 3 turns'));
  }

  /// Applies (or refreshes) Ignite on [target]: a burn of 10% of [rawDamage]
  /// per tick. Landing Ignite clears the target's Photosynthesis stacks.
  void _applyIgnite(MageState target, int rawDamage, List<DuelEvent> e) {
    final perTick = (rawDamage * 0.10).round();
    if (perTick < 1) return; // a sub-1 burn is no burn
    target.statuses.removeWhere((s) => s is PhotosynthesisStatus);
    final existing = _statusOf<IgniteStatus>(target);
    if (existing != null) {
      existing.refresh(perTick);
    } else {
      target.statuses.add(IgniteStatus(perTick));
    }
    e.add(BuffAppliedEvent(target, 'Ignited ($perTick/turn)'));
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
  ({int toShield, int toHp, bool broken, int multiplierPercent}) _applyOneHit(
    MageState target,
    int amount,
    MagicElement? attackElement,
    bool ignoresShields,
  ) {
    final shield = ignoresShields ? null : target.shield;
    if (shield == null) {
      target.takeHpDamage(amount);
      return (toShield: 0, toHp: amount, broken: false, multiplierPercent: 100);
    }
    if (shield.isBarrier) {
      target.shield = null;
      return (toShield: amount, toHp: 0, broken: true, multiplierPercent: 100);
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
        multiplierPercent: pct
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
      multiplierPercent: pct
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
    final queued = <({MageState holder, StatusOp op, int seq})>[];
    var seq = 0;
    for (final mage in [mage1, mage2]) {
      for (final status in mage.statuses) {
        for (final op in status.operationsFor(phase, mage)) {
          queued.add((holder: mage, op: op, seq: seq++));
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
            shieldBroken: r.broken));
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

  /// Set true when the cast fizzled (charge pulled below cost at resolution),
  /// so the post-resolution sweep leaves the caster's charge intact.
  bool fizzled = false;

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
