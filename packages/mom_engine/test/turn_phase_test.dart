import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

// ---- Test-double statuses ------------------------------------------------
// Phase 4 will build the real Ignite/Photosynthesis on these same primitives;
// here we use minimal stand-ins to exercise the turn-phase framework.

/// End-of-turn damage-over-time for [turnsLeft] turns (ticks on the applying
/// turn too). Shield-aware unless [bypass].
class _Burn extends TurnStatus {
  final int amount;
  int turnsLeft;
  final MagicElement? element;
  final bool bypass;
  _Burn(this.amount, this.turnsLeft, {this.element, this.bypass = false});

  @override
  String get id => 'burn';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) =>
      phase == TurnPhase.end
          ? [
              StatusDamage(amount,
                  element: element, bypassShield: bypass, source: 'Burn')
            ]
          : const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => --turnsLeft <= 0;
}

/// End-of-turn heal, effectively permanent.
class _Regen extends TurnStatus {
  final int amount;
  _Regen(this.amount);

  @override
  String get id => 'regen';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) =>
      phase == TurnPhase.end
          ? [StatusHeal(amount, source: 'Regen')]
          : const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) => false; // never expires
}

/// Start-of-turn damage (bypasses shields), one tick.
class _StartStrike extends TurnStatus {
  final int amount;
  bool _spent = false;
  _StartStrike(this.amount);

  @override
  String get id => 'startStrike';

  @override
  List<StatusOp> operationsFor(TurnPhase phase, MageState holder) =>
      phase == TurnPhase.start && !_spent
          ? [StatusDamage(amount, bypassShield: true, source: 'StartStrike')]
          : const [];

  @override
  bool advanceAndCheckExpiry(MageState holder) {
    _spent = true;
    return true; // gone after its first end-phase bookkeeping
  }
}

