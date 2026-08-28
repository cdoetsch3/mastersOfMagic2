import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The bank's DoT engine and debuff suite — TYPE_EFFECTS_DESIGN.md §7a, and
/// its "build-time test ledger" in particular. Every expectation carries a
/// `reason:` naming the ruling it pins, and every one of them was mutation-
/// verified: the assertion was watched to FAIL against the opposite rule
/// (Wither applied before Blight, Scour rolling per-burn, a tick skipping the
/// shield, Fester missing a final tick) before it was allowed to stand.

/// Deterministic RNG, matching `combat_stats_test`'s: `nextDouble` returns the
/// scripted values then 0.99 forever, `nextInt` returns 0 — so damage rolls
/// take their minimum and any guarded chance > 0 always fires. [intCalls]
/// counts the guarded rolls, which is how "ONE deflection roll" is proven.
class ScriptedRandom implements Random {
  final List<double> doubles;
  var _i = 0;
  int intCalls = 0;
  ScriptedRandom([this.doubles = const []]);
  @override
  double nextDouble() => _i < doubles.length ? doubles[_i++] : 0.99;
  @override
  int nextInt(int max) {
    intCalls++;
    return 0;
  }

  @override
  bool nextBool() => false;
}

/// A stand-in for the Divert stance the buff lane is building: any status
/// contributing to the two deflection stats must be summed into the roll and
/// cleared by Shatter. ⭐ Written as a stranger to this file's code on purpose
/// — the bank must act on the [StatModifier] SEAM, never on a class it has
/// heard of.
class _FakeDivert extends TurnStatus implements StatModifier {
  final int deflectChance;
  final int deflectAmount;

  _FakeDivert(this.deflectChance, this.deflectAmount);

