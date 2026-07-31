import 'dart:math';

import 'action.dart';
import 'ai.dart';
import 'element.dart';
import 'element_status.dart';
import 'mage.dart';
import 'spell.dart';
import 'spellbook.dart';
import 'status.dart';

/// The **1–10 intelligence ladder** from GAME_DESIGN §6b, as one brain.
///
/// Each level adds a specific *competence*, not a bigger number — a dial only
/// makes an opponent better at the same game, while a ladder makes each step a
/// qualitatively different opponent:
///
/// | Lvl | Gains |
/// |---|---|
/// | 1 | Any legal move, uniformly at random |
/// | 2 | One habit, repeated forever |
/// | 3 | Charge to a fixed number, then cast |
/// | 4 | Stops wasting charge, and **shields under threat** |
/// | 5 | **Counter-aware** — reads the enemy shield's element |
/// | 6 | Never misses a lethal |
/// | 7 | **Sees statuses** — Ignite, Blind, and damage already on the clock |
/// | 8 | **Plans toward a payoff** — refuses to feed a wall; builds stacks |
/// | 9 | **Predictive** — pre-empts the big hit implied by enemy charge |
/// | 10 | Everything 9 does, and **never blunders** |
///
/// ⭐ **Two things carry difficulty, not one.** The *competences* above make
/// each rung a qualitatively different opponent; on top of them sits a
/// **blunder rate** that falls as the ladder rises — a flat chance each turn of
/// throwing the move away and playing at random instead. Competences alone
/// separated the upper rungs by only a point or two, which is not a usable
/// dial; the blunder gradient is what turns them into distinct difficulties.
///
/// ⭐ **Levels 1-3 are ordered by weakness, not by sophistication.** Uniform
/// random is genuinely the worst thing on the ladder (it squanders whole charge
/// cycles), a single repeated habit is next, and a fixed charge-then-cast
/// rhythm is the strongest of the three. Numbering them the other way — which
/// is how the design first read — made the bottom of the dial run backwards.
///
/// ⭐ **Shielding starts at 4, not 6.** Putting up a wall is core play, not an
/// advanced tactic — and while nothing below 6 shielded, two things broke:
/// spamming a 0-charge Flick was a viable strategy against the low rungs, and
/// level 5's counter-awareness had no walls to counter, so it could not
/// measure at all.
///
/// ⭐ **Prediction sits at 9 because it measures as the strongest single
/// competence.** Pre-shielding a telegraphed cast beat every other rung in
/// simulation, so rating it 7 made the ladder non-monotonic. Status sight and
/// payoff planning are real but narrower, and moved down accordingly.
///
/// ⭐ **Level 10 plays exactly like level 9 and never blunders.** An earlier
/// version had it randomise its spell choice and its timing to be unreadable.
/// Both are *deliberately suboptimal in isolation* — mixing takes a
/// near-best line, and cashing out early sacrifices the efficiency big spells
/// are built around — and they only pay against an opponent that learns
/// patterns. Nothing in a simulation does, so level 10 was paying a real cost
/// to collect nothing. A perfect executor is the cleaner definition of the top
/// rung.
///
/// Capabilities are **cumulative** — a level-9 brain also does everything 5–8
/// do. Guarded by `test/ladder_ai_test.dart`, which plays the rungs against
/// each other and asserts the ladder actually climbs.
/// What a mage can **legitimately observe** about its opponent.
///
/// ⚠️ Reading [MageState] directly lets an AI see straight through Umbra's
/// Creeping Dark, which is the entire point of that element — an AI that
/// cheats makes Umbra worthless against everything except humans. The engine
/// treats concealment as display-layer, so enforcing it is the *caller's* job.
///
/// | Threshold | Hidden from the opponent |
/// |---|---|
/// | Shadow (5+) | which element they are charging |
/// | Dusk (10+) | their charge **and** their health |
///
/// 📝 **Midnight (15) is deliberately not modelled here.** It hides a mage's
/// *own* charge and health from itself, which is a UI stress rather than
/// hidden information — a human under Midnight still remembers what they just
/// did. Simulating amnesia would punish the AI for something a player does not
/// actually suffer.
class EnemyView {
  final MageState _enemy;
  final bool elementHidden;
  final bool chargeHidden;
  final bool healthHidden;

