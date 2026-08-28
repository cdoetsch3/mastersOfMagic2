import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The SPECIAL-STANCE and SUSTAIN half of the banked generation
/// (TYPE_EFFECTS_DESIGN.md §7a): Steadfast, Composure, Bloodlust, Death Wish,
/// Reflect, Mend and Renewal.
///
/// ⭐ The four §7a ledger entries this lane owes are marked ⭐ below: Death
/// Wish's threshold and Composure's veto over it, Reflect returning exactly the
/// deflected amount and never bouncing twice, Renewal replacing Mend's rate
/// AND duration, and Steadfast's expiry leaving standing shields alone.

/// `nextDouble` walks [doubles] then returns 0.99; `nextInt` walks [ints] then
/// returns 0. Two independent scripts, matching `stat_derivation_test` — the
/// hit roll draws a double while crit and deflect draw ints, so one shared
/// script would couple every test here to the engine's internal call order.
class ScriptedRandom implements Random {
  final List<double> doubles;
  final List<int> ints;
  var _d = 0;
  var _i = 0;
  ScriptedRandom({this.doubles = const [], this.ints = const []});
  @override
  double nextDouble() => _d < doubles.length ? doubles[_d++] : 0.99;
  @override
  int nextInt(int max) => _i < ints.length ? ints[_i++] : 0;
  @override
  bool nextBool() => false;
}

/// A fixed-damage attack: `_roll(n, n)` draws no RNG at all, so the only
/// [Random] calls in these tests are the ones under test.
Spell dmg(int amount) => Spell(
    id: 'dmg$amount', name: 'Dmg$amount', chargeCost: 0,
    priority: SpellPriority.attack, effect: DamageEffect(amount, amount));

