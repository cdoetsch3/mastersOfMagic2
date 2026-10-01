import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Deterministic RNG: `nextDouble` returns scripted values then 0.99 forever;
/// `nextInt` returns 0 (so a guarded crit/deflect chance always fires when it
/// is > 0, and damage rolls take their minimum).
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

Spell dmg(int amount, {int hits = 1}) => Spell(
  id: 'dmg$amount',
  name: 'Dmg$amount',
  chargeCost: 0,
  priority: 9,
  effect: DamageEffect(amount, amount, hits: hits),
);

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    // ⚠️ critChance pinned to 0 throughout this file: every mage now starts
    // at MageState.baseCritChance (5%, ruling 2026-09-30), and these tests
    // assert exact damage — an unpinned base crit is a 1-in-20 flake per hit.
    // A test about crits sets its own chance after construction.
    alice = MageState(name: 'Alice')..critChance = 0;
    bruno = MageState(name: 'Bruno')..critChance = 0;
  });

  void cast(DuelEngine d, Spell s, MagicElement e) {
    alice
      ..charge = s.chargeCost
      ..element = e;
    d.resolveTurn(CastAction(s, e), const ForfeitAction());
  }

  // ======================================================================
  // Accuracy & dodge — a single unified hit roll (§5.2 step 3)
  // ======================================================================
  group('accuracy & dodge', () {
    test('default stats always hit', () {
      // 100 accuracy, 0 dodge → the full 20 lands. (That the default path
      // draws *no* RNG isn't proven here — a missPercent of 0 never rolls
      // regardless — but by the sim staying byte-identical to Phase 3.)
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.0]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.flora);
      expect(bruno.hp, 80, reason: '100 accuracy, 0 dodge → always lands');
    });

    test('dodge subtracts from accuracy, creating a miss chance', () {
      bruno.dodge = 30; // 100 − 30 = 70 hit → 30 miss
      // 0.2 → 20 < 30 → miss.
      var duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.2]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100, reason: 'rolled a miss');

      // 0.5 → 50 < 30 is false → hit.
      alice = MageState(name: 'Alice')..critChance = 0;
      bruno = MageState(name: 'Bruno')
        ..critChance = 0
        ..dodge = 30;
      duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.5]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 80, reason: 'rolled a hit');
    });

    test('accuracy above 100 claws back dodge (120 − 30 = 90 hit)', () {
      // With +20 gear accuracy the miss chance is only 10%, not 30%.
      bruno.dodge = 30;
      alice.accuracyBonus = 20;
      // 0.2 → 20 < 10 is false → hits (a 100-accuracy attacker would miss here).
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.2]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(
        bruno.hp,
        80,
        reason: 'the extra accuracy turned a miss into a hit',
      );
    });

    test('accuracy above 100 is not clamped — a miss chance can still exist', () {
      bruno.dodge = 30;
      alice.accuracyBonus = 20; // 90 hit → 10 miss
      // 0.05 → 5 < 10 → still a miss: 120 accuracy does not fully cancel dodge.
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.05]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100);
    });

    test('Blind is exactly a flat −50 accuracy penalty', () {
      // Unblinded 100-accuracy attacker never misses...
      var duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.4]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 80);

      // ...but with Blind active (−50 → 50 hit / 50 miss), 0.4 misses.
      alice = MageState(name: 'Alice')
        ..critChance = 0
        ..statuses.add(BlindStatus()..advanceAndCheckExpiry(alice));
      bruno = MageState(name: 'Bruno')..critChance = 0;
      duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom([0.4]),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 100, reason: '0.4 < 0.5 → the blinded attack misses');
    });
  });

  // ======================================================================
  // Crit — per hit (§5.2 step 4/5)
  // ======================================================================
  group('crit', () {
    test('a crit multiplies damage by (1 + critDamage)', () {
      alice
        ..critChance = 100
        ..critDamage = 50; // ×1.5
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 70, reason: '20 × 1.5 = 30');
    });

    test('crit is emitted on the DamageEvent', () {
      alice.critChance = 100;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final r = duel.resolveTurn(
        CastAction(dmg(20), MagicElement.pyro),
        const ForfeitAction(),
      );
      expect(r.events.whereType<DamageEvent>().single.crit, isTrue);
    });

    test(
      'crit rolls per hit — a whole multi-hit spell crits together here',
      () {
        alice
          ..critChance = 100
          ..critDamage = 50;
        final duel = DuelEngine(
          alice,
          bruno,
          rng: ScriptedRandom(),
          baseMissPercent: 0,
        );
        cast(duel, dmg(4, hits: 3), MagicElement.pyro); // 4×1.5 = 6, ×3 = 18
        expect(bruno.hp, 82);
        alice
          ..charge = 0
          ..element = MagicElement.pyro;
        final r = duel.resolveTurn(
          CastAction(dmg(4, hits: 3), MagicElement.pyro),
          const ForfeitAction(),
        );
        expect(
          r.events.whereType<DamageEvent>().where((e) => e.crit).length,
          3,
        );
      },
    );
  });

  // ======================================================================
  // Deflection — defender side, per hit (§5.2 step 6). Pure reduction.
  // ======================================================================
  group('deflection', () {
    test('a deflect removes a percent of the incoming hit', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 40;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(bruno.hp, 88, reason: '40% of 20 = 8 removed, 12 lands');
    });

    test('the removed amount is reported, and is reduction not reflection', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 40;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final r = duel.resolveTurn(
        CastAction(dmg(20), MagicElement.pyro),
        const ForfeitAction(),
      );
      expect(r.events.whereType<DamageEvent>().single.deflected, 8);
      expect(alice.hp, 100, reason: 'nothing is bounced back to the attacker');
    });

    // ⚠️ UPDATED 2026-08-28 with the §7a "Deflect clamps" ruling. This test
    // used to be 'deflectAmount is clamped to 100 — damage never goes
    // negative' and expected hp 100 (the whole hit erased). The ruling
    // replaced the [0,100] safety clamp with a hard 90% cap on the deflected
    // fraction, so the assertion moves from "all of it" to "90% of it, and a
    // sliver lands". The old expectation is not deleted — it is superseded:
    // its purpose (damage never goes negative) is still covered, because 90%
    // of a positive number is still less than it.
    test('the deflected fraction caps at 90% — a sliver always lands', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 120; // ruled cap: 90
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.pyro);
      expect(
        bruno.hp,
        98,
        reason:
            '⚠️ kills the old clamp-to-100 (hp 100, hit erased) and the '
            'unclamped read (hp 100 too, at 120%); 90% of 20 is 18, so 2 lands',
      );
    });
  });

  // ======================================================================
  // Interaction: crit then deflect on the same hit (order matters)
  // ======================================================================
  test('crit raises the hit, then deflection reduces the crit', () {
    alice
      ..critChance = 100
      ..critDamage = 50; // 20 → 30
    bruno
      ..deflectChance = 100
      ..deflectAmount = 50; // 30 → 15 removed, 15 lands
    final duel = DuelEngine(
      alice,
      bruno,
      rng: ScriptedRandom(),
      baseMissPercent: 0,
    );
    cast(duel, dmg(20), MagicElement.pyro);
    expect(bruno.hp, 85, reason: '20 ×1.5 = 30, then −50% = 15 lands');
  });

  // ======================================================================
  // Gear's flat damage — per cast and per charge spent (ITEMS §9b.8)
  // ======================================================================
  group('flat damage from gear', () {
    test('damagePerCast adds once to a single hit', () {
      alice.damagePerCast = 2; // the wand lane
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.flora);
      expect(bruno.hp, 78, reason: '20 + 2, once');
    });

    test('damagePerCast adds once to a multi-hit spell, not per hit', () {
      alice.damagePerCast = 2;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, dmg(5, hits: 4), MagicElement.flora);
      // ⚠️ Kills the per-hit implementation: 4×(5+2) would be 28.
      expect(bruno.hp, 100 - (5 * 4 + 2), reason: '20 + 2, ONCE');
    });

    test('damagePerCharge scales with the charge the spell cost', () {
      alice.damagePerCharge = 1; // the quarterstaff lane
      final threeCharge = Spell(
        id: 'big',
        name: 'Big',
        chargeCost: 3,
        priority: 9,
        effect: const DamageEffect(20, 20),
      );
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, threeCharge, MagicElement.flora);
      // ⚠️ Kills the flat-constant implementation (21) and the per-cast
      // confusion (20 + 0): the staff pays for COMMITMENT.
      expect(bruno.hp, 100 - 23, reason: '20 + 1×3 charges');
    });

    test('a zero-cost spell pays the staff nothing', () {
      alice.damagePerCharge = 1;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      cast(duel, dmg(20), MagicElement.flora); // chargeCost 0
      expect(bruno.hp, 80, reason: 'no charge spent, no staff bonus');
    });
  });

  // ======================================================================
  // The log's evidence: which hit got the gear, and which hit crit
  // ======================================================================
  //
  // ⭐ Ruling 2026-09-21. A player read "takes Barrage: 10, 14, 10, 11, 32"
  // and asked what proc'd. Nothing did — gear is per cast, so the whole lump
  // rides hit 0 — but the maths is invisible in the line. The rule stands and
  // the EVENT now carries the evidence, which is what the app's log prints.
  group('DamageEvent explains a big hit', () {
    test('⭐ gearBonus rides the first hit and no other', () {
      alice
        ..damagePerCast = 11
        ..charge = 3
        ..element = MagicElement.pyro;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      final hits = duel
          .resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction())
          .events
          .whereType<DamageEvent>()
          .toList();

      expect(hits, hasLength(3), reason: 'one hit per point of charge spent');
      expect(
        hits.first.gearBonus,
        11,
        reason:
            'the whole per-cast lump, on the hit that actually received it '
            '— 0 here means the event never learned why hit 0 is the big '
            'one, which is the report this ruling answers',
      );
      expect(
        hits.skip(1).map((h) => h.gearBonus),
        everyElement(0),
        reason:
            '⚠️ THE pin: gear is per CAST. A mutant reading flatBonus '
            'unconditionally tags all three hits and teaches the player the '
            'opposite of the rule',
      );
    });

    test('a caster with no flat damage tags nothing', () {
      alice
        ..charge = 2
        ..element = MagicElement.pyro;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      final hits = duel
          .resolveTurn(CastAction(Spellbook.barrage), const ForfeitAction())
          .events
          .whereType<DamageEvent>();
      expect(
        hits.map((h) => h.gearBonus),
        everyElement(0),
        reason:
            'a bare "(+0 gear)" on every line would be noise the renderer '
            'has to filter — the event says 0, so the line says nothing',
      );
    });

    test('⭐ crit marks the hit that crit, and only that hit', () {
      // Execute crits at impact time once the target is under 30%, so the
      // first hits land ordinary and a later one does not — the one shape in
      // the game where a multi-hit spell crits partway through. ⚠️ Alice's
      // crit chance stays 0, so nothing else can raise the flag.
      final finisher = Spell(
        id: 'finisher',
        name: 'Finisher',
        chargeCost: 0,
        priority: 9,
        effect: const DamageEffect(40, 40, hits: 3, executeBelowPercent: 30),
      );
      alice.damagePerCast = 11;
      final duel = DuelEngine(
        alice,
        bruno,
        rng: ScriptedRandom(),
        baseMissPercent: 0,
      );
      alice
        ..charge = 0
        ..element = MagicElement.flora;
      final hits = duel
          .resolveTurn(
            CastAction(finisher, MagicElement.flora),
            const ForfeitAction(),
          )
          .events
          .whereType<DamageEvent>()
          .toList();

      expect(hits, hasLength(3));
      expect(
        hits.map((h) => h.crit),
        [false, false, true],
        reason:
            '51 then 40 leaves Bruno on 9 of 100 — under the 30% line only '
            'for the third. A mutant hoisting the crit flag out of the loop '
            'marks all three',
      );
      expect(
        hits.map((h) => h.gearBonus),
        [11, 0, 0],
        reason:
            '⚠️ the two flags are independent and land on DIFFERENT hits '
            'here — kills any implementation that derives one from the '
            'other, or that tags gear onto whichever hit was biggest',
      );
    });
  });
}