  EnemyView._(this._enemy, this.elementHidden, this.chargeHidden,
      this.healthHidden);

  factory EnemyView.of(MageState enemy) {
    CreepingDarkStatus? dark;
    for (final s in enemy.statuses) {
      if (s is CreepingDarkStatus) dark = s;
    }
    return EnemyView._(
      enemy,
      dark?.shadow ?? false,
      dark?.dusk ?? false,
      dark?.dusk ?? false,
    );
  }

  /// Charge, or `null` when Dusk hides it.
  int? get charge => chargeHidden ? null : _enemy.charge;

  /// Health, or `null` when Dusk hides it.
  int? get hp => healthHidden ? null : _enemy.hp;

  /// The element they are charging, or `null` under Shadow.
  MagicElement? get element => elementHidden ? null : _enemy.element;

  /// Shields are a visible board object — Creeping Dark does not hide them.
  ActiveShield? get shield => _enemy.shield;

  /// Statuses are visible; the thresholds hide element, charge and health only.
  List<TurnStatus> get statuses => _enemy.statuses;

  int get barrierPoints => _enemy.barrierPoints;
}

/// Chance a rung throws its turn away and plays at random instead.
///
/// ⭐ The competence ladder makes each rung a *different* opponent; this makes
/// each rung a *harder* one. Measured with competences alone, levels 6-9 sat
/// within two points of each other — real differences in character, useless as
/// a difficulty setting. The blunder gradient is what spreads them out.
///
/// Level 1 is absent because it is already fully random; blundering is its
/// entire behaviour rather than a modifier on it.
/// ⚠️ Compressed at the bottom on purpose. At 0.48 a level-2 brain blunders
/// away half its habit and becomes indistinguishable from level 1's pure
/// randomness — the rung stops meaning anything.
const Map<int, double> _blunderRate = {
  2: 0.32, 3: 0.26, 4: 0.21, 5: 0.17, 6: 0.13,
  7: 0.10, 8: 0.07, 9: 0.04, 10: 0.00,
};

/// Chance an enemy of the given [intelligence] throws away its turn.
/// Level 10 alone never blunders — that is the whole of its advantage over 9.
double blunderRateForIntelligence(int intelligence) =>
    _blunderRate[intelligence.clamp(1, 10)] ?? 0.60;

class LadderAi implements DuelAi {
  /// 1–10. Values outside the range are clamped.
  final int intelligence;
  final List<Spell> spells;

  /// The elements this brain may cycle through — its loadout. Level 5+ chooses
  /// among these to counter the enemy's shield; below that the choice is
  /// arbitrary.
  final List<MagicElement> elements;

  /// Element this brain is locked to, if any. A mono-element sim run locks
  /// each side, which makes level 5's counter-*picking* unavailable — it can
  /// still counter-*avoid* by declining a worthless attack.
  final MagicElement? lockedElement;

  LadderAi(
    int intelligence, {
    this.spells = Spellbook.all,
    this.elements = MagicElement.values,
    this.lockedElement,
  }) : intelligence = intelligence.clamp(1, 10);

  bool _can(int level) => intelligence >= level;

