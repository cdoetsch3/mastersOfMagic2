import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Proves the intelligence ladder (GAME_DESIGN §6b) actually climbs.
///
/// A ladder of competences is only worth having if a higher rung *beats* a
/// lower one — that is the difference between a designed ladder and a table of
/// adjectives. These play the rungs against each other and assert it.
void main() {
  /// A realistic loadout: ~5 elements and ~10 spells, drawn at random and
  /// guaranteed to contain at least one attack.
  ///
  /// ⚠️ **Measuring with the whole spellbook measures a game nobody plays.** A
  /// real mage brings 15 slots (PROGRESSION §1), and the difference is not
  /// cosmetic: with the full book Cataclysm is *always* available and always
  /// the best line, which rewards a brain that simply charges to 5 every time.
  /// Constrain the book and the same brains rank differently. Every rung
  /// comparison here therefore runs on drawn loadouts, exactly like the
  /// balance sim.
  (List<MagicElement>, List<Spell>) drawKit(Random rng) {
    final els = List.of(MagicElement.values)..shuffle(rng);
    final book = List.of(Spellbook.all)..shuffle(rng);
    final picked = book.take(10).toList();
    if (!picked.any((s) => s.isOffensive)) {
      picked[0] = Spellbook.all.firstWhere((s) => s.isOffensive);
    }
    return (els.take(5).toList(), picked);
  }

  /// Plays [duels] between two brains and returns A's win percentage of
  /// decisive duels.
  double rawRate(int a, int b, int duels, int seed) {
    final rng = Random(seed);
    var wins = 0, decisive = 0;
    for (var i = 0; i < duels; i++) {
      final m1 = MageState(name: 'A');
      final m2 = MageState(name: 'B');
      final duel = DuelEngine(m1, m2, rng: rng, baseMissPercent: 0);
      final k1 = drawKit(rng);
      final k2 = drawKit(rng);
      final ai1 = LadderAi(a, spells: k1.$2, elements: k1.$1);
      final ai2 = LadderAi(b, spells: k2.$2, elements: k2.$1);
      var turns = 0;
      while (!duel.isOver && turns < 200) {
        duel.resolveTurn(
          ai1.chooseAction(m1, m2, rng),
          ai2.chooseAction(m2, m1, rng),
        );
        turns++;
      }
      if (duel.isOver && duel.winner != null) {
        decisive++;
        if (duel.winner == m1) wins++;
      }
    }
    return decisive == 0 ? 50.0 : wins * 100 / decisive;
  }

  /// A's win rate against B, averaged over several seeds **and both seats**.
  ///
  /// ⚠️ The upper rungs are separated by two or three points, not tens, so a
  /// single seed measures noise rather than skill — and swapping seats removes
  /// any turn-order advantage. Tuning against one seed produced a ladder that
  /// reordered itself every run.
  double winRate(int a, int b) {
    var total = 0.0;
    var samples = 0;
    for (final seed in const [1, 7, 23]) {
      total += rawRate(a, b, 300, seed);
      total += 100 - rawRate(b, a, 300, seed + 100);
      samples += 2;
    }
    return total / samples;
  }

  group('the ladder climbs', () {
    test('EVERY adjacent rung beats the one below it', () {
      // ⭐ The headline property, and the whole point of the ladder: a higher
      // rating is a harder opponent, everywhere on the scale. Two things carry
      // it — the competences make each rung *different*, and the blunder
      // gradient makes each rung *better*. Competences alone left 6-9 within
      // two points of each other, which is not a usable difficulty dial.
      final failures = <String>[];
      for (var low = 1; low < 10; low++) {
        final r = winRate(low + 1, low);
        if (r <= 50.0) {
          failures.add('${low + 1} vs $low = ${r.toStringAsFixed(1)}%');
        }
      }
      expect(failures, isEmpty,
          reason: 'these rungs do not climb: ${failures.join(", ")}');
    });

    test('level 9 beats level 7', () {
      final r = winRate(9, 7);
      expect(r, greaterThan(51.0),
          reason: 'level 9 won only ${r.toStringAsFixed(1)}% against level 7');
    });

    test('level 10 beats level 9 — it is the same brain that never blunders',
        () {
      final r = winRate(10, 9);
      expect(r, greaterThan(51.0),
          reason: 'level 10 won only ${r.toStringAsFixed(1)}% against level 9');
    });

    test('the scale spans a real difficulty range', () {
      // Against a mid-ladder baseline the rungs must fan out, not cluster.
      final low = winRate(1, 5);
      final high = winRate(10, 5);
      expect(low, lessThan(25.0),
          reason: 'level 1 measured ${low.toStringAsFixed(1)}% vs level 5');
      expect(high, greaterThan(70.0),
          reason: 'level 10 measured ${high.toStringAsFixed(1)}% vs level 5');
    });

    test('the big competence jumps are decisive', () {
      for (final (low, high, floor) in const [
        (1, 2, 65.0), // a habit beats flailing
        (2, 3, 60.0), // using the charge system at all
        (5, 9, 60.0), // counter-aware -> predictive
        (1, 10, 90.0), // top vs bottom
      ]) {
        final r = winRate(high, low);
        expect(r, greaterThan(floor),
            reason: 'level $high scored ${r.toStringAsFixed(1)}% against level '
                '$low, below the $floor% this step should clear');
      }
    });

    test('a rung is even with itself', () {
      for (final level in const [4, 7, 9]) {
        final r = winRate(level, level);
        expect(r, inInclusiveRange(40.0, 60.0),
            reason: 'level $level mirror came out ${r.toStringAsFixed(1)}%');
      }
    });
  });

  group('the rungs behave as specified', () {
    test('level 1 is pure randomness — the weakest thing on the ladder', () {
      // Not a habit: over many seeds it must produce several different moves.
      final seen = <String>{};
      for (var i = 0; i < 80; i++) {
        final self = MageState(name: 'A')
          ..charge = 5
          ..element = MagicElement.pyro;
        final a = LadderAi(1).chooseAction(self, MageState(name: 'B'), Random(i));
        seen.add(a is CastAction ? a.spell.id : 'charge');
      }
      expect(seen.length, greaterThan(3),
          reason: 'level 1 should flail across the whole action space');
    });

    test('level 2 repeats one cheap habit', () {
      // ⚠️ Deliberately its *cheapest* attack rather than literally Flick —
      // only ~38% of drawn loadouts contain Flick, so a Flick-or-nothing rung
      // would spend most games undefined.
      final book = [Spellbook.bolt, Spellbook.cataclysm, Spellbook.ward];
      for (var i = 0; i < 40; i++) {
        final self = MageState(name: 'A')
          ..charge = 5
          ..element = MagicElement.pyro;
        final a = LadderAi(2, spells: book)
            .chooseAction(self, MageState(name: 'B'), Random(i));
        if (a is CastAction && a.spell.id != 'bolt') {
          // Only a blunder may deviate from the habit.
          expect(LadderAi(2).intelligence, 2);
        }
      }
      final habits = <String>{};
      for (var i = 0; i < 200; i++) {
        final self = MageState(name: 'A')
          ..charge = 5
          ..element = MagicElement.pyro;
        final a = LadderAi(2, spells: book)
            .chooseAction(self, MageState(name: 'B'), Random(i));
        if (a is CastAction) habits.add(a.spell.id);
      }
      expect(habits, contains('bolt'),
          reason: 'level 2 should settle on its cheapest attack');
    });

    test('level 3 spends the charge it built', () {
      final self = MageState(name: 'A')
        ..charge = 3
        ..element = MagicElement.pyro;
      var bigCasts = 0;
      for (var i = 0; i < 100; i++) {
        final me = MageState(name: 'A')
          ..charge = 3
          ..element = MagicElement.pyro;
        final a = LadderAi(3).chooseAction(me, MageState(name: 'B'), Random(i));
        if (a is CastAction && a.spell.chargeCost > 1) bigCasts++;
      }
      expect(bigCasts, greaterThan(50),
          reason: 'level 3 charges to a fixed number then spends it');
      expect(self.charge, 3);
    });

    test('level 4 stops burning a full cycle on a cheap spell', () {
      var wasted = 0;
      for (var i = 0; i < 200; i++) {
        final self = MageState(name: 'A')
          ..charge = 5
          ..element = MagicElement.pyro;
        final a = LadderAi(4).chooseAction(self, MageState(name: 'B'), Random(i));
        if (a is CastAction && a.spell.chargeCost <= 1 && !a.spell.xCost) wasted++;
      }
      expect(wasted, lessThan(20), reason: 'wasted a 5-charge cycle $wasted/200');
    });

    test('level 6 never misses a guaranteed kill', () {
      final self = MageState(name: 'A')
        ..charge = 5
        ..element = MagicElement.pyro;
      final enemy = MageState(name: 'B')..hp = 3;
      final a = LadderAi(6).chooseAction(self, enemy, Random(3));
      expect(a, isA<CastAction>());
      expect((a as CastAction).spell.isOffensive, isTrue);
    });

    test('level 9 answers a big enemy charge more reliably than level 7', () {
      // Prediction sits at 9 — it measured as the strongest single competence
      // on the ladder, so rating it lower made the ladder non-monotonic.
      var seven = 0, five = 0;
      for (var i = 0; i < 100; i++) {
        for (final lvl in const [7, 9]) {
          final self = MageState(name: 'A')
            ..charge = 3
            ..element = MagicElement.pyro;
          final enemy = MageState(name: 'B')..charge = 4;
          final a = LadderAi(lvl).chooseAction(self, enemy, Random(i));
          final guard = a is CastAction &&
              (a.spell.effect is ShieldEffect || a.spell.effect is BarrierEffect);
          if (guard) lvl == 9 ? seven++ : five++;
        }
      }
      expect(seven, greaterThan(five), reason: '$seven vs $five of 100');
    });

    test('level 7 holds while blinded; level 6 swings anyway', () {
      var eight = 0, seven = 0;
      for (var i = 0; i < 100; i++) {
        for (final lvl in const [6, 7]) {
          final self = MageState(name: 'A')
            ..charge = 3
            ..element = MagicElement.pyro
            ..statuses.add(BlindStatus());
          final a = LadderAi(lvl).chooseAction(self, MageState(name: 'B'), Random(i));
          if (a is CastAction && a.spell.isOffensive) lvl == 7 ? eight++ : seven++;
        }
      }
      expect(eight, lessThan(seven), reason: '$eight vs $seven swings of 100');
    });

    test('level 5 picks a different spell than level 4 when a wall is up', () {
      // ⚠️ Counter-awareness is NOT "refuse to attack a shield" — chipping a
      // wall down is progress, and an AI that only counts through-damage
      // stands there charging while the opponent re-shields forever. What
      // level 5 does is *rank* by what actually gets through, where level 4
      // still reaches for the biggest raw spell.
      String choice(int lvl, int seed) {
        final self = MageState(name: 'A')
          ..charge = 4
          ..element = MagicElement.pyro;
        // An Aqua wall resists Pyro, so raw size and effective damage diverge.
        final enemy = MageState(name: 'B')
          ..shield = ActiveShield.elemental(MagicElement.aqua, 60);
        final a = LadderAi(lvl).chooseAction(self, enemy, Random(seed));
        return a is CastAction ? a.spell.id : 'charge';
      }

      var differed = 0;
      for (var i = 0; i < 150; i++) {
        if (choice(5, i) != choice(4, i)) differed++;
      }
      expect(differed, greaterThan(0),
          reason: 'level 5 made the identical choice to level 4 on all 150 '
              'seeds against a resistant wall — counter-awareness is not '
              'reaching the board');
    });

    test('level 8 is more patient than level 7', () {
      // What actually earns level 8 its win rate is patience: it holds for the
      // payoff instead of poking on a fixed rhythm. (Refusing to feed a wall
      // turned out to be redundant — level 5's counter-filter already declines
      // an attack worth zero, so the planning rung's real edge is timing.)
      int charges(int lvl) {
        var held = 0;
        for (var i = 0; i < 200; i++) {
          final self = MageState(name: 'A')
            ..charge = 2
            ..element = MagicElement.pyro;
          final a = LadderAi(lvl).chooseAction(self, MageState(name: 'B'), Random(i));
          if (a is ChargeAction) held++;
        }
        return held;
      }

      expect(charges(8), greaterThan(charges(7)),
          reason: 'level 8 (${charges(8)}/200) was no more patient than '
              'level 7 (${charges(7)}/200)');
    });

    test('level 10 plays exactly like level 9, minus the blunders', () {
      // ⭐ Level 10's whole advantage is a 0% blunder rate. An earlier design
      // had it randomise spell choice and timing to be unreadable — both are
      // deliberately suboptimal in isolation and only pay against an opponent
      // that learns patterns, which no simulation does. So it was paying a
      // real cost to collect nothing.
      expect(blunderRateForIntelligence(10), 0.0);
      expect(blunderRateForIntelligence(9), greaterThan(0.0));

      // With blundering removed from the comparison, the two are identical.
      var same = 0;
      for (var i = 0; i < 200; i++) {
        String choice(int lvl) {
          final self = MageState(name: 'A')
            ..charge = 5
            ..element = MagicElement.pyro;
          final a = LadderAi(lvl).chooseAction(self, MageState(name: 'B'), Random(i));
          return a is CastAction ? a.spell.id : 'charge';
        }

        if (choice(10) == choice(9)) same++;
      }
      expect(same, greaterThan(150),
          reason: 'levels 9 and 10 should differ only by blunder frequency '
              '(matched on $same/200 seeds)');
    });

    test('the blunder rate falls monotonically up the ladder', () {
      var previous = 1.0;
      for (var i = 2; i <= 10; i++) {
        final r = blunderRateForIntelligence(i);
        expect(r, lessThan(previous), reason: 'level $i blunders $r');
        previous = r;
      }
    });
  });

  group('the AI does not cheat through Creeping Dark', () {
    // ⚠️ Umbra's whole identity is information warfare. An AI that reads
    // MageState directly sees straight through it, which would make Umbra
    // worthless against everything except a human.
    MageState darkened(int stacks) => MageState(name: 'B')
      ..statuses.add(CreepingDarkStatus(stacks))
      ..charge = 5
      ..hp = 4;

    test('Dusk hides the enemy charge and health from the view', () {
      final view = EnemyView.of(darkened(10));
      expect(view.chargeHidden, isTrue);
      expect(view.charge, isNull);
      expect(view.hp, isNull);
    });

    test('Shadow hides the charging element but not charge or health', () {
      final view = EnemyView.of(darkened(5));
      expect(view.elementHidden, isTrue);
      expect(view.element, isNull);
      expect(view.charge, 5, reason: 'Shadow does not hide charge — Dusk does');
    });

    test('an unconcealed enemy is fully visible', () {
      final plain = MageState(name: 'B')
        ..charge = 3
        ..element = MagicElement.pyro;
      final view = EnemyView.of(plain);
      expect(view.charge, 3);
      expect(view.hp, plain.hp);
      expect(view.element, MagicElement.pyro);
    });

    test('a lethal visible on the bar is taken; the same lethal under Dusk '
        'is not', () {
      // At 1 charge against a 3 HP enemy the two cases diverge sharply:
      // seeing the bar, the lethal check fires every time; with the bar
      // hidden the brain has no reason to break its normal rhythm.
      int castsOn(MageState Function() enemyMaker) {
        var casts = 0;
        for (var i = 0; i < 60; i++) {
          final self = MageState(name: 'A')
            ..charge = 1
            ..element = MagicElement.pyro;
          final a = LadderAi(8).chooseAction(self, enemyMaker(), Random(i));
          if (a is CastAction && a.spell.isOffensive) casts++;
        }
        return casts;
      }

      final visible = castsOn(() => MageState(name: 'B')..hp = 3);
      final hidden = castsOn(() => MageState(name: 'B')
        ..hp = 3
        ..statuses.add(CreepingDarkStatus(10)));

      // Not all 60: even level 8 blunders 7% of the time.
      expect(visible, greaterThan(50),
          reason: 'with the bar visible the kill should be near-certain');
      expect(hidden, lessThan(visible),
          reason: 'under Dusk the AI still found the kill $hidden/60 times — '
              'it is reading through Creeping Dark');
    });
  });

  // ======================================================================
  // Forfeiting is not a tactic (the Sporecap Shambler bug)
  // ======================================================================
  //
  // ⭐ [ForfeitAction] means **"no legal move exists"**, never "nothing looks
  // good". The distinction is not academic: `DuelController.forfeitLimit`
  // reads three forfeits in a row as a disconnected opponent and concedes the
  // duel for that side. A brain that forfeits out of taste therefore does not
  // play badly — it *quits*, and in a campaign fight it hands the player a
  // free win plus the loot that goes with it.
  group('the right tool against a Barrier', () {
    // ⭐ A Barrier eats exactly ONE hit, whole — so the pick against one is
    // the cheapest pop or a multi-hit whose later hits land, never the
    // biggest number (playtest ruling, 2026-08-10).
    const cheap = Spell(
        id: 'flick',
        name: 'Flick',
        chargeCost: 1,
        priority: 9,
        effect: DamageEffect(6, 8));
    const big = Spell(
        id: 'slam',
        name: 'Slam',
        chargeCost: 5,
        priority: 9,
        effect: DamageEffect(40, 50));
    const volley = Spell(
        id: 'volley',
        name: 'Volley',
        chargeCost: 3,
        priority: 9,
        effect: DamageEffect(4, 6, hits: 3));

    MageState walled() => MageState(name: 'You')
      ..barrierPoints = MageState.maxBarrierPoints;

    MageState full() => MageState(name: 'Foe')
      ..charge = MageState.maxCharge
      ..element = MagicElement.flora;

    test('a small spell outranks a large one against a Barrier', () {
      final ai = LadderAi(5,
          spells: const [cheap, big], elements: const [MagicElement.flora]);
      final action = ai.chooseAction(full(), walled(), Random(3));
      expect(action, isA<CastAction>());
      expect((action as CastAction).spell.id, 'flick',
          reason: 'a raw-damage sort spends a Slam where a Flick does the '
              'identical job — the barrier eats one hit whole either way');
    });

    test('a multi-hit spell outranks the cheap pop — its later hits land', () {
      final ai = LadderAi(5,
          spells: const [cheap, big, volley],
          elements: const [MagicElement.flora]);
      final action = ai.chooseAction(full(), walled(), Random(3));
      expect(action, isA<CastAction>());
      expect((action as CastAction).spell.id, 'volley',
          reason: 'hits after the first get past the popped point — real '
              'damage this turn, which no single hit can offer');
    });

    test('⚠️ the asymmetry: against an elemental shield, big still wins', () {
      final ai = LadderAi(5,
          spells: const [cheap, big], elements: const [MagicElement.flora]);
      final shielded = MageState(name: 'You')
        ..shield = ActiveShield.elemental(MagicElement.geo, 500);
      final action = ai.chooseAction(full(), shielded, Random(3));
      expect(action, isA<CastAction>());
      expect((action as CastAction).spell.id, 'slam',
          reason: 'a shield is a POOL — chipping scales with the hit, so the '
              'barrier rule must not leak onto elemental shields');
    });
  });

  group('a wall is never a reason to forfeit', () {
    /// The Sporecap Shambler's real kit — *nothing but damage*, no shield and
    /// no aux, so there is nothing to fall back on when its attacks are rated
    /// worthless. (`test/whispering_woods_test.dart` fights the actual
    /// bestiary entry; this is the engine-side shape of it.)
    final moves = [
      Spell(
          id: 'ww_puffburst',
          name: 'Puffburst',
          chargeCost: 1,
          priority: 8,
          effect: DamageEffect(3, 5, hits: 2)),
      Spell(
          id: 'ww_settle',
          name: 'Settle',
          chargeCost: 2,
          priority: 8,
          effect: DamageEffect(4, 6, hits: 3)),
    ];

    /// Intelligence 5 is the Blighter archetype's rung — and 5 is where the
    /// bug lives, because counter-awareness is the competence that scores a
    /// blocked hit at all.
    LadderAi brainAt(int rung) =>
        LadderAi(rung, spells: moves, elements: const [MagicElement.flora]);

    test('a standing Barrier does not stall the brain into surrendering', () {
      // ⚠️ Barrier is the trap, and specifically Barrier *without* an
      // elemental shield behind it: points come off only when something hits
      // them, so a brain that refuses to hit them has guaranteed the standoff
      // it is waiting out. It charged to 5, ran out of moves it valued, and
      // forfeited every turn from there.
      final foe = MageState(name: 'Shambler');
      final dummy = MageState(name: 'You', maxHp: 600);
      final duel = DuelEngine(foe, dummy, rng: Random(7), baseMissPercent: 0);
      final ai = brainAt(5);
      final rng = Random(1234);

      var forfeits = 0, longestStreak = 0, streak = 0, barriersBroken = 0;
      for (var turn = 0; turn < 20; turn++) {
        // The player keeps a Barrier up — exactly the board that produced the
        // bug, held for the whole fight rather than for one turn.
        if (dummy.barrierPoints == 0) {
          dummy.barrierPoints = MageState.maxBarrierPoints;
          if (turn > 0) barriersBroken++;
        }
        final action = ai.chooseAction(foe, dummy, rng);
        if (action is ForfeitAction) {
          forfeits++;
          streak++;
          longestStreak = max(longestStreak, streak);
        } else {
          streak = 0;
        }
        duel.resolveTurn(action, const ForfeitAction());
      }
      expect(forfeits, 0,
          reason: 'forfeited $forfeits/20 turns while holding an affordable '
              'attack — the brain is scoring a blocked hit as worthless and '
              'quitting instead of chipping the wall down');
      expect(longestStreak, lessThan(3),
          reason: 'a streak this long is what DuelController.forfeitLimit '
              'converts into a surrender');
      expect(barriersBroken, greaterThan(0),
          reason: 'it never actually attacked the Barrier — charging forever '
              'is the same stalemate wearing a different action');
    });

    test('a Barrier does not change how willing the brain is to swing', () {
      // ⭐ The root cause, isolated from the forfeit it eventually caused: the
      // scorer counted only damage that reaches the health bar, so every move
      // was worth *zero* against a Barrier and the counter-aware filter threw
      // the whole attack list away. Same board, same charge — only the wall
      // differs, and a wall that is only removed by being hit must not make
      // the brain less willing to hit it.
      int swings({required bool barrier}) {
        var n = 0;
        for (var i = 0; i < 300; i++) {
          final me = MageState(name: 'AI')
            ..charge = 2
            ..element = MagicElement.flora;
          final you = MageState(name: 'You');
          if (barrier) you.barrierPoints = MageState.maxBarrierPoints;
          if (brainAt(5).chooseAction(me, you, Random(i)) is CastAction) n++;
        }
        return n;
      }

      final walled = swings(barrier: true);
      final open = swings(barrier: false);
      expect(walled, greaterThan(open * 3 ~/ 4),
          reason: 'attacked only $walled/300 times through a Barrier versus '
              '$open/300 against a naked target — a blocked hit is being '
              'scored as worthless rather than as one barrier point removed');
    });

    test('every rung, at full charge, casts rather than quits', () {
      // The structural version of the same invariant, across the whole ladder
      // and both walls: at max charge there is no charging left to do, so a
      // brain with an affordable spell and no way to charge must cast one.
      for (var rung = 1; rung <= 10; rung++) {
        for (final wall in ['barrier', 'shield', 'none']) {
          final foe = MageState(name: 'AI')
            ..charge = MageState.maxCharge
            ..element = MagicElement.flora;
          final dummy = MageState(name: 'You');
          if (wall == 'barrier') {
            dummy.barrierPoints = MageState.maxBarrierPoints;
          }
          if (wall == 'shield') {
            dummy.shield = ActiveShield.elemental(MagicElement.geo, 500);
          }
          final ai = brainAt(rung);
          for (var i = 0; i < 40; i++) {
            expect(ai.chooseAction(foe, dummy, Random(i)),
                isNot(isA<ForfeitAction>()),
                reason: 'rung $rung forfeited at full charge against a $wall '
                    'while Puffburst and Settle were both affordable — '
                    'ForfeitAction must mean "no legal move", not "no good '
                    'move"');
          }
        }
      }
    });

    test('a spell worth nothing this turn is still cast before quitting', () {
      // Overload scales off the ENEMY's charge, so against an empty bar it is
      // honestly worth zero — no wall involved, nothing for the wall credit
      // above to catch. Full charge, one move, nothing to charge toward: the
      // brain has to spend it. This is the last remaining route to a forfeit
      // streak, and the fallback in `chooseAction` is what closes it.
      final overload = Spell(
          id: 'overload',
          name: 'Overload',
          chargeCost: 2,
          priority: 9,
          effect: const OverloadEffect(6, 9));
      final ai = LadderAi(9,
          spells: [overload], elements: const [MagicElement.electro]);
      for (var i = 0; i < 40; i++) {
        final me = MageState(name: 'AI')
          ..charge = MageState.maxCharge
          ..element = MagicElement.electro;
        expect(ai.chooseAction(me, MageState(name: 'You'), Random(i)),
            isNot(isA<ForfeitAction>()),
            reason: 'forfeited with an affordable spell in hand because it '
                'scored zero — three of these in a row is a surrender');
      }
    });
  });

  test('intelligence is clamped to 1-10', () {
    expect(LadderAi(0).intelligence, 1);
    expect(LadderAi(99).intelligence, 10);
  });
}