  @override
  int contributionTo(CombatStat stat) => switch (stat) {
        CombatStat.deflectActivation => deflectChance,
        CombatStat.deflectAmount => deflectAmount,
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
    bruno = MageState(name: 'Bruno');
  });

  DuelEngine engine({
    List<double> doubles = const [],
    bool elementEffects = false,
    ScriptedRandom? rng,
  }) =>
      DuelEngine(alice, bruno,
          rng: rng ?? ScriptedRandom(doubles),
          elementEffects: elementEffects,
          baseMissPercent: 0);

  /// Alice casts [spell]; Bruno does nothing.
  TurnResult cast(DuelEngine d, Spell spell,
      [MagicElement element = MagicElement.flora]) {
    alice
      ..charge = spell.chargeCost
      ..element = element;
    return d.resolveTurn(CastAction(spell, element), const ForfeitAction());
  }

  TurnResult idle(DuelEngine d) =>
      d.resolveTurn(const ForfeitAction(), const ForfeitAction());

  BankDotStatus? dotOn(MageState m, String id) =>
      m.statuses.whereType<BankDotStatus>().where((s) => s.id == id).firstOrNull;

  // =========================================================================
  // The DoT attacks — Agony and Torment
  // =========================================================================
  group('Agony & Torment', () {
    test('the hit lands now and the burn ticks from the same turn', () {
      final duel = engine();
      cast(duel, Spellbook.agony);
      expect(bruno.hp, 100 - 10 - 7,
          reason: 'Agony is 10–13 on the hit plus a 7 tick on the turn it '
              'lands — Ignite\'s "applies now, ticks now" cadence');
      idle(duel);
      idle(duel);
      expect(bruno.hp, 100 - 10 - 21,
          reason: 'three ticks in total, the application turn included');
      idle(duel);
      expect(bruno.hp, 100 - 10 - 21,
          reason: 'and then it is spent — a fourth tick would be a 4-tick DoT');
      expect(dotOn(bruno, 'agony'), isNull,
          reason: 'the status expires with its last tick');
    });

    test('Torment is the long burn — 9 ticks of 5', () {
      final duel = engine();
      cast(duel, Spellbook.torment);
      for (var i = 0; i < 8; i++) {
        idle(duel);
      }
      expect(bruno.hp, 100 - 8 - 45,
          reason: '8–10 on the hit, then 9 × 5 over nine turns');
      expect(dotOn(bruno, 'torment'), isNull, reason: 'nine ticks, no more');
    });

    test('⭐ Agony, Torment and Ignite tick concurrently on one target', () {
      // Ignite is injected rather than proc'd: this is about three DoTs
      // coexisting, not about Pyro's roll.
      bruno.statuses.add(IgniteStatus(4));
      final duel = engine();
      cast(duel, Spellbook.agony);
      cast(duel, Spellbook.torment);
      // Turn 2's end phase: Agony 7 + Torment 5 + Ignite 4 = 16.
      expect(bruno.statuses.whereType<DamageOverTime>().length, 3,
          reason: 'three separate burns, no merging (§7a: all DoTs stack '
              'concurrently; only a same-id recast collides)');
      expect(bruno.hp, 100 - 10 - 7 - 4 - 8 - 16,
          reason: 'turn 1: Agony 10 + tick 7 + Ignite 4; turn 2: Torment 8 '
              'plus all three ticks');
    });

    test('⭐ recasting Agony REFRESHES it — replace, never stack (law 5)', () {
      final duel = engine();
      cast(duel, Spellbook.agony); // tick 1 of 3 lands, 2 left
      cast(duel, Spellbook.agony); // fresh 3-tick clock, then one tick
      expect(bruno.statuses.whereType<BankDotStatus>().length, 1,
          reason: 'one Agony, not two — a recast is a refresh');
      expect(dotOn(bruno, 'agony')!.ticksLeft, 2,
          reason: 'the clock restarted at 3 and this turn spent one of them; '
              'stacking would have left 2 statuses and double the damage');
      expect(bruno.hp, 100 - 20 - 14,
          reason: 'two hits of 10 and two ticks of 7 — one burn, not two');
    });

    test('the burn scales with its caster, like every other damage number', () {
      // ⚠️ Ruled at build time (2026-08-28): a DoT's per-tick is fixed when it
      // is applied, at the caster's level and power scale. Without it a
      // level-60 Agony would tick for a level-1's 7 and the whole lane would
      // quietly stop being playable as the game went on.
      final boss = MageState(name: 'Boss', level: 20);
      final target = MageState(name: 'Target', level: 20);
      final duel = DuelEngine(boss, target,
          rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
      boss
        ..charge = 2
        ..element = MagicElement.flora;
      duel.resolveTurn(CastAction(Spellbook.agony, MagicElement.flora),
          const ForfeitAction());
      final expected = (7 * MageState.levelScaleFor(20)).round();
      expect(expected, greaterThan(7), reason: 'sanity: 4%/level compounds');
      expect(
          target.statuses.whereType<BankDotStatus>().single.damagePerTick,
          expected,
          reason: 'the tick carries the caster\'s scale, fixed at application');
    });

    test('Grace eats the rider and never the damage', () {
      bruno.hasGrace = true;
      final duel = engine();
      cast(duel, Spellbook.agony);
      expect(bruno.hp, 90,
          reason: 'the hit is not a debuff, so Grace cannot absorb it');
      expect(dotOn(bruno, 'agony'), isNull,
          reason: 'the DoT rider IS a debuff — Grace blocks exactly that');
      expect(bruno.hasGrace, isFalse, reason: 'and is spent doing it');
    });
  });

  // =========================================================================
  // The tick pipeline — a tick is DAMAGE, but it is not a HIT
  // =========================================================================
  group('a DoT tick is damage', () {
    test('⭐ it resolves shield-first', () {
      bruno.shield = ActiveShield.elemental(MagicElement.geo, 50);
      bruno.statuses.add(BankDotStatus(
          id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 3));
      final duel = engine();
      idle(duel);
      expect(bruno.hp, 100, reason: 'the shield eats the tick whole');
      expect(bruno.shield!.remaining, 40,
          reason: 'a tick is damage: it meets the shield like any other');
      final tick = duel.resolveTurn(const ForfeitAction(), const ForfeitAction())
          .events
          .whereType<EffectDamageEvent>()
          .single;
      expect(tick.toShield, 10, reason: 'and the log says where it went');
    });

    test('⭐ Divert can deflect a tick', () {
      bruno.statuses
        ..add(_FakeDivert(100, 50))
        ..add(BankDotStatus(
            id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 3));
      final duel = engine();
      final r = idle(duel);
      final tick = r.events.whereType<EffectDamageEvent>().single;
      expect(tick.deflected, 5,
          reason: 'the Divert family answers a tick exactly as it answers an '
              'attack (2026-08-28 tick ruling)');
      expect(bruno.hp, 95, reason: 'half the tick was deflected away');
    });

    test('gear deflection and a Divert status SUM on the same packet', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 20;
      bruno.statuses
        ..add(_FakeDivert(0, 30))
        ..add(BankDotStatus(
            id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 9));
      final duel = engine();
      final tick = idle(duel).events.whereType<EffectDamageEvent>().single;
      expect(tick.deflected, 5,
          reason: 'gear 20% + Divert 30% = 50% — different lanes, both paid '
              '(§7a law 4)');
    });

    test('⭐ a tick never misses, never crits, and fires no on-hit proc', () {
      bruno
        ..dodge = 100 // would make any ATTACK miss outright
        ..critChance = 100
        ..critDamage = 400
        ..hasGrace = true;
      alice
        ..critChance = 100
        ..critDamage = 400;
      bruno.statuses.add(BankDotStatus(
          id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 3));
      final duel = engine(elementEffects: true);
      final r = idle(duel);
      expect(bruno.hp, 90,
          reason: 'exactly the tick: dodge cannot dodge it and no crit '
              'multiplier is ever applied to it');
      expect(r.events.whereType<SpellMissedEvent>(), isEmpty,
          reason: 'a tick is not a cast — there is no hit roll to fail');
      expect(r.events.whereType<DamageEvent>(), isEmpty,
          reason: 'it reports as an effect, never as a spell hit — which is '
              'what keeps it out of the on-hit proc pipeline');
      expect(bruno.hasGrace, isTrue,
          reason: 'and it applies nothing, so nothing consumes Grace');
    });
  });

  // =========================================================================
  // Fester & Scour — the instants that feed and collect
  // =========================================================================
  group('Fester', () {
    test('extends EVERY DoT, element-agnostic — Ignite included', () {
      bruno.statuses
        ..add(IgniteStatus(4)) // 3 ticks
        ..add(BankDotStatus(
            id: 'torment', name: 'Torment', damagePerTick: 5, ticks: 9));
      final duel = engine();
      cast(duel, Spellbook.fester);
      expect(bruno.statuses.whereType<IgniteStatus>().single.ticksLeft, 5,
          reason: 'Ignite gained +3 and paid one tick — Fester iterates '
              'DoT-NESS and never names a status (§7a law 1)');
      expect(dotOn(bruno, 'torment')!.ticksLeft, 11,
          reason: '9 + 3 − 1 spent this turn');
      expect(bruno.hp, 100 - 5 - 4 - 5,
          reason: "Fester's own small hit, then both ticks");
    });

    test('⭐ cast on the turn of a burn\'s FINAL tick, it still catches it', () {
      // The ledger entry. Every cast resolves in the MAIN phase and every
      // tick in the END phase, so a burn down to its last tick is still
      // extendable on that turn — the +3 lands before the bookkeeping that
      // would have expired the status. (Priority 8 is what wins Fester the
      // race against the enemy's SPELLS; the end phase it always beats.)
      bruno.statuses.add(BankDotStatus(
          id: 'agony', name: 'Agony', damagePerTick: 7, ticks: 1));
      final duel = engine();
      cast(duel, Spellbook.fester);
      expect(dotOn(bruno, 'agony')?.ticksLeft, 3,
          reason: '1 + 3 = 4 ticks, one of them spent this very turn — a '
              'Fester that resolved after the end phase would have found '
              'nothing left to feed');
      idle(duel);
      idle(duel);
      idle(duel);
      expect(dotOn(bruno, 'agony'), isNull,
          reason: 'and the extended burn then ends on schedule');
      expect(bruno.hp, 100 - 5 - 28,
          reason: "Fester's hit plus four ticks of 7");
    });

    test('a Fester into nothing is a small hit and a shrug', () {
      final duel = engine();
      final r = cast(duel, Spellbook.fester);
      expect(bruno.hp, 95, reason: 'the hit lands regardless');
      expect(
          r.events
              .whereType<BuffAppliedEvent>()
              .any((e) => e.statusId == 'fester'),
          isTrue,
          reason: 'and the log says plainly that nothing was festering');
    });
  });

  group('Scour', () {
    void loadThreeBurns() {
      bruno.statuses
        ..add(BankDotStatus(
            id: 'agony', name: 'Agony', damagePerTick: 7, ticks: 3)) // 21
        ..add(BankDotStatus(
            id: 'torment', name: 'Torment', damagePerTick: 5, ticks: 9)) // 45
        ..add(IgniteStatus(4)); // 12
    }

    test('⭐ collects the EXACT sum of every remaining tick, and consumes them',
        () {
      loadThreeBurns();
      final duel = engine();
      final r = cast(duel, Spellbook.scour);
      expect(bruno.hp, 100 - 78,
          reason: '21 + 45 + 12 — every remaining tick, paid now');
      expect(bruno.statuses.whereType<DamageOverTime>(), isEmpty,
          reason: 'the statuses are consumed by the collection');
      expect(r.events.whereType<DamageEvent>().length, 1,
          reason: 'ONE combined packet — one shield interaction, not three');
      idle(duel);
      expect(bruno.hp, 100 - 78, reason: 'and nothing is left to tick');
    });

    test('⭐ one packet means ONE deflection roll', () {
      loadThreeBurns();
      bruno
        ..deflectChance = 50
        ..deflectAmount = 50;
      final rng = ScriptedRandom();
      final duel = engine(rng: rng);
      final r = cast(duel, Spellbook.scour);
      expect(rng.intCalls, 1,
          reason: 'exactly one guarded roll in the whole turn — three burns '
              'deflected separately would have rolled three times');
      expect(r.events.whereType<DamageEvent>().single.deflected, 39,
          reason: 'half of the whole 78, not half of each burn in turn');
      expect(bruno.hp, 100 - 39, reason: 'the rest lands as one packet');
    });

    test('the packet is element-agnostic and meets the shield once', () {
      loadThreeBurns();
      // A Pyro shield would DOUBLE against a Pyro attack; Scour's packet is
      // nobody's element, so the raw 78 is what the shield sees.
      bruno.shield = ActiveShield.elemental(MagicElement.pyro, 50);
      final duel = engine();
      cast(duel, Spellbook.scour, MagicElement.pyro);
      expect(bruno.shield, isNull, reason: '78 breaks a 50 shield');
      expect(bruno.hp, 100 - 28,
          reason: 'the overflow strikes health at 1× — no counter maths on a '
              'burn that belongs to no element');
    });

    test('Fester → Scour is the spike the EV note describes', () {
      bruno.statuses.add(BankDotStatus(
          id: 'agony', name: 'Agony', damagePerTick: 7, ticks: 3));
      final duel = engine();
      cast(duel, Spellbook.fester); // 3 + 3 − 1 = 5 ticks left, hit 5, tick 7
      cast(duel, Spellbook.scour);
      expect(bruno.hp, 100 - 5 - 7 - 35,
          reason: 'the ticks Fester added stop being delayed at all: 5 × 7 '
              'collected immediately');
    });
  });

  // =========================================================================
  // Murk — the accuracy tax
  // =========================================================================
  group('Murk', () {
    test('feeds the accuracy derivation negatively', () {
      final duel = engine();
      cast(duel, Spellbook.murk);
      expect(bruno.statusContributionTo(CombatStat.accuracy), -15,
          reason: 'Murk is −15 accuracy on its holder');
      // Bruno now swings back at 85% and rolls a 10 → a miss he would have
      // landed at 100%.
      bruno
        ..charge = 1
        ..element = MagicElement.geo;
      final r = duel.resolveTurn(const ForfeitAction(),
          CastAction(Spellbook.bolt, MagicElement.geo));
      expect(r.events.whereType<SpellMissedEvent>().length, 0,
          reason: 'a 0.99 roll is a hit even at 85 — the sanity check');
      expect(alice.hp, lessThan(100), reason: 'it landed');
    });

    test('⭐ a roll inside the Murk window misses — and would have hit without',
        () {
      // Mutation guard in the test itself: the same scripted roll, twice.
      final murked = engine(doubles: [0.10]);
      cast(murked, Spellbook.murk);
      bruno
        ..charge = 1
        ..element = MagicElement.geo;
      final r = murked.resolveTurn(const ForfeitAction(),
          CastAction(Spellbook.bolt, MagicElement.geo));
      expect(r.events.whereType<SpellMissedEvent>().length, 1,
          reason: '10 < 15% miss — the Murk tax is what missed it');
      expect(alice.hp, 100, reason: 'and a miss is no effect at all');

      final clean = MageState(name: 'Clean');
      final swinger = MageState(name: 'Swinger')
        ..charge = 1
        ..element = MagicElement.geo;
      final control = DuelEngine(clean, swinger,
          rng: ScriptedRandom([0.10]),
          elementEffects: false,
          baseMissPercent: 0);
      control.resolveTurn(const ForfeitAction(),
          CastAction(Spellbook.bolt, MagicElement.geo));
      expect(clean.hp, lessThan(100),
          reason: 'the identical roll lands when nobody is Murked');
    });

    test('⭐ Murk stacks ACROSS lanes with the element lane\'s Blind', () {
      bruno.statuses.add(BlindStatus());
      final duel = engine(doubles: [0.30]);
      cast(duel, Spellbook.murk); // end phase arms the Blind window
      expect(bruno.missChance, 0.5, reason: 'Blind is live from next turn');
      bruno
        ..charge = 1
        ..element = MagicElement.geo;
      final r = duel.resolveTurn(const ForfeitAction(),
          CastAction(Spellbook.bolt, MagicElement.geo));
      expect(r.events.whereType<SpellMissedEvent>().length, 1,
          reason: '15 (Murk) + 50 (Blind) = 65% miss; a 30 roll fails it. '
              'Murk alone would have hit — different currencies, both paid');
    });

    test('Miasma REPLACES Murk — one status per axis per lane', () {
      final duel = engine();
      cast(duel, Spellbook.murk);
      cast(duel, Spellbook.miasma);
      expect(bruno.statuses.whereType<MurkStatus>().length, 1,
          reason: 'one Murk status, last cast wins (law 5)');
      expect(bruno.statusContributionTo(CombatStat.accuracy), -25,
          reason: 'magnitude AND duration replaced together — never summed to '
              '−40');
    });
  });

  // =========================================================================
  // Wither & Blight — the anti-heal lane
  // =========================================================================
  group('Wither & Blight', () {
    /// A 10%-of-max heal at the end of every turn — the shape of a Tonic, a
    /// Regrow and Photosynthesis alike, and all of them route through the one
    /// healing door.
    void loadHot() {
      bruno.hp = 50;
      bruno.statuses
          .add(HealOverTimeStatus(percentPerTurn: 10, turnsLeft: 5));
    }

    test('Wither halves healing received', () {
      loadHot();
      bruno.statuses.add(WitherStatus(turns: 10));
      final duel = engine();
      idle(duel);
      expect(bruno.hp, 55, reason: '10 taxed to 5 by the −50%');
    });

    test('the tier 2 buys DURATION, never depth', () {
      final wither = Spellbook.wither.effect as DebuffGrantEffect;
      final atrophy = Spellbook.atrophy.effect as DebuffGrantEffect;
      expect(atrophy.magnitude, wither.magnitude,
          reason: 'ruled 2026-08-26: the Wither status is ALWAYS −50%');
      expect(atrophy.turns, greaterThan(wither.turns),
          reason: 'Atrophy is 30 turns to Wither\'s 10 — that is the whole '
              'difference between them');
    });

    test('Blight turns healing into damage', () {
      loadHot();
      bruno.statuses.add(BlightStatus(turns: 20));
      final duel = engine();
      final r = idle(duel);
      expect(bruno.hp, 40, reason: 'the 10 heal bites for 10 instead');
      expect(r.events.whereType<EffectHealEvent>(), isEmpty,
          reason: 'nothing was healed, so nothing may claim it was');
      expect(
          r.events
              .whereType<EffectDamageEvent>()
              .single
              .source,
          'Blight',
          reason: 'and the log names the culprit');
    });

    test('⭐ Blight SUPERSEDES Wither — the FULL heal is inverted', () {
      loadHot();
      bruno.statuses
        ..add(WitherStatus(turns: 10))
        ..add(BlightStatus(turns: 20));
      final duel = engine();
      idle(duel);
      expect(bruno.hp, 40,
          reason: 'the ruling, exactly: 10 inverted whole. Wither-reduces-'
              'then-Blight-inverts would read 45, and would mean a player\'s '
              'own second debuff weakened their first');
    });

    test('a positive healing-received bonus cannot soften the bite either', () {
      loadHot();
      bruno
        ..healingReceivedPercent = 50
        ..statuses.add(BlightStatus(turns: 20));
      final duel = engine();
      idle(duel);
      expect(bruno.hp, 40,
          reason: 'Blight inverts at face value — it is not healing any more, '
              'so no healing modifier of either sign applies');
    });

    test('⭐ Blight bites the DRAINER: the damage lands, the heal-back turns',
        () {
      alice
        ..hp = 50
        ..statuses.add(BlightStatus(turns: 20));
      final duel = engine();
      cast(duel, Spellbook.sap); // 9–11, heals half the health lost
      expect(bruno.hp, 91, reason: 'the drain still damages its target in full');
      expect(alice.hp, 45,
          reason: 'and its heal-back bites its caster — the rider cannot be '
              'unbundled from the damage, which is where Blight has teeth');
    });

    test('Wither and Blight both tax the potion lane', () {
      const tonic = ConsumableEffect(name: 'Tonic', healNowPercent: 20);
      bruno.hp = 50;
      bruno.statuses.add(WitherStatus(turns: 10));
      final duel = engine();
      duel.resolveTurn(
          const ForfeitAction(), const UseItemAction('tonic', tonic));
      expect(bruno.hp, 60, reason: '20 halved to 10 — potions are healing too');
      bruno.statuses.add(BlightStatus(turns: 20));
      duel.resolveTurn(
          const ForfeitAction(), const UseItemAction('tonic', tonic));
      expect(bruno.hp, 40,
          reason: 'and under Blight the same potion is poison, at full 20');
    });

    test('the debuffs expire on their own clocks', () {
      bruno.statuses.add(WitherStatus(turns: 2));
      final duel = engine();
      idle(duel);
      expect(bruno.statuses.whereType<WitherStatus>().length, 1,
          reason: 'the turn it lands counts as the first of the two');
      idle(duel);
      expect(bruno.statuses.whereType<WitherStatus>(), isEmpty,
          reason: 'and it is gone after the second');
    });
  });

  // =========================================================================
  // Dispel & Shatter — the strippers
  // =========================================================================
  group('Dispel', () {
    test('⭐ strips buffs only — debuffs and Arcane Knowledge stay', () {
      bruno.statuses
        ..add(PhotosynthesisStatus())
        ..add(AstralAlignmentStatus(5))
        ..add(ArcaneKnowledgeStatus(3))
        ..add(MurkStatus(accuracyPercent: -15, turns: 10))
        ..add(BankDotStatus(
            id: 'agony', name: 'Agony', damagePerTick: 7, ticks: 3));
      bruno
        ..empowerMultiplier = 2
        ..quickenPriority = 2
        ..phaseNext = true
        ..hasGrace = true
        ..hasHaste = true;
      final duel = engine();
      cast(duel, Spellbook.dispel);

      expect(bruno.statuses.whereType<PhotosynthesisStatus>(), isEmpty,
          reason: 'a buff-polarity status, stripped');
      expect(bruno.statuses.whereType<AstralAlignmentStatus>(), isEmpty,
          reason: 'so is the other lane\'s stance — polarity, not element');
      expect(bruno.statuses.whereType<ArcaneKnowledgeStatus>().length, 1,
          reason: '§4.3 rules Arcane Knowledge is never cleared: it is '
              'knowledge, not a stance you are holding');
      expect(bruno.statuses.whereType<MurkStatus>().length, 1,
          reason: 'Dispel strips buffs — a debuff on the target is the '
              'caster\'s own work and must survive');
      expect(dotOn(bruno, 'agony'), isNotNull,
          reason: 'stripping your own DoT off them would be a bug');
      expect(bruno.empowerMultiplier, isNull, reason: 'a pending rider is a buff');
      expect(bruno.quickenPriority, isNull);
      expect(bruno.phaseNext, isFalse);
      expect(bruno.hasGrace, isFalse,
          reason: 'Grace is a buff, and Dispel applies no debuff for it to '
              'absorb');
      expect(bruno.hasHaste, isTrue,
          reason: '⚠️ Haste is the turn order\'s token, not a stance on a mage');
    });
  });

  group('Shatter', () {
    test('⭐ clears shields, Barrier and Divert — and deals nothing', () {
      bruno
        ..shield = ActiveShield.elemental(MagicElement.geo, 60)
        ..barrierPoints = 3
        ..deflectChance = 20 // gear, not a stance
        ..deflectAmount = 20;
      bruno.statuses.add(_FakeDivert(50, 50));
      final duel = engine();
      final r = cast(duel, Spellbook.shatter);

      expect(bruno.hp, 100, reason: 'Shatter deals NO damage (re-ruled 2026-08-26)');
      expect(r.events.whereType<DamageEvent>(), isEmpty,
          reason: 'not a single damage event to its name');
      expect(bruno.shield, isNull, reason: 'the elemental shield is gone');
      expect(bruno.barrierPoints, 0,
          reason: 'ALL the Barrier points, not one of them');
      expect(bruno.statuses.where(isDivertFamily), isEmpty,
          reason: 'and the whole Divert family with them');
      expect(bruno.effectiveDeflectChance, 20,
          reason: '⚠️ gear deflection is not a stance — you cannot shatter it '
              'off someone\'s armour');
    });
  });

  // =========================================================================
  // The aux-offense lane itself
  // =========================================================================
  group('aux-offense (priority 8)', () {
    test('⭐ never rolls to hit — dodge and Blind do not touch it', () {
      bruno.dodge = 100; // any attack would miss outright
      final duel = engine(doubles: [0.01]);
      final r = cast(duel, Spellbook.murk);
      expect(r.events.whereType<SpellMissedEvent>(), isEmpty,
          reason: 'aux-offense resolves or it does not — there is no hit roll');
      expect(bruno.statuses.whereType<MurkStatus>().length, 1,
          reason: 'so the status lands, subject only to Grace');
    });

    test('resolves after aux-defence and before the attacks', () {
      for (final s in [
        Spellbook.murk,
        Spellbook.miasma,
        Spellbook.wither,
        Spellbook.atrophy,
        Spellbook.blight,
        Spellbook.fester,
        Spellbook.scour,
        Spellbook.dispel,
        Spellbook.shatter,
      ]) {
        expect(s.priority, 8,
            reason: '${s.name} is enemy-facing but not an attack');
      }
      expect(Spellbook.agony.priority, 9);
      expect(Spellbook.torment.priority, 9,
          reason: 'the DoT attacks are real attacks and share their clock');
    });

    test('⭐ your debuff lands before their attack resolves, same turn', () {
      // The whole point of splitting the aux lane: 8 beats 9. Murk cast into
      // an incoming Bolt taxes THAT Bolt, not the next one.
      final duel = engine(doubles: [0.10]);
      alice
        ..charge = 1
        ..element = MagicElement.flora;
      bruno
        ..charge = 1
        ..element = MagicElement.geo;
      final r = duel.resolveTurn(
          CastAction(Spellbook.murk, MagicElement.flora),
          CastAction(Spellbook.bolt, MagicElement.geo));
      expect(r.events.whereType<SpellMissedEvent>().length, 1,
          reason: 'aux-offense (8) resolved first, so the −15 was already on '
              'Bruno when his attack (9) rolled — at priority 9 the attack '
              'would have gone first and landed');
      expect(alice.hp, 100, reason: 'and the miss is total');
    });

    test('Grace blocks a debuff granter outright', () {
      bruno.hasGrace = true;
      final duel = engine();
      cast(duel, Spellbook.blight);
      expect(bruno.statuses.whereType<BlightStatus>(), isEmpty,
          reason: 'Grace blocks the next debuff applied, whatever grants it');
      expect(bruno.hasGrace, isFalse, reason: 'and is spent doing it');
    });
  });

  // =========================================================================
  // Wiring — every status the bank emits is a described, snapshot-able thing
  // =========================================================================
  group('wiring', () {
    test('every bank status id has a catalogue entry', () {
      for (final id in [
        'agony',
        'torment',
        'murk',
        'wither',
        'blight',
        'fester',
        'scour',
        'dispel',
        'shatter',
      ]) {
        expect(StatusCatalog.byId(id), isNotNull,
            reason: "'$id' is emitted by the engine and must be described");
      }
    });

    test('the HUD can see every bank status', () {
      bruno.statuses
        ..add(BankDotStatus(
            id: 'agony', name: 'Agony', damagePerTick: 7, ticks: 3))
        ..add(BankDotStatus(
            id: 'torment', name: 'Torment', damagePerTick: 5, ticks: 9))
        ..add(MurkStatus(accuracyPercent: -25, turns: 20))
        ..add(WitherStatus(turns: 10))
        ..add(BlightStatus(turns: 20));
      final snap = StatusSnapshot.of(bruno);
      expect(snap['agony']!.magnitude, 7, reason: 'the pip shows the bleed');
      expect(snap['agony']!.turnsLeft, 3);
      expect(snap['torment']!.magnitude, 5,
          reason: 'one snapshot arm serves every DoT — it reads the id');
      expect(snap['murk']!.magnitude, -25);
      expect(snap['wither']!.magnitude, -50);
      expect(snap['blight']!.turnsLeft, 20);
    });

    test('the bank is addressable by id', () {
      expect(Spellbook.byId('agony'), same(Spellbook.agony));
      expect(Spellbook.bankDots.length, 11,
          reason: 'the eleven spells of the DoT/debuff lane');
      expect(Spellbook.bankDots.map((s) => s.id).toSet().length, 11,
          reason: 'no id collides with another');
      for (final s in Spellbook.bankDots) {
        expect(Spellbook.all.map((e) => e.id).contains(s.id), isFalse,
            reason: '${s.id} must not collide with a shipped spell');
      }
    });

    test('⭐ it composes with the stance lane, which it has never heard of', () {
      // The two banked lanes were built in parallel and share no code. These
      // are the seams meeting: the stance lane's real Divert deflects this
      // lane's tick, this lane's Shatter clears that stance, and this lane's
      // Dispel strips their Lightfoot — all through polarity and
      // [StatModifier], never through a class name.
      bruno.statuses
        ..add(DivertStatus.divert()) // 20% to deflect 40%
        ..add(LightfootStatus.lightfoot())
        ..add(BankDotStatus(
            id: 'agony', name: 'Agony', damagePerTick: 10, ticks: 9));
      final duel = engine();
      final tick = idle(duel).events.whereType<EffectDamageEvent>().single;
      expect(tick.deflected, 4,
          reason: "the stance lane's Divert answers this lane's tick — 40% of "
              '10, no arrangement between the two files required');

      cast(duel, Spellbook.shatter);
      expect(bruno.statuses.whereType<DivertStatus>(), isEmpty,
          reason: 'Shatter finds the Divert family by its deflect '
              'contribution, so it clears a status written in another lane');
      expect(bruno.statuses.whereType<LightfootStatus>().length, 1,
          reason: '⚠️ and takes nothing else — Lightfoot is a stance, not a '
              'defence Shatter is allowed to break');

      cast(duel, Spellbook.dispel);
      expect(bruno.statuses.whereType<LightfootStatus>(), isEmpty,
          reason: 'Dispel strips it because it is buff-polarity — again, no '
              'name involved');
      expect(dotOn(bruno, 'agony'), isNotNull,
          reason: 'and the debuff underneath is left exactly where it was');
    });

    test('the bank\'s DoTs and the element lane\'s are the same kind of thing',
        () {
      expect(IgniteStatus(4), isA<DamageOverTime>(),
          reason: 'Ignite is a DoT by interface — which is the only reason '
              'Fester and Scour can act on it without naming it');
    });
  });
}