  @override
  MageAction chooseAction(MageState self, MageState enemy, Random rng) {
    final affordable = _affordable(self);
    final pool = elements.isEmpty ? MagicElement.values : elements;

    // ⭐ Level 5's actual competence: **pick the element that beats the wall.**
    // Ranking spells by effective damage cannot change the choice when every
    // spell shares one element — the shield multiplier scales them all
    // equally. Counter-awareness only means anything at the moment the element
    // is selectable, which is at zero charge.
    MagicElement chooseElement() {
      if (lockedElement != null) return lockedElement!;
      final wall = EnemyView.of(enemy).shield?.element;
      if (_can(5) && wall != null && self.charge == 0) {
        var best = pool.first;
        var bestPct = -1;
        for (final e in pool) {
          final pct = shieldMultiplierPercent(e, wall);
          if (pct > bestPct) {
            bestPct = pct;
            best = e;
          }
        }
        return best;
      }
      return self.element ?? pool[rng.nextInt(pool.length)];
    }

    final element = self.charge == 0
        ? chooseElement()
        : (lockedElement ?? self.element ?? pool[rng.nextInt(pool.length)]);
    MagicElement? elementArg() => self.charge == 0 ? element : null;

    // ---- Level 1: any legal move, uniformly ------------------------
    // ⚠️ Measurably the WEAKEST rung (≈3.0 damage/turn against a dummy):
    // unpredictable *and* incompetent, squandering whole charge cycles on a
    // free Flick. That is exactly what the bottom of a difficulty dial wants.
    if (!_can(2)) return _uniform(self, affordable, elementArg(), rng);

    // Every rung above 1 is *trying*, so every rung above 1 can blunder — a
    // flat chance of throwing the turn away instead. This is the gradient
    // that separates rungs whose competences are close.
    if (rng.nextDouble() < blunderRateForIntelligence(intelligence)) {
      return _uniform(self, affordable, elementArg(), rng);
    }

    // ---- Level 2: one habit, forever -------------------------------
    // Picks its cheapest attack and throws it forever — Flick when it has one,
    // otherwise whatever the cheapest is. ⚠️ Not *literally* Flick: only ~38%
    // of drawn loadouts contain it, so a Flick-or-nothing rung would spend
    // most games doing something undefined.
    //
    // Fully predictable and cannot punish anything, which is what a new
    // player should meet first — but coherent enough to beat pure randomness.
    if (!_can(3)) {
      final attacks = affordable.where((sp) => sp.isOffensive).toList();
      if (attacks.isEmpty) return ChargeAction(elementArg());
      attacks.sort((a, b) => a.chargeCost.compareTo(b.chargeCost));
      return CastAction(attacks.first, elementArg());
    }

    // ---- Level 3: charge to a fixed number, then cast ---------------
    // Uses the charge system on a rhythm anyone can read, and spends what it
    // built (≈7.1 damage/turn) — the strongest of the three beginner rungs.
    if (!_can(4)) {
      const target = 3;
      if (self.charge < target && self.charge < MageState.maxCharge) {
        return ChargeAction(elementArg());
      }
      final castable = affordable.where((s) => s.isOffensive).toList();
      if (castable.isEmpty) return ChargeAction(elementArg());
      castable.sort((a, b) => b.chargeCost.compareTo(a.chargeCost));
      return CastAction(castable.first, elementArg());
    }

    // Levels 4+ share one deliberating body. Anything a lower rung cannot
    // "see" is gated by _can() inside it.

    // ---- Level 6: never miss a guaranteed kill ----------------------
    // ⭐ Level 7 counts damage already on the clock. A burning enemy is closer
    // to dead than their HP bar says, so level 7 converts kills that level 6
    // cannot see — and stops spending big casts on a target the DoT will
    // finish anyway. This is the competence that makes "sees statuses" pay.
    final view = EnemyView.of(enemy);
    final seenHp = view.hp;
    if (_can(6) && seenHp != null) {
      // ⚠️ Only claim a kill on health we can actually see. Under Dusk the
      // bar is hidden, so a lethal has to be found the hard way — which is
      // exactly what Umbra is buying.
      final effectiveHp = _can(7) ? seenHp - _pendingDot(enemy) : seenHp;
      for (final s in affordable.where((s) => s.isOffensive)) {
        if (estimateDamage(s, self, enemy) >= effectiveHp) {
          return CastAction(s, elementArg());
        }
      }
    }

    // ---- Level 7: don't swing blind ---------------------------------
    // Blind is a flat accuracy penalty; a level-7 brain knows to spend the
    // turn on something that cannot miss instead of coin-flipping a big cast.
    final blinded = self.statuses.any((s) => s is Blinding);
    if (_can(7) && blinded && self.charge < MageState.maxCharge) {
      return ChargeAction(elementArg());
    }

    // ---- Level 7: read your own clock --------------------------------
    // Burning changes the maths on patience. If the DoT alone will take a
    // meaningful bite, stalling to build charge is worse than it looks.
    final selfBurn = _can(7) ? _pendingDot(self) : 0;
    final urgent = selfBurn > 0 && self.hp - selfBurn <= self.maxHp * 0.35;

    // ---- Level 9: pre-empt the incoming hit --------------------------
    // ⭐ The strongest single competence on the ladder. Infers the big cast
    // implied by a large enemy charge and answers it *before* it lands,
    // rather than reacting after.
    // Under Dusk the charge is hidden. ⭐ Handling that uncertainty is itself a
    // competence: level 9+ assumes the worst and guards anyway, while 7-8
    // simply lose the read — which is precisely what Creeping Dark is for.
    final seenCharge = view.charge;
    final threatening =
        seenCharge != null ? seenCharge >= 4 : (_can(9) && enemy.shield == null);
    if (_can(9) && threatening && self.shield == null && !urgent) {
      final guard = _defensive(affordable);
      if (guard != null) return CastAction(guard, elementArg());
    }

    // ---- Level 8: plan toward a payoff -------------------------------
    // Holds the element cycle open to keep a streak or a stack growing,
    // instead of cashing out the moment a cast is affordable.
    if (_can(8)) {
      final plan = _planned(self, enemy, affordable, element, rng);
      if (plan != null) return plan;
    }

    // ---- Level 4: shield when threatened -----------------------------
    // ⭐ Core play, deliberately available early. Higher rungs do it more
    // reliably rather than exclusively.
    if (_can(4) && (seenCharge ?? 0) >= 3 && self.shield == null) {
      final guard = _defensive(affordable);
      final reliability = _can(6) ? 0.6 : 0.45;
      if (guard != null && rng.nextDouble() < reliability) {
        return CastAction(guard, elementArg());
      }
    }

    // ---- The attack decision -----------------------------------------
    var attacks = affordable.where((s) => s.isOffensive).toList();

    // Level 5: counter-awareness. Score by *effective* damage through the
    // enemy shield, and refuse to feed a shield that halves the hit.
    if (_can(5)) {
      attacks = attacks.where((s) => _score(s, self, enemy) > 0).toList();
      attacks.sort((a, b) =>
          _score(b, self, enemy).compareTo(_score(a, self, enemy)));
    } else {
      // Level 4: sensible, but shield-blind — sorts on raw size, so it will
      // happily swing into a resistance it cannot see.
      attacks.sort((a, b) => b.chargeCost.compareTo(a.chargeCost));
    }

    final canCharge = self.charge < MageState.maxCharge;

    // Level 4: stop wasting charge — never spend a full cycle on a cheap
    // spell. This is the single competence that separates 4 from 3.
    if (canCharge && attacks.isNotEmpty) {
      final best = attacks.first;
      final wastesCycle = best.chargeCost < self.charge && !best.xCost;
      if (wastesCycle) return ChargeAction(elementArg());
    }

    if (attacks.isEmpty) {
      if (canCharge) return ChargeAction(elementArg());
      final any = affordable.where((s) => !s.isOffensive).toList();
      if (any.isNotEmpty) return CastAction(any.last, elementArg());
      return const ForfeitAction();
    }

    // At full charge, cash out.
    if (!canCharge) return CastAction(attacks.first, elementArg());

    // Otherwise keep building.
    //
    // ⚠️ Poking mid-cycle is *strictly* bad in this spellbook — big spells are
    // deliberately the efficient ones (paid for by being telegraphed), so a
    // random early swing throws away tempo. Low rungs do it because they do
    // not know better; that impatience is the incompetence.
    // Patience is a gradient, not a switch: each competent rung wastes a
    // little less tempo than the one below it.
    var strikeNow = _can(8)
        ? 0.08
        : _can(6)
            ? 0.16
            : _can(4)
                ? 0.25
                : 0.35;
    // Burning changes the maths: damage you will take regardless makes waiting
    // worse than trading. Level 7 is the first rung that can see this.
    if (urgent) strikeNow = 0.5;
    if (rng.nextDouble() < strikeNow) {
      return CastAction(attacks.first, elementArg());
    }
    return ChargeAction(elementArg());
  }