void main() {
  late MageState alice;
  late MageState bruno;
  late DuelEngine duel;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
    duel = DuelEngine(alice, bruno, elementEffects: false);
  });

  // A quiet turn: neither mage acts in the main phase, isolating phase effects.
  TurnResult idleTurn() =>
      duel.resolveTurn(const ForfeitAction(), const ForfeitAction());

  group('end-phase DoT / HoT', () {
    test('a burn ticks each turn and expires after its duration', () {
      bruno.statuses.add(_Burn(5, 3));
      idleTurn();
      expect(bruno.hp, 95);
      idleTurn();
      expect(bruno.hp, 90);
      idleTurn();
      expect(bruno.hp, 85);
      idleTurn();
      expect(bruno.hp, 85, reason: '3-turn burn is spent');
      expect(bruno.statuses, isEmpty);
    });

    test('burn is shield-aware (hits the shield first, with counter math)', () {
      bruno.shield = ActiveShield.elemental(MagicElement.flora, 20);
      bruno.statuses.add(_Burn(8, 1, element: MagicElement.pyro));
      idleTurn();
      expect(bruno.hp, 100, reason: 'absorbed by shield');
      // pyro counters flora → 8 doubles to 16 vs the 20 shield.
      expect(bruno.shield!.remaining, 4);
    });

    test('a bypass-shield burn ignores the shield', () {
      bruno.shield = ActiveShield.elemental(MagicElement.aqua, 20);
      bruno.statuses.add(_Burn(8, 1, bypass: true));
      idleTurn();
      expect(bruno.hp, 92);
      expect(bruno.shield!.remaining, 20);
    });

    test('emits an EffectDamageEvent, not a spell DamageEvent', () {
      bruno.statuses.add(_Burn(5, 1, bypass: true));
      final result = idleTurn();
      expect(result.events.whereType<EffectDamageEvent>(), hasLength(1));
      expect(result.events.whereType<DamageEvent>(), isEmpty);
    });
  });

  group('survivability-first ordering', () {
    test('a heal resolves before a same-turn burn that would otherwise kill',
        () {
      alice.hp = 6;
      alice.statuses.add(_Regen(10)); // heal lane (early)
      alice.statuses.add(_Burn(12, 1, bypass: true)); // damage lane (late)
      idleTurn();
      // Heals 6→16 first, then burns 16→4: survives.
      expect(alice.alive, isTrue);
      expect(alice.hp, 4);
    });

    test('heal event is emitted before the damage event', () {
      alice.hp = 50;
      alice.statuses.add(_Burn(5, 1, bypass: true));
      alice.statuses.add(_Regen(5));
      final events = idleTurn().events;
      final healIdx = events.indexWhere((e) => e is EffectHealEvent);
      final dmgIdx = events.indexWhere((e) => e is EffectDamageEvent);
      expect(healIdx, lessThan(dmgIdx));
    });
  });

  group('instant death within a phase', () {
    test('a lethal burn ends the duel immediately', () {
      bruno.hp = 4;
      bruno.statuses.add(_Burn(10, 3, bypass: true));
      final result = idleTurn();
      expect(duel.isOver, isTrue);
      expect(duel.winner, alice);
      expect(result.events.whereType<DefeatedEvent>(), hasLength(1));
    });

    test('the Haste holder dies first to symmetric lethal DoTs', () {
      alice.hp = 3;
      bruno.hp = 3;
      alice.statuses.add(_Burn(5, 1, bypass: true));
      bruno.statuses.add(_Burn(5, 1, bypass: true));
      bruno.hasHaste = true; // Bruno's tick resolves first at the same lane
      idleTurn();
      expect(duel.isOver, isTrue);
      expect(duel.isDraw, isFalse, reason: 'ties are impossible with Haste');
      expect(duel.winner, alice, reason: 'the Haste holder (Bruno) dies first');
    });

    test('no Haste: symmetric lethal DoTs still resolve deterministically',
        () {
      // With nobody holding Haste, the seq tiebreak (mage1 first) decides —
      // still a single winner, never a draw, and always the same one.
      alice.hp = 3;
      bruno.hp = 3;
      alice.statuses.add(_Burn(5, 1, bypass: true));
      bruno.statuses.add(_Burn(5, 1, bypass: true));
      idleTurn();
      expect(duel.isDraw, isFalse);
      expect(duel.winner, bruno, reason: 'mage1 (Alice) ticks first, dies');
    });
  });

  group('start phase', () {
    test('start-of-turn damage resolves before the main action', () {
      // Bruno at 4hp with a 5-damage start strike dies before he can act.
      bruno.hp = 4;
      bruno.statuses.add(_StartStrike(5));
      // Even though Bruno "commits" an attack, he never gets to cast it.
      final result = duel.resolveTurn(
        const ForfeitAction(),
        CastAction(Spellbook.flick, MagicElement.pyro), // 0-cost, legal at 0
      );
      expect(duel.isOver, isTrue);
      expect(duel.winner, alice);
      expect(alice.hp, 100, reason: "Bruno's Flick never resolved");
      expect(result.events.whereType<SpellCastEvent>(), isEmpty);
    });
  });

  group('framework integration', () {
    test('statuses do not perturb an ordinary duel with none applied', () {
      // Geo has no on-cast effect yet, so no statuses can appear.
      final r = duel.resolveTurn(
        CastAction(Spellbook.flick, MagicElement.geo),
        const ChargeAction(MagicElement.aqua),
      );
      expect(r.events.whereType<EffectDamageEvent>(), isEmpty);
      expect(r.events.whereType<EffectHealEvent>(), isEmpty);
    });

    test('end phase is skipped when the main phase ends the duel', () {
      bruno.hp = 5;
      bruno.statuses.add(_Regen(50)); // would heal if the end phase ran
      alice
        ..charge = 2
        ..element = MagicElement.pyro;
      duel.resolveTurn(
        CastAction(Spellbook.blast, MagicElement.pyro), // ~20-26, lethal
        const ForfeitAction(),
      );
      expect(duel.isOver, isTrue);
      expect(bruno.alive, isFalse, reason: 'no end-phase Regen save');
    });

    test('phase resolution is deterministic across identical runs', () {
      List<String> run() {
        final a = MageState(name: 'A')..hp = 40;
        final b = MageState(name: 'B')..hp = 40;
        a.statuses.add(_Burn(3, 5, bypass: true));
        b.statuses
          ..add(_Regen(2))
          ..add(_Burn(4, 5, bypass: true));
        final d = DuelEngine(a, b, elementEffects: false);
        final log = <String>[];
        for (var i = 0; i < 4; i++) {
          log.addAll(d
              .resolveTurn(const ForfeitAction(), const ForfeitAction())
              .events
              .map((e) => e.toString()));
        }
        return log;
      }

      expect(run(), run());
    });
  });
}
