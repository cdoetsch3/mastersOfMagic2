import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';
import 'package:mom_engine/mom_engine.dart';

/// ✅ **RULING (Christian, playtest 2026-09-30, note 6): enemy moves sit on
/// the priority ladder** — 1–2 (quickened strikes), 3 (shields), 5 (quick),
/// 7–8 (auxiliary), 9 (the standard attack) — and an ATTACK goes at 9
/// unless something thematic or telegraphed sends it first. 51 moves that
/// had drifted to 4 and 6 were re-pinned: the 28 one-charge countdown jabs
/// to the quick band, the 23 heavier attacks to 9. This pins that no zone
/// drifts off the ladder again. Mages (spellbook loadouts) are exempt:
/// their spells carry the Spellbook's own priorities.
/// The heavy attacks that go FIRST on purpose — the thematic exemption the
/// ruling allows. ⚠️ Add to this set only with a reason the move's own name
/// or doc comment carries: Ashfall's Executioner says "Take It Fast".
const fastByName = {'av_takeitfast'};

void main() {
  test('⭐ every creature move sits on the priority ladder', () {
    const ladder = {1, 2, 3, 5, 7, 8, 9};
    final off = <String>[
      for (final e in Bestiary.all)
        if (!e.isMage)
          for (final m in e.moves)
            if (!ladder.contains(m.priority))
              '${e.zoneId}/${m.id} at ${m.priority}',
    ];
    expect(
      off,
      isEmpty,
      reason:
          'kills a move authored at priority 4 or 6 (the 2026-09-30 snap) '
          'and any future drift off the 1/2/3/5/7/8/9 ladder',
    );
  });

  test('⭐ a three-charge-or-heavier damage move never sits in the quick or '
      'auxiliary band', () {
    final offenders = <String>[
      for (final e in Bestiary.all)
        if (!e.isMage)
          for (final m in e.moves)
            if (m.chargeCost >= 3 &&
                m.effect is DamageEffect &&
                const {5, 7, 8}.contains(m.priority) &&
                !fastByName.contains(m.id))
              '${e.zoneId}/${m.id} c${m.chargeCost} at ${m.priority}',
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'kills the 2026-09-30 snap that put boss heavy hits at 7 (ahead of '
          "the player's Discharge at 8) and Redoubt drains at 5 — Christian: "
          'an attack goes at 9 unless it is thematic or telegraphed',
    );
  });

  test('the standard attack priority is the common case', () {
    final all = [
      for (final e in Bestiary.all)
        if (!e.isMage)
          for (final m in e.moves) m.priority,
    ];
    final atNine = all.where((p) => p == 9).length;
    expect(
      atNine,
      greaterThan(all.length ~/ 3),
      reason:
          'kills a snap that moved attacks off 9 by mistake — 328 of 713 '
          'moves sat there on 2026-09-30',
    );
  });
}