  // ---- helpers -------------------------------------------------------

  List<Spell> _affordable(MageState self) => [
        for (final s in spells)
          if (s.xCost ? self.charge >= 1 : s.chargeCost <= self.charge) s,
      ];

  MageAction _uniform(
      MageState self, List<Spell> affordable, MagicElement? arg, Random rng) {
    final options = <MageAction>[
      if (self.charge < MageState.maxCharge) ChargeAction(arg),
      for (final s in affordable) CastAction(s, arg),
    ];
    if (options.isEmpty) return const ForfeitAction();
    return options[rng.nextInt(options.length)];
  }

  /// How much a cast is *worth* right now.
  ///
  /// ⚠️ [estimateDamage] scores a fully-absorbed hit as **zero**, which is
  /// true of the health bar but false of the board: chipping a wall down is
  /// progress, and a brain that only counts through-damage will stand there
  /// charging while the opponent re-shields forever. Counter-aware rungs
  /// therefore give shield depletion partial credit.
  int _score(Spell sp, MageState self, MageState enemy) {
    final through = estimateDamage(sp, self, enemy);
    if (through > 0) return through;
    final wall = enemy.shield;
    if (wall == null || !sp.isOffensive) return 0;
    // Worth about a third of face value: it buys the *next* hit, not this one.
    final raw = _rawDamage(sp, self);
    return raw ~/ 3;
  }

