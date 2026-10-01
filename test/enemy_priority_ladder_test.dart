import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/enemies/bestiary.dart';

/// ✅ **RULING (Christian, playtest 2026-09-30, note 6): enemy moves sit on
/// the priority ladder** — 1–2 (quickened strikes), 3 (shields), 5 (quick),
/// 7–8 (auxiliary), 9 (the standard attack). 51 moves that had drifted to 4
/// and 6 were snapped to 5 and 7 by script; this pins that no zone drifts
/// off the ladder again. Mages (spellbook loadouts) are exempt: their spells
/// carry the Spellbook's own priorities.
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
