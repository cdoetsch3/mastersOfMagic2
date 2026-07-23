import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Deterministic RNG: `nextDouble` returns scripted values then 0.99 forever
/// (so procs are controllable and default to *not* firing); `nextInt` returns
/// 0 (damage rolls take their minimum, and Absolution's random purge picks the
/// first debuff). See tier23_effects_test for the same helper.
class ScriptedRandom implements Random {
  final List<double> doubles;
  var _i = 0;
  ScriptedRandom([this.doubles = const []]);

  @override
  double nextDouble() => _i < doubles.length ? doubles[_i++] : 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// A fixed-damage spell (min == max) so shield/pierce arithmetic is exact.
Spell dmg(int amount, {int cost = 0, int priority = 9}) => Spell(
    id: 'dmg$amount', name: 'Dmg$amount', chargeCost: cost, priority: priority,
    effect: DamageEffect(amount, amount));

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  void charge(MageState m, MagicElement e, int to) {
    m
      ..charge = to
      ..element = e;
  }

  T? statusOf<T extends TurnStatus>(MageState m) {
    for (final s in m.statuses) {
      if (s is T) return s;
    }
    return null;
  }

  // ======================================================================
  // §4b.2 — Lunar: Phases of the Moon (the global clock)
  // ======================================================================
  group('Lunar — Phases of the Moon', () {
    test('the global clock is New→Waxing→Full→Waning by turn number', () {
      expect(moonPhaseForTurn(1), MoonPhase.newMoon);
      expect(moonPhaseForTurn(2), MoonPhase.waxing);
      expect(moonPhaseForTurn(3), MoonPhase.full);
      expect(moonPhaseForTurn(4), MoonPhase.waning);
      expect(moonPhaseForTurn(5), MoonPhase.newMoon, reason: 'cycle repeats');
    });

    test('New Moon weakens a Lunar attack by 25%', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      charge(alice, MagicElement.lunar, 0);
      duel.resolveTurn(
          CastAction(dmg(20), MagicElement.lunar), const ForfeitAction());
      expect(bruno.hp, 85, reason: 'turn 1 New Moon: 20 × 0.75 = 15');
    });

    test('Full Moon strengthens a Lunar attack by 50%', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      // Advance to turn 3 (Full).
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      charge(alice, MagicElement.lunar, 0);
      duel.resolveTurn(
          CastAction(dmg(20), MagicElement.lunar), const ForfeitAction());
      expect(bruno.hp, 70, reason: 'turn 3 Full Moon: 20 × 1.5 = 30');
    });