  int _rawDamage(Spell sp, MageState self) {
    final e = sp.effect;
    if (e is DamageEffect) {
      return (e.minAmount + e.maxAmount) * e.hits ~/ 2;
    }
    if (e is BarrageEffect) {
      return (e.minPerCharge + e.maxPerCharge) * self.charge ~/ 2;
    }
    return 0;
  }

  /// Damage already scheduled against [m] by its own statuses — the part of a
  /// health bar that is already spent. Level 8+ only.
  int _pendingDot(MageState m) {
    var total = 0;
    for (final s in m.statuses) {
      if (s is IgniteStatus) total += s.perTick * s.turnsLeft;
    }
    return total;
  }

  Spell? _defensive(List<Spell> affordable) {
    final guards = affordable
        .where((s) => s.effect is ShieldEffect || s.effect is BarrierEffect)
        .toList();
    if (guards.isEmpty) return null;
    guards.sort((a, b) => b.chargeCost.compareTo(a.chargeCost));
    return guards.first;
  }

  /// Level 8 — **time the payoff**; level 10 also breaks its own rhythm.
  ///
  /// ⭐ The spellbook deliberately makes big spells the *efficient* ones, paid
  /// for by being telegraphed: sitting on 4–5 charge tells the opponent
  /// exactly what is coming, and invites the pre-shield. So the competence
  /// that separates 8 from 7 is not picking a different spell — 7 already
  /// picks the biggest — it is knowing **when the big cast will actually
  /// land**, and refusing to dump it into a wall.
  ///
  /// Levels 1–7 fire on a fixed rhythm. Level 8 reads the board first.
  MageAction? _planned(MageState self, MageState enemy, List<Spell> affordable,
      MagicElement element, Random rng) {
    final view = EnemyView.of(enemy);
    // Unknown charge is treated as dangerous — planning on an assumption of
    // safety is how a clever brain loses to a hidden board.
    final safe = (view.charge ?? 5) <= 2 && self.hp > self.maxHp * 0.4;
    MagicElement? arg() => self.charge == 0 ? element : null;

    // ⭐ Don't feed the wall. A fresh shield eats a big hit, so a charged
    // level-8 waits it out rather than spending its whole cycle on a cast the
    // opponent has already answered. This is the single read that levels 1-7
    // cannot make.
    final wall = view.shield;
    if (wall != null && self.charge >= 3 && safe) {
      final best = affordable.where((s) => s.isOffensive).fold<int>(
          0, (m, s) => max(m, _score(s, self, enemy)));
      if (best == 0 && self.charge < MageState.maxCharge) {
        return ChargeAction(arg());
      }
    }

    // Payoffs that reward staying on one element — Astral Alignment stacks
    // with charge spent, and Photosynthesis persists as long as the
    // Flora streak is not broken by casting something else.
    final building = self.statuses.any(
        (s) => s is AstralAlignmentStatus || s is PhotosynthesisStatus);
    if (building && safe && self.charge < 4) return ChargeAction(arg());

    return null;
  }

}
