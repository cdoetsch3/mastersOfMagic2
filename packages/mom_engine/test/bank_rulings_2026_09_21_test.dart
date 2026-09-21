import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// The five playtest rulings of **2026-09-21** (Christian), pinned where a
/// retune would otherwise drift back.
///
/// 1. Bloodlust 12 → 25 turns, on BOTH granted statuses.
/// 2. Death Wish 10 → 25 turns.
/// 3. Overkill 4 → 3 charge.
/// 4. Torment 9 → 8 ticks (Torment + Scour was too strong).
/// 5. A landed Waterlogged TAKES Haste off the mage it slowed.
///
/// ⭐ A file per ruling-batch, not edits spread through the lane files: when
/// the next playtest reverses one of these, the pin to argue with is findable
/// by date. Every `expect` below was mutation-verified — watched to fail
/// against the pre-ruling value (or the obvious wrong build of the Haste
/// transfer) before it was allowed to stand.

/// `nextDouble` walks [doubles] then returns 0.99; `nextInt` walks [ints] then
/// returns 0 — matching `bank_specials_test`, so damage rolls take their
/// minimum and guarded chances fire.
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

void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  DuelEngine engine({bool elementEffects = false}) => DuelEngine(alice, bruno,
      rng: ScriptedRandom(),
      elementEffects: elementEffects,
      baseMissPercent: 0);

  /// Alice casts [s]; Bruno does nothing.
  TurnResult cast(DuelEngine d, Spell s,
      [MagicElement e = MagicElement.pyro]) {
    alice
      ..charge = s.chargeCost
      ..element = e;
    return d.resolveTurn(CastAction(s, e), const ForfeitAction());
  }

  TurnResult idle(DuelEngine d) =>
      d.resolveTurn(const ForfeitAction(), const ForfeitAction());

  T only<T extends TurnStatus>(MageState m) {
    final found = m.statuses.whereType<T>().toList();
    expect(found, hasLength(1), reason: 'expected exactly one $T on ${m.name}');
    return found.single;
  }

  BankDotStatus? dotOn(MageState m, String id) =>
      m.statuses.whereType<BankDotStatus>().where((s) => s.id == id).firstOrNull;

  // =========================================================================
  // Rulings 1–2 — the stance clocks
  // =========================================================================
  group('the stance clocks (rulings 1 & 2)', () {
    test('⭐ Bloodlust runs 25 turns, and BOTH of its statuses do', () {
      final duel = engine();
      cast(duel, Spellbook.bloodlust);
      expect(only<KeenStatus>(alice).turnsLeft, 24,
          reason: '⚠️ THE pin: 25 turns, one of them the turn it was cast. A '
              'mutant left on the pre-ruling 12 reads 11');
      expect(only<HeavyhandStatus>(alice).turnsLeft, 24,
          reason: '⚠️ and the SECOND status moved too — retuning only '
              'bloodlustKeen leaves the licensed pair on split clocks, which '
              'is the whole exception coming apart');
      expect(only<KeenStatus>(alice).critChance, 20,
          reason: '⚠️ the magnitudes are UNCHANGED by this ruling — a mutant '
              'that retuned +20% while it was in there fails here');
      expect(only<HeavyhandStatus>(alice).critDamage, 40,
          reason: '⚠️ likewise +40; the ruling bought duration, nothing else');
      expect(Spellbook.bloodlust.chargeCost, 5,
          reason: '⚠️ and the 5-charge price point is untouched');
    });

    test('⭐ Bloodlust is still SHORTER than Ardent, so law 5 still bites', () {
      // The point of the 25, and the reason it is not 30: the override in
      // §7a has to keep costing you something.
      alice.statuses.add(KeenStatus.ardent()); // 30 turns
      final duel = engine();
      cast(duel, Spellbook.bloodlust);
      expect(only<KeenStatus>(alice).turnsLeft, 24,
          reason: '⚠️ kills a merge that keeps the longer clock (29) — law 5 '
              'is last cast wins, and at 25 the window is still a downgrade '
              "from Ardent's 30");
    });

    test('⭐ Death Wish runs 25 turns', () {
      final duel = engine();
      cast(duel, Spellbook.deathWish);
      expect(only<DeathWishStatus>(alice).turnsLeft, 24,
          reason: '⚠️ THE pin: 25 turns (re-ruled from 10 on 2026-09-21). A '
              'mutant left on 10 reads 9');
      expect(Spellbook.deathWish.chargeCost, 2,
          reason: '⚠️ the 2-charge price point is unchanged by the ruling');
    });

    test('the Death Wish clock really runs out at 25, not before', () {
      final duel = engine();
      cast(duel, Spellbook.deathWish);
      for (var i = 0; i < 23; i++) {
        idle(duel);
      }
      expect(only<DeathWishStatus>(alice).turnsLeft, 1,
          reason: '⚠️ 24 turns spent of 25 — a mutant on the old 10 expired '
              'fourteen turns ago and there is no status left to read');
      idle(duel);
      expect(alice.statuses.whereType<DeathWishStatus>(), isEmpty,
          reason: '⚠️ and it does expire — kills a clock that never reaches 0');
    });
  });

  // =========================================================================
  // Ruling 3 — Overkill's price
  // =========================================================================
  group("Overkill's price (ruling 3)", () {
    test('⭐ Overkill costs 3 charge', () {
      expect(Spellbook.overkill.chargeCost, 3,
          reason: '⚠️ THE pin: 4 → 3, ruled 2026-09-21. Crit damage pays '
              'nothing until something is critting, so the old 4 charged a '
              'two-spell combo a one-spell premium');
      expect(Spellbook.heavyhand.chargeCost, 2,
          reason: '⚠️ and the cheap half of the SET did not move with it — a '
              'blanket retune of the Heavyhand set fails here');
    });

    test('a 3-charge bar is now enough to cast it', () {
      alice
        ..charge = 3
        ..element = MagicElement.pyro;
      final duel = engine();
      duel.resolveTurn(
          CastAction(Spellbook.overkill, MagicElement.pyro),
          const ForfeitAction());
      expect(only<HeavyhandStatus>(alice).critDamage, 50,
          reason: '⚠️ the cast RESOLVED off three charge — a mutant still '
              'priced at 4 fizzles and grants nothing');
    });

    test('and it still buys the long clock, which is what the charge is for',
        () {
      final duel = engine();
      cast(duel, Spellbook.overkill);
      expect(only<HeavyhandStatus>(alice).turnsLeft, 29,
          reason: '⚠️ 30 turns, unchanged — the ruling cut the price, not the '
              'stance. A mutant that "rebalanced" the duration too fails here');
    });
  });

  // =========================================================================
  // Ruling 4 — Torment's ticks
  // =========================================================================
  group("Torment's ticks (ruling 4)", () {
    test('⭐ Torment applies 8 ticks worth 40, and pays one of them at once',
        () {
      // ⚠️ Two numbers, because the cadence splits them. The SPELL applies 8
      // ticks = 40; the burn on the board has already paid one by the time
      // the turn ends ("applies now, ticks now"), so it reads 7 / 35.
      final def = Spellbook.torment.effect as DotAttackEffect;
      expect(def.ticks, 8,
          reason: '⚠️ THE pin: 9 → 8 ticks, ruled 2026-09-21 (Torment + Scour '
              'was too strong). Read off the definition, so a mutant on 9 '
              'fails here whatever the cadence does');
      expect(def.damagePerTick, 5,
          reason: '⚠️ the TICK is unchanged at 5 — the ruling cut the count, '
              'not the rate, so the applied total is 8 × 5 = 40');
      expect(def.damagePerTick * def.ticks, 40,
          reason: '⚠️ 40 over time, ~49 with the 8–10 hit. A mutant on 9 '
              'ticks applies 45');

      final duel = engine();
      cast(duel, Spellbook.torment);
      final burn = dotOn(bruno, 'torment')!;
      expect(burn.ticksLeft, 7,
          reason: '⚠️ 8 applied minus the one paid on the application turn — '
              'a mutant on 9 reads 8 here');
      expect(burn.damagePerTick, 5,
          reason: 'the rate travelled onto the status unchanged');
    });

    test('⭐ Torment pays exactly 40 over its life, plus the 8–10 hit', () {
      final duel = engine();
      cast(duel, Spellbook.torment);
      for (var i = 0; i < 7; i++) {
        idle(duel);
      }
      expect(bruno.hp, 100 - 8 - 40,
          reason: '⚠️ the minimum hit (8) then 8 × 5 = 40 over eight turns, '
              '~49 in total on an average hit. A mutant on 9 ticks has paid '
              'only 35 by here and reads 57');
      expect(dotOn(bruno, 'torment'), isNull,
          reason: '⚠️ and the burn is SPENT — a 9-tick Torment is still on '
              'the board here, owing one more 5');
    });

    test('⭐ Torment then Scour detonates for exactly 40 — nothing else', () {
      // The ruling's actual target: the combo. Scour collects every remaining
      // tick as ONE hit, so the tick count is the payout.
      final duel = engine();
      cast(duel, Spellbook.torment);
      // The application turn already paid one tick, so 7 × 5 = 35 is owed.
      expect(dotOn(bruno, 'torment')!.remainingDamage, 35,
          reason: '⚠️ 7 ticks still owed after the application tick — a '
              'mutant on 9 ticks owes 40 here and detonates for 5 more');
      final before = bruno.hp;
      final r = cast(duel, Spellbook.scour);
      expect(before - bruno.hp, 35,
          reason: '⚠️ THE combo pin: Scour collects the 35 still owed and not '
              'a point more. A mutant left on 9 ticks pays 40 — which is the '
              '5 damage this ruling exists to remove');
      expect(r.events.whereType<DamageEvent>().length, 1,
          reason: 'ONE combined packet, as Scour always was — this test is '
              'about the SIZE of it, not its shape');
      expect(bruno.statuses.whereType<DamageOverTime>(), isEmpty,
          reason: 'and the burn is consumed by the collection');
    });

    test('a Torment collected the turn it lands is worth 40 all in', () {
      // The full-value line: the whole 40 is on the board before the first
      // tick is paid, so this is the number the re-rule actually moved.
      final def = Spellbook.torment.effect as DotAttackEffect;
      bruno.statuses.add(BankDotStatus(
          id: 'torment',
          name: 'Torment',
          damagePerTick: def.damagePerTick,
          ticks: def.ticks));
      expect(dotOn(bruno, 'torment')!.remainingDamage, 40,
          reason: '⚠️ 8 × 5 = 40 read straight off the SPELL DEFINITION, not '
              'off a literal — a mutant that retunes the spell but not this '
              'lane would have to pass here too, and cannot');
    });
  });

  // =========================================================================
  // Ruling 5 — Waterlogged takes Haste
  // =========================================================================
  group('Waterlogged takes Haste (ruling 5)', () {
    /// Alice runs an Aqua streak; the 3rd consecutive cast lands Waterlogged.
    /// Bruno forfeits throughout, which moves no Haste of its own.
    void aquaStreak(DuelEngine d, {int casts = 3}) {
      for (var i = 0; i < casts; i++) {
        alice
          ..charge = 1
          ..element = MagicElement.aqua;
        d.resolveTurn(
            CastAction(Spellbook.bolt, MagicElement.aqua),
            const ForfeitAction());
      }
    }

    DuelEngine live() => DuelEngine(alice, bruno,
        rng: Random(1), elementEffects: true, baseMissPercent: 0);

    test('⭐ (a) it takes the token off the mage it slowed', () {
      bruno.hasHaste = true;
      final duel = live();
      aquaStreak(duel);
      expect(bruno.priorityPenalty, 10,
          reason: 'the 3rd consecutive Aqua cast landed Waterlogged — the '
              'precondition for everything below');
      expect(alice.hasHaste, isTrue,
          reason: '⚠️ THE pin (ruled 2026-09-21): the water takes the '
              'initiative. Slowing a mage and leaving them the same-priority '
              'tiebreak was the two halves of one idea disagreeing');
      expect(bruno.hasHaste, isFalse,
          reason: '⚠️ and it LEFT the target — kills a build that copies the '
              'token instead of moving it, putting both mages on Haste');
      expect(duel.hasteHolder, same(alice),
          reason: 'the engine agrees with the flags');
    });

    test('⭐ (a2) it reports through the SAME event the Tailwind grab uses', () {
      // The UI's Haste indicator watches exactly one event kind. A transfer
      // the engine performs silently is a desynced pip.
      bruno.hasHaste = true;
      final duel = live();
      alice
        ..charge = 1
        ..element = MagicElement.aqua;
      duel.resolveTurn(
          CastAction(Spellbook.bolt, MagicElement.aqua),
          const ForfeitAction());
      alice
        ..charge = 1
        ..element = MagicElement.aqua;
      duel.resolveTurn(
          CastAction(Spellbook.bolt, MagicElement.aqua),
          const ForfeitAction());
      alice
        ..charge = 1
        ..element = MagicElement.aqua;
      final r = duel.resolveTurn(
          CastAction(Spellbook.bolt, MagicElement.aqua),
          const ForfeitAction());
      final moved = r.events.whereType<HasteChangedEvent>().toList();
      expect(moved, hasLength(1),
          reason: '⚠️ exactly one HasteChangedEvent on the turn the token '
              'moves — kills both a silent transfer (0) and a second, '
              'parallel mechanism firing alongside the first (2)');
      expect(moved.single.holder, same(alice),
          reason: '⚠️ and it names the CASTER as the new holder, not the '
              'target it was taken from');
    });

    test('⭐ (b) Photosynthesis blocks Waterlogged, so Haste does not move', () {
      // The transfer lives INSIDE the `if` that applies the penalty. Nothing
      // lands, so nothing moves.
      bruno
        ..hasHaste = true
        ..streakElement = MagicElement.flora
        ..streakCount = 5
        ..statuses.add(PhotosynthesisStatus());
      final duel = live();
      aquaStreak(duel);
      expect(bruno.priorityPenalty, 0,
          reason: 'immune while Photosynthesis is live — the block still works');
      expect(bruno.hasHaste, isTrue,
          reason: '⚠️ THE pin: a BLOCKED Waterlogged takes nothing. Kills a '
              'transfer hoisted out of the penalty `if` — it would steal '
              'Haste off a mage who shrugged the debuff off entirely');
      expect(alice.hasHaste, isFalse,
          reason: '⚠️ and the caster gains nothing for a whiffed streak');
    });

    test('⭐ (b2) grace blocks it too, and grace keeps the token', () {
      bruno
        ..hasHaste = true
        ..hasGrace = true;
      final duel = live();
      aquaStreak(duel);
      expect(bruno.priorityPenalty, 0,
          reason: 'grace ate the debuff — the other half of the same `if`');
      expect(bruno.hasHaste, isTrue,
          reason: '⚠️ the same hoisting mutant as (b), through the OTHER '
              'block. Grace blocks the debuff outright, so there is no '
              'Waterlogged for the token to ride out on');
    });

    test('⭐ (c) Cleansing the Waterlogged does NOT hand Haste back', () {
      bruno.hasHaste = true;
      final duel = live();
      aquaStreak(duel);
      expect(alice.hasHaste, isTrue, reason: 'the token moved, as in (a)');
      // The real removal closure — this is exactly what `_resolveCleanse`
      // calls once it has picked a debuff.
      debuffsOn(bruno).firstWhere((d) => d.id == 'waterlogged').remove();
      expect(bruno.priorityPenalty, 0, reason: 'the debuff is genuinely gone');
      expect(alice.hasHaste, isTrue,
          reason: '⚠️ THE pin: the token MOVED, the debuff did not carry it. '
              'Kills a build that parks Haste on the Waterlogged status and '
              'restores it on removal — Cleanse buys your priority back, '
              'never the initiative');
      expect(bruno.hasHaste, isFalse,
          reason: '⚠️ the same mutant from the other side');
    });

    test('⭐ (d) with nobody holding Haste, Waterlogged grants none', () {
      // Waterlogged only TAKES. It never establishes initiative from nothing.
      //
      // ⚠️ **Bruno must CAST, not forfeit.** While Haste is unheld the first
      // non-channel cast grabs it (the pre-existing establishment rule), so an
      // Aqua caster swinging at a forfeiting opponent ends up holding Haste
      // for reasons that have nothing to do with this ruling — and the mutant
      // below would hide behind that. A same-priority pair every turn leaves
      // the token genuinely contested, which is the only board on which the
      // gate is observable.
      final duel = live();
      expect(duel.hasteHolder, isNull, reason: 'nobody holds it to start');
      for (var i = 0; i < 3; i++) {
        alice
          ..charge = 1
          ..element = MagicElement.aqua;
        bruno
          ..charge = 1
          ..element = MagicElement.geo;
        duel.resolveTurn(CastAction(Spellbook.bolt, MagicElement.aqua),
            CastAction(Spellbook.bolt, MagicElement.geo));
      }
      expect(bruno.priorityPenalty, 10, reason: 'Waterlogged still landed');
      expect(alice.hasHaste, isFalse,
          reason: '⚠️ THE mutant this kills: an unconditional grant. Dropping '
              'the `target.hasHaste` gate hands the Aqua caster a free '
              'initiative off every third cast, which is a different spell');
      expect(bruno.hasHaste, isFalse,
          reason: '⚠️ and it certainly does not land on the target');
      expect(duel.hasteHolder, isNull,
          reason: 'still contested — the engine agrees');
    });

    test('a 2nd consecutive Aqua cast takes nothing — the streak gate holds',
        () {
      bruno.hasHaste = true;
      final duel = live();
      aquaStreak(duel, casts: 2);
      expect(bruno.priorityPenalty, 0, reason: 'no Waterlogged on cast 2 of 3');
      expect(bruno.hasHaste, isTrue,
          reason: '⚠️ kills a transfer wired to the Aqua ARM rather than to '
              'the landed debuff — it would fire on every Aqua cast');
    });
  });
}
