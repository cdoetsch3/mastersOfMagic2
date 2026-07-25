import 'dart:math';

import 'package:mom_engine/mom_engine.dart';
import 'package:test/test.dart';

/// Note 20 — the engine records a status snapshot per event, so the UI can
/// reveal one pip at a time as each event animates instead of showing every
/// status the instant the turn resolves.
void main() {
  late MageState alice;
  late MageState bruno;

  setUp(() {
    alice = MageState(name: 'Alice');
    bruno = MageState(name: 'Bruno');
  });

  test('there is exactly one frame per event', () {
    final duel = DuelEngine(alice, bruno, rng: Random(1));
    alice
      ..charge = 2
      ..element = MagicElement.pyro;
    final r = duel.resolveTurn(
        CastAction(Spellbook.blast), const ChargeAction(MagicElement.aero));
    expect(r.frames, hasLength(r.events.length));
  });

  test('a status is absent before its event and present after', () {
    // Force an Ignite: Pyro attack with a proc roll of 0.0.
    final duel = DuelEngine(alice, bruno, rng: _Scripted([0.0]));
    alice
      ..charge = 2
      ..element = MagicElement.pyro;
    final r = duel.resolveTurn(
        CastAction(Spellbook.blast), const ForfeitAction());

    final igniteIdx = r.events.indexWhere(
        (e) => e is BuffAppliedEvent && e.description.contains('Ignited'));
    expect(igniteIdx, greaterThanOrEqualTo(0), reason: 'the burn was applied');

    // Before that event, Bruno carries no Ignite pip...
    expect(r.frames[igniteIdx - 1].mage2['ignite'], isNull,
        reason: 'not yet shown when the damage lands');
    // ...and from that event on, he does.
    expect(r.frames[igniteIdx].mage2['ignite'], isNotNull,
        reason: 'revealed exactly when its event plays');
  });

  test('the final frame matches live state', () {
    final duel = DuelEngine(alice, bruno, rng: _Scripted([0.0]));
    alice
      ..charge = 2
      ..element = MagicElement.pyro;
    final r = duel.resolveTurn(
        CastAction(Spellbook.blast), const ForfeitAction());
    final last = r.frames.last.mage2;
    expect(last['ignite'] != null,
        bruno.statuses.whereType<IgniteStatus>().isNotEmpty);
  });

  test('snapshots carry field-backed buffs too, not just TurnStatuses', () {
    final duel = DuelEngine(alice, bruno, rng: Random(1));
    alice
      ..charge = 3
      ..element = MagicElement.pyro;
    final r = duel.resolveTurn(
        CastAction(Spellbook.empower), const ForfeitAction());
    expect(r.frames.last.mage1['empower']?.magnitude, 2);
  });
}

class _Scripted implements Random {
  final List<double> doubles;
  var _i = 0;
  _Scripted(this.doubles);
  @override
  double nextDouble() => _i < doubles.length ? doubles[_i++] : 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}