/// A fixed-strength shield, for the same reason.
Spell wall(int strength) => Spell(
    id: 'wall$strength', name: 'Wall$strength', chargeCost: 0,
    priority: SpellPriority.shield, effect: ShieldEffect(strength, strength));

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  DuelEngine engine({List<int> ints = const [], List<double> doubles = const []}) =>
      DuelEngine(alice, bruno,
          rng: ScriptedRandom(ints: ints, doubles: doubles),
          elementEffects: false,
          baseMissPercent: 0);

  /// [who] casts [s]; the other mage does nothing.
  void castBy(DuelEngine d, MageState who, Spell s,
      [MagicElement e = MagicElement.pyro]) {
    who
      ..charge = s.chargeCost
      ..element = e;
    d.resolveTurn(
      identical(who, d.mage1) ? CastAction(s, e) : const ForfeitAction(),
      identical(who, d.mage2) ? CastAction(s, e) : const ForfeitAction(),
    );
  }

  void idle(DuelEngine d) =>
      d.resolveTurn(const ForfeitAction(), const ForfeitAction());

  T only<T extends TurnStatus>(MageState m) {
    final found = m.statuses.whereType<T>().toList();
    expect(found, hasLength(1),
        reason: '⚠️ expected exactly one $T on ${m.name}, found '
            '${found.length} — replace-on-cast (law 5) is what keeps this 1');
    return found.single;
  }

  // ======================================================================
  // The block itself — prices, lane, and the wiring every status needs
  // ======================================================================
  group('the spells as banked', () {
    test('the lane ships exactly its seven, held apart from the shipped book',
        () {
      expect(Spellbook.bankSpecials.map((s) => s.id).toSet(), {
        'steadfast', 'composure', 'bloodlust', 'deathWish', 'reflect',
        'mend', 'renewal',
      });
      for (final s in Spellbook.bankSpecials) {
        expect(Spellbook.all, isNot(contains(s)),
            reason: '⚠️ ${s.id} is parked out of Spellbook.all on purpose — '
                'everything in `all` owes the app a description and an icon, '
                'and those are the HUD lane\'s to write, not this one\'s');
      }
    });

    test('every one is priced and laned as §7a rules it', () {
      const priced = {
        'steadfast': 3,
        'composure': 2,
        'bloodlust': 5,
        'deathWish': 2,
        'reflect': 4,
        'mend': 2,
        'renewal': 4,
      };
      priced.forEach((id, cost) {
        final spell =
            Spellbook.bankSpecials.firstWhere((s) => s.id == id);
        expect(spell.chargeCost, cost,
            reason: '⚠️ $id is a $cost-charge spell — a drifted cost is a '
                'silent balance change nothing else would catch');
        expect(spell.priority, SpellPriority.auxDefense,
            reason: '⚠️ $id is SELF-targeting, so it belongs in the aux-DEFENSE '
                'lane (7). At 8 it would resolve after an enemy debuff instead '
                'of before it, which is the whole point of the split');
        expect(spell.isOffensive, isFalse, reason: id);
        expect(spell.isHarmful, isFalse,
            reason: '⚠️ a self-stance must never count as harmful — it would '
                'eat a Stagger and roll for a Blind miss');
      });
    });

    test('every status these spells grant is catalogued, and as a buff', () {
      for (final grant
          in Spellbook.bankSpecials.expand((s) => (s.effect as StanceEffect).grants)) {
        final status = grant.build();
        expect(status.id, grant.statusId,
            reason: '⚠️ the grant\'s declared id is the collision key law 5 '
                'replaces on — a builder returning a different id would make '
                'the replace a no-op and stack silently');
        final info = StatusCatalog.byId(status.id);
        expect(info, isNotNull,
            reason: "⚠️ '${status.id}' has no StatusCatalog entry — the HUD, "
                'the log and the guide all read that table, so an uncatalogued '
                'status shows as a pip nothing can explain');
        expect(info!.lingers, isTrue, reason: status.id);
        expect(status.polarity, StatusPolarity.buff,
            reason: '⚠️ every stance in this lane is a strippable BUFF; one '
                'that drifted to neutral would become invisible to Dispel');
        expect(info.polarity, status.polarity,
            reason: "⚠️ '${status.id}' must read the same in the catalogue as "
                'it does at runtime');
      }
    });

    test('each status serializes into the HUD snapshot', () {
      final expected = {
        'steadfast': Spellbook.steadfast,
        'composure': Spellbook.composure,
        'deathWish': Spellbook.deathWish,
        'reflect': Spellbook.reflect,
        'mending': Spellbook.mend,
      };
      expected.forEach((id, spell) {
        final a = MageState(name: 'A');
        final b = MageState(name: 'B');
        final duel = DuelEngine(a, b,
            rng: ScriptedRandom(), elementEffects: false, baseMissPercent: 0);
        a
          ..charge = spell.chargeCost
          ..element = MagicElement.pyro;
        duel.resolveTurn(
            CastAction(spell, MagicElement.pyro), const ForfeitAction());
        final view = StatusSnapshot.of(a)[id];
        expect(view, isNotNull,
            reason: "⚠️ '$id' never reaches the snapshot, so its pip could "
                'only appear at end of turn instead of on the cast');
        expect(view!.turnsLeft, greaterThan(0),
            reason: "⚠️ '$id' must carry its clock into the pip");
      });
    });
  });

  // ======================================================================
  // Steadfast — own shield strength, at GAIN time
  // ======================================================================
  group('Steadfast', () {
    test('a shield raised under it is rolled 25% stronger', () {
      final duel = engine();
      castBy(duel, alice, Spellbook.steadfast);
      castBy(duel, alice, wall(20));
      expect(alice.shield!.remaining, 25,
          reason: '⚠️ kills the missing hook: without Steadfast in '
              'effectiveShieldStrengthPercent the wall rolls its bare 20');
    });

    test('it sums with gear rather than replacing it', () {
      alice.shieldStrengthPercent = 20;
      final duel = engine();
      castBy(duel, alice, Spellbook.steadfast);
      expect(alice.effectiveShieldStrengthPercent, 45,
          reason: '⚠️ kills a getter that returns the status contribution '
              'alone (25) or the gear alone (20) — derivation is base + gear + '
              'Σ(statuses)');
      castBy(duel, alice, wall(20));
      expect(alice.shield!.remaining, 29,
          reason: '20 × 1.45 = 29');
    });

    test('⭐ its expiry leaves a standing shield exactly as it was', () {
      // The ruling in one test: the bonus is applied to the ROLL, so the pool
      // it produced is thereafter just a pool.
      alice.statuses.add(SteadfastStatus(percent: 25, turns: 1));
      final duel = engine();
      castBy(duel, alice, wall(20));
      expect(alice.shield!.remaining, 25, reason: 'raised while the stance is up');
      expect(alice.statuses.whereType<SteadfastStatus>(), isEmpty,
          reason: 'the 1-turn stance expired in the same end phase');

      idle(duel);
      idle(duel);
      expect(alice.shield!.remaining, 25,
          reason: '⚠️ THE mutant: a CONTINUOUS implementation re-derives the '
              'standing pool and drops it back to 20 the moment the stance '
              'falls off — a shield you already paid for shrinking behind your '
              'back. Gain-time is what makes this 25 forever');
    });

    test('and a shield raised after it expired is the bare roll', () {
      alice.statuses.add(SteadfastStatus(percent: 25, turns: 1));
      final duel = engine();
      idle(duel); // the stance runs out having shielded nothing
      expect(alice.effectiveShieldStrengthPercent, 0);
      castBy(duel, alice, wall(20));
      expect(alice.shield!.remaining, 20,
          reason: '⚠️ the other half of the ruling: gain-time cuts BOTH ways, '
              'so a stance that has expired buys nothing. Kills a status that '
              'never actually expires');
    });

    test('recasting replaces rather than stacking', () {
      final duel = engine();
      castBy(duel, alice, Spellbook.steadfast);
      castBy(duel, alice, Spellbook.steadfast);
      only<SteadfastStatus>(alice);
      expect(alice.effectiveShieldStrengthPercent, 25,
          reason: '⚠️ kills stacking (50%) — law 5 is replace, and a second '
              'cast is a refresh');
      expect(only<SteadfastStatus>(alice).turnsLeft, 24,
          reason: 'refreshed to 25 on the recast, then decremented once');
    });
  });

  // ======================================================================
  // Composure — the crit blanket
  // ======================================================================
  group('Composure', () {
    test('an incoming crit resolves as a normal hit', () {
      alice.critChance = 100;
      final duel = engine();
      castBy(duel, bruno, Spellbook.composure);
      castBy(duel, alice, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ kills the missing blank: a 100%-crit attacker otherwise '
              'lands 20 × 1.5 = 30 (hp 70)');
    });

    test('and the event reports the hit it became, not the crit it was', () {
      alice.critChance = 100;
      final duel = engine();
      castBy(duel, bruno, Spellbook.composure);
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final result =
          duel.resolveTurn(CastAction(dmg(20), MagicElement.pyro),
              const ForfeitAction());
      final hit = result.events.whereType<DamageEvent>().single;
      expect(hit.crit, isFalse,
          reason: '⚠️ kills a blank that suppresses the multiplier but still '
              'flags the event — the HUD would play a crit that did not happen');
    });

    test('it does nothing to an ordinary hit', () {
      final duel = engine();
      castBy(duel, bruno, Spellbook.composure);
      castBy(duel, alice, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ kills a blank that leaks into non-crit damage');
    });
  });

  // ======================================================================
  // Bloodlust — the licensed two-status exception
  // ======================================================================
  group('Bloodlust', () {
    test('grants Keen AND Heavyhand from one cast', () {
      final duel = engine();
      castBy(duel, alice, Spellbook.bloodlust);
      expect(only<KeenStatus>(alice).critChance, 20);
      expect(only<HeavyhandStatus>(alice).critDamage, 40);
      expect(alice.effectiveCritChance, 20,
          reason: '⚠️ kills a grant that never reaches the derivation seam');
      expect(alice.effectiveCritDamage, 90, reason: '50 base + 40');
      expect(only<KeenStatus>(alice).turnsLeft, 11,
          reason: '12 turns, one of them the turn it was cast');
      expect(only<HeavyhandStatus>(alice).turnsLeft, 11);
    });

    test('⭐ it OVERRIDES both existing instances, even stronger ones', () {
      // ⭐ The stat lane's REAL tier-2 stances, not stand-ins: Bloodlust
      // grants `bank_stances.dart`'s Keen and Heavyhand, so this is the
      // genuine cross-lane collision law 5 has to settle.
      alice.statuses
        ..add(KeenStatus.ardent())
        ..add(HeavyhandStatus.overkill());
      final duel = engine();
      castBy(duel, alice, Spellbook.bloodlust);
      expect(only<KeenStatus>(alice).critChance, 20);
      expect(only<HeavyhandStatus>(alice).critDamage, 40);
      expect(alice.effectiveCritChance, 20,
          reason: '⚠️ kills BOTH rejected merges at once: stacking reads 45, '
              'and keeping-the-better-half reads 25. Law 5 is last cast wins, '
              'so the burst window can genuinely cost you a longer stance');
      expect(only<KeenStatus>(alice).turnsLeft, 11,
          reason: '⚠️ and the clock is replaced too, not kept at 29 — '
              'magnitude and duration always travel together');
    });

    test('the crit it buys is still blanked by Composure', () {
      alice.statuses.add(KeenStatus(critChance: 100, turns: 12));
      final duel = engine();
      castBy(duel, bruno, Spellbook.composure);
      castBy(duel, alice, dmg(20));
      expect(bruno.hp, 80,
          reason: '⚠️ the counter-web in one line: the whole crit lane breaks '
              "on the defender's 2-charge answer");
    });
  });

  // ======================================================================
  // Death Wish — the desperation stance
  // ======================================================================
  group('Death Wish', () {
    void attackAt(int aliceHp, {bool composed = false, required int expectHp}) {
      alice.statuses.add(DeathWishStatus(turns: 10));
      if (composed) bruno.statuses.add(ComposureStatus(turns: 25));
      alice.hp = aliceHp;
      final duel = engine();
      castBy(duel, alice, dmg(20));
      expect(bruno.hp, expectHp,
          reason: 'alice at $aliceHp hp, composed: $composed');
    }

    test('⭐ it always crits below 15% of the holder\'s own max health', () {
      attackAt(14, expectHp: 70);
    });

    test('⭐ …and does nothing AT 15%, or above it', () {
      attackAt(15, expectHp: 80);
    });

    test('⭐ 15% is a strict floor, checked either side of the boundary', () {
      // Two mages, one test: the pair is what kills the off-by-one.
      final low = MageState(name: 'Low')..hp = 14;
      final high = MageState(name: 'High')..hp = 15;
      for (final m in [low, high]) {
        m.statuses.add(DeathWishStatus(turns: 10));
      }
      expect(attacksAlwaysCrit(low), isTrue);
      expect(attacksAlwaysCrit(high), isFalse,
          reason: '⚠️ THE mutant: `<=` instead of `<` turns exactly 15% into a '
              'guaranteed crit. §7a says BELOW 15%');
    });

    test('⭐ Composure still blanks it — the defender\'s rule wins', () {
      attackAt(14, composed: true, expectHp: 80);
    });

    test('it costs no extra RNG — the guarantee skips the roll entirely', () {
      // ⚠️ Lockstep: a guaranteed crit that still drew a value would desync a
      // client whose mage does not hold the stance. The scripted int here is
      // the DEFLECT roll; if Death Wish consumed it first, the deflect would
      // read 0 and fire.
      bruno
        ..deflectChance = 50
        ..deflectAmount = 50;
      alice
        ..hp = 14
        ..statuses.add(DeathWishStatus(turns: 10));
      final duel = engine(ints: [60]); // 60 < 50 is false: no deflect
      castBy(duel, alice, dmg(20));
      expect(bruno.hp, 70,
          reason: '⚠️ kills a guarantee that still rolls: that draws the 60 for '
              'the crit, leaving the deflect to read 0 < 50 and soften the hit '
              'to 15 (hp 85)');
    });

    test('the holder healing back over the line switches it off again', () {
      alice
        ..hp = 14
        ..statuses.add(DeathWishStatus(turns: 10));
      expect(attacksAlwaysCrit(alice), isTrue);
      alice.hp = 60;
      expect(attacksAlwaysCrit(alice), isFalse,
          reason: '⚠️ kills a stance that latches on first check — it is a '
              'condition read at every hit, not a flag set once');
    });
  });

  // ======================================================================
  // Reflect — the deflect mirror
  // ======================================================================
  group('Reflect', () {
    test('⭐ it returns EXACTLY the amount the deflect removed', () {
      bruno
        ..deflectChance = 100 // clamped to 90; the scripted 0 fires it
        ..deflectAmount = 50;
      final duel = engine();
      castBy(duel, bruno, Spellbook.reflect);
      castBy(duel, alice, dmg(20));
      expect(bruno.hp, 90, reason: '50% of 20 removed, 10 lands');
      expect(alice.hp, 90,
          reason: '⚠️ kills every wrong magnitude: half the deflect (95), the '
              'whole hit (80), or the landed remainder. §7a ruled 100% of the '
              'DEFLECTED amount, which is what prices the 90/90 clamps');
    });

    test('⭐ the return cannot be re-reflected, however mirrored the board', () {
      // Both mages hold Divert AND Reflect — the ping-pong the rule exists to
      // prevent.
      for (final m in [alice, bruno]) {
        m
          ..deflectChance = 100
          ..deflectAmount = 50;
        m.statuses.add(ReflectStatus(turns: 25));
      }
      final duel = engine();
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final result = duel.resolveTurn(
          CastAction(dmg(20), MagicElement.pyro), const ForfeitAction());
      final returns = result.events
          .whereType<EffectDamageEvent>()
          .where((e) => e.source == 'Reflect')
          .toList();

      expect(returns, hasLength(1),
          reason: '⚠️ THE mutant: routing the return back through the attack '
              'pipeline lets Alice deflect it and mirror it again — one hit '
              'becomes an infinite exchange');
      expect(alice.hp, 90,
          reason: '⚠️ the return is DAMAGE, not a hit: Alice\'s own 50% deflect '
              'never rolls against it, so she takes the full 10 rather than 5');
      expect(bruno.hp, 90,
          reason: '⚠️ and nothing bounces back to Bruno — he is down only the '
              '10 that Alice\'s attack actually landed');
    });

    test('the return resolves shield-first on the attacker', () {
      bruno
        ..deflectChance = 100
        ..deflectAmount = 50;
      bruno.statuses.add(ReflectStatus(turns: 25));
      final duel = engine();
      castBy(duel, alice, wall(30));
      castBy(duel, alice, dmg(20));
      expect(alice.hp, 100,
          reason: '⚠️ kills a return that strikes health directly — it is '
              'ordinary damage, and ordinary damage meets a wall');
      expect(alice.shield!.remaining, 20, reason: '30 − 10 reflected');
    });

    test('it is element-agnostic — the attacker\'s own shield never counters',
        () {
      // A Pyro attacker behind a Pyro wall: if the return carried the attack's
      // element the §0.3 counter table would change what the wall absorbs.
      bruno
        ..deflectChance = 100
        ..deflectAmount = 50;
      bruno.statuses.add(ReflectStatus(turns: 25));
      final duel = engine();
      castBy(duel, alice, wall(30), MagicElement.pyro);
      castBy(duel, alice, dmg(20), MagicElement.pyro);
      expect(alice.shield!.remaining, 20,
          reason: '⚠️ kills passing the attack element into the return: a '
              'same-element hit is soaked at 100%, but any other multiplier '
              'would leave a different remainder');
    });

    test('with nothing to deflect it does nothing at all', () {
      final duel = engine();
      castBy(duel, bruno, Spellbook.reflect);
      alice
        ..charge = 0
        ..element = MagicElement.pyro;
      final result = duel.resolveTurn(
          CastAction(dmg(20), MagicElement.pyro), const ForfeitAction());
      expect(
          result.events
              .whereType<EffectDamageEvent>()
              .where((e) => e.source == 'Reflect'),
          isEmpty,
          reason: '⚠️ kills a Reflect that fires on every hit rather than on a '
              'deflect. §7a calls the dependency deliberate: without a '
              'Divert-family source under it, this is a dead slot');
      expect(alice.hp, 100);
      expect(bruno.hp, 80);
    });
  });

  // ======================================================================
  // Mending — the spell lane's heal over time
  // ======================================================================
  group('Mending', () {
    test('Mend ticks 3% of max health per turn, from the turn it is cast', () {
      alice.hp = 50;
      final duel = engine();
      castBy(duel, alice, Spellbook.mend);
      expect(alice.hp, 53,
          reason: '⚠️ kills a HoT that only starts NEXT turn — the engine\'s '
              'cadence is "applies now, ticks now", same as Regrow and the '
              'Tonic');
      expect(only<MendingStatus>(alice).turnsLeft, 5,
          reason: '6 turns, one of them spent');
      idle(duel);
      expect(alice.hp, 56);
    });

    test('Mend pays 18% of max health across its life, Renewal 50%', () {
      alice.hp = 1;
      var duel = engine();
      castBy(duel, alice, Spellbook.mend);
      for (var i = 0; i < 10; i++) {
        idle(duel);
      }
      expect(alice.hp, 19,
          reason: '⚠️ 3% × 6 = 18 and not a point more — kills a clock that '
              'never expires');

      alice = MageState(name: 'Alice')..hp = 1;
      bruno = MageState(name: 'Bruno');
      duel = engine();
      castBy(duel, alice, Spellbook.renewal);
      for (var i = 0; i < 14; i++) {
        idle(duel);
      }
      expect(alice.hp, 51,
          reason: '⚠️ 5% × 10 = 50. The §7a retune put both totals just under '
              'the equivalent-cost shields; a drifted rate or clock breaks that');
    });

    test('⭐ Renewal over a running Mend replaces the rate AND the duration',
        () {
      alice.hp = 50;
      final duel = engine();
      castBy(duel, alice, Spellbook.mend);
      expect(alice.hp, 53);
      castBy(duel, alice, Spellbook.renewal);

      final mending = only<MendingStatus>(alice);
      expect(mending.percentPerTurn, 5,
          reason: '⚠️ kills a refresh that only resets the clock and leaves the '
              'old 3% rate running');
      expect(mending.turnsLeft, 9,
          reason: '⚠️ and kills one that only swaps the rate, leaving Mend\'s '
              '5 remaining turns — magnitude and duration travel together');
      expect(alice.hp, 58, reason: 'the new 5% rate ticked this turn');
    });

    test('⭐ …and Mend over a running Renewal replaces it DOWNWARD', () {
      // The direction that separates "last cast wins" from "keep the better
      // parts". A merge would leave 5%/10 here and quietly manufacture a spell
      // nobody priced.
      alice.hp = 50;
      final duel = engine();
      castBy(duel, alice, Spellbook.renewal);
      expect(alice.hp, 55);
      castBy(duel, alice, Spellbook.mend);

      final mending = only<MendingStatus>(alice);
      expect(mending.percentPerTurn, 3,
          reason: '⚠️ THE mutant: best-of-both merging keeps the 5% rate');
      expect(mending.turnsLeft, 5,
          reason: '⚠️ …and keeps the 9 remaining turns. Both rejected at '
              'design time: an invisible merge is an unpriced spell');
      expect(alice.hp, 58, reason: 'the weaker 3% rate ticked this turn');
    });

    test('one Mending in the spell lane, whichever granter cast it', () {
      final duel = engine();
      castBy(duel, alice, Spellbook.mend);
      castBy(duel, alice, Spellbook.renewal);
      castBy(duel, alice, Spellbook.mend);
      expect(alice.statuses.whereType<MendingStatus>(), hasLength(1),
          reason: '⚠️ kills stacking HoTs — three casts must leave one status');
    });

    test('it ticks BESIDE the other lanes, never instead of them', () {
      // Law 4: different currencies may pay twice. A belt Tonic and worn
      // Regrow are separate lanes with separate ids, so all three heal.
      alice.hp = 40;
      alice.statuses
        ..add(RegrowStatus(2))
        ..add(HealOverTimeStatus(percentPerTurn: 9, turnsLeft: 3));
      final duel = engine();
      castBy(duel, alice, Spellbook.mend);
      expect(alice.hp, 54,
          reason: '⚠️ 2 (Regrow) + 9 (Tonic) + 3 (Mending) = 14. Kills a '
              'replace-on-cast keyed on shape rather than on id, which would '
              'have Mending evict the Tonic it is supposed to sit beside');
    });

    test('the tick walks through the one healing door', () {
      // Everything the healing-received stat and (later) Wither and Blight
      // hang off. If Mending healed hp directly it would be the one heal in
      // the game they could not touch.
      alice
        ..hp = 50
        ..healingReceivedPercent = 100;
      final duel = engine();
      castBy(duel, alice, Spellbook.mend);
      expect(alice.hp, 56,
          reason: '⚠️ kills a tick that writes hp directly: 3 doubled is 6, so '
              'a bypassed door reads 53');
    });
  });
}
