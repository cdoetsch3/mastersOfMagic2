import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Gear procs — a Greater enchant's element, rolled on the wearer's damaging
/// hits (ENCHANTING_DESIGN §4.1a, ✅ Christian 2026-10-01).
///
/// ⭐ **Mutation-verified**: every `expect` names the wrong implementation it
/// kills. The two that matter most for lockstep are the rng ones — an empty
/// `gearProcs` must draw NOTHING (every seeded duel written before procs stays
/// byte-identical), and the rolls must come in element-enum order whatever
/// order the set was built in (two clients that built the same set two ways
/// must still agree).
///
/// ⚠️ The carrier is a **Geo Bolt**: a first Geo cast fires no element effect
/// of its own (Stagger is every 4th) and draws nothing for it, so every draw
/// after the damage roll in these tests is a gear-proc roll and nothing else.

/// Scripted doubles (then 0.99 — no proc — forever); every `nextInt` is 0, so
/// damage rolls are minimums. Counts what it was asked for.
class _Scripted implements Random {
  final List<double> doubles;
  var _i = 0;
  int doublesDrawn = 0;

  _Scripted(this.doubles);

  @override
  double nextDouble() {
    doublesDrawn++;
    return _i < doubles.length ? doubles[_i++] : 0.99;
  }

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

/// A seeded stream that counts every draw — the twin-stream pin's witness.
class _Counting implements Random {
  final Random _inner;
  int draws = 0;

  _Counting(int seed) : _inner = Random(seed);

  @override
  double nextDouble() {
    draws++;
    return _inner.nextDouble();
  }

  @override
  int nextInt(int max) {
    draws++;
    return _inner.nextInt(max);
  }