    test('the phase only touches Lunar spells, never other elements', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      charge(alice, MagicElement.pyro, 0);
      duel.resolveTurn(
          CastAction(dmg(20), MagicElement.pyro), const ForfeitAction());
      expect(bruno.hp, 80, reason: 'a Pyro attack on turn 1 is unmodified');
    });

    test('Waning boosts a Lunar shield by 50%', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      // Advance to turn 4 (Waning).
      for (var i = 0; i < 3; i++) {
        duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      }
      charge(alice, MagicElement.lunar, 2);
      duel.resolveTurn(
          CastAction(Spellbook.aegis), const ForfeitAction());
      expect(alice.shield!.remaining, 39, reason: 'Aegis 26 × 1.5 = 39');
    });
  });

  // ======================================================================
  // §4b.3 — Solar → Lunar: the eclipse
  // ======================================================================
  group('Solar → Lunar — the eclipse locks the moon to New', () {
    test('a Blinded Lunar mage is at New even on a non-New turn', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      // Blind Bruno, then reach turn 2 (Waxing globally, +25%).
      bruno.statuses.add(BlindStatus());
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction()); // turn 1
      charge(bruno, MagicElement.lunar, 0);
      // Turn 2: Bruno's blind is active (missChance 0.5); script no-miss so we
      // measure damage, not the miss. Eclipse → New Moon → −25%, not +25%.
      duel.resolveTurn(
          const ForfeitAction(), CastAction(dmg(20), MagicElement.lunar));
      expect(alice.hp, 85, reason: 'eclipsed to New: 20 × 0.75 = 15, not +25%');
    });

    test('the eclipse is per-mage — the Solar caster\'s own moon still turns',
        () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      // Only Bruno is eclipsed; Alice (unblinded) on turn 3 gets Full Moon.
      bruno.statuses.add(BlindStatus());
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction()); // 1
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction()); // 2
      charge(alice, MagicElement.lunar, 0);
      duel.resolveTurn(
          CastAction(dmg(20), MagicElement.lunar), const ForfeitAction());
      expect(bruno.hp, 70, reason: 'Alice is not eclipsed: Full Moon, 20 × 1.5');
    });
  });

  // ======================================================================
  // §4b.4 — Astral: Astral Alignment
  // ======================================================================
  group('Astral — Astral Alignment', () {
    test('an Astral cast grants a stack; decays without Astral activity', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      charge(alice, MagicElement.astral, 0);
      duel.resolveTurn(
          CastAction(Spellbook.flick, MagicElement.astral), const ForfeitAction());
      expect(statusOf<AstralAlignmentStatus>(alice)!.stacks, 1);

      // A non-Astral turn sheds the stack (like Photosynthesis).
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      expect(statusOf<AstralAlignmentStatus>(alice), isNull);
    });

    test('stacks cap at 5', () {
      final align = AstralAlignmentStatus(5)..addStack();
      expect(align.stacks, 5);
      expect(align.piercePercent, 25);
    });

    test('the split routes 5%/stack past the shield to health at 100%', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice.statuses.add(AstralAlignmentStatus(4)); // 20% pierce
      // Solar shield is neutral to a Pyro attacker (opposite tiers) → 100%, so
      // the shield chip is un-multiplied and the arithmetic is clean.
      bruno.shield = ActiveShield.elemental(MagicElement.solar, 40);
      charge(alice, MagicElement.pyro, 0);
      duel.resolveTurn(
          CastAction(dmg(25), MagicElement.pyro), const ForfeitAction());
      expect(bruno.hp, 95, reason: '20% of 25 = 5 straight to health');
      expect(bruno.shield!.remaining, 20, reason: 'the other 20 hits the shield');
    });

    test('it pierces a Barrier too — and the Barrier still pops', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice.statuses.add(AstralAlignmentStatus(4)); // 20%
      bruno.shield = ActiveShield.barrier();
      charge(alice, MagicElement.pyro, 0);
      duel.resolveTurn(
          CastAction(dmg(25), MagicElement.pyro), const ForfeitAction());
      expect(bruno.hp, 95, reason: '5 pierces to health');
      expect(bruno.shield, isNull, reason: 'the Barrier absorbs the 20 and pops');
    });

    test('does nothing against an unshielded target (all damage was health)',
        () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice.statuses.add(AstralAlignmentStatus(5));
      charge(alice, MagicElement.pyro, 0);
      duel.resolveTurn(
          CastAction(dmg(25), MagicElement.pyro), const ForfeitAction());
      expect(bruno.hp, 75, reason: 'full 25 to health, no double-counting');
    });
  });

  // ======================================================================
  // §4b table — Lunar → Astral: stripping Alignment
  // ======================================================================
  group('Lunar → Astral — a Lunar attack strips Alignment', () {
    test('a normal Lunar attack strips one stack', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      bruno.statuses.add(AstralAlignmentStatus(3));
      charge(alice, MagicElement.lunar, 0); // turn 1 New — still an attack
      // Bruno charges Astral so its Alignment doesn't also take its -1 decay
      // this turn — isolating the -1 strip from the attack.
      duel.resolveTurn(CastAction(dmg(5), MagicElement.lunar),
          const ChargeAction(MagicElement.astral));
      expect(statusOf<AstralAlignmentStatus>(bruno)!.stacks, 2);
    });

    test('a Full-Moon Lunar attack strips them all', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      bruno.statuses.add(AstralAlignmentStatus(4));
      // Reach turn 3 (Full).
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());
      charge(alice, MagicElement.lunar, 0);
      duel.resolveTurn(
          CastAction(dmg(5), MagicElement.lunar), const ForfeitAction());
      expect(statusOf<AstralAlignmentStatus>(bruno), isNull);
    });
  });

  // ======================================================================
  // §4c.1 — Sanctus: Absolution + Grace
  // ======================================================================
  group('Sanctus — Absolution', () {
    test('fires on the 3rd consecutive Sanctus cast, purging one debuff', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice.statuses.add(IgniteStatus(5)); // a debuff to purge
      alice
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2; // the next Sanctus cast is the 3rd
      charge(alice, MagicElement.sanctus, 0);
      duel.resolveTurn(
          CastAction(Spellbook.flick, MagicElement.sanctus), const ForfeitAction());
      expect(statusOf<IgniteStatus>(alice), isNull, reason: 'Ignite purged');
      expect(alice.hp, 100, reason: 'purged in the heal band before it ticked');
    });

    test('with no debuff to purge, it banks Grace instead', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2;
      charge(alice, MagicElement.sanctus, 0);
      duel.resolveTurn(
          CastAction(Spellbook.flick, MagicElement.sanctus), const ForfeitAction());
      expect(alice.hasGrace, isTrue);
    });

    test('a non-3rd Sanctus cast does nothing', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice.statuses.add(IgniteStatus(5));
      charge(alice, MagicElement.sanctus, 0); // 1st cast, no streak yet
      duel.resolveTurn(
          CastAction(Spellbook.flick, MagicElement.sanctus), const ForfeitAction());
      expect(statusOf<IgniteStatus>(alice), isNotNull);
      expect(alice.hasGrace, isFalse);
    });

    test('casting a different element resets the Sanctus streak', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      alice
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2;
      charge(alice, MagicElement.pyro, 0); // breaks the streak
      duel.resolveTurn(
          CastAction(Spellbook.flick, MagicElement.pyro), const ForfeitAction());
      expect(alice.streakElement, MagicElement.pyro);
      expect(alice.streakCount, 1);
      expect(alice.hasGrace, isFalse, reason: 'no Absolution fired');
    });
  });

  // ======================================================================
  // §4c.2 — Sanctus → Umbra: Absolution sears the dark
  // ======================================================================
  group('Sanctus → Umbra — Absolution strips 5 Creeping Dark', () {
    test('the opponent loses 5 stacks when Absolution fires', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      bruno.statuses.add(CreepingDarkStatus(12));
      alice
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2;
      charge(alice, MagicElement.sanctus, 0);
      // Bruno charges Umbra to pause its own -1 decay, isolating the -5 strip.
      duel.resolveTurn(CastAction(Spellbook.flick, MagicElement.sanctus),
          const ChargeAction(MagicElement.umbra));
      expect(statusOf<CreepingDarkStatus>(bruno)!.stacks, 7);
    });
  });

  // ======================================================================
  // §4c.1 / §4c.4 — Grace and the Hallow spell
  // ======================================================================
  group('Grace and Hallow', () {
    test('Hallow banks Grace', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      charge(alice, MagicElement.pyro, 2);
      duel.resolveTurn(CastAction(Spellbook.hallow), const ForfeitAction());
      expect(alice.hasGrace, isTrue);
      expect(Spellbook.hallow.isHarmful, isFalse, reason: 'element-neutral aux');
    });

    test('Grace blocks the next debuff (a Blind), then is spent', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom([0.0]));
      bruno.hasGrace = true;
      charge(alice, MagicElement.solar, 4); // 40% blind, 0.0 procs
      duel.resolveTurn(CastAction(Spellbook.ruin), const ForfeitAction());
      expect(bruno.statuses.whereType<BlindStatus>(), isEmpty,
          reason: 'Grace ate the Blind');
      expect(bruno.hasGrace, isFalse, reason: 'and was consumed');
    });

    test('Grace blocks Waterlogged', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      bruno.hasGrace = true;
      alice
        ..streakElement = MagicElement.aqua
        ..streakCount = 2; // next Aqua cast is the 3rd → Waterlog
      charge(alice, MagicElement.aqua, 0);
      duel.resolveTurn(
          CastAction(Spellbook.flick, MagicElement.aqua), const ForfeitAction());
      expect(bruno.priorityPenalty, 0, reason: 'Grace blocked the slow');
      expect(bruno.hasGrace, isFalse);
    });

    test('Grace does not stack past one', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      charge(alice, MagicElement.pyro, 2);
      duel.resolveTurn(CastAction(Spellbook.hallow), const ForfeitAction());
      charge(alice, MagicElement.pyro, 2);
      duel.resolveTurn(CastAction(Spellbook.hallow), const ForfeitAction());
      expect(alice.hasGrace, isTrue, reason: 'still just the one charge');
    });
  });

  // ======================================================================
  // §4c.3 — Arcane → Sanctus: an Arcane attack resets the streak
  // ======================================================================
  group('Arcane → Sanctus — an Arcane attack unravels the rite', () {
    test('a landed Arcane attack resets the target Sanctus streak to 0', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      bruno
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2;
      charge(alice, MagicElement.arcane, 0);
      duel.resolveTurn(
          CastAction(dmg(10), MagicElement.arcane), const ForfeitAction());
      expect(bruno.streakElement, isNull);
      expect(bruno.streakCount, 0);
    });

    test('a fully-shielded Arcane attack does NOT reset it (§5.4)', () {
      final duel = DuelEngine(alice, bruno, rng: ScriptedRandom());
      bruno
        ..streakElement = MagicElement.sanctus
        ..streakCount = 2;
      bruno.shield = ActiveShield.elemental(MagicElement.pyro, 500); // eats it
      charge(alice, MagicElement.arcane, 0);
      duel.resolveTurn(
          CastAction(dmg(10), MagicElement.arcane), const ForfeitAction());
      expect(bruno.streakCount, 2, reason: 'no health damage → no reset');
    });
  });
}