  @override
  bool nextBool() {
    draws++;
    return _inner.nextBool();
  }
}

/// Bolt's minimum (scripted `nextInt` 0) at level 1 — the raw damage Ignite's
/// base tick reads.
const _boltMin = 11;

void main() {
  late MageState alice;
  late MageState bruno;

  MageState mage(String name) => MageState(name: name)..critChance = 0;

  setUp(() {
    alice = mage('Alice');
    bruno = mage('Bruno');
  });

  /// Alice casts a 1-charge Geo Bolt at Bruno, who does nothing.
  TurnResult bolt(DuelEngine duel, {MagicElement as = MagicElement.geo}) {
    alice
      ..charge = 1
      ..element = as;
    return duel.resolveTurn(
      CastAction(Spellbook.bolt, as),
      const ForfeitAction(),
    );
  }

  DuelEngine scripted(List<double> doubles) =>
      DuelEngine(alice, bruno, rng: _Scripted(doubles), baseMissPercent: 0);

  Set<String> buffIds(TurnResult r) => {
    for (final e in r.events)
      if (e is BuffAppliedEvent && e.statusId != null) e.statusId!,
  };

  group('the roll', () {
    test('a Greater Pyro wearer ignites on ~15% of 2,000 hits', () {
      final rng = Random(20261001);
      var ignites = 0;
      for (var i = 0; i < 2000; i++) {
        alice = mage('Alice')..gearProcs = {MagicElement.pyro};
        bruno = mage('Bruno');
        final r = bolt(DuelEngine(alice, bruno, rng: rng, baseMissPercent: 0));
        if (buffIds(r).contains('ignite')) ignites++;
      }
      expect(
        ignites,
        inInclusiveRange(2000 * 13 ~/ 100, 2000 * 17 ~/ 100),
        reason:
            '15% ± 2 points of 2,000 hits — the mutants this kills: the '
            'spell path\'s 25% reused for gear (≈500), no roll at all (0), '
            'or a proc on every hit (2,000)',
      );
      expect(
        ElementTuning.gearProcPercent,
        15,
        reason: 'ENCHANTING §4.1a ruled 15% — a retune is a ruling',
      );
    });

    test('⭐ twin streams: an empty gearProcs draws nothing at all', () {
      // Three duels on twin seeds, ten Bolts each. The no-proc duel and the
      // proc-on-the-wrong-mage duel must agree on EVERY event and on the
      // stream position afterwards; the proc duel must not (so the
      // comparison can fail at all).
      List<String> run(
        _Counting rng, {
        Set<MagicElement>? alices,
        Set<MagicElement>? brunos,
      }) {
        alice = MageState(name: 'Alice', maxHp: 10000)
          ..critChance = 0
          ..gearProcs = alices ?? {};
        bruno = MageState(name: 'Bruno', maxHp: 10000)
          ..critChance = 0
          ..gearProcs = brunos ?? {};
        final duel = DuelEngine(alice, bruno, rng: rng, baseMissPercent: 0);
        return [
          for (var i = 0; i < 10; i++)
            for (final e in bolt(duel).events) e.toString(),
        ];
      }

      final none = _Counting(7);
      final idle = _Counting(7);
      final armed = _Counting(7);
      final noneLog = run(none);
      // Bruno wears every proc in the game and never lands a hit.
      final idleLog = run(idle, brunos: MagicElement.values.toSet());
      final armedLog = run(armed, alices: {MagicElement.pyro});

      expect(
        none.draws,
        10,
        reason:
            'one damage roll per Bolt and nothing else — the mutant this '
            'kills draws a gear roll (or a "has procs?" coin) before checking '
            'the set is non-empty',
      );
      expect(
        idleLog,
        noneLog,
        reason:
            'procs roll on the WEARER\'s damaging hit only — a mage who never '
            'hits must leave the shared stream exactly where it was',
      );
      expect(
        idle.nextDouble(),
        none.nextDouble(),
        reason: 'twin streams must sit at the same position after the duel',
      );
      expect(
        armed.draws,
        20,
        reason: 'one damage roll + exactly one proc roll per hit per element',
      );
      expect(
        armedLog,
        isNot(noneLog),
        reason: 'sanity: a real proc set must change the duel',
      );
    });

    test('rolls come in element-enum order, whatever order the set was '
        'built in', () {
      // Draw 1 → pyro (0.0, procs), draw 2 → arcane (0.99, no proc). Built
      // arcane-first, an insertion-order loop would hand the 0.0 to Arcane.
      final duel = scripted([0.0, 0.99]);
      alice.gearProcs = {MagicElement.arcane, MagicElement.pyro};
      final ids = buffIds(bolt(duel));
      expect(
        ids,
        contains('ignite'),
        reason: 'Pyro precedes Arcane in MagicElement — it gets draw 1',
      );
      expect(
        ids,
        isNot(contains('arcaneKnowledge')),
        reason:
            'the mutant this kills iterates the SET, so two clients that '
            'built one wardrobe in two orders resolve two different duels',
      );
    });

    test('a non-damaging cast rolls nothing', () {
      final rng = _Scripted([]);
      final duel = DuelEngine(alice, bruno, rng: rng, baseMissPercent: 0);
      alice
        ..gearProcs = MagicElement.values.toSet()
        ..charge = 1
        ..element = MagicElement.geo;
      duel.resolveTurn(
        CastAction(Spellbook.ward, MagicElement.geo),
        const ForfeitAction(),
      );
      expect(
        rng.doublesDrawn,
        0,
        reason: '"on each damaging hit" — a shield is not one',
      );
    });

    test('a miss rolls nothing past the miss', () {
      // Draw 1 is the hit roll: 0.0 × 100 < 20 → miss.
      final rng = _Scripted([0.0]);
      final duel = DuelEngine(alice, bruno, rng: rng);
      alice.gearProcs = {MagicElement.pyro};
      bolt(duel);
      expect(
        rng.doublesDrawn,
        1,
        reason: 'a missed spell resolves nothing, gear included',
      );
    });

    test('after the spell\'s own element effect, never before it', () {
      // A Pyro Bolt: draw 1 is the spell's 25% Ignite, draw 2 the gear's.
      final rng = _Scripted([0.99, 0.0]);
      final duel = DuelEngine(alice, bruno, rng: rng, baseMissPercent: 0);
      alice.gearProcs = {MagicElement.pyro};
      final ids = buffIds(bolt(duel, as: MagicElement.pyro));
      expect(
        ids,
        contains('ignite'),
        reason:
            'the 0.0 is draw 2 — only a gear roll AFTER the spell roll '
            'reaches it; a gear-first mutant takes 0.99 and never ignites',
      );
    });
  });

  group('each element lands its own effect, at base magnitude', () {
    /// The BuffApplied ids each proc emits — ⭐ a table, so a proc wired to
    /// the wrong element's effect fails on BOTH rows it touches.
    const expected = <MagicElement, Set<String>>{
      MagicElement.pyro: {'ignite'},
      MagicElement.aqua: {'waterlogged'},
      MagicElement.flora: {'photosynthesis'},
      MagicElement.electro: {},
      MagicElement.aero: {},
      MagicElement.geo: {'stagger'},
      MagicElement.solar: {'blind'},
      MagicElement.lunar: {'blind'},
      MagicElement.astral: {'astralAlignment'},
      MagicElement.sanctus: {'grace'},
      MagicElement.umbra: {'creepingDark'},
      MagicElement.arcane: {'arcaneKnowledge'},
    };

    for (final element in MagicElement.values) {
      test('${element.name} emits exactly its own status', () {
        alice = mage('Alice');
        bruno = mage('Bruno')
          ..charge = 3
          ..element = MagicElement.pyro;
        final duel = scripted([0.0]);
        alice.gearProcs = {element};
        expect(
          buffIds(bolt(duel)),
          expected[element],
          reason:
              '${element.name}\'s proc must apply ${element.name}\'s effect '
              '(§4.1a table) — the mutant this kills is a proc wired to '
              'another element\'s effect',
        );
      });
    }

    test('Pyro: Ignite at the base tick, 3 turns', () {
      alice.gearProcs = {MagicElement.pyro};
      bolt(scripted([0.0]));
      final ignite = bruno.statuses.whereType<IgniteStatus>().single;
      expect(
        ignite.perTick,
        (_boltMin * ElementTuning.igniteBurnPercentOfDamage / 100).round(),
        reason: '10% of the hit\'s raw damage — the spell path\'s base tick',
      );
      expect(
        ignite.turnsLeft,
        ElementTuning.igniteTicks - 1,
        reason: '3 ticks, one already spent at this turn\'s end',
      );
    });

    test('Aqua: Waterlogged on them (+10 priority)', () {
      alice.gearProcs = {MagicElement.aqua};
      bolt(scripted([0.0]));
      expect(
        bruno.priorityPenalty,
        ElementTuning.waterloggedPriorityPenalty,
        reason: 'Waterlogged lands on the TARGET, not the wearer',
      );
    });

    test('Flora: one turn of the 1% heal on you', () {
      alice
        ..gearProcs = {MagicElement.flora}
        ..hp = 50;
      bolt(scripted([0.0]));
      expect(
        alice.hp,
        50 +
            (alice.maxHp * ElementTuning.photosynthesisHealPercent / 100)
                .round(),
        reason:
            '+1 Photosynthesis "stack" is one turn of its heal at this '
            'turn\'s end — the mutant this kills adds the status and lets the '
            'streak gate switch it off before it heals',
      );
      expect(
        alice.statuses.whereType<PhotosynthesisStatus>(),
        isEmpty,
        reason: 'a gear unit with no Flora streak expires at its own turn end',
      );
    });

    test('Flora: the unit ADDS to a streak-sustained heal', () {
      alice
        ..gearProcs = {MagicElement.flora}
        ..hp = 50
        ..streakElement = MagicElement.flora
        ..streakCount = ElementTuning.photosynthesisStreak - 1;
      // A 5th consecutive Flora cast: the streak heal AND the gear unit.
      bolt(scripted([0.0]), as: MagicElement.flora);
      expect(
        alice.hp,
        50 + 2,
        reason: 'two units of 1% — "+1" against the streak\'s own one',
      );
    });

    test('Flora: the unit is ONE turn, even while the streak keeps the '
        'status alive', () {
      alice
        ..gearProcs = {MagicElement.flora}
        ..hp = 50
        ..streakElement = MagicElement.flora
        ..streakCount = ElementTuning.photosynthesisStreak - 1;
      final duel = scripted([0.0]); // turn 1 procs, turn 2 does not
      bolt(duel, as: MagicElement.flora);
      bolt(duel, as: MagicElement.flora);
      expect(
        alice.hp,
        50 + 2 + 1,
        reason:
            'turn 1 heals streak + gear, turn 2 the streak alone — the '
            'mutant this kills never clears the unit, so a streak-sustained '
            'status heals double forever off one proc',
      );
    });

    test('Electro: Static Feedback strips exactly one charge', () {
      bruno
        ..charge = 3
        ..element = MagicElement.pyro;
      alice.gearProcs = {MagicElement.electro};
      bolt(scripted([0.0]));
      expect(bruno.charge, 3 - ElementTuning.staticFeedbackChargeDrain);
    });

    test('Aero: Tailwind takes the Haste token', () {
      bruno.hasHaste = true;
      alice.gearProcs = {MagicElement.aero};
      bolt(scripted([0.0]));
      expect(
        alice.hasHaste,
        isTrue,
        reason: 'the wind grabs Haste through the streak\'s own grab',
      );
    });

    test('Geo: Stagger halves their next offensive spell', () {
      alice.gearProcs = {MagicElement.geo};
      bolt(scripted([0.0]));
      expect(
        bruno.nextOffensiveDamageScale,
        ElementTuning.staggerDamagePercent / 100,
      );
    });

    for (final element in [MagicElement.solar, MagicElement.lunar]) {
      test('${element.name}: Blind for ONE turn, not three', () {
        alice.gearProcs = {element};
        final duel = scripted([0.0]);
        bolt(duel);
        final blind = bruno.statuses.whereType<BlindStatus>().single;
        expect(
          blind.turnsLeft,
          1,
          reason: '§4.1a "Blind, 1 turn" — the spell path\'s 3 is the mutant',
        );
        expect(
          blind.missChance,
          0.5,
          reason: 'active from the next turn, like every Blind',
        );
        // One turn of misses, then gone.
        alice.gearProcs = {};
        bolt(duel);
        expect(
          bruno.statuses.whereType<BlindStatus>(),
          isEmpty,
          reason: 'a 1-turn Blind is over after one active turn',
        );
      });
    }

    test('Astral: one Alignment stack that survives to your next cast', () {
      alice.gearProcs = {MagicElement.astral};
      final duel = scripted([0.0]);
      bolt(duel);
      expect(
        alice.statuses.whereType<AstralAlignmentStatus>().single.stacks,
        ElementTuning.alignmentPerCharge,
        reason:
            '"Astral Alignment on your NEXT cast" — without the decay hold a '
            'Geo wearer\'s stack is gone at the end of the turn it landed',
      );
      alice.gearProcs = {};
      bolt(duel);
      expect(
        alice.statuses.whereType<AstralAlignmentStatus>(),
        isEmpty,
        reason: 'the hold is ONE turn — after it the status decays as ever',
      );
    });

    test('Sanctus: Grace on you', () {
      alice.gearProcs = {MagicElement.sanctus};
      bolt(scripted([0.0]));
      expect(alice.hasGrace, isTrue);
      expect(bruno.hasGrace, isFalse, reason: 'Grace is the WEARER\'s');
    });

    test('Umbra: +1 Creeping Dark on the WEARER', () {
      alice.gearProcs = {MagicElement.umbra};
      bolt(scripted([0.0]));
      expect(
        alice.statuses.whereType<CreepingDarkStatus>().single.stacks,
        ElementTuning.creepingDarkPerCharge,
        reason:
            'Creeping Dark is the holder\'s own veil — the engine\'s spell '
            'path puts it on the caster, and so does the proc',
      );
      expect(
        bruno.statuses.whereType<CreepingDarkStatus>(),
        isEmpty,
        reason: 'on them, it would hand the OPPONENT the concealment',
      );
    });

    test('Arcane: +1 Arcane Knowledge, whatever the charge spent', () {
      alice.gearProcs = {MagicElement.arcane};
      bolt(scripted([0.0]));
      expect(
        alice.statuses.whereType<ArcaneKnowledgeStatus>().single.stacks,
        1,
      );
      expect(
        alice.bonusDamagePercent,
        ElementTuning.arcaneKnowledgePercentPerStack,
        reason: 'the stack is mirrored into the damage bonus, as ever',
      );
    });
  });

  group('immunities and the §5.2 web apply unchanged', () {
    test('Grace eats a Pyro proc', () {
      bruno.hasGrace = true;
      alice.gearProcs = {MagicElement.pyro};
      bolt(scripted([0.0]));
      expect(bruno.statuses.whereType<IgniteStatus>(), isEmpty);
      expect(bruno.hasGrace, isFalse, reason: 'and is spent doing it');
    });

    test('Photosynthesis blocks a Waterlogged proc', () {
      bruno.statuses.add(PhotosynthesisStatus());
      bruno
        ..streakElement = MagicElement.flora
        ..streakCount = ElementTuning.photosynthesisStreak;
      alice.gearProcs = {MagicElement.aqua};
      bolt(scripted([0.0]));
      expect(bruno.priorityPenalty, 0);
    });

    test('a standing Geo shield grounds a Static Feedback proc', () {
      bruno
        ..charge = 3
        ..element = MagicElement.pyro
        ..shield = ActiveShield.elemental(MagicElement.geo, 500);
      alice.gearProcs = {MagicElement.electro};
      bolt(scripted([0.0]));
      expect(bruno.charge, 3);
    });

    test('a Tailwind streak of 3+ shrugs off a Stagger proc', () {
      bruno
        ..streakElement = MagicElement.aero
        ..streakCount = ElementTuning.tailwindStreak;
      alice.gearProcs = {MagicElement.geo};
      bolt(scripted([0.0]));
      expect(bruno.nextOffensiveDamageScale, 1.0);
    });

    test('Dusk blocks an Arcane Knowledge proc', () {
      bruno.statuses.add(CreepingDarkStatus(ElementTuning.duskThreshold));
      alice.gearProcs = {MagicElement.arcane};
      bolt(scripted([0.0]));
      expect(alice.statuses.whereType<ArcaneKnowledgeStatus>(), isEmpty);
    });

    test('a 1-turn Blind proc never shortens a standing Blind, nor spends '
        'Grace on nothing', () {
      bruno
        ..hasGrace = true
        ..statuses.add(BlindStatus());
      alice.gearProcs = {MagicElement.solar};
      bolt(scripted([0.0]));
      expect(
        bruno.statuses.whereType<BlindStatus>().single.turnsLeft,
        ElementTuning.blindTurns,
        reason: 'the spell\'s 3-turn window stands',
      );
      expect(
        bruno.hasGrace,
        isTrue,
        reason: 'a proc that changes nothing must not consume the ward',
      );
    });
  });
}
